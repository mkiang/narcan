#' Import MCOD fixed-width data (restricted or public tier)
#'
#' Reads a raw NCHS Multiple Cause of Death fixed-width file into a data frame
#' using the byte-verified column dictionary for the given year and tier. The
#' restricted and public files share the within-record layout; the public file
#' suppresses (blanks) sub-state geography from 2005 and never carries a few
#' certifier-entered items (tobacco, pregnancy). Those suppressed columns are
#' returned as all-\code{NA} so the public output is column-compatible with the
#' restricted output.
#'
#' @param file path to the raw MCOD plaintext (or unzipped) fixed-width file
#' @param year year of the MCOD data (integer)
#' @param tier \code{"restricted"} (default) or \code{"public"}
#'
#' @return a tibble with one row per death and columns in the restricted layout
#'   order for that year
#' @importFrom readr read_fwf fwf_positions
#' @export
#'
#' @examples
#' \dontrun{
#' df <- import_mcod_fwf("MULT2020.USAllCnty.txt", 2020, tier = "restricted")
#' pub <- import_mcod_fwf("mort2020us.dat", 2020, tier = "public")
#' }
import_mcod_fwf <- function(file, year, tier = c("restricted", "public")) {
    tier <- match.arg(tier)
    .import_mcod_data(file, year, tier = tier)
}

#' Shared engine for importing restricted/public MCOD fixed-width data
#'
#' Selects the byte-verified dictionary for \code{year_x} and \code{tier} (by
#' bare name, resolving to the internal copy in \code{R/sysdata.rda}), builds the
#' \code{readr::fwf_positions()} and the \code{col_types} string from the SAME
#' rows in stored order (so they stay aligned, including the intentional
#' nested/overlapping geography fields), reads the file, appends any suppressed
#' columns as typed all-\code{NA}, and reorders to the canonical restricted
#' column order for column parity across tiers.
#'
#' @param file path to the raw fixed-width file
#' @param year_x year of MCOD data
#' @param tier \code{"restricted"} or \code{"public"}
#' @param dict optional dictionary to use instead of the packaged one (for tests)
#' @param restricted_dict optional restricted dictionary defining the canonical
#'   column order (for tests); defaults to the packaged \code{mcod_fwf_dicts}
#'
#' @return a tibble
#' @importFrom readr read_fwf fwf_positions
.import_mcod_data <- function(file, year_x, tier = c("restricted", "public"),
                              dict = NULL, restricted_dict = NULL) {
    tier <- match.arg(tier)
    if (is.null(dict)) {
        dict <- if (tier == "restricted") mcod_fwf_dicts else mcod_public_fwf_dicts
    }
    if (is.null(restricted_dict)) {
        restricted_dict <- mcod_fwf_dicts
    }
    if (!("suppressed" %in% names(dict))) {
        dict$suppressed <- FALSE
    }

    rows <- dict[dict$year == year_x, , drop = FALSE]
    if (nrow(rows) == 0L) {
        stop(sprintf("narcan has no %s dictionary for year %d", tier, year_x))
    }

    present <- rows[!rows$suppressed & !is.na(rows$start), , drop = FALSE]
    supp <- rows[rows$suppressed | is.na(rows$start), , drop = FALSE]

    ## canonical output order = the restricted dictionary's order for this year
    canon_names <- restricted_dict[restricted_dict$year == year_x, "name", drop = TRUE]

    c_types <- paste(present$type, collapse = "")
    df <- readr::read_fwf(
        file = file,
        col_positions = readr::fwf_positions(
            start = present$start,
            end = present$end,
            col_names = present$name
        ),
        col_types = c_types,
        na = c("", "NA", " ")
    )

    ## append suppressed columns as typed all-NA (readr "n" is a double)
    for (i in seq_len(nrow(supp))) {
        df[[supp$name[i]]] <- if (identical(supp$type[i], "c")) {
            NA_character_
        } else {
            NA_real_
        }
    }

    ## guard against a silent drop/extra, then reorder to canonical order
    stopifnot(setequal(names(df), canon_names))
    df[, canon_names, drop = FALSE]
}

utils::globalVariables(c("mcod_fwf_dicts", "mcod_public_fwf_dicts"))
