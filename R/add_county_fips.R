#' Make a new county_fips column that is consistent across years
#'
#' Adds a `county_fips` column (2-digit state FIPS + 3-digit county FIPS) that is
#' comparable across data years.
#'
#' @section Why this is not just a state translation:
#' NCHS mortality files change *both* halves of the county code across eras, and
#' the two halves need different treatment:
#'
#' \tabular{lll}{
#'   \strong{Data years} \tab \strong{State half} \tab \strong{County half} \cr
#'   1979-1981 \tab NCHS numeric (Colorado = `"06"`) \tab alphabetical rank, no FIPS available \cr
#'   1982-2002 \tab NCHS numeric \tab alphabetical rank -- but a true FIPS county
#'     is carried separately \cr
#'   2003-present \tab postal abbreviation (`"CO"`, `"ZZ"`) \tab already FIPS \cr
#' }
#'
#' Before 2003 the 3-digit county half of `countyrs`/`countyoc` is the county's
#' **alphabetical rank within its state**, not its FIPS code. NCHS `05019` is Los
#' Angeles; FIPS `06019` is Fresno. Translating only the state prefix and keeping
#' the rank therefore lands on a valid-looking but wrong county, silently, for
#' about 97% of pre-2003 records -- FIPS county codes step by two (001, 003,
#' 005 ...) while a rank steps by one, so the two coincide only at rank 001, the
#' first county alphabetically in each state.
#'
#' Fortunately the raw records already carry the answer. From data year 1982 the
#' MCOD record holds a genuine FIPS geography block alongside the NCHS one --
#' `fipsctyr` (residence) and `fipsctyo` (occurrence), each a complete 5-digit
#' state + county FIPS -- and [import_mcod_fwf()] reads it. When you pass
#' `countyrs` or `countyoc` for a pre-2003 year and the matching column is
#' present, `add_county_fips()` sources the geography from it and reports doing so
#' once per session. `use_fips_cols = "no"` turns the sourcing off, not the
#' reporting -- the function then says instead that the county half is a rank, so
#' the only way to a quiet call is `suppressMessages()`.
#'
#' The sourcing needs a data year, so pass `year` (or keep a `year` column). A row
#' with no year of its own inherits one only when every year-bearing row in the
#' frame agrees on an era *and* that era is the sourced 1982-2002 span -- the same
#' inheritance used to pick the state scheme, so the two halves of the code cannot
#' disagree about which era a row is in. A frame with no year at all, one that
#' straddles 2002/2003, or one whose years sit outside 1982-2002 lends nothing: its
#' year-less rows are reported rather than guessed, because a numeric state half
#' could equally be a pre-2003 NCHS code or a modern frame already converted to
#' FIPS, and swapping on the wrong guess would overwrite a correct county.
#'
#' Coverage is 1982-2002, the full span in which the FIPS block exists. It is
#' populated from the start: the public files carry ~3,135 distinct `fipsctyr`
#' codes with no blanks in 1982-1988, at full county granularity, since public
#' county masking does not begin until 1989. 1979-1981 carry no FIPS county at
#' all: those years return the NCHS rank and say so, since the county cannot be
#' recovered from the file and only `st_fips` is usable.
#'
#' @section Resolving the state scheme:
#' The NCHS numeric codes overlap the FIPS numeric codes but mean *different*
#' states (NCHS Colorado `"06"` is FIPS California), so a bare 2-digit numeric
#' code is ambiguous on its own. This is resolved by the data year: pass `year`
#' (a scalar, or leave `NULL` to read a `year` column from `df`) and the scheme is
#' chosen deterministically, per row, so a frame spanning the 2002/2003 boundary
#' decodes each era correctly. Only if no year is available does the function fall
#' back to guessing from the observed codes, and it then **warns loudly** whenever
#' the codes are ambiguous.
#'
#' Passing one of the FIPS columns (`fipsctyr`, `fipsctyo`) directly is also
#' handled: it is recognized as already-FIPS regardless of the data year.
#'
#' narcan is US-only: the crosswalk covers the 50 states and DC, not territories.
#' Any code that is not one of those -- a territory/associated-state code, a
#' foreign/unknown residence (`"ZZ"` or FIPS state `"00"`), a county masked on the
#' public file (`"999"`), or an otherwise unrecognized code -- resolves to `NA`
#' rather than a spurious string.
#'
#' Safest usage for a subset analysis: call `add_county_fips()` on the full
#' national frame *first*, then filter to the states you want. Filtering to a
#' single ambiguous numeric code before translation removes the context needed to
#' identify the scheme.
#'
#' @param df cleaned MCOD dataframe with a `countyoc` or `countyrs` column
#' @param county_vector unquoted column to use (`countyoc` or `countyrs`)
#' @param year data year(s) for the records, used to pick the coding scheme and
#'   to decide which rows are eligible for FIPS-column sourcing. Either a single
#'   4-digit year applied to every row, or one year per row
#'   (`length(year) == nrow(df)`) matched positionally; any other length is an
#'   error. `NULL` (default) reads a `year` column from `df` if present.
#' @param scheme state-coding scheme for the *state* half: `"auto"` (default;
#'   resolve from `year`, then from the codes) or force `"nchs"`, `"abbrev"`, or
#'   `"fips"`. Independent of `use_fips_cols`, which governs the *county* half --
#'   forcing a scheme does not disable the FIPS-column sourcing.
#' @param use_fips_cols whether to source pre-2003 geography from the record's
#'   own FIPS columns: `"auto"` (default; do it whenever they are present and the
#'   year is in 1982-2002), `"yes"` (same span, but error instead of falling back
#'   when an in-range row cannot be resolved) or `"no"` (never; reproduces the
#'   pre-0.5.4 behavior, which returns the NCHS county rank).
#'
#' @return same dataframe with four new columns: `state_substr` and
#'   `county_substr` (the 2- and 3-digit halves actually decoded, which on
#'   FIPS-sourced rows come from `fipsctyr`/`fipsctyo` rather than from the column
#'   you named), `st_fips` (2-digit state FIPS) and `county_fips` (5-digit state +
#'   county FIPS). The two `*_substr` columns keep the literal code, including
#'   `"00"` and `"999"`, so a public-file mask stays distinguishable from a blank
#'   field; only `st_fips`/`county_fips` resolve those to `NA`. Existing columns
#'   of those names are overwritten. Row order, row count, class and grouping are
#'   preserved.
#' @importFrom dplyr if_else pull
#' @importFrom rlang as_name enquo inform abort
#' @export
#' @examples
#' ## Modern (2003+) abbreviation-coded data
#' df <- data.frame(countyrs = c("CA001", "NY001", "ZZ999"), year = 2019)
#' add_county_fips(df, countyrs)
#'
#' ## Pre-2003 data as it comes out of import_mcod_fwf(): the NCHS county code
#' ## and the record's own FIPS county side by side. 05019 is Los Angeles, and
#' ## the FIPS column is what says so -- the NCHS half alone would give 06019.
#' old <- data.frame(countyrs = "05019", fipsctyr = "06037", year = 1999)
#' add_county_fips(old, countyrs)$county_fips
add_county_fips <- function(df, county_vector, year = NULL,
                            scheme = c("auto", "nchs", "abbrev", "fips"),
                            use_fips_cols = c("auto", "yes", "no")) {
    scheme <- match.arg(scheme)
    use_fips_cols <- match.arg(use_fips_cols)

    ## A numeric county column has already lost its leading zeros before we see
    ## it (Alabama county 01001 -> 1001, whose first two digits "10" parse as a
    ## different, valid state) -- refuse it rather than silently mis-assign.
    cv <- dplyr::pull(df, {{ county_vector }})
    .refuse_numeric_codes(cv, "`county_vector`")

    ## Needed twice below: to pick the legal code width, and to find the sibling
    ## FIPS column.
    col_name <- .resolve_col_name(df, rlang::enquo(county_vector))

    ## Trim whitespace so a padded fixed-width extract (" CA001") is not
    ## silently dropped to NA.
    raw <- trimws(as.character(cv))

    ## The same leading-zero hazard the numeric refusal above catches, one step
    ## later: a CHARACTER column that already lost its zero ("1001") passes that
    ## check, and substr()-ing it reads state "10" (Delaware) for an Alabama
    ## record. Only a 5-character code can be split into a 2-digit state and a
    ## 3-digit county, so anything else is refused rather than decoded.
    ## `fipsstr`/`fipssto` are the 2-digit state-only FIPS fields, so width 2 is
    ## correct for them: the whole code is the state half and the county half is
    ## empty. Every other geography column is 5.
    ok_width <- if (!is.na(col_name) && col_name %in% c("fipsstr", "fipssto")) {
        c(2L, 5L)
    } else {
        5L
    }
    bad_width <- !is.na(raw) & raw != "" & !nchar(raw) %in% ok_width
    if (any(bad_width)) {
        warning("add_county_fips(): ", sum(bad_width), " county code(s) are the ",
                "wrong width and were treated as malformed (e.g. ",
                paste(utils::head(unique(raw[bad_width]), 3L), collapse = ", "),
                "). A 4-digit code has usually lost its leading zero, which ",
                "would read as a different state.", call. = FALSE)
        raw[bad_width] <- NA_character_
    }

    state_substr <- substr(raw, 1, 2)
    county_substr <- substr(raw, 3, 5)

    ## Resolve per-row years (the `year` argument overrides a `year` column; a
    ## scalar is recycled). Used only to pick the coding scheme.
    yr <- if (!is.null(year)) year else if ("year" %in% names(df)) df$year else NA
    yr <- suppressWarnings(as.numeric(as.character(yr)))
    if (length(yr) == 1L) {
        yr <- rep(yr, nrow(df))
    } else if (length(yr) != nrow(df)) {
        ## Neither a scalar nor one year per row. Silently discarding it would
        ## decode the state under the wrong scheme, and recycling it would attach
        ## years to rows that never had them -- both give a wrong county with no
        ## signal, which is the failure this whole path exists to close.
        stop("add_county_fips(): `year` has length ", length(yr), ", which is ",
             "neither 1 nor nrow(df) (", nrow(df), "). Pass a single year, one ",
             "year per row, or NULL to read a `year` column from `df`.",
             call. = FALSE)
    }

    ## A row with no year of its own takes the frame's era when every year-bearing
    ## row agrees on one -- the same inheritance the scheme detector applies, so
    ## the state and county halves cannot disagree about which era a row is in.
    ## A frame with no year at all, or one straddling 2002/2003, inherits nothing
    ## and is reported rather than guessed.
    yr_eff <- yr
    inherited_era <- .inherited_era(yr)
    known_yr <- unique(yr[!is.na(yr)])
    ## Only lend a year-less row a year the year-bearing rows actually occupy. A frame
    ## whose known years are 1979-1981 has no FIPS block at all, so collapsing "all
    ## pre-2003" to the literal 2000 would source such a row from a field that does not
    ## exist for its era -- two byte-identical rows in one call, one told the county is
    ## unrecoverable and the other silently given a county.
    if (!is.null(inherited_era) &&
        (all(known_yr >= 1982 & known_yr <= 2002) || all(known_yr >= 2003))) {
        yr_eff[is.na(yr_eff)] <- inherited_era
    }

    ## ---- source pre-2003 geography from the record's own FIPS column --------
    ## Deliberately NOT gated on `scheme`: `scheme` picks how the state half is
    ## decoded, `use_fips_cols` picks where the county half comes from. Making an
    ## explicit `scheme=` cancel the swap would leave the released defect
    ## reachable through an argument the old docs told people to pass.
    swapped <- rep(FALSE, nrow(df))
    n_malformed_sibling <- 0L
    sw <- .plan_fips_swap(df, col_name, yr_eff, use_fips_cols, state_substr)
    if (!is.null(sw)) {
        swapped <- sw$use
        n_malformed_sibling <- sw$n_malformed
        if (any(swapped)) {
            state_substr[swapped] <- sw$state[swapped]
            county_substr[swapped] <- sw$county[swapped]
        }
    }

    ## "00" is a foreign/unknown state and "999" is a county masked on the public
    ## file (population under 100,000). Neither names a place, so neither may be
    ## pasted into a county_fips -- 18% of public 2004 residence records carry a
    ## 999 suffix, and emitting "48999" invents a phantom county a downstream
    ## group_by() will treat as real.
    ##
    ## Masked here rather than in place: `state_substr`/`county_substr` are
    ## returned to the caller as the halves actually decoded, and erasing "999"
    ## there would conflate "masked on the public file" with "field was blank" --
    ## the same absent-vs-empty conflation that hid a five-year bug elsewhere in
    ## this project. Keeping the literal value also lets the all-blank check below
    ## tell an all-foreign frame apart from an empty column.
    lookup_state <- state_substr
    lookup_state[!is.na(lookup_state) & lookup_state == "00"] <- NA_character_
    lookup_county <- county_substr
    lookup_county[!is.na(lookup_county) & lookup_county == "999"] <- NA_character_

    ## A zero-row frame is a legitimate result of upstream filtering, not a
    ## malformed input: give it the columns and hand it straight back, so a
    ## pipeline does not fall over on an empty stratum.
    if (nrow(df) == 0L) {
        df[["state_substr"]] <- character(0)
        df[["county_substr"]] <- character(0)
        df[["st_fips"]] <- character(0)
        df[["county_fips"]] <- character(0)
        return(df)
    }

    ## Rows rejected for width above were already warned about, so an all-rejected
    ## frame returns NA rather than aborting -- the codes were not "missing", they
    ## were refused, and the caller has been told why.
    codes <- unique(state_substr)
    codes <- sort(codes[!is.na(codes) & codes != ""])
    if (length(codes) == 0 && !any(bad_width)) {
        stop("All state codes in the county column are missing or blank; ",
             "cannot add county FIPS. Check the input column.", call. = FALSE)
    }

    ## ---- resolve the scheme for every row -----------------------------------
    ## Swapped rows are FIPS by construction. So is a caller who handed us one of
    ## the FIPS columns directly -- without this, a pre-2003 `year` would send
    ## fipsctyr "06037" (Los Angeles) down the NCHS path and return "08037".
    row_scheme <- rep(NA_character_, nrow(df))
    row_scheme[swapped] <- "fips"
    if (any(!swapped)) {
        rest <- which(!swapped)
        is_fips_col <- !is.na(col_name) && col_name %in% .fips_col_names()
        row_scheme[rest] <- if (is_fips_col) {
            ## Column identity outranks the argument. These are narcan's own FIPS
            ## fields -- 5-digit state + county FIPS by construction -- so
            ## honouring an explicit scheme= here just re-decodes a FIPS code
            ## under the wrong scheme: `fipsctyr` "06037" (Los Angeles) came back
            ## "08037" (Colorado), silently. Say so rather than obeying it.
            ## "fips" is excluded: it agrees with the column, so nothing is
            ## overridden and warning would scold a caller who was being careful.
            if (!scheme %in% c("auto", "fips")) {
                warning("add_county_fips(): `", col_name, "` already holds FIPS ",
                        "codes, so scheme = \"", scheme, "\" was ignored for it.",
                        call. = FALSE)
            }
            "fips"
        } else if (scheme != "auto") {
            scheme
        } else {
            ## Full-frame years, not just the unswapped ones: an NA-year row
            ## inherits the era from its neighbours, and the swapped rows are
            ## neighbours too. Passing only `yr[rest]` made adding a `fipsctyr`
            ## column silently re-decode an unrelated NA-year row.
            .detect_fips_scheme_by_row(state_substr[rest], yr[rest], all_yr = yr)
        }
    }

    ## ---- translate ----------------------------------------------------------
    ## Resolved per row with a vectorised lookup rather than by splitting and
    ## rebinding the frame: that keeps row order, row count, class, row names and
    ## grouping exactly as they came in, which a split/bind_rows round trip does
    ## not.
    st_fips <- .lookup_state_fips(lookup_state, row_scheme)

    .warn_unmatched(lookup_state, row_scheme, st_fips)

    if (any(swapped) && !scheme %in% c("auto", "fips")) {
        ## Same override the directly-passed-FIPS-column path warns about, so it
        ## should not be the silent one.
        warning("add_county_fips(): geography for ", sum(swapped), " row(s) came ",
                "from `", .sibling_of(col_name), "`, which already holds FIPS ",
                "codes, so scheme = \"", scheme, "\" was ignored for them.",
                call. = FALSE)
    }
    if (any(swapped)) {
        rlang::inform(
            paste0("add_county_fips(): sourced pre-2003 county geography from ",
                   "`", .sibling_of(col_name), "` for ", sum(swapped),
                   " row(s). The `", col_name, "` county digits are an ",
                   "alphabetical rank, not FIPS. This message is shown once per ",
                   "session; wrap the call in suppressMessages() to silence it."),
            .frequency = "once", .frequency_id = "narcan_fips_cols_used"
        )
    }
    county_fips <- dplyr::if_else(
        is.na(st_fips) | is.na(lookup_county) | lookup_county == "",
        NA_character_,
        paste0(st_fips, lookup_county)
    )

    ## After county_fips exists: the guardrail only speaks for rows that actually
    ## produced a code, so it needs to see the result.
    .warn_unswapped_pre2003(swapped, yr_eff, row_scheme, state_substr, county_fips,
                            col_name, use_fips_cols,
                            .sibling_of(col_name) %in% names(df),
                            n_malformed_sibling)

    ## Assign directly rather than through mutate(): on a grouped frame mutate()
    ## evaluates per group and would reject these whole-frame vectors. Plain
    ## assignment is group-agnostic and leaves class, grouping and row names
    ## exactly as they arrived.
    df[["state_substr"]] <- state_substr
    df[["county_substr"]] <- county_substr
    df[["st_fips"]] <- st_fips
    df[["county_fips"]] <- county_fips
    df
}

