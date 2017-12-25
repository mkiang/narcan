#' Creates a new column called heroin_present if opioid death involved heroin
#'
#' Heroin deaths were recorded in both ICD-9 and ICD-10 years. This creates
#' a new column to flag when that death involved heroin and was an opioid
#' death as defined by flag_opioid_death().
#'
#' @param processed_df MCOD dataframe already processed
#' @param year if NULL, will attempt to detect
#' @param keep_cols keep intermediate columns
#'
#' @return a new dataframe with a binary heroin_present column
#' @importFrom dplyr select one_of "%>%" mutate
#' @importFrom tibble has_name
#' @export
flag_heroin_present <- function(processed_df, year = NULL, keep_cols = FALSE) {
    ## Extract year
    if (is.null(year)) {
        year <- .extract_year(processed_df)
    }

    ## Check if already preprocessed with necessary columns
    original_cols <- names(processed_df)
    if (!(tibble::has_name(processed_df, "f_records_all"))) {
        warning("Missing the column `f_records_all`. ",
                "Generating this column automatically.\n",
                "As a result, all `record_` columns will be dropped.\n",
                "See help(unite_records) for more information.")
        processed_df <- processed_df %>%
            unite_records(year = year)
    }

    if (!(tibble::has_name(processed_df, "opioid_death"))) {
        processed_df <- processed_df %>%
            flag_opioid_deaths(year = year)
    }

    if (year >= 1979 & year <= 1998) {
        new_df <- processed_df %>%
            dplyr::mutate(heroin_present =
                              dplyr::case_when(
                                  grepl(ucod, pattern = "E8500") &
                                      opioid_death == 1 ~ 1,
                                  grepl(f_records_all, pattern = "E8500") &
                                      opioid_death == 1 ~ 1,
                                  TRUE ~ 0))
    } else {
        new_df <- processed_df %>%
            dplyr::mutate(heroin_present =
                              dplyr::case_when(
                                  grepl(f_records_all, pattern = "T401") &
                                      opioid_death == 1 ~ 1,
                                  TRUE ~ 0))
    }

    ## Drop all intermediate columns?
    if (!keep_cols) {
        new_df <- suppressMessages(suppressWarnings(
            dplyr::select(
                new_df, dplyr::one_of(c(original_cols, "heroin_present"))
                )
        ))
    }

    return(new_df)
}
