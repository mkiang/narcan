#' Download Fixed Width Format Dictionaries
#'
#' Download the fixed width format dictionaries from NBER for 1979 to 2004,
#' then add the rest manually (including occupation which started in 2020).
#'
#' @return Dataframe with MCOD fixed width format data
#' @source https://www.nber.org/research/data/mortality-data-vital-statistics-nchs-multiple-cause-death-data
#' @importFrom readr read_fwf fwf_widths
#' @importFrom purrr map_dfr
#' @importFrom dplyr mutate select case_when everything filter
#' @importFrom tibble add_case

.download_mcod_fwf_dicts <- function() {

    ## Download from NBER 1979 to 2004 FWF files
    fwf_dicts <- map_dfr(.x = 1979:2004,
                         .f = ~ .dct_to_fwf_df(.x) %>%
                             mutate(year = .x))

    ## Starting in 2005, they added race recode 40 and the public files
    ## dropped geographic information so we will just repeat.
    fwf_dicts <- bind_rows(
        fwf_dicts,
        fwf_dicts %>%
            filter(year == 2004) %>%
            mutate(year = 2005) %>%
            add_case(
                name = "racer40",
                type = "n",
                start = 489,
                end = 490,
                year = 2005
            ) %>%
            add_case(
                name = "tobacco_use",
                type = "c",
                start = 142,
                end = 142,
                year = 2005
            ) %>%
            add_case(
                name = "pregnancy_status",
                type = "n",
                start = 143,
                end = 143,
                year = 2005
            )
    )
    for (y in 2006:2019) {
        fwf_dicts <- fwf_dicts %>%
          bind_rows(
              fwf_dicts %>%
                  filter(year == 2005) %>%
                  mutate(year = y)
          )
    }

    ## Add 2020 which has occupation
    fwf_dicts <- fwf_dicts %>%
        bind_rows(
            fwf_dicts %>%
                filter(year == 2019) %>%
                add_case(
                    name = "occupation",
                    type = "c",
                    start = 806,
                    end = 809
                ) %>%
                add_case(
                    name = "occupationr",
                    type = "c",
                    start = 810,
                    end = 811
                ) %>%
                add_case(
                    name = "industry",
                    type = "c",
                    start = 812,
                    end = 815
                ) %>%
                add_case(
                    name = "industryr",
                    type = "c",
                    start = 816,
                    end = 817
                ) %>%
                mutate(year = 2020) %>%
                add_case(
                    name = "certifier",
                    type = "c",
                    start = 110,
                    end = 110
                ) %>%
                mutate(year = 2020)
        )

    ## Repeat 2020 for 2021
    for (y in 2021) {
        fwf_dicts <- fwf_dicts %>%
            bind_rows(
                fwf_dicts %>%
                    filter(year == 2020) %>%
                    mutate(year = y)
            )
    }

    return(fwf_dicts)
}