## Internal: the record's own FIPS geography columns, and the NCHS column each
## one supersedes.
.fips_sibling_map <- function() {
    c(countyrs = "fipsctyr", countyoc = "fipsctyo")
}

.fips_col_names <- function() {
    c("fipsctyr", "fipsctyo", "fipsstr", "fipssto")
}

## Internal: which column of `df` did the caller actually name? `{{ }}` accepts a
## whole tidyselect expression, so the literal text of the quosure is not always
## a column name -- `all_of(v)` and `.data[[v]]` both pull the right column while
## `as_name()` sees only the indirection. Resolving the selection against the
## frame instead keeps the FIPS-column swap reachable through those forms.
.resolve_col_name <- function(df, q) {
    nm <- tryCatch(rlang::as_name(q), error = function(e) NA_character_)
    if (!is.na(nm) && nm %in% names(df)) {
        return(nm)
    }
    ## Warnings suppressed because this is an internal probe: `.data[[v]]` is
    ## deprecated in tidyselect but still accepted by dplyr::pull(), and the
    ## caller should not be scolded for a form the pull itself allows.
    tryCatch({
        idx <- suppressWarnings(tidyselect::eval_select(q, df))
        if (length(idx) == 1L) names(idx) else NA_character_
    }, error = function(e) NA_character_)
}

