## 0.5.2 golden anchors (frozen from 0.5.1 before the Hispanic death-side join).
##
## These pin the population values on the paths that MUST stay byte-identical
## after the 0.5.2 pin-lift: the three happy-path schemes AND the currently-
## succeeding all-origin `hispanic_origin = "all"`-in-`by_vars` strict path.
## Values were captured from installed narcan 0.5.1. Crucially, the all-origin
## strict result equals the no-origin result (single 8407729; bridged 8701523),
## so once `.synthesize_pop()` stops pinning origin unconditionally these must
## not move. The join uses bundled national denominators only (no network).

test_that("legacy happy path is unchanged (0.5.1 golden)", {
  x <- suppressMessages(add_pop_counts(
    data.frame(year = 2019, age = 25, sex = "male", race = "white"),
    by_vars = c("year", "age", "sex", "race"), race_scheme = "legacy"))
  expect_equal(x$pop, 8739704)
})

test_that("single happy path is unchanged (0.5.1 golden)", {
  x <- add_pop_counts(
    data.frame(year = 2020, age = 25, sex = "male", race = "white_only"),
    by_vars = c("year", "age", "sex", "race"), race_scheme = "single")
  expect_equal(x$pop, 8407729)
})

test_that("bridged happy path is unchanged (0.5.1 golden)", {
  x <- add_pop_counts(
    data.frame(year = 2019, age = 25, sex = "male", race = "white"),
    by_vars = c("year", "age", "sex", "race"), race_scheme = "bridged")
  expect_equal(x$pop, 8701523)
})

test_that("single all-origin (hispanic_origin='all' in by_vars) == no-origin single", {
  x <- add_pop_counts(
    data.frame(year = 2020, age = 25, sex = "male", race = "white_only",
               hispanic_origin = "all"),
    by_vars = c("year", "age", "sex", "race", "hispanic_origin"),
    race_scheme = "single")
  expect_equal(x$pop, 8407729)
})

test_that("bridged all-origin (hispanic_origin='all' in by_vars) == no-origin bridged", {
  x <- add_pop_counts(
    data.frame(year = 2019, age = 25, sex = "male", race = "white",
               hispanic_origin = "all"),
    by_vars = c("year", "age", "sex", "race", "hispanic_origin"),
    race_scheme = "bridged")
  expect_equal(x$pop, 8701523)
})
