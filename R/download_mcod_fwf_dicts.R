#' Download Fixed Width Format Dictionaries
#'
#' Download the fixed width format dictionaries from NBER for 1979 to 2018,
#' then add 2020 manually (2020 added occupation) and duplicate 2018 to 2019.
#'
#' @return Dataframe with MCOD fixed width format data
#' @source https://www.nber.org/research/data/mortality-data-vital-statistics-nchs-multiple-cause-death-data
#' @importFrom readr read_fwf fwf_widths
#' @importFrom purrr map_dfr
#' @importFrom dplyr mutate select case_when everything filter
#' @importFrom tibble add_case

.download_mcod_fwf_dicts <- function() {

    ## Download from NBER 1979 to 2018 FWF files
    fwf_dicts <- map_dfr(.x = 1979:2018,
                         .f = ~ .dct_to_fwf_df(.x) %>%
                             mutate(year = .x))

    ## 2018 also has race recode 40 but the NBER file doesn't have it so add it
    fwf_dicts <- fwf_dicts %>%
        add_case(name = "racer40",
                 type = "n",
                 start = 489,
                 end = 490,
                 year = 2018)

    ## Add 2019 which is just a duplicate of 2018
    fwf_dicts <- bind_rows(
        fwf_dicts,
        fwf_dicts %>%
            filter(year == 2018) %>%
            mutate(year = 2019)
    )

    ## Add 2020 which has occupation
    fwf_dicts <- fwf_dicts %>%
        bind_rows(
            fwf_dicts %>%
                filter(year == 2019) %>%
                add_case(name = "occupation",
                         type = "c",
                         start = 806,
                         end = 809) %>%
                add_case(name = "occupationr",
                         type = "c",
                         start = 810,
                         end = 811) %>%
                add_case(name = "industry",
                         type = "c",
                         start = 812,
                         end = 815) %>%
                add_case(name = "industryr",
                         type = "c",
                         start = 816,
                         end = 817) %>%
                mutate(year = 2020)
        )

    return(fwf_dicts)
}