.sibling_of <- function(col_name) {
    unname(.fips_sibling_map()[col_name])
}

## Internal: shared numeric-input refusal. A numeric code has already lost its
## leading zeros, so substr() would read the wrong state.
.refuse_numeric_codes <- function(x, what) {
    if (is.numeric(x)) {
        stop("add_county_fips(): ", what, " is numeric, so leading zeros ",
             "are already lost (e.g. Alabama county 01001 reads as 1001, parsed ",
             "as state 10). Supply it as character -- re-read the source with ",
             "the county field as character.", call. = FALSE)
    }
    invisible(TRUE)
}

## Internal: decide, per row, whether to take geography from the sibling FIPS
## column. Returns NULL when the swap cannot apply at all.
.plan_fips_swap <- function(df, col_name, yr, use_fips_cols, state_substr) {
    if (use_fips_cols == "no" || is.na(col_name)) {
        return(NULL)
    }
    sibling <- .sibling_of(col_name)
    if (is.na(sibling)) {
        return(NULL)
    }

    ## 1982 is the first data year carrying the FIPS geography block, and it is
    ## populated from the start: the public sweeps for 1982-1988 show blank_frac 0
    ## and ~3,135 distinct fipsctyr codes, full county granularity, because public
    ## county masking does not begin until 1989. The restricted tier has no swept
    ## file before 1989, but that is a gap in this repo's holdings, not evidence
    ## the field is absent -- the two tiers share one NCHS layout.
    ##
    ## A year is required. It is tempting to infer the era from a numeric state
    ## half -- postal abbreviations start in 2003, so numeric ought to mean
    ## pre-2003 -- but a caller who has already converted a modern frame to
    ## numeric FIPS looks identical, and for them the swap overwrites a correct
    ## `countyrs` with whatever sits in the sibling. Guessing produced a silently
    ## wrong county in that case, which is worse than declining to guess: an
    ## unswapped pre-2003 row is caught by .warn_unswapped_pre2003() and the
    ## caller is told to pass year=.
    ## The state half must be numeric. A postal abbreviation only exists from
    ## 2003, so an abbrev-coded row is 2003+ no matter what a `year` column
    ## claims, and its county digits are already FIPS -- swapping one overwrote a
    ## correct county with the sibling's ("NY013" Chautauqua came back as New
    ## York County). The guardrail already applies this rule; so must the swap.
    ## ...and it must be a state NCHS actually assigns. The swap exists to correct the
    ## county half of a valid US record, not to manufacture geography for one whose own
    ## state field says foreign/unknown ("00") or names a territory narcan does not
    ## cover. Accepting any two digits let `countyrs = "00123"` be silently overwritten
    ## by its sibling and come back as a real county, where 0.5.3 returned NA.
    nchs_states <- sprintf("%02d", narcan::st_fips_map$nchs[!is.na(narcan::st_fips_map$nchs)])
    numeric_half <- !is.na(state_substr) & grepl("^[0-9]{2}$", state_substr) &
        state_substr %in% nchs_states
    in_era <- numeric_half & !is.na(yr) & yr >= 1982 & yr <= 2002

    if (!(sibling %in% names(df))) {
        if (use_fips_cols == "yes" && any(in_era)) {
            rlang::abort(paste0(
                "add_county_fips(use_fips_cols = \"yes\") needs the `", sibling,
                "` column for ", sum(in_era), " row(s) in 1982-2002, and the ",
                "frame does not have it. Re-import with import_mcod_fwf(), which ",
                "reads it, or use the default use_fips_cols = \"auto\"."
            ))
        }
        return(NULL)
    }

    ## Nothing in range means the sibling is never read, so do not judge it. A
    ## modern-only frame that happens to carry a numeric-typed (or zero-row)
    ## `fipsctyr` is a legitimate input, not an error.
    if (!any(in_era)) {
        return(NULL)
    }

    sib <- dplyr::pull(df, !!rlang::sym(sibling))
    ## An all-NA sibling cannot have lost a leading zero, so a numeric-typed one
    ## is harmless -- and it is a routine artifact of a non-matching left_join.
    ## Refusing it would hard-error where the old code degraded to the rank.
    if (!all(is.na(sib[in_era]))) {
        .refuse_numeric_codes(sib, paste0("`", sibling, "`"))
    }
    sib <- trimws(as.character(sib))

    ## A 5-character width is part of what makes the sibling trustworthy. A
    ## character column that already lost its leading zero ("1001") passes the
    ## is.numeric() refusal, and substr()-ing it yields state "10" = Delaware for
    ## an Alabama record -- silently, and precisely for source states 01-05, since
    ## wider codes land on a non-state prefix and go NA loudly. Treat any other
    ## width as unusable, which routes "yes" to its abort and "auto" to the
    ## guardrail instead of to a wrong county.
    usable <- in_era & !is.na(sib) & nchar(sib) == 5L
    if (use_fips_cols == "yes" && any(in_era & !usable)) {
        rlang::abort(paste0(
            "add_county_fips(use_fips_cols = \"yes\"): `", sibling, "` is missing ",
            "or not a 5-digit code for ", sum(in_era & !usable),
            " row(s) in 1982-2002."
        ))
    }
    ## Carried out even when nothing is usable, so the guardrail can say "the
    ## column is here but its values are not 5-digit codes" instead of telling a
    ## caller who already has fipsctyr to go and import it.
    n_malformed <- sum(in_era & !usable)
    if (!any(usable)) {
        return(list(use = rep(FALSE, length(usable)), state = NULL,
                    county = NULL, n_malformed = n_malformed))
    }

    list(use = usable, state = substr(sib, 1, 2), county = substr(sib, 3, 5),
         n_malformed = n_malformed)
}

