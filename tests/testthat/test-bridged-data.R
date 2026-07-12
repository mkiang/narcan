# Value goldens for the bundled SEER bridged national data (0.5.1, P2). Totals
# alone cannot catch a race or Hispanic-origin mislabel (bridging moves race, not
# the total), so the by-race, race x origin, and by-sex 2020 anchors are pinned
# to the person (measured from the SEER Vintage-2024 files during the build).

test_that("pop_bridged has the era-ragged structure and shape", {
    b <- narcan::pop_bridged
    expect_equal(nrow(b), 12348L)                    # 2268 pre-1990 + 10080 1990+
    expect_setequal(b$year, 1969:2024)
    expect_setequal(b$sex, c("male", "female"))
    expect_setequal(b$age, seq(0, 85, 5))
    expect_false(anyNA(b$pop))
    expect_true(all(b$pop >= 0))

    pre  <- b[b$year < 1990, ]
    post <- b[b$year >= 1990, ]
    expect_setequal(pre$race, c("white", "black", "other"))
    expect_setequal(post$race, c("white", "black", "american_indian", "api"))
    expect_setequal(pre$hispanic_origin, "all")
    expect_setequal(post$hispanic_origin, c("non_hispanic", "hispanic"))
    # finest cells only: unique on the full key
    expect_equal(nrow(b),
                 nrow(dplyr::distinct(b, year, age, sex, race, hispanic_origin)))
})

test_that("pop_bridged national totals reconcile to the person", {
    b <- narcan::pop_bridged
    expect_equal(sum(b$pop[b$year == 1990]), 249622814)   # both SEER series agree
    expect_equal(sum(b$pop[b$year == 2020]), 331577720)   # == Census single-race
})

test_that("pop_bridged 2020 by-race / origin / sex anchors are exact", {
    b <- narcan::pop_bridged
    b20 <- b[b$year == 2020, ]
    by_race <- tapply(b20$pop, b20$race, sum)
    expect_equal(as.numeric(by_race["white"]), 256353681)
    expect_equal(as.numeric(by_race["black"]), 47575527)
    expect_equal(as.numeric(by_race["american_indian"]), 4902239)
    expect_equal(as.numeric(by_race["api"]), 22746273)
    # race x origin cell -- catches BOTH a race mislabel and the SEER-vs-Census
    # origin polarity cross-wire at once
    nhw <- sum(b20$pop[b20$race == "white" &
                       b20$hispanic_origin == "non_hispanic"])
    expect_equal(nhw, 201085675)
    by_sex <- tapply(b20$pop, b20$sex, sum)
    expect_equal(as.numeric(by_sex["male"]), 164243648)
    expect_equal(as.numeric(by_sex["female"]), 167334072)
})

test_that("add_pop_counts(bridged) national joins end-to-end with no NA", {
    b <- narcan::pop_bridged
    # a bridged death frame from real keys: one 1985 (pre-1990, 3-group) and one
    # 2000 (1990+, 4-group) stratum
    d <- data.frame(
        year = c(1985L, 2000L), age = 40L, sex = "male",
        race = c("other", "api"), deaths = 1)
    out <- add_pop_counts(d, race_scheme = "bridged")
    expect_false(anyNA(out$pop))
    # each pop equals the all-origin national sum of that (year,age,sex,race)
    exp1985 <- sum(b$pop[b$year == 1985 & b$age == 40 & b$sex == "male" &
                         b$race == "other"])
    exp2000 <- sum(b$pop[b$year == 2000 & b$age == 40 & b$sex == "male" &
                         b$race == "api"])
    expect_equal(out$pop[out$year == 1985L], exp1985)
    expect_equal(out$pop[out$year == 2000L], exp2000)
})

test_that("add_pop_counts(bridged) synthesizes race='total' over the era race set", {
    b <- narcan::pop_bridged
    d <- data.frame(year = c(1985L, 2000L), age = 40L, sex = "male",
                    race = "total", deaths = 1)
    out <- add_pop_counts(d, race_scheme = "bridged")
    expect_false(anyNA(out$pop))
    exp1985 <- sum(b$pop[b$year == 1985 & b$age == 40 & b$sex == "male"])
    exp2000 <- sum(b$pop[b$year == 2000 & b$age == 40 & b$sex == "male"])
    expect_equal(out$pop[out$year == 1985L], exp1985)
    expect_equal(out$pop[out$year == 2000L], exp2000)
})
