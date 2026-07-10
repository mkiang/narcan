# Snapshot the internal ISW7 (drug/opioid) and WHO (maternal) regex builders.
# These strings ARE the package's cause-of-death definitions -- the domain heart
# every flag_* function depends on. Locking them verbatim is the cheapest guard
# against an accidental change when the flag family is refactored later. If a
# snapshot changes, that is a deliberate change to a code definition and must be
# reviewed, not blindly accepted.

test_that(".regex_drug_icd9() is stable (E-codes default; +N-codes)", {
    expect_snapshot({
        cat(.regex_drug_icd9(), "\n")                       # default: e_codes only
        cat(.regex_drug_icd9(n_codes = TRUE), "\n")         # N- and E-codes
        cat(.regex_drug_icd9(n_codes = TRUE, e_codes = FALSE), "\n")
    })
})

test_that(".regex_opioid_icd9() is stable", {
    expect_snapshot({
        cat(.regex_opioid_icd9(), "\n")                     # default: E850[012]
        cat(.regex_opioid_icd9(n_codes = TRUE), "\n")       # + N9650
    })
})

test_that(".regex_drug_icd10() is stable (UCOD and T-code parts)", {
    expect_snapshot({
        cat(.regex_drug_icd10(ucod_codes = TRUE), "\n")
        cat(.regex_drug_icd10(t_codes = TRUE), "\n")
        cat(.regex_drug_icd10(ucod_codes = TRUE, t_codes = TRUE), "\n")
    })
})

test_that(".regex_opioid_icd10() is stable (incl. the T40[012346] nuance)", {
    # The T-code branch is T40[012346] -- 0,1,2,3,4,6 (includes T40.6 other/
    # unspecified narcotics, excludes T40.5 cocaine). This is intentional; the
    # snapshot locks it so a refactor cannot silently alter the opioid definition.
    expect_snapshot({
        cat(.regex_opioid_icd10(ucod_codes = TRUE), "\n")
        cat(.regex_opioid_icd10(t_codes = TRUE), "\n")
        cat(.regex_opioid_icd10(ucod_codes = TRUE, t_codes = TRUE), "\n")
    })
})

test_that(".regex_maternal_icd10() is stable (WHO; +late)", {
    expect_snapshot({
        cat(.regex_maternal_icd10(), "\n")                  # A34, O00-O89, O90-O95(8,9)
        cat(.regex_maternal_icd10(include_late = TRUE), "\n") # + O96/O97 late
    })
})