## Internal: NCHS numeric codes that are NOT valid FIPS codes, used to
## disambiguate the overlapping numeric schemes (e.g. 03/07/14/43).
.nchs_only_codes <- function() {
    m <- narcan::st_fips_map
    setdiff(sprintf("%02d", m$nchs[!is.na(m$nchs)]),
            sprintf("%02d", m$fips))
}

## Internal: the era a no-year row inherits from its neighbours, or NULL when the
## rows that DO have a year disagree (or there are none). Shared by scheme
## detection and the FIPS-column swap so the two cannot classify the same row
## differently -- decoding a row as pre-2003 for the state half while refusing to
## source its county half left a wrong county next to its own correct answer.
.inherited_era <- function(yr) {
    known <- unique(yr[!is.na(yr)])
    if (!length(known)) {
        return(NULL)
    }
    if (all(known <= 2002)) {
        return(2000)
    }
    if (all(known >= 2003)) {
        return(2003)
    }
    NULL
}

## Internal: resolve the scheme for each row from its own year, so a frame that
## straddles the 2002/2003 boundary decodes each era under its own scheme. Rows
## with no usable year fall back to a single guess over the codes they share.
.detect_fips_scheme_by_row <- function(state_substr, yr, all_yr = yr) {
    out <- rep(NA_character_, length(state_substr))
    has_year <- !is.na(yr)

    if (any(has_year)) {
        pre <- has_year & yr <= 2002
        post <- has_year & yr >= 2003
        if (any(pre)) {
            out[pre] <- .detect_fips_scheme(.live_codes(state_substr[pre]),
                                            year = 2000, df = NULL)
        }
        if (any(post)) {
            out[post] <- .detect_fips_scheme(.live_codes(state_substr[post]),
                                             year = 2003, df = NULL)
        }
    }
    if (any(!has_year)) {
        ## A row with no year inherits the frame's era when the rows that DO have
        ## a year agree on one. Resolving it in isolation would make one missing
        ## year silently decode under a different scheme from its neighbours, and
        ## would break the guarantee that an NA in `year=` behaves like an NA in a
        ## `year` column. Only a frame with no usable year at all, or one that
        ## straddles the boundary, falls through to guessing from the codes.
        inherited <- .inherited_era(all_yr)
        ## Guessed from the no-year rows' OWN codes. Pooling the whole frame's
        ## codes here looked symmetric with `all_yr` but is not: a 2003+
        ## abbreviation sitting in another row turns the guess into a "mixed
        ## alphabetic and numeric" abort, and an unrelated NCHS-only code
        ## silently re-routes rows it has no bearing on.
        out[!has_year] <- .detect_fips_scheme(.live_codes(state_substr[!has_year]),
                                              year = inherited, df = NULL)
    }
    out
}

