## Regex helpers

.regex_drug_icd9 <- function(n_codes = FALSE, e_codes = TRUE) {
    ## Just returns the regex for all drug deaths as defined by the ISW7
    ##
    ## ICD-9 Nature of Injury (N) codes that designate
    ## drug poisoning (all intents) according to ISW7:
    ##      909.0 909.5 -- "\\<N909[05]\\>"
    ##      960 961 962 963 964 965 966 967 968 969 -- "\\<N9[67]\\d{2}\\>"
    ##      970 971 972 973 974 975 976 977 978 979 -- "\\<N9[67]\\d{2}\\>"
    ##      995.2 995.4 -- "\\<N995[24]\\>"
    ##  NOTE: ISW7 also includes:
    ##      995.86 995.89
    ##      999.4 999.5 999.6 999.7
    ##      But I exclude 995.8* because we don't have five character codes
    ##      and I exclude 999.* because those are deaths due to transfusion.
    ##
    ## ICD-9 External Cause of Injury (E) codes that designate
    ## drug poisoning (all intents):
    ##      E850 E851 E852 E853 E854 E855 E856 E857 E858 -- "\\<E85\\d{2}\\>"
    ##      E950.0 E950.1 E950.2 E950.3 E950.4 E950.5 -- "\\<E950[012345]\\>"
    ##      E962.0 -- "\\<E9620\\>"
    ##      E980.0 E980.1 E980.2 E980.3 E980.4 E980.5 -- "\\<E980[012345]\\>"

    search_term <- NULL

    if (n_codes) {
        n_1 <- "\\<N909[05]\\>"
        n_2 <- "\\<N9[67]\\d{2}\\>"
        n_3 <- "\\<N995[24]\\>"

        search_term <- c(n_1, n_2, n_3)
    }

    if (e_codes) {
        e_1 <- "\\<E85\\d{2}\\>"
        e_2 <- "\\<E950[012345]\\>"
        e_3 <- "\\<E9620\\>"
        e_4 <- "\\<E980[012345]\\>"

        search_term <- c(search_term, e_1, e_2, e_3, e_4)
    }

    return(paste0(search_term, collapse = "|"))
}


.regex_opioid_icd9 <- function(n_codes = FALSE, e_codes = TRUE) {
    ## Just returns the regex for opioid-specific deaths as defined by the ISW7
    ##
    ## ICD-9 Nature of Injury (N) codes that designate opioid poisoning:
    ##      965.0 -- "\\<N9650\\>"
    ##  NOTE: 965.0 has these subcodes for type of opioid. MCD data doesn't.
    ##      965.00 965.01 965.02 965.09
    ##
    ## ICD-9 External Cause of Injury (E) codes designating opioid poisoning:
    ##      E850.0 E850.1 E850.2 -- "\\<E850[012]\\>"

    search_term <- NULL

    if (n_codes) {
        search_term <- "\\<N9650\\>"
    }

    if (e_codes) {
        search_term <- c(search_term, "\\<E850[012]\\>")
    }

    return(paste0(search_term, collapse = "|"))
}


.regex_drug_icd10 <- function(ucod_codes = FALSE, t_codes = FALSE) {
    ## Just returns the regex for all drug deaths as defined by the ISW7
    ##
    ## For ICD10, you need one UCOD below **AND** one T-code in contributory.
    ##
    ## ICD-10 UCOD codes that designate drug poisoning (all intents):
    ##      X40-X44 -- "\\<X[46][01234]\\d{0,1}\\>"
    ##      X60-X64 -- "\\<X[46][01234]\\d{0,1}\\>"
    ##      X85 -- "\\<X85\\d{0,1}\\>"
    ##      Y10-Y14 -- "\\<Y1[01234]\\d{0,1}\\>"
    ##
    ## ICD-10 T codes in contributing causes that designates drug poisoning:
    ##      T36-T39.9 -- "\\<T3[6789]\\d{0,1}\\>"
    ##      T40.0-T50.9 -- "\\<T[45]\\d{1,2}\\>"

    search_term <- NULL

    if (ucod_codes) {
        u_1 <- "\\<X[46][01234]\\d{0,1}\\>"
        u_2 <- "\\<X85\\d{0,1}\\>"
        u_3 <- "\\<Y1[01234]\\d{0,1}\\>"

        search_term <- c(u_1, u_2, u_3)
    }

    if (t_codes) {
        t_1 <- "\\<T3[6789]\\d{0,1}\\>"
        t_2 <- "\\<T[45]\\d{1,2}\\>"

        search_term <- c(search_term, t_1, t_2)
    }

    return(paste0(search_term, collapse = "|"))
}


.regex_opioid_icd10 <- function(ucod_codes = FALSE, t_codes = FALSE) {
    ## Just returns the regex for all poisoning deaths as defined by the ISW7
    ##
    ## For ICD10, you need one UCOD below **AND** one T-code in contributory.
    ##
    ## ICD-10 UCOD codes that designate opioid poisoning (all intents):
    ##      X40-X44 -- "\\<X[46][01234]\\d{0,1}\\>"
    ##      X60-X64 -- "\\<X[46][01234]\\d{0,1}\\>"
    ##      X85 -- "\\<X85\\d{0,1}\\>"
    ##      Y10-Y14 -- "\\<Y1[01234]\\d{0,1}\\>"
    ##
    ## ICD-10 T codes in contributing causes that designates opioid poisoning:
    ##      T40.0-T40.4 -- "\\<T40[01234]\\>"

    search_term <- NULL

    if (ucod_codes) {
        u_1 <- "\\<X[46][01234]\\d{0,1}\\>"
        u_2 <- "\\<X85\\d{0,1}\\>"
        u_3 <- "\\<Y1[01234]\\d{0,1}\\>"

        search_term <- c(u_1, u_2, u_3)
    }

    if (t_codes) {
        t_1 <- "\\<T40[012346]\\>"

        search_term <- c(search_term, t_1)
    }

    return(paste0(search_term, collapse = "|"))
}
