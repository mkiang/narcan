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

# ---- Hispanic pin holds in BOTH eras (D-HISP; no era branch) ------------------

test_that("bridged death-side join rejects a non-'all' hispanic_origin key", {
    d <- data.frame(year = 2000L, age = 40L, sex = "male", race = "white",
                    hispanic_origin = "hispanic", deaths = 1)
    expect_error(
        narcan:::.check_bridged_death_keys(
            d, c("year", "age", "sex", "race", "hispanic_origin")),
        "0.5.2")
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
