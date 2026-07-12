# Routing for the single-race BACKFILL (0.5.1, P4). Single-race now spans
# 2000-2024, but the bundled frozen 0.5.0 tables (pop_singlerace,
# pop_singlerace_state) cover 2020-2024 only. .route_pop_slice() and the
# descriptive accessors must send any request that reaches a pre-2020 year to the
# *_full backfill (national bundled, state/county via parquet) and otherwise stay
# on the dependency-free frozen table. Every death frame is built from the REAL
# bundled tables / fixtures, so keys are valid by construction and no network is
# touched. The state/county *_full parquets ship as Release assets in P5; here
# they are stood in for by the bundled WY fixtures.

cty_fixture <- function() {
    fx <- system.file("extdata", "pop_singlerace_county_fixture.parquet",
                      package = "narcan")
    if (!nzchar(fx) || !file.exists(fx)) skip("county fixture not installed")
    fx
}

# ---- .route_pop_slice(): factor-safe pre-2020 gate ----------------------------

test_that(".route_pop_slice is factor-safe: a 2024 factor year picks the frozen table", {
    df <- data.frame(year = factor("2024"), age = 25, sex = "male",
                     race = "white_only")
    sl <- narcan:::.route_pop_slice(
        df, by_vars = c("year", "age", "sex", "race"), scheme = "single")
    # frozen pop_singlerace (2020-2024), NOT the 2000-2024 *_full. A bare
    # as.integer(factor("2024")) would be level code 1 (< 2020) and mis-route.
    expect_setequal(sl$year, 2020:2024)
})

test_that(".route_pop_slice sends a pre-2020 national year to pop_singlerace_full", {
    df <- data.frame(year = 2005L, age = 25, sex = "male", race = "white_only")
    sl <- narcan:::.route_pop_slice(
        df, by_vars = c("year", "age", "sex", "race"), scheme = "single")
    expect_setequal(sl$year, 2000:2024)
})

# ---- add_pop_counts(): national backfill join ---------------------------------

test_that("a 2005 single national join matches the backfill with no NA", {
    f <- narcan::pop_singlerace_full
    keys <- dplyr::distinct(f[f$year == 2005L, ], year, age, sex, race)
    keys$deaths <- 1
    out <- add_pop_counts(keys, race_scheme = "single",
                          by_vars = c("year", "age", "sex", "race"))
    expect_false(anyNA(out$pop))
    expect_equal(nrow(out), nrow(keys))
    # per-cell pop sums over the origin dimension -> the 2005 national total
    expect_equal(sum(out$pop), sum(f$pop[f$year == 2005L]))
})

test_that("a yearless (pooled) single national frame uses the frozen 2020-2024 window", {
    keys <- dplyr::distinct(narcan::pop_singlerace, age, sex, race)  # no year col
    keys$deaths <- 1
    out <- suppressWarnings(
        add_pop_counts(keys, race_scheme = "single",
                       by_vars = c("age", "sex", "race")))
    expect_false(anyNA(out$pop))
    # pooled denominator == the frozen table total (2020-2024), not 2000-2024
    expect_equal(sum(out$pop), sum(narcan::pop_singlerace$pop))
})

test_that("a 1999 single frame hard-errors (outside the 2000-2024 coverage)", {
    f <- narcan::pop_singlerace_full
    keys <- dplyr::distinct(f[f$year == 2000L, ], year, age, sex, race)
    keys$year <- 1999L
    keys$deaths <- 1
    expect_error(
        add_pop_counts(keys, race_scheme = "single",
                       by_vars = c("year", "age", "sex", "race")),
        "no single-race population")
})

# ---- add_pop_counts(): factor year end-to-end ---------------------------------

