#' Flag suicide five types: firearm, poisoning, fall, suffocation, or other
#'
#' ICD-10 only. Pre-1999 (ICD-9) data returns all zeros and emits a single
#' warning; ICD-9 detection is a future work item. The subtype helpers below
#' warn only when a pre-1999 `year` is passed explicitly, so calling this
#' orchestrator does not emit duplicate warnings.
#'
#' @param df processed MCOD dataframe
#' @param year if NULL, detected from `year`/`datayear`; used only to warn on
#'   pre-1999 (ICD-9) data
#'
#' @return new dataframe
#' @importFrom dplyr mutate
#' @export
#' @examples
#' df <- data.frame(
#'     year = 2019,
#'     ucod = c("X72", "X68", "X80", "X70", "X78")
#' )
#' flag_suicide_types(df, year = 2019)
flag_suicide_types <- function(df, year = NULL) {
    .warn_icd9_only(.detect_year_safe(df, year), "flag_suicide_types")
    new_df <- df |>
        flag_suicide_firearm() |>
        flag_suicide_poison() |>
        flag_suicide_fall() |>
        flag_suicide_suffocation() |>
        flag_suicide_other()

    return(new_df)
}


#' Flag suicide by firearm
#'
#' ICD-10 only (see flag_suicide_types). Warns if an explicit pre-1999 `year`
#' is supplied.
#'
#' @param df a processed MCOD dataframe
#' @param year optional; warns if explicitly < 1999
#'
#' @return dataframe
#' @importFrom dplyr mutate
#' @export
#' @examples
#' df <- data.frame(ucod = c("X72", "X73", "X60"))
#' flag_suicide_firearm(df)
flag_suicide_firearm <- function(df, year = NULL) {
    .warn_icd9_only(year, "flag_suicide_firearm")
    new_df <- df |>
        dplyr::mutate(suicide_firearm = grepl("\\<X7[234]\\d{0,1}\\>", ucod) + 0)

    return(new_df)
}


#' Flag suicide by poison
#'
#' ICD-10 only (see flag_suicide_types). Warns if an explicit pre-1999 `year`
#' is supplied.
#'
#' @param df a processed MCOD dataframe
#' @param year optional; warns if explicitly < 1999
#'
#' @return dataframe
#' @importFrom dplyr mutate
#' @export
#' @examples
#' df <- data.frame(ucod = c("X60", "X64", "X72"))
#' flag_suicide_poison(df)
flag_suicide_poison <- function(df, year = NULL) {
    .warn_icd9_only(year, "flag_suicide_poison")
    new_df <- df |>
        dplyr::mutate(suicide_poison = grepl("\\<X6\\d\\d{0,1}\\>", ucod) + 0)

    return(new_df)
}


#' Flag suicide by fall
#'
#' ICD-10 only (see flag_suicide_types). Warns if an explicit pre-1999 `year`
#' is supplied.
#'
#' @param df a processed MCOD dataframe
#' @param year optional; warns if explicitly < 1999
#'
#' @return dataframe
#' @importFrom dplyr mutate
#' @export
#' @examples
#' df <- data.frame(ucod = c("X80", "X72"))
#' flag_suicide_fall(df)
flag_suicide_fall <- function(df, year = NULL) {
    .warn_icd9_only(year, "flag_suicide_fall")
    new_df <- df |>
        dplyr::mutate(suicide_fall = grepl("\\<X80\\d{0,1}\\>", ucod) + 0)

    return(new_df)
}


#' Flag suicide by suffocation
#'
#' ICD-10 only (see flag_suicide_types). Warns if an explicit pre-1999 `year`
#' is supplied.
#'
#' @param df a processed MCOD dataframe
#' @param year optional; warns if explicitly < 1999
#'
#' @return dataframe
#' @importFrom dplyr mutate
#' @export
#' @examples
#' df <- data.frame(ucod = c("X70", "X80"))
#' flag_suicide_suffocation(df)
flag_suicide_suffocation <- function(df, year = NULL) {
    .warn_icd9_only(year, "flag_suicide_suffocation")
    new_df <- df |>
        dplyr::mutate(suicide_suffocation = grepl("\\<X70\\d{0,1}\\>", ucod) + 0)

    return(new_df)
}


#' Flag suicide by other (not poison, fall, firearm, suffocation)
#'
#' ICD-10 codes: U03, X71, X75-X79, X81-X84, Y870. ICD-10 only (see
#' flag_suicide_types). Warns if an explicit pre-1999 `year` is supplied.
#'
#' @param df a processed MCOD dataframe
#' @param year optional; warns if explicitly < 1999
#'
#' @return dataframe
#' @importFrom dplyr mutate
#' @export
#' @examples
#' df <- data.frame(ucod = c("X78", "X83", "X72"))
#' flag_suicide_other(df)
flag_suicide_other <- function(df, year = NULL) {
    .warn_icd9_only(year, "flag_suicide_other")
    new_df <- df |>
        dplyr::mutate(suicide_other = grepl("\\<U03\\d{0,1}\\>|\\<X7[156789]\\d{0,1}\\>|\\<X8[1234]\\d{0,1}\\>|\\<Y870\\d{0,1}\\>", ucod) + 0)

    return(new_df)
}
