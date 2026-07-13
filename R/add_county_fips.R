#' Make a new county_fips column that is consistent across years
#'
#' Adds a `county_fips` column (2-digit state FIPS + 3-digit county) that is
#' comparable across data years, translating whichever state-coding scheme the
#' input uses into FIPS.
#'
#' NCHS mortality files do not code state the same way in every era, so the
#' scheme must be identified before it can be translated:
#'
#' \tabular{lll}{
#'   \strong{Data years} \tab \strong{State field} \tab \strong{`scheme`} \cr
#'   1979-2002 \tab NCHS numeric codes (e.g. Colorado = `"06"`) \tab `"nchs"` \cr
#'   2003-present \tab 2-letter postal abbreviations (e.g. `"CO"`, `"ZZ"`) \tab `"abbrev"` \cr
#'   (user-preconverted) \tab already FIPS numeric (Colorado = `"08"`) \tab `"fips"` \cr
#' }
#'
#' The NCHS numeric codes overlap the FIPS numeric codes but mean *different*
#' states (NCHS Colorado `"06"` is FIPS California), so a bare 2-digit numeric
#' code is ambiguous on its own. This is resolved by the data year: pass `year`
#' (a scalar, or leave `NULL` to read a `year` column from `df`) and the scheme
#' is chosen deterministically. Only if no year is available does the function
#' fall back to guessing from the observed codes, and it then **warns loudly**
#' whenever the codes are ambiguous. `"fips"` is never auto-detected from numeric
#' codes with a year >= 2003 (raw files use abbreviations by then); pass
#' `scheme = "fips"` explicitly for data you have already converted.
#'
#' narcan is US-only: the crosswalk covers the 50 states and DC, not territories.
#' Any code that is not one of those -- a territory/associated-state code, a
#' foreign/unknown residence (`"ZZ"`), or an otherwise unrecognized code --
#' resolves to `NA` state FIPS (with a warning for genuinely unexpected codes),
#' and its `county_fips` is `NA` rather than a spurious string.
#'
#' Safest usage for a subset analysis: call `add_county_fips()` on the full
#' national frame *first*, then filter to the states you want. Filtering to a
#' single ambiguous numeric code before translation removes the context needed to
#' identify the scheme.
#'
#' @param df cleaned MCOD dataframe with a `countyoc` or `countyrs` column
#' @param county_vector unquoted column to use (`countyoc` or `countyrs`)
#' @param year data year(s) for the records, used to pick the coding scheme. A
#'   scalar (or vector) of 4-digit years, or `NULL` (default) to read a `year`
#'   column from `df` if present.
#' @param scheme state-coding scheme: `"auto"` (default; resolve from `year`,
#'   then from the codes) or force `"nchs"`, `"abbrev"`, or `"fips"`.
#'
#' @return same dataframe with new `st_fips` and `county_fips` columns
#' @importFrom dplyr mutate left_join if_else pull bind_rows
#' @export
#' @examples
#' ## Modern (2003+) abbreviation-coded data
#' df <- data.frame(countyrs = c("CA001", "NY001", "ZZ999"), year = 2019)
#' add_county_fips(df, countyrs)
#'
#' ## Pre-2003 NCHS-numeric data -- pass the year so "06" resolves to Colorado
#' old <- data.frame(countyrs = c("06031", "06005"))
#' add_county_fips(old, countyrs, year = 2000)
add_county_fips <- function(df, county_vector, year = NULL,
                            scheme = c("auto", "nchs", "abbrev", "fips")) {
    scheme <- match.arg(scheme)

    ## A numeric county column has already lost its leading zeros before we see
    ## it (Alabama county 01001 -> 1001, whose first two digits "10" parse as a
    ## different, valid state) -- refuse it rather than silently mis-assign.
    cv <- dplyr::pull(df, {{ county_vector }})
    if (is.numeric(cv)) {
        stop("add_county_fips(): `county_vector` is numeric, so leading zeros ",
             "are already lost (e.g. Alabama county 01001 reads as 1001, parsed ",
             "as state 10). Supply it as character -- re-read the source with ",
             "the county field as character.", call. = FALSE)
    }

    ## Trim whitespace so a padded fixed-width extract (" CA001") is not
    ## silently dropped to NA.
    df <- df |>
        dplyr::mutate(
            state_substr  = substr(trimws(as.character({{county_vector}})), 1, 2),
            county_substr = substr(trimws(as.character({{county_vector}})), 3, 5)
        )

    codes <- unique(df$state_substr)
    codes <- sort(codes[!is.na(codes) & codes != ""])
    if (length(codes) == 0) {
        stop("All state codes in the county column are missing or blank; ",
             "cannot add county FIPS. Check the input column.", call. = FALSE)
    }

    ## Resolve per-row years (the `year` argument overrides a `year` column; a
    ## scalar is recycled). Used only to pick the coding scheme.
    yr <- if (!is.null(year)) year else if ("year" %in% names(df)) df$year else NA
    yr <- suppressWarnings(as.numeric(as.character(yr)))
    if (length(yr) == 1L) {
        yr <- rep(yr, nrow(df))
    }

    if (scheme == "auto" && length(yr) == nrow(df) &&
        any(yr <= 2002, na.rm = TRUE) && any(yr >= 2003, na.rm = TRUE)) {
        ## The frame straddles the 2002/2003 NCHS->FIPS boundary with a per-row
        ## year. Resolve AND apply the scheme separately per era, so one global
        ## scheme cannot silently mis-decode the minority era (e.g. a 2003 FIPS
        ## "48" decoded as NCHS Washington). Rows are recombined in input order.
        era <- ifelse(is.na(yr), "na", ifelse(yr <= 2002, "pre", "post"))
        parts <- lapply(split(seq_len(nrow(df)), era), function(idx) {
            sub <- df[idx, , drop = FALSE]
            sub_codes <- unique(sub$state_substr)
            sub_codes <- sort(sub_codes[!is.na(sub_codes) & sub_codes != ""])
            sch <- if (length(sub_codes) == 0) {
                "nchs"
            } else {
                .detect_fips_scheme(sub_codes, unique(yr[idx]), NULL)
            }
            sub <- .apply_fips_scheme(sub, sch)
            sub[[".orig_row"]] <- idx
            sub
        })
        df <- dplyr::bind_rows(parts)
        df <- df[order(df[[".orig_row"]]), , drop = FALSE]
        df[[".orig_row"]] <- NULL
    } else {
        if (scheme == "auto") {
            scheme <- .detect_fips_scheme(codes, year, df)
        }
        df <- .apply_fips_scheme(df, scheme)
    }

    df |>
        dplyr::mutate(
            county_fips = dplyr::if_else(
                is.na(st_fips) | is.na(county_substr) | county_substr == "",
                NA_character_,
                paste0(st_fips, county_substr)
            )
        )
}