test_that("a factor `year` joins end-to-end (single) == the integer-year pop", {
    # A factor year passes the factor-safe routing/coverage guards but would
    # otherwise hard-error at the final left_join (factor vs integer key).
    # .guarded_pop_join() coerces it to numeric the same value-neutral way race
    # is coerced to character, so the result matches the plain integer-year join.
    d_fac <- data.frame(year = factor("2024"), age = 25, sex = "male",
                        race = "white_only", deaths = 1)
    d_int <- data.frame(year = 2024L, age = 25, sex = "male",
                        race = "white_only", deaths = 1)
    out_fac <- add_pop_counts(d_fac, race_scheme = "single",
                              by_vars = c("year", "age", "sex", "race"))
    out_int <- add_pop_counts(d_int, race_scheme = "single",
                              by_vars = c("year", "age", "sex", "race"))
    expect_false(anyNA(out_fac$pop))
    expect_equal(out_fac$pop, out_int$pop)
    # add_pop_counts() must never leak the pop-table provenance columns
    # (pop_singlerace carries scheme/source/vintage; .synthesize_pop drops them).
    expect_false(any(c("scheme", "source", "vintage") %in% names(out_fac)))
})

test_that("a factor `year` joins end-to-end (bridged) == the integer-year pop", {
    d_fac <- data.frame(year = factor("2015"), age = 25, sex = "male",
                        race = "white", deaths = 1)
    d_int <- data.frame(year = 2015L, age = 25, sex = "male",
                        race = "white", deaths = 1)
    out_fac <- add_pop_counts(d_fac, race_scheme = "bridged",
                              by_vars = c("year", "age", "sex", "race"))
    out_int <- add_pop_counts(d_int, race_scheme = "bridged",
                              by_vars = c("year", "age", "sex", "race"))
    expect_false(anyNA(out_fac$pop))
    expect_equal(out_fac$pop, out_int$pop)
    expect_false(any(c("scheme", "source", "vintage") %in% names(out_fac)))
})

test_that("a character `year`/`age` joins end-to-end == the integer-keyed pop", {
    # A plain character year/age (e.g. read from a CSV) would otherwise hard-error
    # at the final left_join; .guarded_pop_join() coerces character the same
    # value-neutral way it coerces a factor.
    d_chr <- data.frame(year = "2024", age = "25", sex = "male",
                        race = "white_only", deaths = 1)
    d_int <- data.frame(year = 2024L, age = 25L, sex = "male",
                        race = "white_only", deaths = 1)
    out_chr <- add_pop_counts(d_chr, race_scheme = "single",
                              by_vars = c("year", "age", "sex", "race"))
    out_int <- add_pop_counts(d_int, race_scheme = "single",
                              by_vars = c("year", "age", "sex", "race"))
    expect_false(anyNA(out_chr$pop))
    expect_equal(out_chr$pop, out_int$pop)
})

test_that("a passenger column named year/age but NOT in by_vars survives uncoerced", {
    # Regression: the year/age coercion loop must touch only join keys. A stray
    # character/factor column literally named `age`/`year` that is not a by_var
    # must pass through unchanged (the byte-for-byte legacy guarantee).
    pop_slice <- data.frame(year = 2015, pop = 100)
    deaths <- data.frame(year = factor("2015"), age = "25-29", deaths = 3)
    out <- narcan:::.guarded_pop_join(deaths, pop_slice, by_vars = "year",
                                      scheme = "legacy")
    expect_identical(out$age, "25-29")     # passenger age untouched
    expect_type(out$age, "character")
    expect_equal(out$pop, 100)             # key year coerced + joined
})

# ---- add_pop_counts(): state + county backfill join ---------------------------

test_that("a pre-2020 single STATE join routes to the *_full parquet (via option)", {
    skip_if_not_installed("duckdb")
    fx <- state_fixture()
    withr::local_options(narcan.pop_single_state_parquet = fx)
    keys <- get_pop_state(scheme = "single", states = "56", years = 2005L,
                          parquet = fx)
    keys <- dplyr::distinct(keys, state_fips, year, age, sex, race)
    keys$deaths <- 1
    out <- add_pop_counts(
        keys, race_scheme = "single",
        by_vars = c("state_fips", "year", "age", "sex", "race"))
    expect_false(anyNA(out$pop))
    expect_equal(nrow(out), nrow(keys))
})

