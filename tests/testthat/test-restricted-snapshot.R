test_that("1979-2021 restricted layout is unchanged from v0.1.1 except racer40 2003-2011", {
    golden <- readRDS(test_path("fixtures", "golden_v011_restricted.rds"))
    golden <- golden[golden$year <= 2021, c("name", "type", "start", "end", "year")]
    golden <- golden[order(golden$year, golden$start, golden$name), ]

    new <- mcod_fwf_dicts[mcod_fwf_dicts$year <= 2021,
                          c("name", "type", "start", "end", "year")]
    ## drop the intentionally-added documented-but-empty racer40 (2003-2011)
    new <- new[!(new$name == "racer40" & new$year <= 2011), ]
    new <- new[order(new$year, new$start, new$name), ]

    expect_equal(as.data.frame(new), as.data.frame(golden))
})

test_that("hspanicr was widened to 487-488 for 2022+ (the one value fix)", {
    for (y in 2022:2024) {
        r <- mcod_fwf_dicts[mcod_fwf_dicts$year == y & mcod_fwf_dicts$name == "hspanicr", ]
        expect_equal(r$start, 487L)
        expect_equal(r$end, 488L)
    }
})

test_that("racer40 parity: present as documented-but-empty from 2003", {
    yrs <- sort(unique(mcod_fwf_dicts$year[mcod_fwf_dicts$name == "racer40"]))
    expect_true(all(2003:2024 %in% yrs))
})