## Internal: NCHS numeric codes that are NOT valid FIPS codes, used to
## disambiguate the overlapping numeric schemes (e.g. 03/07/14/43/52/62).
.nchs_only_codes <- function() {
    m <- narcan::st_fips_map
    setdiff(sprintf("%02d", m$nchs[!is.na(m$nchs)]),
            sprintf("%02d", m$fips))
}

## Internal: resolve the state-coding scheme for `add_county_fips()`.
.detect_fips_scheme <- function(codes, year = NULL, df = NULL) {
    has_alpha <- any(grepl("[A-Za-z]", codes))
    has_num   <- any(grepl("^[0-9]+$", codes))

    if (has_alpha && has_num) {
        stop("Mixed alphabetic and numeric state codes detected (",
             paste(codes, collapse = ", "), "). This usually means pre-2003 ",
             "(NCHS numeric) and 2003+ (postal abbreviation) data are stacked ",
             "together. Split by era or pass `scheme=` explicitly.",
             call. = FALSE)
    }
    if (has_alpha) {
        return("abbrev")
    }

    ## Numeric codes: disambiguate NCHS vs FIPS by year first. Resolve the year
    ## from the argument or a `year` column and drop NAs uniformly, so an NA in
    ## the `year` argument behaves identically to an NA in a `year` column.
    ## Coerce to numeric so a character/factor year compares numerically.
    if (is.null(year) && !is.null(df) && "year" %in% names(df)) {
        year <- df$year
    }
    year <- suppressWarnings(as.numeric(as.character(year)))
    year <- unique(year[!is.na(year)])

    spans_boundary <- FALSE
    if (length(year) >= 1) {
        if (all(year <= 2002)) {
            return("nchs")
        }
        if (all(year >= 2003)) {
            warning("Numeric state codes in year(s) >= 2003, where raw NCHS ",
                    "files use postal abbreviations. Assuming these are already ",
                    "FIPS-coded; pass `scheme=` to override.", call. = FALSE)
            return("fips")
        }
        ## year straddles the 2002/2003 boundary -> fall through to membership
        spans_boundary <- TRUE
    }

    ## No usable (or a boundary-straddling) year: guess from the codes.
    if (any(codes %in% .nchs_only_codes())) {
        return("nchs")
    }
    fips_set <- sprintf("%02d", narcan::st_fips_map$fips)
    if (all(codes %in% fips_set)) {
        warning("Numeric state codes (", paste(codes, collapse = ", "), ") are ",
                "valid in BOTH the NCHS (<= 2002) and FIPS schemes and the data ",
                "year is ",
                if (spans_boundary) "ambiguous (spans the 2002/2003 boundary)"
                else "not available",
                ". Assuming FIPS. Pass `year=` or `scheme=` to disambiguate; ",
                "safest: run add_county_fips() on the full national frame before ",
                "filtering states.", call. = FALSE)
        return("fips")
    }
    if (all(codes %in% sprintf("%02d", narcan::st_fips_map$nchs))) {
        return("nchs")
    }
    stop("Unrecognized state coding system. Observed 2-digit state code(s): ",
         paste(codes, collapse = ", "), ". Expected postal abbreviations, NCHS ",
         "state codes, or FIPS state codes.", call. = FALSE)
}

