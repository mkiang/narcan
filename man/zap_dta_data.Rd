% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/zap_dta_data.r
\name{zap_dta_data}
\alias{zap_dta_data}
\title{Clear Stata metadta from MCOD dta files}
\usage{
zap_dta_data(dta_df)
}
\arguments{
\item{dta_df}{dataframe from imported dta (e.g., from haven::read_dta())}
}
\value{
dataframe
}
\description{
The NBER MCOD dta files come with a variety of metadata not necessary for
use in R. This function clears all metadata as well as replacing NAN and
blanks ("") with NA.
}
