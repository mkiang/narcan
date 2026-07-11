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
#' @examples
#' df <- data.frame(
#'     year = 2019,
#'     record_1 = c("X42", "I250"),
#'     record_2 = c("T401", "")
#' )
#' unite_records(df, year = 2019)
unite_records <- function(icd_df, year = NULL) {
    ## Unite all 20 records columns into a single new column for easier
    ## regexing.
    .check_mcod_df(icd_df, fn = "unite_records")

    ## Extract year ----
    if (is.null(year)) {
        year <- .extract_year(icd_df)
    }

    ## For ICD-9 dataframes
    if (.dispatch_era(year) == "icd9") {
        ## ICD-9 record codes in [800, 999] need an E/N prefix set by the
        ## paired nature-of-injury flag. Build the 20 f_record_ columns
        ## pairwise (base R Map; across() cannot walk two column sets in
        ## lockstep), then drop the source columns and collapse. No purrr.
        rec_cols <- paste0("record_", 1:20)
        nif_cols <- paste0("rnifla_", 1:20)
        icd_df[paste0("f_record_", 1:20)] <-
            Map(prefix_to_record, icd_df[rec_cols], icd_df[nif_cols])

        df <- icd_df |>
            dplyr::select(-dplyr::starts_with("record_"), -dplyr::starts_with("rnifla_")) |>
            tidyr::unite(f_records_all, dplyr::starts_with("f_record_"), sep = " ") |>
            dplyr::mutate(f_records_all = trimws(gsub("\\s+", " ",
                                        gsub("\\bNA\\b", "", f_records_all))))
    } else {
        ## NOTE: Some random ICD10 years will still have an rnifla_ column even
        ##      though they are all blank. We drop them here to keep them
        ##      conformable with all other years.
        df <- icd_df |>
            tidyr::unite(f_records_all, dplyr::starts_with("record_"), sep = " ") |>
            dplyr::mutate(f_records_all = trimws(gsub("\\s+", " ",
                                        gsub("\\bNA\\b", "", f_records_all)))) |>
            dplyr::select(-dplyr::starts_with("rnifla"))
    }

    return(df)
}