.live_codes <- function(x) {
    x <- unique(x)
    ## "00" (foreign/unknown) and "ZZ" name no state in any scheme, so they are
    ## no evidence for one. Leaving "00" in made an all-foreign frame abort with
    ## "Unrecognized state coding system" instead of resolving to NA.
    sort(x[!is.na(x) & x != "" & !x %in% c("00", "ZZ")])
}

## Internal: resolve the state-coding scheme for `add_county_fips()`.
.detect_fips_scheme <- function(codes, year = NULL, df = NULL) {
    if (length(codes) == 0) {
        ## No usable code is no evidence either way, so the year decides. Without
        ## this an all-foreign frame ("ZZ"/"00" only) defaulted to nchs and a
        ## 2019 frame was told its rows were pre-2003.
        yrs <- suppressWarnings(as.numeric(as.character(year)))
        yrs <- unique(yrs[!is.na(yrs)])
        if (length(yrs) && all(yrs >= 2003)) {
            return("abbrev")
        }
        return("nchs")
    }
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
    }

    ## No usable year: guess from the codes.
    if (any(codes %in% .nchs_only_codes())) {
        return("nchs")
    }
    fips_set <- sprintf("%02d", narcan::st_fips_map$fips)
    if (all(codes %in% fips_set)) {
        warning("Numeric state codes (", paste(codes, collapse = ", "), ") are ",
                "valid in BOTH the NCHS (<= 2002) and FIPS schemes and the data ",
                "year is not available. Assuming FIPS. Pass `year=` or `scheme=` ",
                "to disambiguate; safest: run add_county_fips() on the full ",
                "national frame before filtering states.", call. = FALSE)
        return("fips")
    }
    if (all(codes %in% sprintf("%02d", narcan::st_fips_map$nchs))) {
        return("nchs")
    }
    stop("Unrecognized state coding system. Observed 2-digit state code(s): ",
         paste(codes, collapse = ", "), ". Expected postal abbreviations, NCHS ",
         "state codes, or FIPS state codes.", call. = FALSE)
}

