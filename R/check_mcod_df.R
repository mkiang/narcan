#' Warn (never abort) when a user-facing entry point gets a malformed frame
#'
#' Minimal, non-breaking input check shared by the main data-consuming
#' functions. Emits one warning if `df` is not a data frame, and one warning
#' naming any `need` columns that are absent, so the caller gets a named signal
#' instead of a downstream "object not found" (from a data-masked `grepl()`) or
#' join error. It never aborts -- processing continues and any genuine error
#' still surfaces where it would have before.
#'
#' @param df the object passed as the function's data argument
#' @param need character vector of column names the caller requires and does
#'   not create itself
#' @param fn name of the calling function (for the message)
#'
#' @return invisibly NULL
#' @keywords internal
.check_mcod_df <- function(df, need = character(), fn = "") {
    if (!is.data.frame(df)) {
        warning(sprintf("%s(): expected a data frame but got %s.",
                        fn, class(df)[1L]), call. = FALSE)
        return(invisible(NULL))
    }

    absent <- setdiff(need, names(df))
    if (length(absent) > 0L) {
        warning(sprintf(
            "%s(): missing expected column%s %s; downstream steps may error.",
            fn,
            if (length(absent) > 1L) "s" else "",
            paste0("`", absent, "`", collapse = ", ")
        ), call. = FALSE)
    }

    invisible(NULL)
}

#' Build the opioid-death gate for the opioid-type flags
#'
#' Shared by `flag_opioid_types()` and its subtype flags. When
#' `opioid_deaths_only` is `TRUE` (the default), returns the defused expression
#' `opioid_death == 1` for injection (with `!!`) into a `case_when()`, so the
#' gate is evaluated in the data mask and is therefore grouped/`rowwise()`-safe;
#' it errors clearly first if the `opioid_death` column is absent (it is required
#' in that mode). When `FALSE`, returns a scalar `TRUE`, so the type fires
#' wherever its code appears and `opioid_death` is not referenced at all.
#'
#' @param df the processed data frame
#' @param opioid_deaths_only logical scalar
#' @param fn name of the calling function (for the error message)
#' @return an injectable expression (`opioid_death == 1`) or scalar `TRUE`
#' @keywords internal
.opioid_gate <- function(df, opioid_deaths_only, fn = "") {
    if (!isTRUE(opioid_deaths_only)) {
        return(TRUE)
    }
    if (is.null(df[["opioid_death"]])) {
        stop(sprintf(
            paste0("%s(): `opioid_death` is required when `opioid_deaths_only ",
                   "= TRUE`. Run flag_opioid_deaths() first, or set ",
                   "`opioid_deaths_only = FALSE`."), fn), call. = FALSE)
    }
    rlang::expr(opioid_death == 1)
}
