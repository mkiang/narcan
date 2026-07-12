## Regex helpers

## Single source of truth for the drug-poisoning UCOD set, split by ISW7/NCHS
## intent (unintentional, suicide, homicide, undetermined). Both the drug UCOD
## regex and flag_od_intent() derive from this so the intent partition and the
## drug-death definition can never silently diverge. The ICD-9 E-code set IS
## exactly these four partitions; the ICD-10 drug UCOD regex unions them (with
## X4/X6 collapsed to the equivalent X[46] class in .regex_drug_icd10).
.drug_ucod_intents <- function(era) {
    if (identical(era, "icd9")) {
        c(unintended   = "\\<E85[0-8]\\d\\>",
          suicide      = "\\<E950[012345]\\>",
          homicide     = "\\<E9620\\>",
          undetermined = "\\<E980[012345]\\>")
    } else {
        c(unintended   = "\\<X4[01234]\\d{0,1}\\>",
          suicide      = "\\<X6[01234]\\d{0,1}\\>",
          homicide     = "\\<X85\\d{0,1}\\>",
          undetermined = "\\<Y1[01234]\\d{0,1}\\>")
    }
}

## Single source of truth for the ISW7 "any opioid" subtypes, as the code SUBDIGIT
## per subtype (T40.x for ICD-10, E850.x for ICD-9). The aggregate opioid regex
## (.regex_opioid_icd10/_icd9) composes its character class from these digits, and
## each flag_<subtype>_present() reads its own digit -- so the aggregate opioid
## definition and the per-subtype flags can never diverge. Order is kept
## ascending so the composed class is a stable string.
## ICD-10 T40.x: .0 opium, .1 heroin, .2 natural/semisynthetic, .3 methadone,
## .4 other synthetic, .6 other/unspecified (.5 = cocaine, excluded). ICD-9
## E850.x: .0 heroin, .1 methadone, .2 other opioid (opium/natural/synthetic have
## no ICD-9 subcode).
.opioid_subtype_codes <- function(era) {
    if (identical(era, "icd9")) {
        c(heroin = "0", methadone = "1", other_op = "2")
    } else {
        c(opium = "0", heroin = "1", other_natural = "2", methadone = "3",
          other_synth = "4", other_op = "6")
    }
}

## Full anchored regex for ONE opioid subtype, or NA if it has no code in `era`.
.opioid_subtype_regex <- function(subtype, era) {
    codes <- .opioid_subtype_codes(era)
    if (!subtype %in% names(codes)) {
        return(NA_character_)
    }
    prefix <- if (identical(era, "icd9")) "E850" else "T40"
    paste0("\\<", prefix, codes[[subtype]], "\\>")
}

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
    ##      E850 E851 E852 E853 E854 E855 E856 E857 E858 -- "\\<E85[0-8]\\d\\>"
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
        ## The E-code drug set is exactly the four intent partitions.
        search_term <- c(search_term, unname(.drug_ucod_intents("icd9")))
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
        ## Composed from the single subtype code source (E850.0/.1/.2).
        search_term <- c(search_term, paste0(
            "\\<E850[", paste(.opioid_subtype_codes("icd9"), collapse = ""),
            "]\\>"))
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
    ##      T40.0-T50.9 -- "\\<T(4\\d|50)\\d{0,1}\\>"

    search_term <- NULL

    if (ucod_codes) {
        u_1 <- "\\<X[46][01234]\\d{0,1}\\>"
        u_2 <- "\\<X85\\d{0,1}\\>"
        u_3 <- "\\<Y1[01234]\\d{0,1}\\>"

        search_term <- c(u_1, u_2, u_3)
    }

    if (t_codes) {
        t_1 <- "\\<T3[6789]\\d{0,1}\\>"
        t_2 <- "\\<T(4\\d|50)\\d{0,1}\\>"

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
    ## ICD-10 T codes in contributing causes that designates opioid poisoning
    ## (ISW7 "any opioid" = T40.0-T40.4 and T40.6):
    ##      T40.0-T40.4, T40.6 -- "\\<T40[012346]\\>"
    ## NOTE (ISW7 2012, Appendix B1 footnote): T40.6 ("other and unspecified
    ## narcotics") can capture non-opioids (e.g., cocaine) in some jurisdictions.

    search_term <- NULL

    if (ucod_codes) {
        u_1 <- "\\<X[46][01234]\\d{0,1}\\>"
        u_2 <- "\\<X85\\d{0,1}\\>"
        u_3 <- "\\<Y1[01234]\\d{0,1}\\>"

        search_term <- c(u_1, u_2, u_3)
    }

    if (t_codes) {
        ## Composed from the single subtype code source (T40.0-.4, .6).
        t_1 <- paste0("\\<T40[",
                      paste(.opioid_subtype_codes("icd10"), collapse = ""),
                      "]\\>")

        search_term <- c(search_term, t_1)
    }

    return(paste0(search_term, collapse = "|"))
}

.regex_maternal_icd10 <- function(include_late = FALSE) {
    ## `include_late` will add the ICD-10 codes that occur *after* 42 days (
    ## but less than 1 year), which are not technically maternal mortality
    ## deaths by the WHO definition.
    ##
    ## These are ICD10 maternal mortality codes as defined by the WHO.
    ## Source: http://www.who.int/reproductivehealth/publications/monitoring/maternal-mortality-2015/en/

    u_1 <- "\\<A34\\d{0,1}\\>"
    u_2 <- "\\<O[012345678]{1}[0-9]{1}\\d{0,1}\\>"
    u_3 <- "\\<O9[01234589]{1}\\d{0,1}\\>"

    search_term <- c(u_1, u_2, u_3)

    if (include_late) {
        u_4 <- "\\<O9[67]{1}\\d{0,1}\\>"
        search_term <- c(search_term, u_4)
    }

    return(paste0(search_term, collapse = "|"))
}
