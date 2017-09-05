#' Wrapper to make a directory (and subdirectories) if necessary
#'
#' Mimics `mkdir -p` by making a directory and all subdirectories and
#' suppressing error messages if folder already exists.
#'
#' @param path Location of folder to be made
#'
#' @return None
#' @export
#'
#' @examples
#' mkdir_p('./test_directory')

mkdir_p <- function(path) {
    ## Mimics mkdir -p
    dir.create(path, showWarnings = FALSE, recursive = TRUE)
}
