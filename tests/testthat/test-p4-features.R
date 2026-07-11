# Tests for the 0.4-P4 features: opioid_deaths_only (#2), categorize_sex/
# categorize_female (#11), remap_age (#15), and the flag_all_deaths wrapper.

## --- #2: flag_opioid_types(..., opioid_deaths_only) ------------------------

test_that("opioid_deaths_only = TRUE (default) is unchanged; FALSE un-gates types (#2)", {
    d <- data.frame(year = 2019, ucod = c("X42", "I250"),
                    f_records_all = c("T401", "T401"))
    proc <- d |> flag_drug_deaths(2019) |> flag_opioid_deaths(2019)

    t_true <- proc |> flag_opioid_types(2019)
    expect_equal(t_true$opioid_death, c(1, 0))
    expect_equal(t_true$heroin_present, c(1, 0))     # only the opioid death
    expect_equal(t_true$num_opioids, c(1, 0))

    t_false <- proc |> flag_opioid_types(2019, opioid_deaths_only = FALSE)
    expect_equal(t_false$heroin_present, c(1, 1))    # contributory-only too
    expect_equal(t_false$opioid_death, c(1, 0))      # opioid_death itself unchanged
    expect_equal(t_false$num_opioids, c(1, 1))
    expect_true(all(t_false$unspecified_op_present == 0))  # residual stays coherent
})

test_that("opioid_deaths_only preserves the DAG-landmine under TRUE, runs under FALSE (#2)", {
    proc <- data.frame(year = 2019, ucod = "X42", f_records_all = "T403")
    expect_error(flag_methadone_present(proc, year = 2019L), "opioid_death")
    expect_equal(
        flag_methadone_present(proc, year = 2019L, opioid_deaths_only = FALSE)$methadone_present,
        1)
})

test_that("opioid_deaths_only leaves ICD-9 subtype flags unchanged (#2)", {
    # 1993 is a genuine ICD-9 year (1979-1998). ICD-9 opioid_death is pure
    # presence, so TRUE and FALSE agree there.
    d <- data.frame(year = 1993, ucod = "E8500", f_records_all = "N9650")
    a <- d |> flag_opioid_deaths(1993) |> flag_opioid_types(1993)
    b <- d |> flag_opioid_deaths(1993) |> flag_opioid_types(1993, opioid_deaths_only = FALSE)
    expect_equal(a$heroin_present, 1)     # non-trivial: E8500 (heroin) is present
    expect_equal(a$heroin_present, b$heroin_present)
    expect_equal(a$num_opioids, b$num_opioids)
})

test_that("opioid type flags are grouped / rowwise safe AND match ungrouped (#2 regression)", {
    g <- data.frame(year = 2019, grp = c("a", "b", "a", "b"), ucod = "X42",
                    f_records_all = c("T401", "T403", "T401", "T406")) |>
        flag_opioid_deaths(2019)
    gg <- dplyr::group_by(g, grp)
    expect_equal(flag_heroin_present(gg, 2019)$heroin_present, c(1, 0, 1, 0))
    expect_no_error(flag_heroin_present(dplyr::rowwise(g), 2019))

    ## grouped output must EQUAL ungrouped across all 9 type columns (guards a
    ## future silent-wrong-value regression, not just the no-error case).
    type_cols <- c("opium_present", "heroin_present", "other_natural_present",
                   "methadone_present", "other_synth_present", "other_op_present",
                   "unspecified_op_present", "num_opioids", "multi_opioids")
    for (odo in c(TRUE, FALSE)) {
        grp_out <- dplyr::ungroup(flag_opioid_types(gg, 2019, opioid_deaths_only = odo))
        ung_out <- flag_opioid_types(g, 2019, opioid_deaths_only = odo)
        expect_equal(as.data.frame(grp_out)[type_cols], ung_out[type_cols])
    }
})

