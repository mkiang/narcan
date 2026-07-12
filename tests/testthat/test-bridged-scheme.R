# Bridged (SEER) join contract (0.5.1). The SEER denominator data lands in a
# later sub-phase, so these exercise the guard core directly through
# .guarded_pop_join()/.check_bridged_death_keys() with a SYNTHETIC finest-cell
# bridged pop slice (same shape the build will emit): era-ragged race + Hispanic
# origin, "all" synthesized. Bridged is strict (no silent NA), year-aware, and
# validates the race set PER ROW against that row's era.

## Synthetic finest-cell bridged pop: pre-1990 (1985) = white/black/other,
## all-origin only; 1990+ (2000) = white/black/american_indian/api x
## non_hispanic/hispanic. National grain (year, age, sex, race, hispanic_origin).
bridged_pop <- function() {
    pre <- expand.grid(
        year = 1985L, age = c(40L, 45L), sex = c("male", "female"),
        race = c("white", "black", "other"), hispanic_origin = "all",
        stringsAsFactors = FALSE)
    post <- expand.grid(
        year = 2000L, age = c(40L, 45L), sex = c("male", "female"),
        race = c("white", "black", "american_indian", "api"),
        hispanic_origin = c("non_hispanic", "hispanic"),
        stringsAsFactors = FALSE)
    p <- rbind(pre, post)
    p$pop <- seq_len(nrow(p)) * 1000
    p$scheme <- "bridged"; p$source <- "seer_uspop"; p$vintage <- "SEER2024"
    tibble::as_tibble(p)
}

by4 <- c("year", "age", "sex", "race")

# ---- valid joins across both eras --------------------------------------------

test_that("bridged joins a mixed-era frame with no NA and collapses origin", {
    d <- data.frame(year = c(1985L, 2000L), age = 40L, sex = "male",
                    race = c("white", "api"), deaths = 1)
    out <- narcan:::.guarded_pop_join(d, bridged_pop(), by4, "bridged")
    expect_false(anyNA(out$pop))
    expect_equal(nrow(out), 2L)
    # 2000 api pop is the all-origin sum of its non_hisp + hisp finest cells
    src <- bridged_pop()
    exp_api <- sum(src$pop[src$year == 2000L & src$age == 40L &
                           src$sex == "male" & src$race == "api"])
    expect_equal(out$pop[out$race == "api"], exp_api)
})

test_that("bridged synthesizes race='total' over the era-appropriate race set", {
    d <- data.frame(year = c(1985L, 2000L), age = 40L, sex = "male",
                    race = "total", deaths = 1)
    out <- narcan:::.guarded_pop_join(d, bridged_pop(), by4, "bridged")
    src <- bridged_pop()
    exp85 <- sum(src$pop[src$year == 1985L & src$age == 40L & src$sex == "male"])
    exp00 <- sum(src$pop[src$year == 2000L & src$age == 40L & src$sex == "male"])
    expect_equal(out$pop[out$year == 1985L], exp85)  # white+black+other
    expect_equal(out$pop[out$year == 2000L], exp00)  # 4 races x 2 origins
})

# ---- era-conditioned race domain (per row) -----------------------------------

test_that("bridged requires year in by_vars", {
    d <- data.frame(year = 2000L, age = 40L, sex = "male", race = "white",
                    deaths = 1)
    expect_error(
        narcan:::.check_bridged_death_keys(d, c("age", "sex", "race")),
        "requires `year`")
})

test_that("bridged hard-errors AIAN/API requested before 1990", {
    d <- data.frame(year = 1985L, age = 40L, sex = "male",
                    race = c("american_indian", "api"), deaths = 1)
    expect_error(narcan:::.check_bridged_death_keys(d, by4),
                 "not denominable")
})

test_that("bridged accepts white/black/other pre-1990 and the 4-group 1990+", {
    pre <- data.frame(year = 1985L, age = 40L, sex = "male",
                      race = c("white", "black", "other"), deaths = 1)
    post <- data.frame(year = 2000L, age = 40L, sex = "male",
                       race = c("white", "black", "american_indian", "api"),
                       deaths = 1)
    expect_silent(narcan:::.check_bridged_death_keys(pre, by4))
    expect_silent(narcan:::.check_bridged_death_keys(post, by4))
})

test_that("bridged hard-errors 'other' requested for a 1990+ year", {
    d <- data.frame(year = 2000L, age = 40L, sex = "male", race = "other",
                    deaths = 1)
    expect_error(narcan:::.check_bridged_death_keys(d, by4),
                 "unrecognized bridged")
})

