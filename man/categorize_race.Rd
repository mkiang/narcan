% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/categorize_race.R
\name{categorize_race}
\alias{categorize_race}
\title{Create a categorical race column from standardized race column}
\usage{
categorize_race(race_column)
}
\arguments{
\item{race_column}{race column created from remap_race()}
}
\value{
factor
}
\description{
From 1979 to 2015, the race variable in MCOD files underwent several
changes. This function creates a categorical race variable based on
the standardized race column created by remap_race().
}
\examples{
categorize_race(c(0, 1, 1, 1, 0:7, 99))
}
