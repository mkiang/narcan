test_that("1979-2021 restricted layout is unchanged from v0.1.1 except the documented fixes", {
    golden <- readRDS(test_path("fixtures", "golden_v011_restricted.rds"))
    golden <- golden[golden$year <= 2021, c("name", "type", "start", "end", "year")]

    new <- mcod_fwf_dicts[mcod_fwf_dicts$year <= 2021,
                          c("name", "type", "start", "end", "year")]

    ## Every deviation from the v0.1.1 golden layout is normalized away here, one carve-out per
    ## approved correction, so this test still proves that NOTHING ELSE moved. Do not regenerate
    ## the fixture -- that would defeat the purpose.

    ## (a) racer40, which the v0.1.1 golden layout carried only from 2012. It is now named for
    ## 2003-2011 too: position-less for 2003-2007 (those bytes hold the state of occurrence) and
    ## at 489-490 for 2008-2011 (blank 2008-2010, real data from 2011). None of that exists in
    ## golden, so drop the whole range before comparing.
    new <- new[!(new$name == "racer40" & new$year <= 2011), ]

    ## (b) certifier/tobacco_use/pregnancy_status added to 2003-2004. The 2003 layout doc
    ## documents all three and the restricted bytes are populated; v0.1.1 carried them from 2005.
    new <- new[!(new$name %in% c("certifier", "tobacco_use", "pregnancy_status") &
                     new$year %in% 2003:2004), ]

    ## (c) 2003 byte 450 is Race Recode 5, not Race Recode 2. Rename rather than drop, so the
    ## position itself is still compared against the golden layout.
    new$name[new$name == "racer5" & new$year == 2003L] <- "racer2"

    ## (d) rnifla_20 dropped for 2003: it sits inside record_20 (439-442) and is all-blank in
    ## both tiers. It is the golden layout that carries the phantom, so drop it there.
    golden <- golden[!(golden$name == "rnifla_20" & golden$year == 2003L), ]

    golden <- golden[order(golden$year, golden$start, golden$name), ]
    new <- new[order(new$year, new$start, new$name), ]

    expect_equal(as.data.frame(new), as.data.frame(golden))
})

test_that("2003-2004 gained certifier/tobacco_use/pregnancy_status at the 2005 positions", {
    ref <- mcod_fwf_dicts[mcod_fwf_dicts$year == 2005L, ]
    fields <- c(certifier = 110L, tobacco_use = 142L, pregnancy_status = 143L)
    for (y in 2003:2004) {
        d <- mcod_fwf_dicts[mcod_fwf_dicts$year == y, ]
        for (nm in names(fields)) {
            expect_equal(d$start[d$name == nm], unname(fields[[nm]]), info = paste(nm, y))
            ## all three are single-byte fields, and the type must match 2005 or an arrow
            ## dataset spanning the boundary gets two schemas for one column
            expect_equal(d$end[d$name == nm], unname(fields[[nm]]), info = paste(nm, y))
            expect_equal(d$type[d$name == nm], ref$type[ref$name == nm], info = paste(nm, y))
        }
    }
    ## certifier is now unbroken from 2003 to the present
    yrs <- sort(unique(mcod_fwf_dicts$year[mcod_fwf_dicts$name == "certifier"]))
    expect_equal(yrs, 2003:2024)
})

test_that("2003-2019 share one column set; 2020+ is a strict superset", {
    ## This is what a multi-year arrow dataset needs. Note it stops at 2019: 2020 onward add
    ## coded occupation and industry, so a 2003-2024 open_dataset() still needs
    ## unify_schemas = TRUE. The boundary is pinned here rather than skipped.
    ref <- sort(mcod_fwf_dicts$name[mcod_fwf_dicts$year == 2005L])
    for (y in 2003:2019) {
        got <- sort(mcod_fwf_dicts$name[mcod_fwf_dicts$year == y])
        expect_equal(got, ref, info = paste("year", y))
    }
    for (y in 2020:2024) {
        got <- mcod_fwf_dicts$name[mcod_fwf_dicts$year == y]
        expect_setequal(setdiff(got, ref),
                        c("industry", "industryr", "occupation", "occupationr"))
        ## expect_equal, not expect_length: on failure this names the missing column
        expect_equal(setdiff(ref, got), character(0), info = paste("year", y))
    }
})