## Internal: build a code -> st_fips lookup for one scheme and left-join it,
## setting unmatched/ambiguous codes to NA and warning on unexpected ones.
.apply_fips_scheme <- function(df, scheme) {
    m <- narcan::st_fips_map
    fips_fmt <- sprintf("%02d", m$fips)

    if (scheme == "abbrev") {
        lu <- data.frame(state_substr = m$abbrev, st_fips = fips_fmt,
                         stringsAsFactors = FALSE)
        lu <- lu[!is.na(lu$state_substr), ]
    } else if (scheme == "fips") {
        lu <- unique(data.frame(state_substr = fips_fmt, st_fips = fips_fmt,
                                stringsAsFactors = FALSE))
    } else {
        ## nchs: states + DC only (territories are dropped from st_fips_map), so
        ## every nchs code is present and unique. The NA-drop and de-duplication
        ## below are defensive -- they keep the join key unique (and unmatched
        ## codes NA rather than aborting) if the map ever regains an ambiguous
        ## code. A territory/foreign nchs code is simply unmatched -> NA.
        keep <- !is.na(m$nchs)
        lu <- data.frame(state_substr = sprintf("%02d", m$nchs[keep]),
                         st_fips = fips_fmt[keep], stringsAsFactors = FALSE)
        dup <- names(which(table(lu$state_substr) > 1))
        lu <- unique(lu[!lu$state_substr %in% dup, ])
    }

    df <- df |>
        dplyr::left_join(lu, by = "state_substr", relationship = "many-to-one")

    present <- unique(df$state_substr[!is.na(df$state_substr) & df$state_substr != ""])
    unmatched <- setdiff(setdiff(present, lu$state_substr), "ZZ")
    if (length(unmatched) > 0) {
        warning("State code(s) with no ", scheme, " match (set to NA): ",
                paste(sort(unmatched), collapse = ", "), ".", call. = FALSE)
    }
    df
}
