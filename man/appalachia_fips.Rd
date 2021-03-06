% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/data-appalachia_fips.R
\docType{data}
\name{appalachia_fips}
\alias{appalachia_fips}
\title{Dataframe of Appalachian counties with name and FIPS codes}
\format{
A data frame with 420 rows and 7 columns
\describe{
  \item{st_abbrev}{chr, state abbreviation}
  \item{state}{chr, full state name}
  \item{county}{chr, short name for the county}
  \item{county_name}{chr, full county name with state}
  \item{state_fips}{chr, two character state FIPS code}
  \item{county_fips}{chr, three character county FIPS code}
  \item{fipschar}{chr, five character full FIPS code}
}
}
\source{
\url{https://github.com/davemistich/election-appalachia/}
}
\usage{
appalachia_fips
}
\description{
A dataset that contains all 420 counties belonging to the Appalachia region.
}
\keyword{datasets}
