#' Download 1979-2015 Population Estimates
#'
#' All annual population estimates from 1979 to 2015 by age (18 bins) and
#' race. This is the function used to create the pop_est dataframe.
#'
#' @return Dataframe with US Census Bureau population estimates
#' @source https://www.census.gov/programs-surveys/popest.html
#' @importFrom dplyr mutate group_by summarize arrange

.download_all_pop_data <- function() {
    ## Wrapper to download all population data -- also collapses into five
    ## year age groups since that's all we need.

    ## Download
    pop_1979  <- .download_1979_pop_data()
    pop_1980s <- .download_1980s_pop_data()
    pop_1990s <- .download_1990s_pop_data()
    pop_2000s <- .download_2000s_pop_data()
    pop_2010s <- .download_2010s_pop_data()

    ## Combine
    population_counts <- rbind(pop_1979, pop_1980s, pop_1990s,
                               pop_2000s, pop_2010s)

    ## Add age categories
    population_counts <- population_counts %>%
        mutate(age = (findInterval(age_years, c(seq(0, 85, 5), 150)) - 1) * 5,
               age_cat = factor(age,
                                levels = seq(0, 85, 5),
                                labels = c(paste0(seq(0, 84, 5),
                                                  '-',
                                                  seq(4, 84, 5)),
                                           "85+"),
                                ordered = TRUE))

    ## Now collapse down age into the five year bins
    population_counts <- population_counts %>%
        group_by(year, age, age_cat, sex, race) %>%
        summarize(pop = sum(pop)) %>%
        arrange(year, race, sex, age)

    return(population_counts)
}
