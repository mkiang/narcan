#' Unite the 20 record columns from MCOD dataframe into a single column
#'
#' This function collapses the 20 contributory cause columns into a single
#' column for easier regex'ing. ICD-9 dataframes will also get appropriate
#' prefixes before collapsing.
#'
#' @param icd_df an ICD dataframe
#' @param year the year of this dataframe -- if NULL, will attempt to detect
#'
#' @return dataframe
#' @importFrom dplyr mutate select starts_with
#' @importFrom tidyr unite
#' @export
unite_records <- function(icd_df, year = NULL) {
    ## Unite all 20 records columns into a single new column for easier
    ## regexing.
    .check_mcod_df(icd_df, fn = "unite_records")

    ## Extract year ----
    if (is.null(year)) {
        year <- .extract_year(icd_df)
    }

    ## For ICD-9 dataframes
    if (.is_icd9(year)) {
        ## ICD-9 record codes in [800, 999] need an E/N prefix set by the
        ## paired nature-of-injury flag. Build the 20 f_record_ columns
        ## pairwise (base R Map; across() cannot walk two column sets in
        ## lockstep), then drop the source columns and collapse. No purrr.
        rec_cols <- paste0("record_", 1:20)
        nif_cols <- paste0("rnifla_", 1:20)
        icd_df[paste0("f_record_", 1:20)] <-
            Map(prefix_to_record, icd_df[rec_cols], icd_df[nif_cols])

        df <- icd_df |>
            select(-starts_with("record_"), -starts_with("rnifla_")) |>
            unite(f_records_all, starts_with("f_record_"), sep = " ") |>
            mutate(f_records_all = gsub(f_records_all,
                                        pattern = " NA", replacement = ""))
    } else if (.is_icd10(year)) {
        ## NOTE: Some random ICD10 years will still have an rnifla_ column even
        ##      though they are all blank. We drop them here to keep them
        ##      conformable with all other years.
        df <- icd_df |>
            unite(f_records_all, starts_with("record_"), sep = " ") |>
            mutate(f_records_all = gsub(f_records_all,
                                        pattern = " NA", replacement = "")) |>
            select(-starts_with("rnifla"))
    } else {
        stop(sprintf(
            paste0("Cannot unite records for year %s: expected a 4-digit year ",
                   "in 1979-1998 (ICD-9) or >= 1999 (ICD-10). Two-digit ",
                   "`datayear` values (e.g. 93) are unsupported -- pass an ",
                   "explicit 4-digit `year`."),
            year), call. = FALSE)
    }

    return(df)
}
