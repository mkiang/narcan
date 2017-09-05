#' Download Standard Populations
#'
#' Download a variety of common standard populations from the SEER website
#'
#' @return Dataframe with SEER standard populations
#' @export

download_standard_pops <- function() {
    ## Downloads different standard populations from SEER website using the
    ## 18 age group coding. Performs minimal manipulation to make age and
    ## standard factors readable.
    ##
    ## NOTE: Stores all standards so you'll need to filter to a specific
    ## standard and then left_join() on age_cat.


    ## Download the 18 (0-4 year old) grouping
    pop_url <- "https://seer.cancer.gov/stdpopulations/stdpop.18ages.txt"

    ## Make a dictionary for factor values of standard population
    ## This includes codes for the 19 age group coding -- keep them in case
    ## we decide to use that instead.
    standards_dict <- list(
        s6   = "World (Segi 1960) Std Million (19 age groups)",
        s7   = "1991 Canadian Std Million (19 age groups)",
        s5   = "European (Scandinavian 1960) Std Million (19 age groups)",
        s8   = "1996 Canadian Std Million (19 age groups)",
        s10  = "World (WHO 2000-2025) Std Mlibrarillion (19 age groups)",
        s141 = "1940 US Std Million (19 age groups)",
        s151 = "1950 US Std Million (19 age groups)",
        s161 = "1960 US Std Million (19 age groups)",
        s171 = "1970 US Std Million (19 age groups)",
        s181 = "1980 US Std Million (19 age groups)",
        s191 = "1990 US Std Million (19 age groups)",
        s201 = "2000 US Std Million (19 age groups)",
        s203 = "2000 US Std Population (19 age groups - Census P25-1130)",
        s202 = "2000 US Std Population (single ages to 84 - Census P25-1130)",
        s205 = "2000 US Std Population (single ages to 99 - Census P25-1130)",
        s11  = "World (WHO 2000-2025) Std Million (single ages to 84)",
        s12  = "World (WHO 2000-2025) Std Million (single ages to 99)",
        s1   = "World (Segi 1960) Std Million (18 age groups)",
        s2   = "1991 Canadian Std Million (18 age groups)",
        s3   = "European (Scandinavian 1960) Std Million (18 age groups)",
        s4   = "1996 Canadian Std Million (18 age groups)",
        s9   = "World (WHO 2000-2025) Std Million (18 age groups)",
        s140 = "1940 US Std Million (18 age groups)",
        s150 = "1950 US Std Million (18 age groups)",
        s160 = "1960 US Std Million (18 age groups)",
        s170 = "1970 US Std Million (18 age groups)",
        s180 = "1980 US Std Million (18 age groups)",
        s190 = "1990 US Std Million (18 age groups)",
        s200 = "2000 US Std Million (18 age groups)",
        s204 = "2000 US Std Population (18 age groups - Census P25-1130)")

    ## Download
    standard_pop <- readr::read_fwf(pop_url,
                                    readr::fwf_widths(c(3, 3, 8),
                                                      c("standard", "age",
                                                        "pop")),
                                    col_types = "iii")

    ## Create standard codes and better age groups
    standard_pop <- standard_pop %>%
        dplyr::mutate(standard = paste0("s", standard),
                      standard_cat = factor(standard,
                                            levels = names(standards_dict),
                                            labels = unname(unlist(standards_dict)),
                                            ordered = TRUE),
                      age = (age - 1) * 5,
                      age_cat = factor(age,
                                       levels = seq(0, 85, 5),
                                       labels = c(paste0(seq(0, 84, 5), "-",
                                                         seq(4, 84, 5)), "85+"),
                                       ordered = TRUE)) %>%
        dplyr::select(age_cat, standard_cat, pop_std = pop,
                      dplyr::everything())

    return(standard_pop)
}


