# Warn-only input guard (.check_mcod_df), added in Phase 3. It must NEVER abort:
# it warns on a non-data-frame or on absent required columns so a caller gets a
# named signal instead of a cryptic downstream "object not found"/join error.

test_that(".check_mcod_df warns (and returns NULL, does not error) on a non-data-frame", {
    expect_warning(.check_mcod_df(1:10, fn = "f"), "data frame")
    expect_null(suppressWarnings(.check_mcod_df(1:10, fn = "f")))
})

test_that(".check_mcod_df warns on absent required columns and names them", {
    df <- tibble::tibble(ucod = "T401")
    expect_warning(
        .check_mcod_df(df, need = c("ucod", "drug_death"), fn = "f"),
        "drug_death"
    )
})

test_that(".check_mcod_df is silent when the frame has every needed column", {
    df <- tibble::tibble(ucod = "T401", drug_death = 1L)
    expect_silent(.check_mcod_df(df, need = c("ucod", "drug_death"), fn = "f"))
})
