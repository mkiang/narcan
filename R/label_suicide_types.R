#' Create a new column with labels for suicide type
#'
#' @param processed_df processe MCOD dataframe
#'
#' @return dataframe
#' @importFrom dplyr mutate case_when
#' @export
label_suicide_type <- function(processed_df) {

    new_df <- processed_df %>%
        mutate(suicide_type = case_when(
            suicide_firearm     == 1 ~ "suicide_firearm",
            suicide_poison      == 1 ~ "suicide_poison",
            suicide_fall        == 1 ~ "suicide_fall",
            suicide_suffocation == 1 ~ "suicide_suffocation",
            suicide_other       == 1 ~ "suicide_other",
            TRUE ~ "not_suicide"))

    return(new_df)
}
