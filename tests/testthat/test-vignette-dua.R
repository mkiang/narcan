# DUA / network guard for vignette source. Vignettes knit under R CMD check, so
# a live download_*/HTTP call in an evaluated chunk would hit the network (and,
# for restricted data, could leak bytes). This mirrors the restricted-path grep:
# code chunks must contain no network-triggering call. Prose may reference
# download_pop_data() in backticks -- only fenced R code is checked.

vignette_code_lines <- function(path) {
    ln <- readLines(path, warn = FALSE)
    fence <- grepl("^```", ln)
    in_code <- FALSE
    keep <- logical(length(ln))
    for (i in seq_along(ln)) {
        if (fence[i]) {
            # a fence that opens an r chunk turns code on; any fence turns it off
            in_code <- !in_code && grepl("^```\\{r", ln[i])
            next
        }
        keep[i] <- in_code
    }
    ln[keep]
}

test_that("no vignette evaluates a download or HTTP call", {
    vigs <- list.files(test_path("..", "..", "vignettes"), pattern = "\\.Rmd$",
                       full.names = TRUE)
    if (length(vigs) == 0) {
        vigs <- list.files("vignettes", pattern = "\\.Rmd$", full.names = TRUE)
    }
    skip_if(length(vigs) == 0, "no vignettes to scan")

    bad_patterns <- c("download_pop_data\\(", "download\\.file\\(",
                      "\\bcurl\\b", "https?://", "read_csv\\(\\s*url",
                      "\\burl\\(")
    for (v in vigs) {
        code <- vignette_code_lines(v)
        hits <- code[Reduce(`|`, lapply(bad_patterns, grepl, x = code))]
        expect_identical(
            hits, character(0),
            info = sprintf("network call in evaluated chunk of %s: %s",
                           basename(v), paste(hits, collapse = " | ")))
    }
})
