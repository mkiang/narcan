# Frozen-legacy reproducibility pin (P5 / 0.5.0). narcan::pop_est is the
# legacy Census PEP series and MUST reproduce bit-for-bit so every published
# rate that used it stays reproducible. Baseline = the 0.4.2 bytes (post the
# year==420 hotfix + re-sort in fix_pop_est_year420.R), captured in
# fixtures/pop_est_v0.4.2.rds. Any change that trips this test is a breaking
# change to the reproducibility pin and must be intentional + documented.

test_that("pop_est reproduces the frozen 0.4.2 baseline bit-for-bit", {
    golden <- readRDS(test_path("fixtures", "pop_est_v0.4.2.rds"))
    expect_identical(narcan::pop_est, golden)
})
