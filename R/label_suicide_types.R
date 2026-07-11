#' Create a new column with labels for suicide type
#'
#' @param processed_df processed MCOD dataframe
#'
#' @return dataframe
#' @importFrom dplyr mutate case_when
#' @export
#' @examples
#' df <- data.frame(year = 2019, ucod = c("X72", "X68"))
#' df |>
#'     flag_suicide_types(year = 2019) |>
#'     label_suicide_type()
label_suicide_type <- function(processed_df) {

    new_df <- processed_df |>
        dplyr::mutate(suicide_type = dplyr::case_when(
            suicide_firearm     == 1 ~ "suicide_firearm",
            suicide_poison      == 1 ~ "suicide_poison",
            suicide_fall        == 1 ~ "suicide_fall",
            suicide_suffocation == 1 ~ "suicide_suffocation",
            suicide_other       == 1 ~ "suicide_other",
            TRUE ~ "not_suicide"))

    return(new_df)
}
