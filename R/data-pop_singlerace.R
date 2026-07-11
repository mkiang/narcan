#' Single-race population estimates, national, 2020-2024
#'
#' Annual US resident population by age (5-year bins, 18 groups), sex, single-race
#' group, and Hispanic origin, from the US Census Bureau Population Estimates
#' Program (Vintage 2024, single-race Alldata6). The single-race groups follow the
#' 1997 OMB standard and match the labels produced by \code{categorize_race()} for
#' 2022+ deaths (codes 101-106). Use these denominators only with single-race
#' death counts; they are NOT comparable to the bridged-race \code{pop_est}.
#'
#' Only the finest cells are stored (sex male/female, the six single races,
#' Hispanic origin non_hispanic/hispanic); \code{"total"} / \code{"both"} /
#' \code{"all"} are synthesized on demand, never stored, so aggregation never
#' double-counts a marginal.
#'
#' @docType data
#'
#' @format A data frame with 2160 rows and 9 columns
#' \describe{
#'   \item{year}{year of observation (2020-2024)}
#'   \item{age}{starting age for the 5-year age bin (0, 5, ..., 85 = 85+)}
#'   \item{sex}{\code{"male"} or \code{"female"}}
#'   \item{race}{single-race group: \code{white_only}, \code{black_only},
#'     \code{american_indian_only}, \code{asian_only}, \code{nhopi_only},
#'     \code{multiracial}}
#'   \item{hispanic_origin}{\code{"non_hispanic"} or \code{"hispanic"}}
#'   \item{pop}{population count}
#'   \item{scheme}{race scheme (\code{"single"})}
#'   \item{source}{data source (\code{"census_pep_v2024"})}
#'   \item{vintage}{Census vintage (\code{"V2024"})}
#' }
#' @source \url{https://www.census.gov/programs-surveys/popest.html}
#' @keywords datasets
"pop_singlerace"

#' Single-race population estimates, state, 2020-2024
#'
#' State-level counterpart of \code{pop_singlerace}: annual state population by
#' age (5-year bins), sex, single-race group, and Hispanic origin, from the US
#' Census Bureau Population Estimates Program (Vintage 2024). Same schema as
#' \code{pop_singlerace} plus a \code{state_fips} column. Only finest cells are
#' stored; totals are synthesized on demand.
#'
#' County-level single-race denominators are distributed separately (too large to
#' bundle) and fetched via \code{download_pop_data()} / \code{get_pop_county()}.
#'
#' @docType data
#'
#' @format A data frame with 110160 rows and 10 columns
#' \describe{
#'   \item{state_fips}{2-digit state FIPS code}
#'   \item{year}{year of observation (2020-2024)}
#'   \item{age}{starting age for the 5-year age bin (0, 5, ..., 85 = 85+)}
#'   \item{sex}{\code{"male"} or \code{"female"}}
#'   \item{race}{single-race group (see \code{pop_singlerace})}
#'   \item{hispanic_origin}{\code{"non_hispanic"} or \code{"hispanic"}}
#'   \item{pop}{population count}
#'   \item{scheme}{race scheme (\code{"single"})}
#'   \item{source}{data source (\code{"census_pep_v2024"})}
#'   \item{vintage}{Census vintage (\code{"V2024"})}
#' }
#' @source \url{https://www.census.gov/programs-surveys/popest.html}
#' @keywords datasets
"pop_singlerace_state"
