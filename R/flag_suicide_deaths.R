#' Flag suicide deaths (no accidental poisoning)
#'
#' ICD-10 only. Pre-1999 (ICD-9) data returns all zeros and emits a warning;
#' ICD-9 suicide detection is a future work item.
#'
#' @param df processed MCOD dataframe
#' @param year if NULL, detected from `year`/`datayear`; used only to warn on
#'   pre-1999 (ICD-9) data
#'
#' @return new dataframe
#' @importFrom dplyr mutate
#' @export
#' @examples
#' df <- data.frame(year = 2019, ucod = c("X72", "I250"))
#' flag_suicide_deaths(df, year = 2019)
flag_suicide_deaths <- function(df, year = NULL) {
    .warn_icd9_only(.detect_year_safe(df, year), "flag_suicide_deaths")
    ## Word-boundary anchors (\< \>) and the optional trailing digit (\d{0,1})
    ## mirror flag_suicide_types()'s subtype regexes, so a code only matches as a
    ## whole token. This is the union of those subtypes and returns the identical
    ## set on real 3- and 4-character ICD-10 codes (defense-in-depth only).
    new_df <- df |>
        dplyr::mutate(suicide_death = grepl(
            "\\<U03\\d{0,1}\\>|\\<X[67]\\d\\d{0,1}\\>|\\<X8[01234]\\d{0,1}\\>|\\<Y870\\d{0,1}\\>",
            ucod) + 0)

    return(new_df)
}
