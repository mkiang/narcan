# #7: opioid-subtype flags use word-boundaried code patterns, so a longer token
# that merely CONTAINS a subtype code (e.g. "T4011") no longer falsely flags.
# opioid_death is set via a real opioid T-code so the subtype gate is open.

overmatch <- function(subtype_fn, base, bad, year = 2019L) {
    df <- data.frame(year = year, ucod = "X42",
                     f_records_all = paste(base, bad),
                     stringsAsFactors = FALSE)
    withd <- flag_opioid_deaths(df, year = year, keep_cols = TRUE)
    subtype_fn(withd, year = year)
}

test_that("subtype flags do not over-match a longer token (#7)", {
    expect_equal(overmatch(flag_opium_present, "T401", "T4001")$opium_present, 0)
    expect_equal(overmatch(flag_heroin_present, "T403", "T4011")$heroin_present, 0)
    expect_equal(overmatch(flag_other_natural_present, "T401", "T4021")$other_natural_present, 0)
    expect_equal(overmatch(flag_methadone_present, "T401", "T4031")$methadone_present, 0)
    expect_equal(overmatch(flag_other_synth_present, "T401", "T4041")$other_synth_present, 0)
    expect_equal(overmatch(flag_other_op_present, "T401", "T4061")$other_op_present, 0)
})

test_that("subtype flags still fire on the real (bounded) code", {
    expect_equal(overmatch(flag_heroin_present, "T401", "T999")$heroin_present, 1)
    expect_equal(overmatch(flag_methadone_present, "T403", "T999")$methadone_present, 1)
})
