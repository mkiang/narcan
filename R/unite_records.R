#' Unite the 20 record columns from MCOD dataframe into a single column
#'
#' This function collapses the 20 contributory cause columns into a single
#' column for easier regex'ing. ICD-9 dataframes will also get appropriate
#' prefixes before collapsing.
#'
#' @param icd_df an ICD dataframe
#' @param year the year of this dataframe -- if NULL, will attempt to detect
#'
#' @return dataframe
#' @importFrom dplyr mutate select starts_with
#' @importFrom tidyr unite
#' @export
unite_records <- function(icd_df, year = NULL) {
    ## Unite all 20 records columns into a single new column for easier
    ## regexing.

    ## Extract year ----
    if (is.null(year)) {
        year <- .extract_year(icd_df)
    }

    ## For ICD-9 dataframes
    if (year >= 1979 & year <= 1998) {
        ## Make sure record columns are appropriate prefixed
        df <- icd_df %>%
            mutate(f_record_1  = prefix_to_record(record_1,  rnifla_1),
                   f_record_2  = prefix_to_record(record_2,  rnifla_2),
                   f_record_3  = prefix_to_record(record_3,  rnifla_3),
                   f_record_4  = prefix_to_record(record_4,  rnifla_4),
                   f_record_5  = prefix_to_record(record_5,  rnifla_5),
                   f_record_6  = prefix_to_record(record_6,  rnifla_6),
                   f_record_7  = prefix_to_record(record_7,  rnifla_7),
                   f_record_8  = prefix_to_record(record_8,  rnifla_8),
                   f_record_9  = prefix_to_record(record_9,  rnifla_9),
                   f_record_10 = prefix_to_record(record_10, rnifla_10),
                   f_record_11 = prefix_to_record(record_11, rnifla_11),
                   f_record_12 = prefix_to_record(record_12, rnifla_12),
                   f_record_13 = prefix_to_record(record_13, rnifla_13),
                   f_record_14 = prefix_to_record(record_14, rnifla_14),
                   f_record_15 = prefix_to_record(record_15, rnifla_15),
                   f_record_16 = prefix_to_record(record_16, rnifla_16),
                   f_record_17 = prefix_to_record(record_17, rnifla_17),
                   f_record_18 = prefix_to_record(record_18, rnifla_18),
                   f_record_19 = prefix_to_record(record_19, rnifla_19),
                   f_record_20 = prefix_to_record(record_20, rnifla_20)) %>%
            select(-starts_with("record_"), -starts_with("rnifla_"))

        ## Unite f_record_ columns
        df <- df %>%
            unite(f_records_all, starts_with("f_record_"), sep = " ") %>%
            mutate(f_records_all = gsub(f_records_all,
                                        pattern = " NA", replacement = ""))
    } else if (year >= 1999) {
        ## NOTE: Some random ICD10 years will still have an rnifla_ column even
        ##      though they are all blank. We drop them here to keep them
        ##      conformable with all other years.
        df <- icd_df %>%
            unite(f_records_all, starts_with("record_"), sep = " ") %>%
            mutate(f_records_all = gsub(f_records_all,
                                        pattern = " NA", replacement = "")) %>%
            select(-starts_with("rnifla"))
    }

    return(df)
}
