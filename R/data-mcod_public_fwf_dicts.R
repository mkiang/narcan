#' Fixed-width column dictionary for PUBLIC-use MCOD files
#'
#' Byte positions for parsing the NCHS/CDC Multiple Cause of Death public-use
#' fixed-width files (`mortYYYYus.zip`), one set of rows per data year
#' (1979-2024). The public file shares the within-record layout of the
#' restricted file but suppresses certain columns; suppressed columns are carried
#' here with `NA` positions and `suppressed = TRUE` so `import_mcod_fwf(...,
#' tier = "public")` returns them as all-`NA`, keeping the public output
#' column-compatible with the restricted output.
#'
#' Verified against the raw CDC public-use bytes (identical layout to the NBER
#' mirror). Effective record length by year: 440 (1979-2002; 1980 is
#' variable-length and read newline-delimited), 488 (2003-2012), 490 (2013-2019),
#' 817 (2020-2024).
#'
#' @docType data
#'
#' @format A data frame with 6 columns
#' \describe{
#'   \item{name}{string, variable name (matches [mcod_fwf_dicts])}
#'   \item{type}{string, single-letter readr column type ("c"/"n")}
#'   \item{start}{integer, 1-indexed starting byte position (`NA` if suppressed)}
#'   \item{end}{integer, ending byte position (`NA` if suppressed)}
#'   \item{year}{integer, data year}
#'   \item{suppressed}{logical; `TRUE` for columns not present on the public file
#'     (sub-state geography, record type, certifier from 2005; tobacco and
#'     pregnancy; race-recode-40 before it reaches the public file in 2013) --
#'     returned as all-`NA` for column parity}
#' }
#'
#' @source \url{https://www.cdc.gov/nchs/nvss/mortality_public_use_data.htm}
#' @seealso [mcod_fwf_dicts] for the restricted-use tier; [import_mcod_fwf()].
#' @keywords datasets
"mcod_public_fwf_dicts"