test_that("a 2022-only single STATE join uses the bundled frozen table (dep-free)", {
    s <- narcan::pop_singlerace_state
    keys <- dplyr::distinct(s[s$year == 2022L, ], state_fips, year, age, sex, race)
    keys$deaths <- 1
    out <- add_pop_counts(
        keys, race_scheme = "single",
        by_vars = c("state_fips", "year", "age", "sex", "race"))
    expect_false(anyNA(out$pop))
    expect_equal(sum(out$pop), sum(s$pop[s$year == 2022L]))
})

test_that("a yearless single COUNTY frame pools over the frozen 2020-2024 window", {
    skip_if_not_installed("duckdb")
    fx <- cty_fixture()
    withr::local_options(narcan.pop_single_county_parquet = fx)
    base <- get_pop_county(scheme = "single", states = "56", years = 2020:2024,
                           parquet = fx)
    keys <- dplyr::distinct(base, state_fips, county_fips, age, sex, race)
    keys$deaths <- 1
    expect_warning(
        out <- add_pop_counts(
            keys, race_scheme = "single",
            by_vars = c("state_fips", "county_fips", "age", "sex", "race")),
        "pooled over all covered years")
    expect_false(anyNA(out$pop))
    expect_equal(sum(out$pop), sum(base$pop))   # pooled == 2020-2024 total
})

# ---- descriptive accessors: D-ACCESSORDEFAULT / D-COUNTYDEFAULT ---------------

test_that("get_pop_state(single) default (no years) == the frozen bundled window", {
    out <- get_pop_state(scheme = "single")
    expect_setequal(out$year, 2020:2024)
    expect_equal(nrow(out), nrow(dplyr::distinct(
        narcan::pop_singlerace_state, state_fips, year, age, sex, race)))
})

test_that("get_pop_state(single, years=2015) reaches the *_full backfill", {
    skip_if_not_installed("duckdb")
    out <- get_pop_state(scheme = "single", states = "56", years = 2015L,
                         parquet = state_fixture())
    expect_setequal(out$year, 2015)
    expect_true(all(out$state_fips == "56"))
    expect_false(anyNA(out$pop))
})

test_that("get_pop_state(single, years=2018:2022) keeps 2018-2019 (no frozen drop)", {
    skip_if_not_installed("duckdb")
    out <- get_pop_state(scheme = "single", states = "56", years = 2018:2022,
                         parquet = state_fixture())
    expect_setequal(out$year, 2018:2022)   # frozen would silently drop 2018-2019
})

test_that("get_pop_state(single) is factor-safe on the frozen path (no duckdb)", {
    out <- get_pop_state(scheme = "single", states = "56",
                         years = factor(c("2022", "2023")))
    ref <- get_pop_state(scheme = "single", states = "56",
                         years = c(2022L, 2023L))
    expect_setequal(out$year, c(2022, 2023))
    expect_equal(nrow(out), nrow(ref))
    expect_equal(sum(out$pop), sum(ref$pop))
})

test_that("get_pop_county(single) default (no years) narrows to 2020-2024", {
    skip_if_not_installed("duckdb")
    fx <- cty_fixture()
    out <- get_pop_county(scheme = "single", states = "56", parquet = fx)
    expect_setequal(out$year, 2020:2024)   # fixture spans 2000-2024; default narrows
    expect_false(anyNA(out$pop))
    expect_true(min(out$pop) >= 0)         # zero-pop cells kept as 0, not NA
})

test_that("get_pop_county(single, years=2005) reaches a pre-2020 county", {
    skip_if_not_installed("duckdb")
    fx <- cty_fixture()
    out <- get_pop_county(scheme = "single", states = "56", years = 2005L,
                          parquet = fx)
    expect_setequal(out$year, 2005)
})

test_that("an empty county slice returns 0 rows (not an error)", {
    skip_if_not_installed("duckdb")
    fx <- cty_fixture()
    out <- get_pop_county(scheme = "single", counties = "99999", years = 2024L,
                          parquet = fx)
    expect_equal(nrow(out), 0L)
})