test_that("bridged hard-errors detailed Asian subgroups with a collapse hint", {
    for (s in c("chinese", "japanese", "hawaiian", "filipino")) {
        d <- data.frame(year = 2000L, age = 40L, sex = "male", race = s,
                        deaths = 1)
        expect_error(narcan:::.check_bridged_death_keys(d, by4),
                     "collapse .* to `api`|subgroup")
    }
})

test_that("bridged hard-errors numeric race", {
    d <- data.frame(year = 2000L, age = 40L, sex = "male", race = 2, deaths = 1)
    expect_error(narcan:::.check_bridged_death_keys(d, by4), "remap_race")
})

# ---- no silent NA + many-to-one ----------------------------------------------

test_that("bridged hard-errors (no silent NA) when a key has no denominator", {
    d <- data.frame(year = 2000L, age = 40L, sex = "male", race = "white",
                    deaths = 1)
    d2 <- d; d2$age <- 5L                            # age not in the synthetic pop
    expect_error(
        narcan:::.guarded_pop_join(d2, bridged_pop(), by4, "bridged"),
        "no bridged population")
})

# ---- scheme coherence: single-race values under bridged hard-error -----------

test_that("single-race labels/codes under bridged hit the contradiction guard", {
    d <- data.frame(year = 2000L, age = 40L, sex = "male",
                    race = "asian_only", deaths = 1)
    expect_error(narcan:::.guarded_pop_join(d, bridged_pop(), by4, "bridged"),
                 "race_scheme")
    d2 <- data.frame(year = 2000L, age = 40L, sex = "male", race = 104,
                     deaths = 1)
    expect_error(narcan:::.guarded_pop_join(d2, bridged_pop(), by4, "bridged"),
                 "race_scheme")
})

# ---- Hispanic-origin join, 1990+ (0.5.2 pin lifted) --------------------------

test_that("bridged origin-stratified join (1990+) succeeds per origin", {
    d <- data.frame(year = 2000L, age = 40L, sex = "male", race = "white",
                    hispanic_origin = c("hispanic", "non_hispanic"), deaths = 1)
    by5 <- c("year", "age", "sex", "race", "hispanic_origin")
    out <- narcan:::.guarded_pop_join(d, bridged_pop(), by5, "bridged")
    expect_false(anyNA(out$pop))
    ## each origin gets its OWN finest-cell denominator, not the all-origin sum
    src <- bridged_pop()
    exp_h <- src$pop[src$year == 2000L & src$age == 40L & src$sex == "male" &
                     src$race == "white" & src$hispanic_origin == "hispanic"]
    exp_nh <- src$pop[src$year == 2000L & src$age == 40L & src$sex == "male" &
                      src$race == "white" & src$hispanic_origin == "non_hispanic"]
    expect_equal(out$pop[out$hispanic_origin == "hispanic"], exp_h)
    expect_equal(out$pop[out$hispanic_origin == "non_hispanic"], exp_nh)
})

test_that("bridged pre-1990 origin stratification hard-errors (SEER: origin from 1990)", {
    d <- data.frame(year = 1985L, age = 40L, sex = "male", race = "white",
                    hispanic_origin = "hispanic", deaths = 1)
    expect_error(
        narcan:::.check_bridged_death_keys(
            d, c("year", "age", "sex", "race", "hispanic_origin")),
        "before 1990")
})

test_that("per-year invariant: an 'all'-beside-stratified corrupt slice errors", {
    ## A 2000 cell carrying BOTH stratified rows AND a stray "all" marginal --
    ## a double-count the finest-key uniqueness assert cannot see (three distinct
    ## "unique" rows). Driven via the all-origin request (where the relabel would
    ## otherwise mask it). The invariant runs on the RAW slice, before any relabel.
    corrupt <- rbind(bridged_pop(), data.frame(
        year = 2000L, age = 40L, sex = "male", race = "white",
        hispanic_origin = "all", pop = 999000, scheme = "bridged",
        source = "seer_uspop", vintage = "SEER2024"))
    d <- data.frame(year = 2000L, age = 40L, sex = "male", race = "white",
                    hispanic_origin = "all", deaths = 1)
    expect_error(
        narcan:::.guarded_pop_join(
            d, corrupt, c("year", "age", "sex", "race", "hispanic_origin"),
            "bridged"),
        "double-count")
})

