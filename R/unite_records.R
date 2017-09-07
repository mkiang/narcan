#' Unite the 20 record columns from ICD-9 dataframe into a single column
#'
#' ICD-9 dataframes contain 20 record columns (contributory causes) along with
#' 20 flag columns that denote if the contributory cause is an N code or an
#' E code. This function collapses the 20 columns into a single column with
#' all codes (and their appropriate prefix) to make regex'ing easier.
#'
#' @param icd9_df an ICD-9 dataframe
#'
#' @return dataframe
#' @importFrom dplyr mutate select starts_with
#' @importFrom tidyr unite
#' @export
unite_records <- function(icd9_df) {
    ## Unite all 20 records columns into a single new column for easier
    ## regexing.

    ## Make sure record columns are appropriate prefixed
    df <- icd9_df %>%
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

    return(df)
}
