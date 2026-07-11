#' Make a new county_fips column that is consistent across years
#'
#' @param df cleaned MCOD dataframe with countyoc or countyrs column
#' @param county_vector specify if we should use countyoc or countyrs
#'
#' @return same dataframe with new county_fips column
#' @importFrom dplyr mutate left_join pull transmute
#' @importFrom stringr str_replace_all
#' @export
#' @examples
#' df <- data.frame(countyrs = c("53033", "54001", "55079", "56001"))
#' add_county_fips(df, countyrs)
add_county_fips <- function(df, county_vector) {
    df <- df |>
        dplyr::mutate(state_substr = substr({{county_vector}}, 1, 2),
               county_substr = substr({{county_vector}}, 3, 5))

    substr_codes <- df |>
        dplyr::pull(state_substr) |>
        unique() |>
        sort()

    if (all(c("DC", datasets::state.abb) %in% substr_codes)) {
        ## Abbreviations?
        rep_pattern <- as.character(sprintf("%02d", narcan::st_fips_map$fips))
        names(rep_pattern) <- narcan::st_fips_map$abbrev

        df <- df |>
            dplyr::mutate(st_fips = stringr::str_replace_all(state_substr, pattern = rep_pattern))

    } else if (all(c("03", "07", "14", "43") %in% substr_codes)) {
        ## NCHS state codes
        df <- df |>
            dplyr::left_join(narcan::st_fips_map |>
                                 transmute(
                                     st_fips = sprintf("%02d", fips),
                                     state_substr = sprintf("%02d", nchs)
                                 ),
                             by = "state_substr")

    } else if (all(c("53", "54", "55", "56") %in% substr_codes)) {
        df <- df |>
            dplyr::mutate(st_fips = state_substr)

    } else {
        warning("Unknown state coding system")
    }

    df <- df |>
        dplyr::mutate(county_fips = paste0(st_fips, county_substr))

    return(df)
}