test_that("per-year invariant: an NA/stray origin label beside cells errors", {
    ## Defense in depth: a stray NA (or unrecognized label) beside stratified
    ## cells for a year is neither pure-"all" nor pure-stratified -> corrupt.
    corrupt <- rbind(bridged_pop(), data.frame(
        year = 2000L, age = 40L, sex = "male", race = "white",
        hispanic_origin = NA_character_, pop = 999000, scheme = "bridged",
        source = "seer_uspop", vintage = "SEER2024"))
    d <- data.frame(year = 2000L, age = 40L, sex = "male", race = "white",
                    hispanic_origin = "all", deaths = 1)
    expect_error(
        narcan:::.guarded_pop_join(
            d, corrupt, c("year", "age", "sex", "race", "hispanic_origin"),
            "bridged"),
        "invalid|double-count")
})

test_that("R3: .guarded_pop_join self-defends against a stray pop-dimension column", {
    ## Direct internal call with hispanic_origin present but NOT in by_vars must
    ## error (belt-and-suspenders; add_pop_counts blocks it at the call site).
    d <- data.frame(year = 2000L, age = 40L, sex = "male", race = "white",
                    hispanic_origin = "hispanic", deaths = 1)
    expect_error(
        narcan:::.guarded_pop_join(d, bridged_pop(), by4, "bridged"),
        "population-dimension column")
})

## A minimal 1995 stratified bridged slice for the CAVEAT-B nudge tests.
bridged_pop_1995 <- function() {
    p <- expand.grid(
        year = 1995L, age = 40L, sex = "male", race = "white",
        hispanic_origin = c("hispanic", "non_hispanic"),
        stringsAsFactors = FALSE)
    p$pop <- c(1000, 2000)
    p$scheme <- "bridged"; p$source <- "seer_uspop"; p$vintage <- "SEER2024"
    tibble::as_tibble(p)
}

test_that("CAVEAT-B nudges once for 1990-1996 bridged stratified, then stays silent", {
    if (exists("bridged_hispanic_early_reporting", envir = narcan:::.narcan_state)) {
        rm("bridged_hispanic_early_reporting", envir = narcan:::.narcan_state)
    }
    d <- data.frame(year = 1995L, age = 40L, sex = "male", race = "white",
                    hispanic_origin = "hispanic", deaths = 1)
    by5 <- c("year", "age", "sex", "race", "hispanic_origin")
    expect_message(
        narcan:::.guarded_pop_join(d, bridged_pop_1995(), by5, "bridged"),
        "1990-1996")
    ## second call is silent (once per session)
    expect_message(
        narcan:::.guarded_pop_join(d, bridged_pop_1995(), by5, "bridged"),
        NA)
})

test_that("CAVEAT-B nudge is NOT burned by a call that errors (DD6) before it", {
    if (exists("bridged_hispanic_early_reporting", envir = narcan:::.narcan_state)) {
        rm("bridged_hispanic_early_reporting", envir = narcan:::.narcan_state)
    }
    ## a 1995 frame mixing "all" + stratified -> DD6 errors BEFORE the nudge line
    bad <- data.frame(year = 1995L, age = 40L, sex = "male", race = "white",
                      hispanic_origin = c("all", "hispanic"), deaths = 1)
    by5 <- c("year", "age", "sex", "race", "hispanic_origin")
    expect_error(narcan:::.check_bridged_death_keys(bad, by5), "double-count")
    ## the once-per-session flag must NOT have been set by the failed call
    expect_false(exists("bridged_hispanic_early_reporting",
                        envir = narcan:::.narcan_state))
})

# ---- P4 origin matrix (bridged) ----------------------------------------------

test_that("bridged origin-stratified national join runs end-to-end on REAL pop_bridged (G1)", {
    ## Not just the synthetic .guarded_pop_join() path: route a real death frame
    ## through add_pop_counts() against the bundled narcan::pop_bridged.
    keys <- dplyr::distinct(
        narcan::pop_bridged[narcan::pop_bridged$year == 2000L, ],
        year, age, sex, race, hispanic_origin)
    keys <- keys[keys$hispanic_origin %in% c("hispanic", "non_hispanic"), ]
    keys$deaths <- 1
    by5 <- c("year", "age", "sex", "race", "hispanic_origin")
    out <- add_pop_counts(keys, race_scheme = "bridged", by_vars = by5)
    expect_false(anyNA(out$pop))
    src <- narcan::pop_bridged
    cell <- out[out$hispanic_origin == "hispanic", ][1, ]
    exp <- src$pop[src$year == 2000L & src$age == cell$age & src$sex == cell$sex &
                   src$race == cell$race & src$hispanic_origin == "hispanic"]
    expect_equal(cell$pop, sum(exp))
})

