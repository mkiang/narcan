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
