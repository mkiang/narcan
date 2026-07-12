# Join contract for add_pop_counts() (P5 / 0.5.0). Two schemes route through the
# single guarded join .guarded_pop_join(). "legacy" must stay byte-for-byte
# (frozen pop_est, warn+NA); "single" is strict (no silent NA, hard-errors on
# out-of-domain keys, synthesizes total/both/all marginals). Inputs are built
# from the REAL bundled narcan tables so every key is valid by construction.

## A valid single-race death frame: one row per finest key for a given year,
## with a deterministic count. Uses pop_singlerace's own keys.
single_input <- function(year = 2024L) {
    keys <- dplyr::distinct(
        narcan::pop_singlerace[narcan::pop_singlerace$year == year, ],
        year, age, sex, race
    )
    keys$deaths <- seq_len(nrow(keys))
    tibble::as_tibble(keys)
}

# ---- back-compat: legacy is byte-for-byte -------------------------------------

test_that("legacy default is value-identical for a factor race + grouped input", {
    inp <- rate_input(year = 2015L, sex = "male", race = "white")
    plain <- add_pop_counts(inp)

    # same inputs but race as an (unordered) factor and grouped by age
    fct <- inp
    fct$race <- factor(fct$race)
    fct <- dplyr::group_by(fct, age)
    out <- add_pop_counts(fct)

    expect_s3_class(out, "grouped_df")               # grouping restored
    expect_identical(dplyr::group_vars(out), "age")
    expect_identical(dplyr::ungroup(out)$pop, plain$pop)  # coercion is neutral
    expect_type(out$race, "character")               # factor coerced away
})

test_that("legacy positional by_vars call still works", {
    inp <- rate_input(year = 2015L, sex = "male", race = "white")
    out <- add_pop_counts(inp, c("year", "age", "sex", "race"))
    expect_false(anyNA(out$pop))
    expect_equal(nrow(out), nrow(inp))
})

test_that("legacy unmatched CHARACTER race warns and leaves pop NA", {
    inp <- rate_input(year = 2015L, sex = "male", race = "white")
    inp$race <- "unknown_group"                      # char, absent from pop_est
    expect_warning(out <- add_pop_counts(inp), "no matching population")
    expect_true(all(is.na(out$pop)))
})

test_that("legacy numeric bridged race code errors (dplyr type mismatch)", {
    inp <- rate_input(year = 2015L, sex = "male", race = "white")
    inp$race <- 1L                                   # numeric vs character key
    expect_error(add_pop_counts(inp))
})

# ---- contradiction guard (fires on the default) -------------------------------

test_that("single-race race values under the default scheme hard-error", {
    inp <- rate_input(year = 2015L, sex = "male", race = "white")
    for (bad in c("asian_only", "multiracial")) {
        inp2 <- inp
        inp2$race <- bad
        expect_error(add_pop_counts(inp2), "race_scheme")
    }
    inp3 <- inp
    inp3$race <- 104                                 # numeric 101-106
    expect_error(add_pop_counts(inp3), "race_scheme")
})

test_that("race_scheme = 'bridged' is accepted by match.arg (0.5.1)", {
    ## 0.5.0 rejected "bridged" at match.arg; 0.5.1 accepts it. End-to-end
    ## national bridged needs the pop_bridged data (built in a later sub-phase),
    ## so here we only confirm match.arg no longer rejects it -- the observed
    ## error must NOT be the match.arg "should be one of" rejection.
    inp <- single_input()
    res <- tryCatch(add_pop_counts(inp, race_scheme = "bridged"),
                    error = function(e) conditionMessage(e))
    expect_true(is.character(res))
    expect_false(grepl("should be one of", res))
})

# ---- single scheme: national join + value correctness -------------------------

test_that("single national join matches every key with no NA", {
    inp <- single_input(2024L)
    out <- add_pop_counts(inp, race_scheme = "single")

    expect_equal(nrow(out), nrow(inp))
    expect_false(anyNA(out$pop))
    # pop equals the all-origin sum of the finest cells for each key
    expected <- narcan::pop_singlerace |>
        dplyr::filter(year == 2024L) |>
        dplyr::group_by(year, age, sex, race) |>
        dplyr::summarize(pop = sum(pop), .groups = "drop")
    chk <- dplyr::left_join(out, expected, by = c("year", "age", "sex", "race"),
                            suffix = c("", "_exp"))
    expect_equal(chk$pop, chk$pop_exp)
})

