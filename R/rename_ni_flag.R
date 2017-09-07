#' Rename nature of injury columns for consistency
#'
#' Some of the NBER ICD-9 MCOD files use rniflag_ as a column name while
#' others use rnifla_. This function makes the names consistent (to rnifla_).
#'
#' @param icd9_df an ICD-9 dataframe
#'
#' @return dataframe
#' @export
rename_ni_flag <- function(icd9_df) {
    names(icd9_df) <- gsub(names(icd9_df),
                      pattern = "rniflag_",
                      replacement = "rnifla_")

    return(icd9_df)
}
