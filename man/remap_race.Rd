% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/remap_race.R
\name{remap_race}
\alias{remap_race}
\title{Remaps the race column to a single standard across 1979-2015}
\usage{
remap_race(icd_df, year = NULL)
}
\arguments{
\item{icd_df}{an MCOD dataframe}

\item{year}{year of file, if NULL will try to extract year automatically}
}
\value{
dataframe
}
\description{
The race column in MCOD data underwent several changes from 1979-2015.
This function standardizes the race column and can (should) be used with
categorize_race() to result in a single set of consist race codes across
all files.
}