## Internal: code -> st_fips lookup table for one scheme.
.scheme_lookup <- function(scheme) {
    m <- narcan::st_fips_map
    fips_fmt <- sprintf("%02d", m$fips)

    if (scheme == "abbrev") {
        lu <- data.frame(state_substr = m$abbrev, st_fips = fips_fmt,
                         stringsAsFactors = FALSE)
        return(lu[!is.na(lu$state_substr), ])
    }
    if (scheme == "fips") {
        return(unique(data.frame(state_substr = fips_fmt, st_fips = fips_fmt,
                                 stringsAsFactors = FALSE)))
    }
    ## nchs: states + DC only (territories are dropped from st_fips_map), so
    ## every nchs code is present and unique. The NA-drop and de-duplication
    ## below are defensive -- they keep the join key unique (and unmatched
    ## codes NA rather than aborting) if the map ever regains an ambiguous
    ## code. A territory/foreign nchs code is simply unmatched -> NA.
    keep <- !is.na(m$nchs)
    lu <- data.frame(state_substr = sprintf("%02d", m$nchs[keep]),
                     st_fips = fips_fmt[keep], stringsAsFactors = FALSE)
    dup <- names(which(table(lu$state_substr) > 1))
    unique(lu[!lu$state_substr %in% dup, ])
}

