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

test_that("public geography is suppressed from 2005, certifier/tobacco/pregnancy from 2003", {
    d <- mcod_public_fwf_dicts
    supp_2010 <- d$name[d$year == 2010 & d$suppressed]
    expect_true(all(c("stateoc", "countyoc", "staters", "countyrs", "cityrs",
                      "rectype", "certifier", "tobacco_use", "pregnancy_status")
                    %in% supp_2010))
    ## pre-2005 public still carries geography
    expect_false("stateoc" %in% d$name[d$year == 2004 & d$suppressed])
    ## ...but the three certifier-entered items are blank in public 2003-2004 too
    for (y in 2003:2004) {
        supp <- d$name[d$year == y & d$suppressed]
        expect_true(all(c("certifier", "tobacco_use", "pregnancy_status") %in% supp),
                    info = paste("year", y))
    }
})

test_that("2013 certifier/tobacco_use stay declared: an upstream dropout, not masking", {
    ## Both fields are 100% blank in the RESTRICTED 2013 file as well, so this is a one-year
    ## NCHS gap rather than a confidentiality suppression. Marking them suppressed would assert
    ## a masking that did not happen; the declared positions read blank -> NA in both tiers.
    d <- mcod_public_fwf_dicts
    for (nm in c("certifier", "tobacco_use")) {
        expect_false(d$suppressed[d$year == 2013 & d$name == nm], info = nm)
        expect_false(is.na(d$start[d$year == 2013 & d$name == nm]), info = nm)
    }
    ## pregnancy_status IS genuinely masked in public that year
    expect_true(d$suppressed[d$year == 2013 & d$name == "pregnancy_status"])
})

test_that("racer40 is suppressed on public 2003-2012 then present", {
    d <- mcod_public_fwf_dicts
    expect_true(d$suppressed[d$year == 2010 & d$name == "racer40"])
    expect_false(d$suppressed[d$year == 2013 & d$name == "racer40"])
})