test_that("every name in 2003-2024 carries one consistent type", {
    d <- mcod_fwf_dicts[mcod_fwf_dicts$year %in% 2003:2024, ]
    n_types <- tapply(d$type, d$name, function(x) length(unique(x)))
    expect_true(all(n_types == 1L),
                info = paste("multi-typed:", paste(names(n_types)[n_types > 1], collapse = ", ")))
})

test_that("2003 byte 450 is racer5, and racer2 survives only through 2002", {
    r <- mcod_fwf_dicts[mcod_fwf_dicts$name == "racer5" & mcod_fwf_dicts$year == 2003L, ]
    expect_equal(r$start, 450L)
    expect_equal(max(mcod_fwf_dicts$year[mcod_fwf_dicts$name == "racer2"]), 2002L)
})

test_that("the phantom rnifla_20 is gone from 2003", {
    expect_false(any(mcod_fwf_dicts$name == "rnifla_20" & mcod_fwf_dicts$year == 2003L))
})

test_that("hspanicr was widened to 487-488 for 2022+ (the one value fix)", {
    for (y in 2022:2024) {
        r <- mcod_fwf_dicts[mcod_fwf_dicts$year == y & mcod_fwf_dicts$name == "hspanicr", ]
        expect_equal(r$start, 487L)
        expect_equal(r$end, 488L)
    }
})

test_that("racer40 parity: named from 2003 so the column set stays uniform", {
    yrs <- sort(unique(mcod_fwf_dicts$year[mcod_fwf_dicts$name == "racer40"]))
    expect_true(all(2003:2024 %in% yrs))
})

test_that("racer40 has no position in 2003-2007 and keeps 489-490 from 2008", {
    ## Measured in verify_fwf/output/review/86_racer40_489490_oracle.csv: bytes 489-490 hold the
    ## expanded state of occurrence (legacy NCHS numeric coding) for 2003-2007 -- 52 codes
    ## matching stateoc count-for-count, with 33 (NY less NYC) + 55 (NYC) summing to the NY total
    ## in every one of those years. They are blank 2008-2010 and carry real Race Recode 40 from
    ## 2011. Declaring a position for 2003-2007 surfaced state codes under a race name, so those
    ## years are named but position-less and import as all-NA.
    for (y in 2003:2007) {
        r <- mcod_fwf_dicts[mcod_fwf_dicts$year == y & mcod_fwf_dicts$name == "racer40", ]
        expect_true(is.na(r$start), info = paste("year", y))
        expect_true(is.na(r$end), info = paste("year", y))
    }
    for (y in 2008:2012) {
        r <- mcod_fwf_dicts[mcod_fwf_dicts$year == y & mcod_fwf_dicts$name == "racer40", ]
        expect_equal(r$start, 489L, info = paste("year", y))
        expect_equal(r$end, 490L, info = paste("year", y))
    }
})

test_that("a 2003 import returns racer40 as all-NA, not the bytes at 489-490", {
    ## Build the full 490-byte record explicitly. The declared layout now stops at 488, so
    ## growing the line with `substr<-` would be a silent no-op and the leak assertion below
    ## would pass for the wrong reason.
    line <- paste0(paste(rep("0", 488L), collapse = ""), "05")
    stopifnot(nchar(line) == 490L, substr(line, 489L, 490L) == "05")
    substr(line, 102, 105) <- "2003"
    tmp <- withr::local_tempfile()
    writeLines(c(line, line), tmp)

    out <- import_mcod_fwf(tmp, year = 2003, tier = "restricted")

    expect_true(all(is.na(out$racer40)))
    ## racer40 is type "n", so if it regained 489-490 readr would parse "05" to the double 5 --
    ## comparing only against the string "05" would never fire. Check both. Every other field on
    ## this all-zeros fixture reads 0 or "0000", so a bare == 5 is unambiguous here.
    leaked <- vapply(out, function(cl) {
        any(as.character(cl) == "05", na.rm = TRUE) ||
            (is.numeric(cl) && any(cl == 5, na.rm = TRUE))
    }, logical(1))
    expect_false(any(leaked))
})

test_that("restricted rows without a position are exactly the known set", {
    ## Guard against a position going missing by accident: NA start/end on the restricted tier
    ## means "declared but unavailable", and racer40 2003-2007 is the only such case.
    no_pos <- mcod_fwf_dicts[is.na(mcod_fwf_dicts$start), c("name", "year")]
    expect_setequal(no_pos$name, "racer40")
    expect_setequal(no_pos$year, 2003:2007)
    ## start and end always go missing together
    expect_identical(is.na(mcod_fwf_dicts$start), is.na(mcod_fwf_dicts$end))
})