test_that("single state join uses the state table and matches", {
    st <- narcan::pop_singlerace_state
    keys <- dplyr::distinct(
        st[st$year == 2024L & st$state_fips == "06", ],
        state_fips, year, age, sex, race
    )
    keys$deaths <- 1
    out <- add_pop_counts(tibble::as_tibble(keys), race_scheme = "single",
                          by_vars = c("state_fips", "year", "age", "sex", "race"))
    expect_false(anyNA(out$pop))
    expect_equal(nrow(out), nrow(keys))
})

# ---- single scheme: domain guards (no silent NA) ------------------------------

test_that("single scheme hard-errors on out-of-domain keys", {
    good <- single_input(2024L)

    bad_race <- good; bad_race$race <- "white"       # legacy label
    expect_error(add_pop_counts(bad_race, race_scheme = "single"),
                 "unrecognized single-race")

    num_race <- good; num_race$race <- 104           # numeric under single
    expect_error(add_pop_counts(num_race, race_scheme = "single"),
                 "remap_race")

    bad_age <- good; bad_age$age <- 3L               # not a 5-year bin start
    expect_error(add_pop_counts(bad_age, race_scheme = "single"),
                 "5-year bin")

    bad_sex <- good; bad_sex$sex <- "unknown"
    expect_error(add_pop_counts(bad_sex, race_scheme = "single"),
                 "male")
})

test_that("single scheme hard-errors (no silent NA) on out-of-coverage year", {
    inp <- single_input(2024L)
    inp$year <- 1999L                                # before single coverage
    expect_error(add_pop_counts(inp, race_scheme = "single"),
                 "no single-race population")
})

# ---- single scheme: reserved-token synthesis ----------------------------------

test_that("sex='both' synthesizes the sex marginal", {
    both <- narcan::pop_singlerace |>
        dplyr::filter(year == 2024L) |>
        dplyr::distinct(year, age, race) |>
        dplyr::mutate(sex = "both", deaths = 1)
    out <- add_pop_counts(both, race_scheme = "single")
    expect_false(anyNA(out$pop))
    expected <- narcan::pop_singlerace |>
        dplyr::filter(year == 2024L) |>
        dplyr::group_by(year, age, race) |>
        dplyr::summarize(pop = sum(pop), .groups = "drop")
    chk <- dplyr::left_join(out, expected, by = c("year", "age", "race"),
                            suffix = c("", "_exp"))
    expect_equal(chk$pop, chk$pop_exp)
})

test_that("race='total' synthesizes the race marginal (incl. multiracial)", {
    tot <- narcan::pop_singlerace |>
        dplyr::filter(year == 2024L) |>
        dplyr::distinct(year, age, sex) |>
        dplyr::mutate(race = "total", deaths = 1)
    out <- add_pop_counts(tot, race_scheme = "single")
    expect_false(anyNA(out$pop))
    # total must equal the sum over ALL six single races (incl. multiracial=106)
    expected <- narcan::pop_singlerace |>
        dplyr::filter(year == 2024L) |>
        dplyr::group_by(year, age, sex) |>
        dplyr::summarize(pop = sum(pop), .groups = "drop")
    chk <- dplyr::left_join(out, expected, by = c("year", "age", "sex"),
                            suffix = c("", "_exp"))
    expect_equal(chk$pop, chk$pop_exp)
})

# ---- single scheme: geography routing ------------------------------------

test_that("a stratifier carried but absent from by_vars hard-errors (no silent sum)", {
    # geography: sub-national deaths must not collapse onto a national count
    inp <- single_input(2024L)
    inp$state_fips <- "06"                            # carried, not in by_vars
    expect_error(add_pop_counts(inp, race_scheme = "single"),
                 "population-dimension")

    # race omitted while stratified: the HIGH silent-13x-deflation case
    r <- data.frame(year = 2024L, age = 30L, sex = "male", race = "asian_only",
                    deaths = 1)
    expect_error(
        add_pop_counts(r, race_scheme = "single",
                       by_vars = c("year", "age", "sex")),
        "population-dimension")

    # sex omitted while stratified: silent ~2x
    s <- data.frame(year = 2024L, age = 30L, sex = "male", race = "asian_only",
                    deaths = 1)
    expect_error(
        add_pop_counts(s, race_scheme = "single",
                       by_vars = c("year", "age", "race")),
        "population-dimension")
})

