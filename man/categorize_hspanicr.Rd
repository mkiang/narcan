% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/categorize_hspanicr.R
\name{categorize_hspanicr}
\alias{categorize_hspanicr}
\title{Create a categorical Hispanic column from the hspanicr column}
\usage{
categorize_hspanicr(hspanicr_column)
}
\arguments{
\item{hspanicr_column}{hspanicr column from MCOD dataframe}
}
\value{
factor
}
\description{
The hspanicr column was not introduced until 1987 and not all years have
all possible Hispanic options. This creates a categorical variable so
functions like tidyr::complete() will expand rows that have no observations.
}
\examples{
categorize_hspanicr(c(1:5, NA, 9, 8, 4))
}