test_that("bridged cross-era DD6: 1985 'all' + 2000 'hispanic' errors; pre-1990 guard does NOT preempt (G2)", {
    ## DD6's paradigm case (79_ j): the silently-succeeding "Hispanic trend" whose
    ## pre-1990 points are all-origin. The mixed-origin stop must fire, and the
    ## pre-1990 era guard must not preempt it (the 1985 row is "all", not stratified).
    d <- data.frame(year = c(1985L, 2000L), age = 40L, sex = "male", race = "white",
                    hispanic_origin = c("all", "hispanic"), deaths = 1)
    by5 <- c("year", "age", "sex", "race", "hispanic_origin")
    msg <- tryCatch(add_pop_counts(d, race_scheme = "bridged", by_vars = by5),
                    error = function(e) conditionMessage(e))
    expect_match(msg, "double-count")
    expect_false(grepl("before 1990", msg))
})

test_that("per-year invariant catches a corrupt year=NA group (G4)", {
    corrupt <- rbind(bridged_pop(), data.frame(
        year = NA_integer_, age = 40L, sex = "male", race = "white",
        hispanic_origin = c("all", "hispanic"), pop = c(9, 1),
        scheme = "bridged", source = "s", vintage = "v"))
    d <- data.frame(year = 2000L, age = 40L, sex = "male", race = "white",
                    hispanic_origin = "hispanic", deaths = 1)
    msg <- tryCatch(
        narcan:::.guarded_pop_join(
            d, corrupt, c("year", "age", "sex", "race", "hispanic_origin"),
            "bridged"),
        error = function(e) conditionMessage(e))
    expect_match(msg, "invalid|double-count")
    expect_match(msg, "NA")
})

test_that("origin-stratified add_pop_counts matches get_pop_state at state grain (bridged, synthetic parquet)", {
    ## Bridged state/county are Release-asset-only, so a blank skip would leave the
    ## bridged parquet-origin route permanently untested. Inject a small synthetic
    ## state parquet via the option hook (same mechanism as the single tests) so
    ## the route is really exercised.
    skip_if_not_installed("duckdb")
    skip_if_not_installed("DBI")
    syn <- expand.grid(
        state_fips = c("06", "36"), year = 2000L, age = c(40L, 45L),
        sex = c("male", "female"),
        race = c("white", "black", "american_indian", "api"),
        hispanic_origin = c("hispanic", "non_hispanic"), stringsAsFactors = FALSE)
    syn$pop <- seq_len(nrow(syn)) * 100
    syn$scheme <- "bridged"; syn$source <- "seer_uspop"; syn$vintage <- "SEER2024"
    path <- withr::local_tempfile(fileext = ".parquet")
    con <- DBI::dbConnect(duckdb::duckdb())
    on.exit(DBI::dbDisconnect(con, shutdown = TRUE), add = TRUE)
    duckdb::duckdb_register(con, "syn", syn)
    DBI::dbExecute(con, sprintf("COPY syn TO '%s' (FORMAT PARQUET)", path))
    withr::local_options(narcan.pop_bridged_state_parquet = path)

    gp <- get_pop_state(scheme = "bridged", states = "06", years = 2000L,
                        hispanic_origin = "hispanic")
    by6 <- c("state_fips", "year", "age", "sex", "race", "hispanic_origin")
    deaths <- gp[, by6]
    deaths$deaths <- 1
    ap <- add_pop_counts(deaths, race_scheme = "bridged", by_vars = by6)
    m <- merge(ap, gp, by = by6, suffixes = c("_ap", "_gp"))
    expect_equal(nrow(m), nrow(gp))
    expect_equal(m$pop_ap, m$pop_gp)
})

# ---- D-SCHEMESELECT: legacy nudge in the bridged-overlap span -----------------

test_that("legacy by-race join in 2000-2020 nudges once toward bridged", {
    ## clear the once-per-session flag so the message fires in this test
    if (exists("legacy_bridged_overlap", envir = narcan:::.narcan_state)) {
        rm("legacy_bridged_overlap", envir = narcan:::.narcan_state)
    }
    inp <- rate_input(year = 2010L, sex = "male", race = "white")
    expect_message(add_pop_counts(inp), "race_scheme = \"bridged\"")
    # second call is silent (once per session)
    expect_message(add_pop_counts(inp), NA)
})