test_that("st_fips (add_county_fips) without a geography key hard-errors", {
    inp <- single_input(2024L)
    inp$st_fips <- "06"                              # add_county_fips's name
    expect_error(add_pop_counts(inp, race_scheme = "single"), "st_fips")
})

test_that("single scheme warns when year is pooled (omitted from by_vars)", {
    d <- data.frame(age = 40L, sex = "male", race = "asian_only", deaths = 3)
    expect_warning(
        out <- add_pop_counts(d, race_scheme = "single",
                              by_vars = c("age", "sex", "race")),
        "pooled over all covered years")
    expect_false(anyNA(out$pop))
    exp <- sum(narcan::pop_singlerace$pop[
        narcan::pop_singlerace$race == "asian_only" &
            narcan::pop_singlerace$sex == "male" &
            narcan::pop_singlerace$age == 40L])
    expect_equal(out$pop, exp)
})

test_that("legacy does NOT apply the single-scheme stratifier guard", {
    # legacy is frozen: a narrow by_vars is a bare join (not the single guard)
    inp <- rate_input(year = 2015L, sex = "male", race = "white")
    # sex present in df, omitted from by_vars -> under legacy this must NOT hit
    # the population-dimension guard (that guard is single-only)
    out <- suppressWarnings(
        add_pop_counts(inp, by_vars = c("year", "age", "race")))
    expect_true("pop" %in% names(out))
})

test_that("county routing joins the county parquet (via fixture)", {
    skip_if_not_installed("duckdb")
    fx <- system.file("extdata", "pop_singlerace_county_fixture.parquet",
                      package = "narcan")
    skip_if_not(nzchar(fx) && file.exists(fx))
    withr::local_options(narcan.pop_single_county_parquet = fx)

    # Wyoming (56) is the fixture state; build a county death frame from it.
    keys <- get_pop_county(states = "56", years = 2024L, parquet = fx)
    keys <- dplyr::distinct(keys, state_fips, county_fips, year, age, sex, race)
    keys$deaths <- 1
    out <- add_pop_counts(
        keys, race_scheme = "single",
        by_vars = c("state_fips", "county_fips", "year", "age", "sex", "race"))
    expect_false(anyNA(out$pop))
    expect_equal(nrow(out), nrow(keys))
})

# ---- single scheme: grouping + factor safety ----------------------------------

test_that("single scheme restores grouped and rowwise inputs", {
    inp <- single_input(2024L)

    grp <- dplyr::group_by(inp, age)
    out_g <- add_pop_counts(grp, race_scheme = "single")
    expect_s3_class(out_g, "grouped_df")
    expect_identical(dplyr::group_vars(out_g), "age")

    rw <- dplyr::rowwise(inp)
    out_r <- add_pop_counts(rw, race_scheme = "single")
    expect_s3_class(out_r, "rowwise_df")
})

test_that("single scheme coerces a categorize_race() factor and joins", {
    inp <- single_input(2024L)
    inp$race <- factor(inp$race, levels = c("white_only", "black_only",
        "american_indian_only", "asian_only", "nhopi_only", "multiracial"),
        ordered = TRUE)
    out <- suppressWarnings(add_pop_counts(inp, race_scheme = "single"))
    expect_type(out$race, "character")
    expect_false(anyNA(out$pop))
})

# ---- single scheme: Hispanic-origin join (0.5.2 pin lifted) -------------------

test_that("single-race origin-stratified join succeeds per origin (0.5.2)", {
    ## Build a finest-cell frame that INCLUDES hispanic_origin, then join with
    ## origin as a key: each origin must get its OWN denominator, not the sum.
    keys <- dplyr::distinct(
        narcan::pop_singlerace[narcan::pop_singlerace$year == 2024L, ],
        year, age, sex, race, hispanic_origin)
    keys$deaths <- seq_len(nrow(keys))
    inp <- tibble::as_tibble(keys)
    out <- add_pop_counts(
        inp, race_scheme = "single",
        by_vars = c("year", "age", "sex", "race", "hispanic_origin"))
    expect_false(anyNA(out$pop))
    expect_setequal(unique(out$hispanic_origin), c("hispanic", "non_hispanic"))
    ## per-origin, not all-origin: one concrete hispanic cell == its finest pop.
    src <- narcan::pop_singlerace
    cell <- out[out$hispanic_origin == "hispanic", ][1, ]
    exp <- src$pop[src$year == 2024L & src$age == cell$age &
                   src$sex == cell$sex & src$race == cell$race &
                   src$hispanic_origin == "hispanic"]
    expect_equal(cell$pop, sum(exp))
})