## Internal: per-row state lookup under a per-row scheme. Vectorised by scheme so
## the frame is never split.
.lookup_state_fips <- function(state_substr, row_scheme) {
    out <- rep(NA_character_, length(state_substr))
    for (s in unique(row_scheme[!is.na(row_scheme)])) {
        lu <- .scheme_lookup(s)
        i <- which(row_scheme == s)
        out[i] <- lu$st_fips[match(state_substr[i], lu$state_substr)]
    }
    out
}

## Internal: warn once per scheme about codes that did not resolve. "ZZ" (foreign
## residence) is expected and excluded.
.warn_unmatched <- function(state_substr, row_scheme, st_fips) {
    bad <- is.na(st_fips) & !is.na(state_substr) & state_substr != "" &
        state_substr != "ZZ" & !is.na(row_scheme)
    if (!any(bad)) {
        return(invisible(NULL))
    }
    for (s in unique(row_scheme[bad])) {
        codes <- sort(unique(state_substr[bad & row_scheme == s]))
        warning("State code(s) with no ", s, " match (set to NA): ",
                paste(codes, collapse = ", "), ".", call. = FALSE)
    }
    invisible(NULL)
}

## Internal: the guardrail. If pre-2003 rows went down the NCHS path without the
## FIPS-column swap, their county half is an alphabetical rank, not FIPS. Say so
## once -- a per-call warning would fire on every legitimate public-tier or
## 1979-1981 call and put devtools::check() in a permanent warning state.
.warn_unswapped_pre2003 <- function(swapped, yr, row_scheme, state_substr,
                                    county_fips, col_name, use_fips_cols,
                                    has_sibling, n_malformed_sibling = 0L) {
    ## A caller who handed us fipsctyr/fipsctyo directly already has FIPS in both
    ## halves. Nothing to flag.
    if (!is.na(col_name) && col_name %in% .fips_col_names()) {
        return(invisible(NULL))
    }
    ## Two ways to know a row's county half is a rank. The year window is the
    ## direct one. The resolved scheme is the other: NCHS numeric state coding
    ## ended in 2002, so an nchs-resolved row is pre-2003 whether or not a year
    ## was supplied -- and the no-year case is exactly where the swap cannot fire,
    ## so it is the one that most needs saying. Neither is gated on `scheme`:
    ## forcing it changes how the state half is read and leaves the county half a
    ## rank either way.
    ## No lower bound: 1979-1981 are pre-2003 too, and they are the years with no
    ## remedy at all, so they are the last ones that should slip through. Bounding
    ## at 1982 let a forced `scheme=` on 1980 data bypass the guardrail entirely,
    ## since a forced scheme also defeats the nchs_row test below.
    ## Third test, for the case the other two both miss: no year at all, and a
    ## numeric state half. That row MIGHT be a pre-2003 rank -- we cannot tell,
    ## which is exactly why the swap declines to fire on it. A forced `scheme=`
    ## defeats nchs_row and an absent year defeats in_window, so without this a
    ## forced scheme on a yearless frame returned a wrong county in total silence.
    in_window <- !is.na(yr) & yr <= 2002
    nchs_row <- !is.na(row_scheme) & row_scheme == "nchs"
    noyear_numeric <- is.na(yr) & !is.na(state_substr) &
        grepl("^[0-9]{2}$", state_substr)
    ## Only rows that actually produced a county code can be carrying a wrong
    ## one. A masked "999", a foreign "00", a territory or a blank already came
    ## back NA, and counting those was not just a miscount: the notice fires once
    ## per session, so a harmless call spent the budget and the next genuinely
    ## wrong call went out in silence.
    ##
    ## The state half must also be numeric. An alphabetic code is a postal
    ## abbreviation whose county digits are already FIPS, so it is right even if
    ## the row carries a contradictory pre-2003 year.
    has_code <- !is.na(county_fips) & !is.na(state_substr) &
        grepl("^[0-9]{2}$", state_substr) & state_substr != "00"
    affected <- !swapped & has_code & (in_window | nchs_row | noyear_numeric)
    if (!any(affected)) {
        return(invisible(NULL))
    }

    ## Name the remedy that would actually work for THESE rows. Generic advice is
    ## worse than none: it sends the caller away believing a pipeline is fixed.
    n_all <- sum(affected)
    n_noyear <- sum(affected & is.na(yr))
    n_pre1982 <- sum(affected & !is.na(yr) & yr < 1982)
    ## "drop use_fips_cols" only helps if there is a sibling to fall back on and
    ## the rows are in the span the sourcing covers.
    droppable <- has_sibling && any(affected & !is.na(yr) & yr >= 1982)

    remedy <- if (n_pre1982 == n_all) {
        ## The one span with no remedy at all. Say that plainly rather than
        ## staying silent: the county is still wrong, and a caller who is never
        ## told will not know to stop at state level.
        paste0("No FIPS county was recorded before 1982, so the true county ",
               "cannot be recovered from these files -- use `st_fips` and treat ",
               "county-level results for these years as unavailable.")
    } else if (n_noyear == n_all) {
        paste0("The data year is unknown, so the FIPS-column sourcing cannot ",
               "fire at all: pass year= (or add a `year` column) to enable it.")
    } else if (use_fips_cols == "no" && droppable) {
        paste0("use_fips_cols = \"no\" is what disabled the FIPS-column ",
               "sourcing; drop it to get the right county.",
               ## ...for the rows it can help. Pre-1982 rows are beyond any
               ## remedy, so promising them a fix would be the same misdirection
               ## this branch was added to remove.
               if (n_pre1982 > 0) {
                   paste0(" ", n_pre1982, " of these row(s) are before 1982, ",
                          "where no FIPS county was recorded and dropping it ",
                          "will not help.")
               } else {
                   ""
               })
    } else if (n_malformed_sibling >= n_all) {
        ## The column is already there. Telling this caller to import it would
        ## be the same misdirection the branches above exist to remove.
        paste0("`", .sibling_of(col_name), "` is present but ", n_malformed_sibling,
               " of its value(s) are not 5-digit codes, so they could not be ",
               "used -- a 4-digit code has usually lost its leading zero. ",
               "Re-read that column as character.")
    } else {
        paste0("Import with import_mcod_fwf() so `fipsctyr`/`fipsctyo` are ",
               "available, and leave use_fips_cols = \"auto\".",
               if (n_pre1982 > 0) {
                   paste0(" ", n_pre1982, " of these row(s) are before 1982, ",
                          "where no FIPS county was recorded and none can be ",
                          "recovered.")
               } else {
                   ""
               },
               if (n_noyear > 0) {
                   paste0(" ", n_noyear, " have no data year, which the sourcing ",
                          "needs: pass year=.")
               } else {
                   ""
               })
    }

    ## Only assert the rank when we know it. A yearless numeric row could equally
    ## be a modern frame already converted to FIPS, and telling that caller their
    ## county is wrong would be its own false alarm.
    lead <- if (n_noyear == n_all) {
        paste0("add_county_fips(): ", n_all, " row(s) have a numeric state code ",
               "and no data year, so it cannot be determined whether their ",
               "county half is a FIPS county or a pre-2003 NCHS alphabetical ",
               "rank. If the data is pre-2003 the returned county_fips points at ",
               "the wrong county for about half of them. ")
    } else {
        paste0("add_county_fips(): ", n_all, " pre-2003 row(s) were decoded from ",
               "the NCHS county code, whose last 3 digits are an alphabetical ",
               "rank within the state, NOT a FIPS county. The returned ",
               "county_fips will point at the wrong county for about half of ",
               "them. ")
    }
    rlang::inform(paste0(lead, remedy),
                  .frequency = "once",
                  .frequency_id = "narcan_fips_cols_missing")
    invisible(NULL)
}