test_that("opioid_deaths_only = FALSE: ICD-9 unspecified residual is coherent (#2)", {
    # N9650 (opioid nature code) with no specific opioid E-code -> unspecified.
    d1 <- data.frame(year = 1993, ucod = "E8542", f_records_all = "N9650") |>
        flag_opioid_deaths(1993)
    r1 <- flag_opioid_types(d1, 1993, opioid_deaths_only = FALSE)
    expect_equal(r1$unspecified_op_present, 1)
    expect_equal(r1$num_opioids, 1)

    # a non-opioid drug record must NOT inflate the residual.
    d2 <- data.frame(year = 1993, ucod = "E8542", f_records_all = "N9670") |>
        flag_opioid_deaths(1993)
    r2 <- flag_opioid_types(d2, 1993, opioid_deaths_only = FALSE)
    expect_equal(r2$unspecified_op_present, 0)
    expect_equal(r2$num_opioids, 0)
})

## --- #11: categorize_sex / categorize_female -------------------------------

test_that("categorize_sex maps both eras to male/female/NA (#11)", {
    expect_equal(categorize_sex(c(1, 2, 9), year = 2000), c("male", "female", NA))
    expect_equal(categorize_sex(c("M", "F", "U"), year = 2019), c("male", "female", NA))
    # labels line up with pop_est$sex
    expect_true(all(stats::na.omit(categorize_sex(c(1, 2), year = 2000)) %in%
                        unique(pop_est$sex)))
})

test_that("categorize_female returns 1/0/NA (#11)", {
    r <- categorize_female(c(1, 2), year = 2000)
    expect_equal(r, c(0L, 1L))
    expect_type(r, "integer")
    expect_equal(categorize_female(c("M", "F", NA), year = 2019), c(0L, 1L, NA))
})

test_that("categorize_sex infers era from type when year omitted, and warns (#11)", {
    expect_warning(r <- categorize_sex(c(1, 2)), "not supplied")
    expect_equal(r, c("male", "female"))
    expect_warning(categorize_sex(c(1, 2), year = 2019), "mapped to NA")  # era mismatch
})

## --- #15: remap_age --------------------------------------------------------

test_that("remap_age converts 2003+ detail age; known sub-year -> 0 (fixes sketch bug) (#15)", {
    out <- remap_age(data.frame(year = 2019, age = c(1037, 2006, 4015, 1999, 9999)))
    expect_equal(out$age_years, c(37, 0, 0, NA, NA))
})

test_that("remap_age converts pre-2003 detail age (#15)", {
    expect_equal(remap_age(data.frame(year = 2000, age = c(37, 205, 999)))$age_years,
                 c(37, 0, NA))
})

test_that("remap_age dispatches on 2003 (not 1999) and errors on impossible year (#15)", {
    # 1000 is a valid 2003+ code (year 0) but an invalid pre-2003 code -> era matters
    expect_equal(remap_age(data.frame(year = 2003, age = 1025))$age_years, 25)
    expect_error(remap_age(data.frame(year = 1850, age = 1)), "cannot map age")
    expect_error(remap_age(data.frame(year = 2019)), "needs the raw detail-age")
})

## --- flag_all_deaths wrapper -----------------------------------------------

test_that("flag_all_deaths runs the canonical chain (matches the steps) (#P4)", {
    d <- data.frame(year = 2019, ucod = "X42", f_records_all = "T401 T404")
    wrapped <- flag_all_deaths(d, year = 2019)
    manual <- d |>
        flag_drug_deaths(2019) |>
        flag_opioid_deaths(2019) |>
        flag_opioid_types(2019) |>
        flag_od_intent(2019)
    expect_equal(wrapped$drug_death, manual$drug_death)
    expect_equal(wrapped$opioid_death, manual$opioid_death)
    expect_equal(wrapped$num_opioids, manual$num_opioids)
    expect_equal(wrapped$unintended_intent, manual$unintended_intent)
})

test_that("flag_all_deaths toggles omit optional steps (#P4)", {
    d <- data.frame(year = 2019, ucod = "X42", f_records_all = "T401")
    no_types <- flag_all_deaths(d, year = 2019, types = FALSE)
    expect_false("heroin_present" %in% names(no_types))
    expect_true("opioid_death" %in% names(no_types))       # core steps stay
    no_intent <- flag_all_deaths(d, year = 2019, intent = FALSE)
    expect_false("unintended_intent" %in% names(no_intent))
})
