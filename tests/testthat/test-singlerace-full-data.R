# Value goldens for the single-race BACKFILL datasets (0.5.1, P3), 2000-2024.
# Committed literals are from sources INDEPENDENT of the build parse: the
# 2020-2024 by-race from the Census-measured recon (verify_fwf p5_spike
# recon_census_singlerace_by_year.csv), the 2005 by-race from st-est00int's OWN
# STATE=0 US-row control total (independent of the state-summing), and the
# national totals corroborated by PEP-vs-SEER (recon_total_by_year.csv). The
# interior-year race LABELS are pinned structurally by G5 (state numeric-code vs
# county named-column decode agreeing to the person at build) x the single shared
# race_case; these tests lock the VALUES as a durable regression tripwire.

test_that("pop_singlerace_full has the 2000-2024 shape (G6, G8)", {
    x <- narcan::pop_singlerace_full
    expect_equal(nrow(x), 10800L)                       # 25 x 18 x 2 x 6 x 2
    expect_setequal(x$year, 2000:2024)
    expect_setequal(x$sex, c("male", "female"))
    expect_setequal(x$age, seq(0, 85, 5))
    expect_setequal(x$race, c("white_only", "black_only", "american_indian_only",
                              "asian_only", "nhopi_only", "multiracial"))
    expect_setequal(x$hispanic_origin, c("non_hispanic", "hispanic"))
    expect_setequal(x$vintage, c("int2000", "int2010", "V2024"))
    expect_false(anyNA(x$pop))
    expect_true(all(x$pop >= 0))
    expect_equal(nrow(x), nrow(dplyr::distinct(
        x, year, age, sex, race, hispanic_origin)))
})

test_that("national totals reconcile (G4)", {
    x <- narcan::pop_singlerace_full
    tot <- function(y) sum(x$pop[x$year == y])
    expect_equal(tot(2000), 282162411)   # 2000-2010 intercensal
    expect_equal(tot(2005), 295516599)
    expect_equal(tot(2009), 306771529)
    expect_equal(tot(2015), 321815121)   # REBASED 2010-2020 intercensal (not postcensal)
    expect_equal(tot(2020), 331577720)   # V2024 (== bridged, == 0.5.0)
    expect_equal(tot(2024), 340110988)
})

test_that("by-race national anchors are exact (G1) -- independent literals", {
    x <- narcan::pop_singlerace_full
    byr <- function(y) {
        d <- x[x$year == y, ]
        v <- tapply(d$pop, d$race, sum)
        as.numeric(v[c("white_only", "black_only", "american_indian_only",
                       "asian_only", "nhopi_only", "multiracial")])
    }
    # 2020 (recon CSV, Census-measured) -- catches a race transposition.
    expect_equal(byr(2020),
                 c(251705938, 44911745, 4302125, 20224610, 851893, 9581409))
    # 2024 (recon CSV) -- a second V2024-vintage anchor.
    expect_equal(byr(2024),
                 c(254281598, 46608846, 4743298, 22825008, 939712, 10712526))
    # 2005 (st-est00int STATE=0 US-row control; independent of the state-summing).
    expect_equal(byr(2005),
                 c(235491577, 37961688, 3147772, 13007663, 568804, 5339095))
    # 2015 (int2010 vintage) -- pinned as a durable tripwire (structural
    # independence via G5 at build; value locks a future regression).
    expect_equal(byr(2015),
                 c(244269338, 42476259, 5102048, 18240436, 770560, 10956480))
})

test_that("directional SEX/ORIGIN guards hold every year (label-swap tripwire)", {
    x <- narcan::pop_singlerace_full
    for (y in 2000:2024) {
        d <- x[x$year == y, ]
        bs <- tapply(d$pop, d$sex, sum)
        bo <- tapply(d$pop, d$hispanic_origin, sum)
        expect_gt(bs[["female"]], bs[["male"]])
        expect_gt(bo[["non_hispanic"]], bo[["hispanic"]])
    }
})

test_that("national G12: 2020-2024 slice == frozen 0.5.0 pop_singlerace (D-FREEZE)", {
    keys <- c("year", "age", "sex", "race", "hispanic_origin")
    n <- narcan::pop_singlerace_full
    n <- n[n$year %in% 2020:2024, c(keys, "pop")]
    f <- as.data.frame(narcan::pop_singlerace)[, c(keys, "pop")]
    m <- merge(n, f, by = keys, all = TRUE, suffixes = c(".n", ".f"))
    expect_equal(nrow(m), nrow(n))          # 1:1 (no cell on one side only)
    expect_equal(nrow(n), nrow(f))
    expect_false(anyNA(m$pop.n))
    expect_false(anyNA(m$pop.f))
    expect_true(all(m$pop.n == m$pop.f))    # value-for-value
})

