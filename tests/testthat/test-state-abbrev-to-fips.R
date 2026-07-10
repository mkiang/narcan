# state_abbrev_to_fips() now returns ZERO-PADDED fips (Phase 3 fix; MK ruled the
# prior unpadded "6" a bug at the Phase 2 checkpoint), matching add_county_fips().

test_that("state_abbrev_to_fips() returns zero-padded fips", {
    expect_equal(state_abbrev_to_fips("CA"), "06")
    expect_equal(state_abbrev_to_fips(c("CA", "NY")), c("06", "36"))
})
