#' Flag suicide five types: firearm, poisoning, fall, suffocation, or other
#'
#' TODO: Make this also work with ICD-9
#'
#' @param df processed MCOD dataframe
#'
#' @return new dataframe
#' @importFrom dplyr mutate
#' @export
flag_suicide_types <- function(df) {
    new_df <- df %>%
        flag_suicide_firearm() %>%
        flag_suicide_poison() %>%
        flag_suicide_fall() %>%
        flag_suicide_suffocation() %>%
        flag_suicide_other()

    return(new_df)
}


#' Flag suicide by firearm
#'
#' TODO: MAKE WORK WITH ICD-9
#'
#' @param df a processed MCOD dataframe
#'
#' @return dataframe
#' @importFrom dplyr mutate
#' @export
flag_suicide_firearm <- function(df) {
    new_df <- df %>%
        mutate(suicide_firearm = grepl("X7[234]", ucod) + 0)

    return(new_df)
}


#' Flag suicide by poison
#'
#' TODO: MAKE WORK WITH ICD-9
#'
#' @param df a processed MCOD dataframe
#'
#' @return dataframe
#' @importFrom dplyr mutate
#' @export
flag_suicide_poison <- function(df) {
    new_df <- df %>%
        mutate(suicide_poison = grepl("X6\\d{1}", ucod) + 0)

    return(new_df)
}


#' Flag suicide by fall
#'
#' TODO: MAKE WORK WITH ICD-9
#'
#' @param df a processed MCOD dataframe
#'
#' @return dataframe
#' @importFrom dplyr mutate
#' @export
flag_suicide_fall <- function(df) {
    new_df <- df %>%
        mutate(suicide_fall = grepl("X80", ucod) + 0)

    return(new_df)
}


#' Flag suicide by suffocation
#'
#' TODO: MAKE WORK WITH ICD-9
#'
#' @param df a processed MCOD dataframe
#'
#' @return dataframe
#' @importFrom dplyr mutate
#' @export
flag_suicide_suffocation <- function(df) {
    new_df <- df %>%
        mutate(suicide_suffocation = grepl("X70", ucod) + 0)

    return(new_df)
}


#' Flag suicide by other (not poison, fall, firearm, suffocation)
#'
#' ICD-10 codes: U03, X71, X75-X79, X81-X84, Y870
#'
#' TODO: MAKE WORK WITH ICD-9
#'
#' @param df a processed MCOD dataframe
#'
#' @return dataframe
#' @importFrom dplyr mutate
#' @export
flag_suicide_other <- function(df) {
    new_df <- df %>%
        mutate(suicide_other = grepl("U03|X7[156789]|X8[1234]|Y870",
                                   ucod) + 0)

    return(new_df)
}
