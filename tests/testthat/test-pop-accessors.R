# Descriptive population accessors + the provenance-driven downloader (P5 /
# 0.5.0). County reads run against the bundled fixture parquet; the download flow
# runs OFFLINE against a temp manifest with file:// URLs (no network, no
# httptest2). CI must never hit github.com / www2.census.gov here.

county_fixture <- function() {
    fx <- system.file("extdata", "pop_singlerace_county_fixture.parquet",
                      package = "narcan")
    if (!nzchar(fx) || !file.exists(fx)) skip("county fixture not installed")
    fx
}

# ---- manifest + pop_sources() -------------------------------------------------

test_that("pop_sources() lists the 0.5.1 single-race + bridged datasets", {
    m <- pop_sources()
    expect_s3_class(m, "data.frame")
    expect_setequal(m$dataset,
                    c("pop_singlerace", "pop_singlerace_state",
                      "pop_singlerace_full", "pop_bridged",
                      "pop_singlerace_county_full", "pop_singlerace_state_full",
                      "pop_bridged_state", "pop_bridged_county"))
    expect_setequal(unique(m$scheme), c("single", "bridged"))
})

test_that("manifest is current: backfill/bridged coverage + one asset per scheme x grain", {
    # Regression against a stale asset silently shipping (CP-3/CP-4). The routing
    # advertises single-race 2000-2024 and bridged 1969-2024; the resolvable
    # assets must actually span that, and .pop_asset_path requires exactly one
    # asset row per (scheme, grain) (D-COUNTYASSET supersede).
    m <- narcan:::.pop_manifest()
    row <- function(ds) m[m$dataset == ds, ]
    for (ds in c("pop_singlerace_full", "pop_singlerace_county_full",
                 "pop_singlerace_state_full")) {
        expect_equal(row(ds)$year_min, "2000")
        expect_equal(row(ds)$year_max, "2024")
    }
    for (ds in c("pop_bridged", "pop_bridged_state", "pop_bridged_county")) {
        expect_equal(row(ds)$year_min, "1969")
        expect_equal(row(ds)$year_max, "2024")
    }
    # exactly one downloadable asset per (scheme, grain) that ships an asset
    assets <- m[nzchar(m$asset_url), ]
    counts <- table(paste(assets$scheme, assets$grain))
    expect_true(all(counts == 1L))
    expect_setequal(names(counts),
                    c("single county", "single state", "bridged county",
                      "bridged state"))
})

# ---- get_pop_state() ----------------------------------------------------------

test_that("get_pop_state() origin levels reconcile to the finest cells", {
    src <- narcan::pop_singlerace_state
    src <- src[src$state_fips == "06" & src$year == 2024L, ]

    all_ca <- get_pop_state(states = "06", years = 2024L)
    expect_true(all(all_ca$hispanic_origin == "all"))
    expect_equal(sum(all_ca$pop), sum(src$pop))

    nh <- get_pop_state(states = "06", years = 2024L,
                        hispanic_origin = "non_hispanic")
    h <- get_pop_state(states = "06", years = 2024L,
                       hispanic_origin = "hispanic")
    expect_equal(sum(nh$pop) + sum(h$pop), sum(src$pop))
})

# ---- get_pop_county() ---------------------------------------------------------

test_that("get_pop_county() reads the fixture and reconciles to the state file", {
    skip_if_not_installed("duckdb")
    fx <- county_fixture()

    wy <- get_pop_county(states = "56", parquet = fx)
    expect_true(all(wy$state_fips == "56"))
    expect_true(all(wy$hispanic_origin == "all"))

    # county->state aggregation == the bundled state .rda for Wyoming
    bundled <- narcan::pop_singlerace_state
    bundled <- bundled[bundled$state_fips == "56", ]
    expect_equal(sum(wy$pop), sum(bundled$pop))
})

test_that("get_pop_county() filters years + counties via pushdown", {
    skip_if_not_installed("duckdb")
    fx <- county_fixture()
    one <- get_pop_county(years = 2024L, parquet = fx)
    expect_setequal(one$year, 2024L)
    expect_true(nchar(one$county_fips[1]) == 5L)
})