test_that("the removed `hispanic=` argument now errors (DD3 breaking change)", {
    inp <- single_input(2024L)
    expect_error(
        add_pop_counts(inp, race_scheme = "single", hispanic = "hispanic"),
        "unused argument")
})

test_that("DD2: 'unknown' and NA hispanic_origin are non-denominable and error", {
    keys <- dplyr::distinct(
        narcan::pop_singlerace[narcan::pop_singlerace$year == 2024L, ],
        year, age, sex, race)
    by5 <- c("year", "age", "sex", "race", "hispanic_origin")
    unk <- keys; unk$hispanic_origin <- "unknown"; unk$deaths <- 1
    expect_error(add_pop_counts(unk, race_scheme = "single", by_vars = by5),
                 "no denominator")
    na <- keys; na$hispanic_origin <- NA_character_; na$deaths <- 1
    expect_error(add_pop_counts(na, race_scheme = "single", by_vars = by5),
                 "no denominator")
    ## a detailed categorize_hspanicr() label reads the GENERIC message (no carve-out)
    det <- keys; det$hispanic_origin <- "mexican"; det$deaths <- 1
    err <- tryCatch(add_pop_counts(det, race_scheme = "single", by_vars = by5),
                    error = function(e) conditionMessage(e))
    expect_match(err, "unrecognized")
    expect_false(grepl("no denominator", err))
})

test_that("DD6: mixing 'all' with a stratified origin in one frame errors", {
    keys <- dplyr::distinct(
        narcan::pop_singlerace[narcan::pop_singlerace$year == 2024L, ],
        year, age, sex, race)
    by5 <- c("year", "age", "sex", "race", "hispanic_origin")
    mixed <- rbind(
        transform(keys[1, ], hispanic_origin = "all"),
        transform(keys[1, ], hispanic_origin = "hispanic"))
    mixed$deaths <- 1
    expect_error(add_pop_counts(mixed, race_scheme = "single", by_vars = by5),
                 "double-count")
})

test_that("DD4: legacy scheme with hispanic_origin in by_vars errors cleanly", {
    inp <- rate_input(year = 2015L, sex = "male", race = "white")
    inp$hispanic_origin <- "hispanic"
    expect_error(
        add_pop_counts(inp, by_vars = c("year", "age", "sex", "race",
                                        "hispanic_origin")),
        "no Hispanic-origin denominator")
})

test_that("DD4: legacy silently-summed stratified origin PASSENGER errors (not in by_vars)", {
    ## The documented add_hispanic_origin() -> add_pop_counts() handoff with the
    ## legacy DEFAULT: hispanic_origin present but not in by_vars would otherwise
    ## give both strata the same all-origin pop_est denominator. Must error.
    inp <- rate_input(year = 2015L, sex = "male", race = "white")
    inp$hispanic_origin <- "hispanic"
    expect_error(suppressMessages(add_pop_counts(inp)),
                 "no Hispanic-origin denominator")
})

test_that("legacy tolerates a pure-'all' hispanic_origin passenger (harmless)", {
    inp <- rate_input(year = 2015L, sex = "male", race = "white")
    inp$hispanic_origin <- "all"
    out <- suppressMessages(add_pop_counts(inp))
    expect_false(anyNA(out$pop))
})

# ---- get_pop_state() accessor -------------------------------------------------

test_that("get_pop_state() filters and collapses origin", {
    all_ca <- get_pop_state(states = "06", years = 2024L)
    expect_true(all(all_ca$state_fips == "06"))
    expect_true(all(all_ca$hispanic_origin == "all"))
    # all-origin pop reconciles to the bundled finest cells
    src <- narcan::pop_singlerace_state
    src <- src[src$state_fips == "06" & src$year == 2024L, ]
    expect_equal(sum(all_ca$pop), sum(src$pop))

    hisp <- get_pop_state(states = "06", years = 2024L,
                          hispanic_origin = "hispanic")
    expect_true(all(hisp$hispanic_origin == "hispanic"))
})