test_that("county-full fixture (Wyoming) spans 2000-2024 with a clean grain (G14-lite)", {
    skip_if_not_installed("duckdb")
    fx <- system.file("extdata", "pop_singlerace_county_fixture.parquet",
                      package = "narcan")
    if (!nzchar(fx) || !file.exists(fx)) skip("county fixture not installed")
    con <- DBI::dbConnect(duckdb::duckdb())
    on.exit(DBI::dbDisconnect(con, shutdown = TRUE), add = TRUE)
    q <- function(s) DBI::dbGetQuery(con, sprintf(s,
        paste0("'", fx, "'")))
    expect_setequal(q("SELECT DISTINCT year y FROM read_parquet(%s)")$y, 2000:2024)
    expect_true(all(q("SELECT DISTINCT state_fips s FROM read_parquet(%s)")$s == "56"))
    bad <- q("SELECT COUNT(*) n FROM read_parquet(%s) WHERE pop < 0 OR pop IS NULL")$n
    expect_equal(bad, 0)
    nall <- q("SELECT COUNT(*) n FROM read_parquet(%s)")$n
    nkey <- q("SELECT COUNT(*) n FROM (SELECT DISTINCT county_fips, year, age, sex,
               race, hispanic_origin FROM read_parquet(%s))")$n
    expect_equal(nall, nkey)               # finest key unique (no stored marginal)
})

test_that("state-full fixture 2020-2024 == frozen 0.5.0 state, value-for-value (D-FREEZE, WY)", {
    skip_if_not_installed("duckdb")
    fx <- system.file("extdata", "pop_singlerace_state_fixture.parquet",
                      package = "narcan")
    if (!nzchar(fx) || !file.exists(fx)) skip("state fixture not installed")
    con <- DBI::dbConnect(duckdb::duckdb())
    on.exit(DBI::dbDisconnect(con, shutdown = TRUE), add = TRUE)
    full <- DBI::dbGetQuery(con, sprintf(paste0(
        "SELECT state_fips, year, age, sex, race, hispanic_origin, pop FROM ",
        "read_parquet('%s') WHERE year BETWEEN 2020 AND 2024"), fx))
    frz <- as.data.frame(narcan::pop_singlerace_state)
    keys <- c("state_fips", "year", "age", "sex", "race", "hispanic_origin")
    frz <- frz[frz$state_fips == "56", c(keys, "pop")]
    m <- merge(full, frz, by = keys, all = TRUE, suffixes = c(".f", ".z"))
    expect_equal(nrow(m), nrow(full))       # 1:1, no cell on one side only
    expect_equal(nrow(full), nrow(frz))
    expect_false(anyNA(m$pop.f))
    expect_false(anyNA(m$pop.z))
    expect_true(all(m$pop.f == m$pop.z))    # backfill's 2020-2024 slice is frozen
})

test_that("county-full fixture 2020-2024 aggregates to the frozen 0.5.0 state (G5 x freeze, WY)", {
    skip_if_not_installed("duckdb")
    fx <- system.file("extdata", "pop_singlerace_county_fixture.parquet",
                      package = "narcan")
    if (!nzchar(fx) || !file.exists(fx)) skip("county fixture not installed")
    con <- DBI::dbConnect(duckdb::duckdb())
    on.exit(DBI::dbDisconnect(con, shutdown = TRUE), add = TRUE)
    agg <- DBI::dbGetQuery(con, sprintf(paste0(
        "SELECT year, age, sex, race, hispanic_origin, SUM(pop) pop FROM ",
        "read_parquet('%s') WHERE year BETWEEN 2020 AND 2024 GROUP BY ALL"), fx))
    frz <- as.data.frame(narcan::pop_singlerace_state)
    keys <- c("year", "age", "sex", "race", "hispanic_origin")
    frz <- frz[frz$state_fips == "56", c(keys, "pop")]
    m <- merge(agg, frz, by = keys, all = TRUE, suffixes = c(".c", ".z"))
    expect_equal(nrow(m), nrow(frz))
    expect_false(anyNA(m$pop.c))
    expect_false(anyNA(m$pop.z))
    expect_true(all(m$pop.c == m$pop.z))    # county->state == frozen state (WY)
})
