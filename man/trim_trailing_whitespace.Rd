% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/trim_trailing_whitespace.R
\name{trim_trailing_whitespace}
\alias{trim_trailing_whitespace}
\title{Trim trailing whitespace on 3-char ICD-9 codes}
\usage{
trim_trailing_whitespace(icd9_record)
}
\arguments{
\item{icd9_record}{One of the record columns from an ICD-9 dataframe}
}
\value{
vector
}
\description{
Some of the ICD-9 codes only contain 3 characters (i.e., they do not contain
subcodes) but have a space at the end. This function just takes the record
column and strips out the trailing space.
}
\examples{
trim_trailing_whitespace(c("400 ", "402", "4032"))
}