test_that("get_pop_county() names the duckdb fix when duckdb is absent", {
    # mock duckdb (and DBI) absence at the source
    local_mocked_bindings(requireNamespace = function(package, ...) FALSE,
                          .package = "base")
    expect_error(get_pop_county(states = "56"), "needs the 'duckdb' package")

    # add_pop_counts()'s county auto-route must give the SAME named-fix error
    df <- data.frame(state_fips = "56", county_fips = "56001", year = 2024L,
                     age = 40L, sex = "male", race = "asian_only", deaths = 1)
    expect_error(
        add_pop_counts(df, race_scheme = "single",
                       by_vars = c("state_fips", "county_fips", "year", "age",
                                   "sex", "race")),
        "needs the 'duckdb' package")
})

test_that("get_pop_county() errors clearly on a missing parquet", {
    skip_if_not_installed("duckdb")
    expect_error(
        get_pop_county(parquet = tempfile(fileext = ".parquet")),
        "not found")
})

# ---- download_pop_data() OFFLINE via a file:// manifest -----------------------

## Build a temp manifest whose asset_url/source_url are file:// paths to local
## fixtures, with correct sha256s, so the real download+verify+cache logic runs
## without network.
local_file_manifest <- function(env = parent.frame()) {
    fx <- county_fixture()
    raw_src <- withr::local_tempfile(fileext = ".csv", .local_envir = env)
    writeLines(c("a,b", "1,2"), raw_src)
    sha <- function(p) unname(tools::sha256sum(p))
    as_url <- function(p) paste0("file://", normalizePath(p, winslash = "/"))

    mani <- withr::local_tempfile(fileext = ".csv", .local_envir = env)
    df <- data.frame(
        dataset = c("pop_singlerace_county"),
        scheme = "single", grain = "county", source = "census_pep_v2024",
        source_url = as_url(raw_src), source_sha256 = sha(raw_src),
        asset_url = as_url(fx), asset_sha256 = sha(fx),
        vintage = "V2024", downloaded_on = "2026-07-11",
        n_rows = "49680", year_min = "2020", year_max = "2024", note = "test",
        stringsAsFactors = FALSE)
    utils::write.csv(df, mani, row.names = FALSE)
    mani
}

test_that("download_pop_data() fetches + sha256-verifies the processed asset", {
    mani <- local_file_manifest()
    cache <- withr::local_tempdir()
    withr::local_options(narcan.pop_manifest_path = mani)

    p <- download_pop_data(scheme = "single", dest = cache)
    expect_true(file.exists(p[[1]]))
    expect_identical(names(p), "pop_singlerace_county")
    # a second call is a cache hit: same path AND not re-downloaded (mtime held)
    mt <- file.mtime(p[[1]])
    p2 <- download_pop_data(scheme = "single", dest = cache)
    expect_identical(unname(p2), unname(p))
    expect_identical(file.mtime(p2[[1]]), mt)
})

test_that("download_pop_data(raw = TRUE) fetches + verifies the source file", {
    mani <- local_file_manifest()
    cache <- withr::local_tempdir()
    withr::local_options(narcan.pop_manifest_path = mani)

    p <- download_pop_data(scheme = "single", raw = TRUE, dest = cache)
    expect_true(file.exists(p[[1]]))
})

test_that("download_pop_data() errors on a corrupt (sha256-mismatch) asset", {
    fx <- county_fixture()
    cache <- withr::local_tempdir()
    mani <- withr::local_tempfile(fileext = ".csv")
    df <- data.frame(
        dataset = "pop_singlerace_county", scheme = "single", grain = "county",
        source = "census_pep_v2024", source_url = "", source_sha256 = "",
        asset_url = paste0("file://", normalizePath(fx, winslash = "/")),
        asset_sha256 = strrep("0", 64L),          # deliberately wrong
        vintage = "V2024", downloaded_on = "2026-07-11", n_rows = "1",
        year_min = "2020", year_max = "2024", note = "bad",
        stringsAsFactors = FALSE)
    utils::write.csv(df, mani, row.names = FALSE)
    withr::local_options(narcan.pop_manifest_path = mani)
    expect_error(download_pop_data(scheme = "single", dest = cache),
                 "sha256 mismatch")
})
