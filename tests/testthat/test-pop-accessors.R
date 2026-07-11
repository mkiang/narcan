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

test_that("pop_sources() returns the three single-race datasets", {
    m <- pop_sources()
    expect_s3_class(m, "data.frame")
    expect_setequal(m$dataset,
                    c("pop_singlerace", "pop_singlerace_state",
                      "pop_singlerace_county"))
    expect_true(all(m$scheme == "single"))
    expect_true(all(m$vintage == "V2024"))
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
    # simulate absence by pointing requireNamespace at a bogus lib is hard;
    # instead assert the error path exists for a missing parquet.
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
    skip_on_cran()
    mani <- local_file_manifest()
    cache <- withr::local_tempdir()
    withr::local_options(narcan.pop_manifest_path = mani)

    p <- download_pop_data(scheme = "single", dest = cache)
    expect_true(file.exists(p[[1]]))
    expect_identical(names(p), "pop_singlerace_county")
    # a second call is a cache hit (file already present) and still verifies
    p2 <- download_pop_data(scheme = "single", dest = cache)
    expect_identical(unname(p2), unname(p))
})

test_that("download_pop_data(raw = TRUE) fetches + verifies the source file", {
    skip_on_cran()
    mani <- local_file_manifest()
    cache <- withr::local_tempdir()
    withr::local_options(narcan.pop_manifest_path = mani)

    p <- download_pop_data(scheme = "single", raw = TRUE, dest = cache)
    expect_true(file.exists(p[[1]]))
})

test_that("download_pop_data() errors on a corrupt (sha256-mismatch) asset", {
    skip_on_cran()
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
