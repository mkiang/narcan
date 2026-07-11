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

    ## Detect the coding scheme by SUBSET membership so a realistic subset (a
    ## single state, a filtered batch) is classified correctly -- not by
    ## requiring the entire national code space to be present in the data.
    abbrev_set <- narcan::st_fips_map$abbrev
    nchs_set <- sprintf("%02d", narcan::st_fips_map$nchs)
    fips_set <- sprintf("%02d", narcan::st_fips_map$fips)
    ## NCHS-only numeric codes (valid as NCHS, not as FIPS) disambiguate the
    ## otherwise-overlapping numeric schemes.
    nchs_only <- setdiff(nchs_set, fips_set)

    if (all(substr_codes %in% abbrev_set)) {
        ## Postal abbreviations
        rep_pattern <- as.character(sprintf("%02d", narcan::st_fips_map$fips))
        names(rep_pattern) <- narcan::st_fips_map$abbrev

        df <- df |>
            dplyr::mutate(st_fips = stringr::str_replace_all(state_substr, pattern = rep_pattern))

    } else if (all(substr_codes %in% nchs_set) &&
               any(substr_codes %in% nchs_only)) {
        ## NCHS state codes. `relationship = "many-to-one"` makes an ambiguous
        ## NCHS code error loudly instead of silently fanning one record into
        ## two rows: nchs 62 maps to BOTH American Samoa (fips 60) and the
        ## Northern Mariana Islands (fips 69) in st_fips_map.
        df <- df |>
            dplyr::left_join(narcan::st_fips_map |>
                                 transmute(
                                     st_fips = sprintf("%02d", fips),
                                     state_substr = sprintf("%02d", nchs)
                                 ),
                             by = "state_substr",
                             relationship = "many-to-one")

    } else if (all(substr_codes %in% fips_set)) {
        ## FIPS state codes (also the fallback for numeric codes valid in both
        ## the NCHS and FIPS spaces, since FIPS is the modern standard).
        df <- df |>
            dplyr::mutate(st_fips = state_substr)

    } else {
        stop(sprintf(
            paste0("Unrecognized state coding system. Observed 2-digit state ",
                   "code(s): %s. Expected postal abbreviations, NCHS state ",
                   "codes, or FIPS state codes."),
            paste(substr_codes, collapse = ", ")), call. = FALSE)
    }

    df <- df |>
        dplyr::mutate(county_fips = paste0(st_fips, county_substr))

    return(df)
}
