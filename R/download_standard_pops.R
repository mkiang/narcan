#' Download Standard Populations
#'
#' Download a variety of common standard populations from the SEER website.
#' Performs minimal manipulation to make age and standard factors human
#' readable and consistent across standards. Note that one must dplyr::filter()
#' to a single standard before performing dplyr::left_join() on age_cat.
#'
#' @return Dataframe with SEER standard populations
#' @source https://seer.cancer.gov/stdpopulations/
#' @importFrom readr read_fwf fwf_widths
#' @importFrom dplyr mutate select case_when everything
#' @export
download_standard_pops <- function() {
    ## Define URLS
    base_url <- "https://seer.cancer.gov/stdpopulations/"
    pop_18   <- "stdpop.18ages.txt"
    pop_19   <- "stdpop.19ages.txt"
    pop_85   <- "stdpop.singleagesthru84.txt"
    pop_100  <- "stdpop.singleagesthru99.txt"

    ## Make a dictionary for factor values of standard population
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
    col_widths <- fwf_widths(c(3, 3, 8),
                             c("standard", "age","pop"))

    df_18  <- read_fwf(sprintf("%s%s", base_url, pop_18),
                       col_widths, col_types = "iii")
    df_19  <- read_fwf(sprintf("%s%s", base_url, pop_19),
                       col_widths, col_types = "iii")
    df_85  <- read_fwf(sprintf("%s%s", base_url, pop_85),
                       col_widths, col_types = "iii")
    df_100 <- read_fwf(sprintf("%s%s", base_url, pop_100),
                       col_widths, col_types = "iii")

    ## Make age groups consistent across standards
    df_18 <- df_18 %>%
        mutate(age = (age - 1) * 5,
               age_cat = factor(age,
                                levels = seq(0, 85, 5),
                                labels = c(paste0(seq(0, 84, 5), "-",
                                                  seq(4, 84, 5)), "85+"),
                                ordered = TRUE))

    df_19 <- df_19 %>%
        mutate(age = case_when(age >= 2 ~ as.integer((age - 1) * 5),
                               TRUE ~ age),
               age_cat = factor(age,
                                levels = c(0, 1, seq(5, 85, 5)),
                                labels = c("0", "1-4",
                                           paste0(seq(5, 84, 5), "-",
                                                  seq(9, 84, 5)), "85+"),
                                ordered = TRUE))

    df_85 <- df_85 %>%
        mutate(age_cat = factor(age,
                                levels = 0:85,
                                labels = c(0:84, "85+"),
                                ordered = TRUE))

    df_100 <- df_100 %>%
        mutate(age_cat = factor(age,
                                levels = 0:100,
                                labels = c(0:99, "100+"),
                                ordered = TRUE))

    ## Create better standards variable
    standard_pops <- rbind(df_18, df_19, df_85, df_100)
    standard_pops <- standard_pops %>%
        mutate(standard = paste0("s", standard),
               standard_cat = factor(standard,
                                     levels = names(standards_dict),
                                     labels = unname(unlist(standards_dict))))

    ## Reorder columns
    standard_pops <- standard_pops %>%
        select(age_cat, standard_cat, pop_std = pop, everything())

    return(standard_pops)
}
