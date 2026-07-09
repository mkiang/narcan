test_that("public and restricted have identical column sets every year", {
    for (y in 1979:2024) {
        pub <- mcod_public_fwf_dicts$name[mcod_public_fwf_dicts$year == y]
        res <- mcod_fwf_dicts$name[mcod_fwf_dicts$year == y]
        expect_setequal(pub, res)
    }
})

test_that("suppressed is logical and lines up with NA positions", {
    d <- mcod_public_fwf_dicts
    expect_type(d$suppressed, "logical")
    expect_true(all(is.na(d$start[d$suppressed])))
    expect_true(all(is.na(d$end[d$suppressed])))
    expect_true(all(!is.na(d$start[!d$suppressed])))
})

test_that("public geography and certifier/tobacco/pregnancy are suppressed from 2005", {
    d <- mcod_public_fwf_dicts
    supp_2010 <- d$name[d$year == 2010 & d$suppressed]
    expect_true(all(c("stateoc", "countyoc", "staters", "countyrs", "cityrs",
                      "rectype", "certifier", "tobacco_use", "pregnancy_status")
                    %in% supp_2010))
    ## pre-2005 public still carries geography
    expect_false("stateoc" %in% d$name[d$year == 2004 & d$suppressed])
})

test_that("racer40 is suppressed on public 2003-2012 then present", {
    d <- mcod_public_fwf_dicts
    expect_true(d$suppressed[d$year == 2010 & d$name == "racer40"])
    expect_false(d$suppressed[d$year == 2013 & d$name == "racer40"])
})