# ---- scheme-aware option hook + >1-row asset guard ----------------------------

test_that("the single county option key does not leak into a bridged read", {
    skip_if_not_installed("duckdb")
    fx <- cty_fixture()
    # A temp manifest with ONLY a single-county asset (no bridged row) so the
    # bridged read has nothing to resolve and cannot hit the network. Proves the
    # bridged read looks up narcan.pop_bridged_county_parquet, not the single key
    # -- if it borrowed the single option/fixture it would succeed, not error.
    mani <- withr::local_tempfile(fileext = ".csv")
    df <- data.frame(
        dataset = "pop_singlerace_county_full", scheme = "single",
        grain = "county", source = "census_pep", source_url = "",
        source_sha256 = "",
        asset_url = paste0("file://", normalizePath(fx, winslash = "/")),
        asset_sha256 = "", vintage = "V2024", downloaded_on = "2026-07-12",
        n_rows = "1", year_min = "2000", year_max = "2024", note = "test",
        stringsAsFactors = FALSE)
    utils::write.csv(df, mani, row.names = FALSE)
    withr::local_options(narcan.pop_single_county_parquet = fx,
                         narcan.pop_manifest_path = mani)
    expect_error(
        narcan:::.load_pop_parquet("bridged", "county", years = 2020L),
        "no downloadable bridged county parquet")
})

# ---- coverage guard: a stale/short asset must fail LOUD, never silent ---------

test_that("a stale 2020-2024 county asset hard-errors on a pre-2020 request (not silent)", {
    skip_if_not_installed("duckdb")
    fx <- cty_fixture()
    # Build the exact stale artifact: the county fixture truncated to 2020-2024,
    # i.e. what a manifest row still pointing at the 0.5.0 asset would resolve to.
    stale <- withr::local_tempfile(fileext = ".parquet")
    con <- DBI::dbConnect(duckdb::duckdb())
    on.exit(DBI::dbDisconnect(con, shutdown = TRUE), add = TRUE)
    q <- function(x) paste0("'", x, "'")
    DBI::dbExecute(con, sprintf(paste0(
        "COPY (SELECT * FROM read_parquet(%s) WHERE year >= 2020) TO %s ",
        "(FORMAT PARQUET)"), q(fx), q(stale)))
    # descriptive accessor: previously returned 0 rows SILENTLY; now loud.
    expect_error(
        get_pop_county(scheme = "single", states = "56", years = 2015L,
                       parquet = stale),
        "does not cover year\\(s\\) 2015")
})

test_that("the coverage guard catches an interior gap (membership, not just range)", {
    skip_if_not_installed("duckdb")
    fx <- cty_fixture()
    # a non-contiguous asset: 2000-2009 + 2015-2024 spliced, a 2010-2014 hole.
    # MIN=2000/MAX=2024 would pass a range check; membership must catch 2012.
    gappy <- withr::local_tempfile(fileext = ".parquet")
    con <- DBI::dbConnect(duckdb::duckdb())
    on.exit(DBI::dbDisconnect(con, shutdown = TRUE), add = TRUE)
    q <- function(x) paste0("'", x, "'")
    DBI::dbExecute(con, sprintf(paste0(
        "COPY (SELECT * FROM read_parquet(%s) WHERE year <= 2009 OR year >= 2015) ",
        "TO %s (FORMAT PARQUET)"), q(fx), q(gappy)))
    expect_error(
        get_pop_county(scheme = "single", states = "56", years = 2012L,
                       parquet = gappy),
        "does not cover year\\(s\\) 2012")
})

test_that("get_pop_state(single) hard-errors past the frozen coverage (not silent 0 rows)", {
    # 2025 is past the frozen 2020-2024 window; the dep-free branch must fail loud.
    expect_error(
        get_pop_state(scheme = "single", states = "56", years = 2025L),
        "cover 2020-2024|no coverage past 2024")
})

