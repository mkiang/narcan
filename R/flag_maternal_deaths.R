#' Creates a new column called maternal_death with 1 if maternal death
#'
#' Maternal deaths according to ICD-10 codes.
#'
#' @param processed_df MCOD dataframe already processed
#' @param year if NULL, will attempt to detect
#' @param ucod_only if TRUE, only flag maternal deaths in underlying cause
#' @param keep_cols keep intermediate columns
#'
#' @return a new dataframe with a binary maternal_death column
#' @importFrom dplyr select one_of "%>%" mutate
#' @importFrom tibble has_name
#' @export
flag_maternal_deaths <- function (processed_df, year = NULL,
                                  ucod_only = FALSE, keep_cols = FALSE) {
    ## Extract year
    if (is.null(year)) {
        year <- .extract_year(processed_df)
    }

    if (year < 2003) {
        warning(paste("Calculating maternal mortality using death",
                      "certificate data before 2003 is not recommended."))
    }

    original_cols <- names(processed_df)

    ## First flag columns based only on underlying cause
    df <- processed_df %>%
        mutate(maternal_death = (grepl(.regex_maternal_icd10(), ucod)) + 0)

    ## Now also flag contributing causes if ucod_only == FALSE
    if (ucod_only == FALSE) {
        if (!(tibble::has_name(processed_df, "f_records_all"))) {
            warning("Missing the column `f_records_all`. ",
                    "Generating this column automatically.\n",
                    "As a result, all `record_` columns will be dropped.\n",
                    "See help(unite_records) for more information.")
            df <- df %>% unite_records(year = year)
        }
        df <- df %>%
            mutate(maternal_death = case_when(
                grepl(.regex_maternal_icd10(), f_records_all) ~ 1,
                TRUE ~ maternal_death))
    }

    if (!keep_cols) {
        df <- suppressMessages(suppressWarnings(
            dplyr::select(
                df, dplyr::one_of(c(original_cols, "maternal_death"))
            )
        ))
    }

    return(df)
}
