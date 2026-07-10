# Bucket B: state_abbrev_to_fips() returns UNPADDED fips ("6" for CA), which
# disagrees with add_county_fips()'s zero-padded "06". Whether that is a bug or
# intentional is a Phase-2-CHECKPOINT decision for MK -- so this only locks the
# CURRENT (unpadded) behavior. If MK rules "bug", Phase 3 pads it and the desired
# test below is un-skipped and this KNOWN-BEHAVIOR test deleted.

test_that("KNOWN BEHAVIOR: state_abbrev_to_fips() returns unpadded fips", {
    expect_equal(state_abbrev_to_fips("CA"), "6")     # not "06"
    expect_equal(state_abbrev_to_fips(c("CA", "NY")), c("6", "36"))
})

test_that("state_abbrev_to_fips() returns zero-padded fips", {
    skip("Bucket B: un-skip only if MK rules the unpadded output a bug at the Phase 2 checkpoint")
    expect_equal(state_abbrev_to_fips("CA"), "06")
    expect_equal(state_abbrev_to_fips(c("CA", "NY")), c("06", "36"))
})