test_that("empty `years` (length 0) fails with a clean message, not a raw SQL error", {
    skip_if_not_installed("duckdb")
    expect_error(
        get_pop_county(scheme = "single", states = "56", years = integer(0),
                       parquet = cty_fixture()),
        "empty")
})

test_that("a duplicated finest-cell population slice hard-errors (no double-count)", {
    skip_if_not_installed("duckdb")
    fx <- cty_fixture()
    # duplicate the county's finest-cell rows: the many-to-one join cannot catch
    # this (summarize collapses it) -- the input-uniqueness assert must.
    dup <- withr::local_tempfile(fileext = ".parquet")
    con <- DBI::dbConnect(duckdb::duckdb())
    on.exit(DBI::dbDisconnect(con, shutdown = TRUE), add = TRUE)
    q <- function(x) paste0("'", x, "'")
    DBI::dbExecute(con, sprintf(paste0(
        "COPY (SELECT * FROM read_parquet(%s) UNION ALL SELECT * FROM ",
        "read_parquet(%s)) TO %s (FORMAT PARQUET)"), q(fx), q(fx), q(dup)))
    withr::local_options(narcan.pop_single_county_parquet = dup)
    d <- data.frame(state_fips = "56", county_fips = "56001", year = 2022L,
                    age = 25, sex = "male", race = "white_only", deaths = 1)
    expect_error(
        add_pop_counts(d, race_scheme = "single",
                       by_vars = c("state_fips", "county_fips", "year", "age",
                                   "sex", "race")),
        "duplicate finest-cell")
})

test_that(".check_bridged_death_keys is factor-safe (a 2015 factor year is post-1990)", {
    # factor level codes are small ints (< 1990); a non-factor-safe check would
    # misclassify 2015 as pre-1990 and reject api/american_indian. The guard must
    # pass (return invisibly) for a post-1990 factor year.
    df <- data.frame(year = factor(rep("2015", 4)), age = 25, sex = "male",
                     race = c("white", "black", "american_indian", "api"))
    expect_silent(
        narcan:::.check_bridged_death_keys(df, by_vars = c("year", "age", "sex",
                                                           "race")))
})

test_that(".pop_asset_path trips on a same-URL / conflicting-sha256 manifest", {
    mani <- withr::local_tempfile(fileext = ".csv")
    mk_row <- function(sha) data.frame(
        dataset = "pop_singlerace_county", scheme = "single", grain = "county",
        source = "census_pep", source_url = "", source_sha256 = "",
        asset_url = "file:///tmp/same.parquet", asset_sha256 = sha,
        vintage = "V2024", downloaded_on = "2026-07-12", n_rows = "1",
        year_min = "2000", year_max = "2024", note = "conflict",
        stringsAsFactors = FALSE)
    df <- rbind(mk_row(strrep("0", 64L)), mk_row(strrep("1", 64L)))
    utils::write.csv(df, mani, row.names = FALSE)
    withr::local_options(narcan.pop_manifest_path = mani)
    expect_error(narcan:::.pop_asset_path("single", "county"),
                 "ambiguous|exactly one")
})

test_that(".pop_asset_path errors on an ambiguous (>1 different-URL) manifest", {
    mani <- withr::local_tempfile(fileext = ".csv")
    mk_row <- function(url) data.frame(
        dataset = "pop_singlerace_county", scheme = "single", grain = "county",
        source = "census_pep", source_url = "", source_sha256 = "",
        asset_url = url, asset_sha256 = strrep("0", 64L),
        vintage = "V2024", downloaded_on = "2026-07-12", n_rows = "1",
        year_min = "2000", year_max = "2024", note = "dup",
        stringsAsFactors = FALSE)
    df <- rbind(mk_row("file:///tmp/a.parquet"), mk_row("file:///tmp/b.parquet"))
    utils::write.csv(df, mani, row.names = FALSE)
    withr::local_options(narcan.pop_manifest_path = mani)
    expect_error(narcan:::.pop_asset_path("single", "county"),
                 "ambiguous|exactly one")
})
