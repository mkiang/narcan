# Regression tests for add_county_fips() -- P2b redesign: year-primary scheme
# detection (NCHS numeric <=2002, postal abbreviations 2003+), explicit scheme
# override, and safe NA handling. See verify_fwf/output/review/40_p2b_findings.md
# (findings C1-C5).

test_that("NCHS-numeric data (<=2002) with a year resolves to the correct state (C1)", {
    # NCHS 06 is Colorado (FIPS 08), NOT California (FIPS 06). The year picks nchs.
    df <- tibble::tibble(countyrs = c("06031", "06005"))
    out <- add_county_fips(df, countyrs, year = 2000)
    expect_equal(out$st_fips, c("08", "08"))
    expect_equal(out$county_fips, c("08031", "08005"))
})

test_that("abbreviation data (2003+) resolves; year read from a `year` column", {
    df <- tibble::tibble(countyrs = c("CA001", "NY013", "ZZ999"), year = 2019)
    out <- add_county_fips(df, countyrs)
    expect_equal(out$st_fips, c("06", "36", NA))       # ZZ -> NA (unknown/foreign)
    expect_equal(out$county_fips, c("06001", "36013", NA))
})

test_that("explicit scheme= overrides detection", {
    df <- tibble::tibble(countyrs = c("06031", "06005"))
    expect_equal(add_county_fips(df, countyrs, scheme = "nchs")$st_fips, c("08", "08"))
    expect_equal(add_county_fips(df, countyrs, scheme = "fips")$st_fips, c("06", "06"))
})

test_that("ambiguous numeric codes with no year warn loudly, default to FIPS (C1)", {
    df <- tibble::tibble(countyrs = c("06031", "06005"))
    expect_warning(out <- add_county_fips(df, countyrs), "valid in BOTH")
    expect_equal(out$st_fips, c("06", "06"))
})

test_that("a missing county code becomes NA, not the string 'NANA' (C2)", {
    df <- tibble::tibble(countyrs = c("CA001", NA), year = 2019)
    out <- suppressWarnings(add_county_fips(df, countyrs))
    expect_equal(out$county_fips, c("06001", NA_character_))
})

test_that("all-missing state codes raise a clean error (C3)", {
    df <- tibble::tibble(countyrs = c(NA, NA))
    expect_error(add_county_fips(df, countyrs), "missing or blank")
})

test_that("territory NCHS code becomes NA with a warning; batch survives (C4)", {
    # 62 (American Samoa / N. Mariana Islands) is a territory code; narcan is
    # US-only, so it is not in st_fips_map -- the row goes NA, not abort.
    df <- tibble::tibble(countyrs = c("01001", "06005", "62001"))
    expect_warning(out <- add_county_fips(df, countyrs, year = 2000), "62")
    expect_equal(nrow(out), 3L)
    expect_equal(out$st_fips, c("01", "08", NA))
})

test_that("with no FIPS column the NCHS fallback resolves every state and keeps rows", {
    # No fipsctyo here, so this exercises the fall-through path: the state half is
    # translated and the county half is passed through as the NCHS alphabetical
    # rank. That is NOT a FIPS county -- see the 1982-2002 tests below for the
    # path that returns real geography.
    df <- tibble::tibble(countyoc = c("03001", "07001", "14001", "43001"))
    out <- add_county_fips(df, countyoc, year = 2000)
    expect_equal(nrow(out), nrow(df))
    expect_equal(out$st_fips, c("04", "09", "17", "47"))   # AZ, CT, IL, TN
    expect_equal(out$county_substr, rep("001", 4))         # rank, not FIPS
})

test_that("realistic abbreviation subsets resolve", {
    out1 <- add_county_fips(tibble::tibble(countyoc = c("CA001", "CA003")), countyoc)
    expect_equal(unique(out1$st_fips), "06")
    out2 <- add_county_fips(tibble::tibble(countyoc = c("CA001", "NY001")), countyoc)
    expect_false(anyNA(out2$st_fips))
    expect_equal(nrow(out2), 2L)
})

test_that("genuinely unrecognizable numeric codes error informatively", {
    df <- tibble::tibble(countyoc = c("99001", "98002"))    # in neither scheme
    expect_error(add_county_fips(df, countyoc), "Unrecognized state coding system")
})

test_that("mixed alphabetic + numeric state codes error with guidance", {
    df <- tibble::tibble(countyoc = c("CA001", "06001"))
    expect_error(add_county_fips(df, countyoc), "Mixed")
})

test_that("an unknown abbreviation becomes NA with a warning", {
    df <- tibble::tibble(countyoc = c("CA001", "QQ002"), year = 2019)
    expect_warning(out <- add_county_fips(df, countyoc), "QQ")
    expect_equal(out$st_fips, c("06", NA))
})

test_that("an NA in the year argument is handled like an NA year column (re-review #1)", {
    codes <- c("06031", "06005", "06013")
    arg <- add_county_fips(tibble::tibble(countyrs = codes), countyrs,
                           year = c(2000, 2001, NA))
    col <- add_county_fips(tibble::tibble(countyrs = codes,
                                          year = c(2000, 2001, NA)), countyrs)
    expect_equal(arg$st_fips, c("08", "08", "08"))     # Colorado, not California
    expect_equal(arg$st_fips, col$st_fips)             # both paths agree
})

test_that("a boundary-spanning per-row year decodes each era with its own scheme", {
    # Per-row year straddling 2002/2003: resolve the scheme SEPARATELY per era so
    # a single global scheme cannot mis-decode the minority era. "06" is NCHS
    # Colorado (-> FIPS 08) in 2002 but assumed FIPS California ("06") in 2003.
    df <- tibble::tibble(countyrs = c("06031", "06005"), year = c(2002, 2003))
    expect_warning(out <- add_county_fips(df, countyrs), "already|FIPS")
    expect_equal(out$st_fips, c("08", "06"))
    expect_equal(out$county_fips, c("08031", "06005"))
})

test_that("a mixed-era frame decodes NCHS-only and FIPS codes to the right states", {
    # AZ NCHS "03" (2002) and TX FIPS "48" (2003): the old global scheme decoded
    # TX as NCHS Washington; per-era decoding keeps them Arizona and Texas.
    df <- tibble::tibble(countyrs = c("03013", "48001"), year = c(2002, 2003))
    out <- suppressWarnings(add_county_fips(df, countyrs))
    expect_equal(out$county_fips, c("04013", "48001"))
})

test_that("a numeric county_vector is refused (leading zeros already lost)", {
    df <- data.frame(countyrs = c(6031, 1001), year = 2000)
    expect_error(add_county_fips(df, countyrs, year = 2000), "numeric")
})

test_that("whitespace-padded state codes still resolve (re-review #3)", {
    df <- tibble::tibble(countyrs = c(" CA001", "NY013 "), year = 2019)
    out <- add_county_fips(df, countyrs)
    expect_equal(out$st_fips, c("06", "36"))
})

test_that("a factor/character year is coerced by label, not factor code (R2 guard)", {
    codes <- c("06031", "06005")
    # factor("2019") must coerce to 2019 (>=2003 -> FIPS -> CA 06), NOT the factor
    # integer code 1 (which would pick NCHS -> CO 08). Locks the as.character() guard.
    expect_equal(
        suppressWarnings(add_county_fips(tibble::tibble(countyrs = codes),
                                         countyrs, year = factor("2019"))$st_fips),
        c("06", "06"))
    # character pre-2003 year -> NCHS -> Colorado
    expect_equal(
        add_county_fips(tibble::tibble(countyrs = codes), countyrs,
                        year = "2000")$st_fips,
        c("08", "08"))
    # an all-NA year argument falls through to the code-guess (FIPS default)
    expect_warning(out <- add_county_fips(tibble::tibble(countyrs = codes),
                                          countyrs, year = c(NA, NA)),
                   "not available")
    expect_equal(out$st_fips, c("06", "06"))
})

# ---------------------------------------------------------------------------
# Sourcing pre-2003 geography from the record's own FIPS columns (0.5.4).
#
# Before 2003 the last 3 digits of countyrs/countyoc are the county's
# alphabetical rank within its state, not FIPS. NCHS 05019 is Los Angeles;
# translating only the state prefix yields 06019 = Fresno. The raw record
# carries the real answer in fipsctyr/fipsctyo, which import_mcod_fwf() reads.
# ---------------------------------------------------------------------------

test_that("a pre-2003 frame takes county geography from fipsctyr, not the NCHS rank", {
    df <- tibble::tibble(countyrs = "05019", fipsctyr = "06037", year = 1999)
    out <- suppressMessages(add_county_fips(df, countyrs))
    expect_equal(out$county_fips, "06037")     # Los Angeles, not 06019 = Fresno
    expect_equal(out$st_fips, "06")
    # both halves come from the sibling, so county_substr is 037 and not the
    # 019 the caller passed in
    expect_equal(out$county_substr, "037")
})

test_that("an explicit scheme= does not disable the FIPS-column swap", {
    # scheme picks how the STATE half is decoded; use_fips_cols picks where the
    # COUNTY half comes from. Gating the swap on scheme == "auto" left the
    # released defect reachable through an argument the old docs encouraged --
    # scheme = "fips" returned 05019 (Arkansas rank 019), valid-looking, wrong,
    # and with the residual notice suppressed too.
    df <- tibble::tibble(countyrs = "05019", fipsctyr = "06037", year = 1999)
    for (s in c("auto", "nchs", "abbrev", "fips")) {
        for (u in c("auto", "yes")) {
            out <- suppressMessages(suppressWarnings(
                add_county_fips(df, countyrs, scheme = s, use_fips_cols = u)
            ))
            expect_equal(out$county_fips, "06037",
                         info = paste0("scheme=", s, " use_fips_cols=", u))
        }
    }
})

test_that("a forced scheme still flags an unswapped pre-2003 row", {
    # scheme = "fips" used to set row_scheme to "fips", and the guardrail was
    # gated on row_scheme == "nchs", so the wrong county passed in silence.
    rlang::reset_message_verbosity("narcan_fips_cols_missing")
    bare <- tibble::tibble(countyrs = "05019", year = 1999)
    expect_message(add_county_fips(bare, countyrs, scheme = "fips"),
                   "alphabetical rank")
})

test_that("the occurrence column uses fipsctyo", {
    df <- tibble::tibble(countyoc = "14016", fipsctyo = "17031", year = 2000)
    out <- suppressMessages(add_county_fips(df, countyoc))
    expect_equal(out$county_fips, "17031")     # Cook County, IL
})

test_that("use_fips_cols = 'no' reproduces the pre-0.5.4 result", {
    df <- tibble::tibble(countyrs = "05019", fipsctyr = "06037", year = 1999)
    out <- suppressMessages(add_county_fips(df, countyrs, use_fips_cols = "no"))
    expect_equal(out$county_fips, "06019")     # the old, wrong answer
})

test_that("foreign state 00 and public-masked county 999 resolve to NA, quietly", {
    df <- tibble::tibble(countyrs = c("05019", "05019"),
                         fipsctyr = c("00123", "06999"),
                         year = 1999)
    expect_silent(out <- suppressMessages(add_county_fips(df, countyrs)))
    expect_equal(out$county_fips, c(NA_character_, NA_character_))
})

test_that("a numeric FIPS sibling column is refused, not silently truncated", {
    # 6037 would substr to state "60", which is not a state at all.
    df <- tibble::tibble(countyrs = "05019", fipsctyr = 6037, year = 1999)
    expect_error(add_county_fips(df, countyrs), "fipsctyr")
})

test_that("a numeric sibling is not judged when no row is in era", {
    # A read_csv() round trip types an all-NA fipsctyr as double. On a frame with
    # no pre-2003 rows the column is never read, so refusing it aborts a
    # legitimate call for nothing.
    modern <- tibble::tibble(countyrs = c("CA037", "CA075"),
                             fipsctyr = c(NA_real_, NA_real_), year = 2019)
    expect_equal(add_county_fips(modern, countyrs)$county_fips,
                 c("06037", "06075"))

    empty <- tibble::tibble(countyrs = character(0), fipsctyr = numeric(0),
                            year = numeric(0))
    expect_equal(nrow(add_county_fips(empty, countyrs)), 0L)

    # An all-NA sibling cannot have lost a leading zero, so refusing it would
    # hard-error where the old code degraded to the rank. A non-matching
    # left_join types the column double routinely.
    in_era <- tibble::tibble(countyrs = "05019", fipsctyr = NA_real_, year = 1999)
    expect_equal(suppressMessages(add_county_fips(in_era, countyrs)$county_fips),
                 "06019")
})

test_that("the swap survives tidyselect indirection", {
    # all_of(v) pulls the right column, but the quosure text is not a column
    # name, so naming the sibling off the expression text missed the swap and
    # quietly returned Fresno.
    df <- tibble::tibble(countyrs = "05019", fipsctyr = "06037", year = 1999)
    v <- "countyrs"
    expect_equal(suppressMessages(add_county_fips(df, all_of(v))$county_fips),
                 "06037")
    expect_equal(suppressMessages(add_county_fips(df, "countyrs")$county_fips),
                 "06037")
    expect_equal(
        suppressMessages(add_county_fips(df, !!rlang::sym(v))$county_fips),
        "06037"
    )
})

test_that("a year vector that fits neither shape is an error, not a guess", {
    # HEAD used such a vector as a frame-level year set; briefly the rewrite
    # discarded it and fell through to code-guessing, returning the wrong STATE.
    df <- tibble::tibble(countyrs = rep("06031", 10))
    expect_error(add_county_fips(df, countyrs, year = c(1999, 2000)),
                 "neither 1 nor nrow")
})

test_that("an NA-year row inherits the era from swapped neighbours too", {
    # Rows 1-2 swap; row 3 has no year. Inheriting only from unswapped rows left
    # row 3 with no era at all, so adding a fipsctyr column that should only
    # help rows 1-2 silently re-decoded row 3 from Colorado to California.
    df <- tibble::tibble(countyrs = c("06031", "06031", "06031"),
                         fipsctyr = c("08031", "08031", NA),
                         year = c(1999, 1999, NA))
    out <- suppressMessages(add_county_fips(df, countyrs))
    expect_equal(out$st_fips, c("08", "08", "08"))

    # ...and the answer does not depend on the sibling column being present
    bare <- suppressMessages(add_county_fips(df[, c("countyrs", "year")], countyrs))
    expect_equal(bare$st_fips, c("08", "08", "08"))
})

test_that("the swap fires only on in-era rows of a stacked multi-year frame", {
    # The fentanyl_waves shape: one frame spanning both eras, where fipsctyr
    # exists as a column but is NA for every 2003+ row.
    df <- tibble::tibble(
        countyrs = c("05019", "05019", "CA037", "CA037"),
        fipsctyr = c("06037", "06037", NA, NA),
        year     = c(1999, 2002, 2003, 2019)
    )
    out <- suppressMessages(add_county_fips(df, countyrs))
    expect_equal(out$county_fips, rep("06037", 4))
    expect_equal(nrow(out), 4L)
})

test_that("input row order is preserved when eras are interleaved", {
    df <- tibble::tibble(
        id       = 1:4,
        countyrs = c("CA037", "05019", "CA037", "05019"),
        fipsctyr = c(NA, "06037", NA, "06075"),
        year     = c(2019, 1999, 2019, 2001)
    )
    out <- suppressMessages(add_county_fips(df, countyrs))
    expect_equal(out$id, 1:4)
    expect_equal(out$county_fips, c("06037", "06037", "06037", "06075"))
})

test_that("the swap covers the whole 1982-2002 span by default", {
    # 1982 is the first year carrying the FIPS block, and it is populated from
    # the start: public 1982-1988 has ~3,135 distinct fipsctyr codes at full
    # county granularity, because public masking only begins in 1989.
    for (y in c(1982, 1985, 1988, 1989, 2002)) {
        df <- tibble::tibble(countyrs = "05019", fipsctyr = "06037", year = y)
        expect_equal(suppressMessages(add_county_fips(df, countyrs)$county_fips),
                     "06037", info = paste("year", y))
    }
})

test_that("1979-1981 have no FIPS block, so the swap cannot reach them", {
    df <- tibble::tibble(countyrs = "05019", fipsctyr = "06037", year = 1981)
    for (u in c("auto", "yes")) {
        out <- suppressMessages(add_county_fips(df, countyrs, use_fips_cols = u))
        expect_equal(out$county_fips, "06019", info = u)
    }
})

test_that("use_fips_cols = 'yes' errors when the sibling cannot serve an in-era row", {
    no_col <- tibble::tibble(countyrs = "05019", year = 1999)
    expect_error(add_county_fips(no_col, countyrs, use_fips_cols = "yes"), "fipsctyr")

    blank <- tibble::tibble(countyrs = "05019", fipsctyr = NA_character_, year = 1999)
    expect_error(add_county_fips(blank, countyrs, use_fips_cols = "yes"),
                 "missing or not a 5-digit code")

    # ...but is a silent no-op where the era does not apply
    modern <- tibble::tibble(countyrs = "CA037", year = 2019)
    expect_equal(add_county_fips(modern, countyrs, use_fips_cols = "yes")$county_fips,
                 "06037")
})

test_that("passing a FIPS column directly is not re-decoded as NCHS", {
    # The trap: with a pre-2003 year, the old code sent fipsctyr "06037" down the
    # NCHS path and returned "08037" (Colorado) with no warning.
    df <- tibble::tibble(fipsctyr = "06037", year = 1999)
    out <- add_county_fips(df, fipsctyr)
    expect_equal(out$county_fips, "06037")

    # ...and an explicit scheme= does not reopen it. The column is FIPS by
    # construction, so column identity outranks the argument -- but say so
    # rather than obeying silently.
    for (nm in c("fipsctyr", "fipsctyo")) {
        d <- tibble::tibble(x = "06037", year = 1999)
        names(d)[1] <- nm
        expect_warning(out <- add_county_fips(d, !!rlang::sym(nm), scheme = "nchs"),
                       "already holds FIPS")
        expect_equal(out$county_fips, "06037")   # not 08037 = Colorado
    }
})

test_that("a pre-2003 frame with no year is flagged, and the year fixes it", {
    rlang::reset_message_verbosity("narcan_fips_cols_missing")
    df <- tibble::tibble(countyrs = "43019", fipsctyr = "47037")
    expect_message(out <- add_county_fips(df, countyrs), "pass year=")
    expect_equal(out$county_fips, "47019")       # Carter County, TN -- wrong
    expect_equal(
        suppressMessages(add_county_fips(df, countyrs, year = 2000)$county_fips),
        "47037"                                  # Davidson County, TN -- right
    )
})

test_that("a no-year row is resolved from its own codes, not the whole frame", {
    # Pooling the frame's codes to resolve no-year rows looks symmetric with the
    # year inheritance but is not: a 2003+ abbreviation elsewhere turned the
    # guess into a "mixed alphabetic and numeric" abort, and an unrelated
    # NCHS-only code re-routed rows it had no bearing on.
    straddle <- tibble::tibble(countyrs = c("05019", "CA037", "CA075"),
                               year = c(1999, 2019, NA))
    out <- suppressMessages(suppressWarnings(add_county_fips(straddle, countyrs)))
    expect_equal(out$st_fips, c("06", "06", "06"))

    # The vignette's own frame, plus one row whose year went missing.
    v <- tibble::tibble(countyrs = c("05019", "33061", "CA075", "TX201", "CA037"),
                        fipsctyr = c("06037", "36061", NA, NA, NA),
                        year = c(1999, 2001, 2003, 2004, NA))
    out_v <- suppressMessages(suppressWarnings(add_county_fips(v, countyrs)))
    expect_equal(out_v$st_fips, c("06", "36", "06", "48", "06"))
})

test_that("swapped rows still disambiguate their neighbours", {
    d <- tibble::tibble(countyrs = c("03013", "05019", "36061", "05019", "36061"),
                        fipsctyr = c("04013", "06037", "39061", NA, NA),
                        year = 1999)
    out <- suppressMessages(add_county_fips(d, countyrs))
    expect_equal(out$st_fips, c("04", "06", "39", "06", "39"))
})

test_that("a primary county code that is not 5 characters is refused", {
    # "1001" survives the is.numeric() refusal but substr()s to state "10"
    # (Delaware) for an Alabama record.
    expect_warning(out <- add_county_fips(tibble::tibble(countyrs = c("1001", "CA037"),
                                                         year = 2019), countyrs),
                   "wrong width")
    expect_equal(out$county_fips, c(NA, "06037"))

    # ...but fipsstr/fipssto are genuinely 2 characters: the whole code is the
    # state half. Rejecting those NA'd a state the old version resolved.
    st <- add_county_fips(tibble::tibble(fipsstr = c("06", "36"), year = 2019),
                          fipsstr)
    expect_equal(st$st_fips, c("06", "36"))
})

test_that("an all-foreign frame resolves to NA, quietly, with or without a year", {
    # "00" names no state in any scheme, so it is neither evidence for one nor
    # something to warn about -- and an all-"00" frame is a legitimate stratum.
    for (y in list(NULL, 1999)) {
        df <- tibble::tibble(countyrs = c("00000", "00999"))
        expect_silent(out <- add_county_fips(df, countyrs, year = y))
        expect_equal(out$county_fips, c(NA_character_, NA_character_))
    }
})

test_that("a no-year pre-2003 frame with no sibling is still flagged", {
    # Nothing to source from, so the answer stays wrong -- but the caller has to
    # be told, and told the one thing that would help.
    rlang::reset_message_verbosity("narcan_fips_cols_missing")
    df <- tibble::tibble(countyrs = "43019")
    expect_message(out <- add_county_fips(df, countyrs), "pass year=")
    expect_equal(out$county_fips, "47019")
})

test_that("a no-year frame is never silently decoded, under any scheme", {
    # The guardrail's nchs test only catches the 4 NCHS-only codes (03/07/14/43)
    # and a forced scheme= defeats it entirely, so without a third test a yearless
    # frame returned a wrong county with no signal at all.
    # "abbrev" is excluded: forcing it on a numeric code yields NA, and a row
    # that produced no county cannot be carrying a wrong one.
    for (s in c("auto", "nchs", "fips")) {
        rlang::reset_message_verbosity("narcan_fips_cols_missing")
        df <- tibble::tibble(countyrs = "05019")
        expect_message(suppressWarnings(add_county_fips(df, countyrs, scheme = s)),
                       "cannot be determined", info = s)
    }
    # ...but an abbreviation-coded (2003+) row needs no such notice: a postal
    # abbreviation is proof the record is not pre-2003.
    rlang::reset_message_verbosity("narcan_fips_cols_missing")
    expect_no_message(add_county_fips(tibble::tibble(countyrs = "CA037"), countyrs))
})

test_that("a no-year row is not guessed into the sibling", {
    # Tempting inference: a numeric state half means pre-2003, so swap. But a
    # caller who pre-converted a modern frame to numeric FIPS looks identical,
    # and for them the swap overwrites a correct countyrs with the sibling --
    # the same silent-wrong-county class this release exists to close.
    modern <- tibble::tibble(countyrs = "06037", fipsctyr = "08031")
    for (s in c("auto", "fips")) {
        for (u in c("auto", "yes")) {
            out <- suppressMessages(suppressWarnings(
                add_county_fips(modern, countyrs, scheme = s, use_fips_cols = u)
            ))
            expect_equal(out$county_fips, "06037",
                         info = paste("scheme", s, "use", u))
        }
    }
})

test_that("a sibling that is not a 5-digit code is not trusted", {
    # "1001" survives the is.numeric() refusal but substr()s to state "10"
    # (Delaware) for an Alabama record -- silently, and only for source states
    # 01-05, since wider prefixes miss the roster and go NA loudly.
    df <- tibble::tibble(countyrs = "05019", fipsctyr = "1001", year = 1999)
    expect_equal(suppressMessages(add_county_fips(df, countyrs)$county_fips),
                 "06019")                       # fell back, did not invent 10001
    expect_error(add_county_fips(df, countyrs, use_fips_cols = "yes"),
                 "5-digit")
})

test_that("a pre-2003 row is flagged under every scheme, including pre-1982", {
    # A forced scheme= defeats the nchs test, so the year window is the only
    # thing left -- and bounding it at 1982 let 1979-1981 through in silence,
    # which is the span with no remedy at all.
    for (s in c("auto", "nchs", "fips")) {
        for (y in c(1980, 1999)) {
            rlang::reset_message_verbosity("narcan_fips_cols_missing")
            df <- tibble::tibble(countyrs = "05019", year = y)
            expect_message(
                suppressWarnings(add_county_fips(df, countyrs, scheme = s)),
                "alphabetical rank",
                info = paste("scheme", s, "year", y)
            )
        }
    }
    # An alphabetic code decodes under abbrev whatever the year says, and its
    # county digits are already FIPS -- so a contradictory pre-2003 year must not
    # make the guardrail call a correct answer wrong.
    rlang::reset_message_verbosity("narcan_fips_cols_missing")
    abbrev_row <- tibble::tibble(countyrs = "CA037", year = 1999)
    expect_no_message(out <- add_county_fips(abbrev_row, countyrs))
    expect_equal(out$county_fips, "06037")
})

test_that("an explicit scheme that agrees with the column does not warn", {
    df <- tibble::tibble(fipsctyr = "06037", year = 1999)
    expect_no_warning(out <- add_county_fips(df, fipsctyr, scheme = "fips"))
    expect_equal(out$county_fips, "06037")
})

test_that("masked county 999 and foreign state 00 are NA on every path", {
    # The masking used to live only inside the swap, but 18% of public 2004
    # residence records carry a 999 suffix, so "48999" was being handed to
    # callers as though it named a county.
    modern <- tibble::tibble(countyrs = c("CA037", "TX999", "GA999"), year = 2004)
    expect_equal(add_county_fips(modern, countyrs)$county_fips,
                 c("06037", NA, NA))

    old <- tibble::tibble(countyrs = "44999", year = 2000)
    expect_equal(suppressMessages(add_county_fips(old, countyrs)$county_fips),
                 NA_character_)

    direct <- tibble::tibble(fipsctyr = c("06999", "00123"), year = 1999)
    expect_equal(add_county_fips(direct, fipsctyr)$county_fips,
                 c(NA_character_, NA_character_))

    # An all-foreign frame is a legitimate stratum, not an empty column: masking
    # in place made it trip the "all state codes are missing or blank" abort.
    all_foreign <- tibble::tibble(fipsctyr = c("00123", "00456"), year = 1999)
    expect_equal(add_county_fips(all_foreign, fipsctyr)$county_fips,
                 c(NA_character_, NA_character_))

    # ...and the literal halves survive, so a caller can still size the masking
    # rather than confusing it with a blank field.
    masked <- suppressMessages(add_county_fips(modern, countyrs))
    expect_equal(masked$county_substr, c("037", "999", "999"))
})

test_that("class, grouping, row names and row count survive", {
    tb <- tibble::tibble(countyrs = "05019", fipsctyr = "06037", year = 1999)
    expect_s3_class(suppressMessages(add_county_fips(tb, countyrs)), "tbl_df")

    bd <- data.frame(countyrs = c("05019", "05019"),
                     fipsctyr = c("06037", "06075"), year = 1999,
                     row.names = c("a", "b"))
    out_bd <- suppressMessages(add_county_fips(bd, countyrs))
    expect_s3_class(out_bd, "data.frame")
    expect_false(inherits(out_bd, "tbl_df"))
    expect_equal(rownames(out_bd), c("a", "b"))

    gp <- dplyr::group_by(
        tibble::tibble(countyrs = c("05019", "05019"), fipsctyr = c("06037", "06075"),
                       year = 1999, g = c("a", "b")),
        g
    )
    out_gp <- suppressMessages(add_county_fips(gp, countyrs))
    expect_equal(dplyr::group_vars(out_gp), "g")
    expect_equal(nrow(out_gp), 2L)
})

test_that("a caller's own .orig_row column is left alone", {
    df <- tibble::tibble(countyrs = c("05019", "CA037"),
                         fipsctyr = c("06037", NA),
                         year = c(1999, 2019),
                         .orig_row = c("keep me", "and me"))
    out <- suppressMessages(add_county_fips(df, countyrs))
    expect_equal(out$.orig_row, c("keep me", "and me"))
})

test_that("a zero-row frame comes back empty with the new columns, not an error", {
    df <- tibble::tibble(countyrs = character(0), year = numeric(0))
    out <- add_county_fips(df, countyrs)
    expect_equal(nrow(out), 0L)
    expect_true(all(c("st_fips", "county_fips") %in% names(out)))
})

test_that("the FIPS-sourcing notice and the NCHS-rank warning each fire once", {
    rlang::reset_message_verbosity("narcan_fips_cols_used")
    df <- tibble::tibble(countyrs = "05019", fipsctyr = "06037", year = 1999)
    # match on the sourcing phrase, not "fipsctyr": the fallback notice names
    # fipsctyr too, so a swap that silently stopped firing would still pass
    expect_message(add_county_fips(df, countyrs),
                   "sourced pre-2003 county geography")
    expect_message(add_county_fips(df, countyrs), NA)      # once per session

    rlang::reset_message_verbosity("narcan_fips_cols_missing")
    bare <- tibble::tibble(countyrs = "05019", year = 1999)
    expect_message(add_county_fips(bare, countyrs), "alphabetical rank")
    expect_message(add_county_fips(bare, countyrs), NA)
})

test_that("the residual notice names a remedy that would actually work", {
    # "leave use_fips_cols = auto" is actively wrong advice for someone who
    # passed "no" on purpose.
    rlang::reset_message_verbosity("narcan_fips_cols_missing")
    df <- tibble::tibble(countyrs = "05019", fipsctyr = "06037", year = 1999)
    expect_message(add_county_fips(df, countyrs, use_fips_cols = "no"),
                   "is what disabled")

    # ...but "drop use_fips_cols" is only true advice when there is a sibling to
    # fall back on and the row is in the sourced span. Neither holds here, so the
    # message must name the remedy that would actually work.
    rlang::reset_message_verbosity("narcan_fips_cols_missing")
    no_sib <- tibble::tibble(countyrs = "05019", year = 1999)
    expect_message(add_county_fips(no_sib, countyrs, use_fips_cols = "no"),
                   "import_mcod_fwf")

    rlang::reset_message_verbosity("narcan_fips_cols_missing")
    too_early <- tibble::tibble(countyrs = "05019", fipsctyr = "06037", year = 1980)
    expect_message(add_county_fips(too_early, countyrs, use_fips_cols = "no"),
                   "before 1982")
})

test_that("1979-1981 say the county cannot be recovered at all", {
    # No FIPS county was recorded before 1982. Staying silent would leave the
    # caller with a wrong county and no way to know; naming either of the other
    # remedies would be worse, since neither exists for this span.
    rlang::reset_message_verbosity("narcan_fips_cols_missing")
    df <- tibble::tibble(countyrs = "05019", year = 1980)
    expect_message(out <- add_county_fips(df, countyrs), "before 1982")
    expect_equal(out$county_fips, "06019")
    expect_equal(out$st_fips, "06")     # the state half is still right
})

test_that("a harmless call does not spend the once-per-session notice", {
    # The guardrail counts only rows that actually produced a county code. Before
    # that mask, an all-masked or all-territory frame -- which returns NA and is
    # nobody's wrong county -- fired the notice, and because it is once-per-
    # session the NEXT call, with a genuinely wrong county, went out silent.
    # Deliberately no reset between the two calls: the ordering IS the test.
    rlang::reset_message_verbosity("narcan_fips_cols_missing")
    harmless <- tibble::tibble(countyrs = c("05999", "06999"), year = 1999)
    expect_no_message(add_county_fips(harmless, countyrs))

    genuine <- tibble::tibble(countyrs = "05019", year = 1999)
    expect_message(add_county_fips(genuine, countyrs), "alphabetical rank")
})

test_that("an abbrev-coded row is never sourced from the sibling", {
    # A postal abbreviation only exists from 2003, so the row is 2003+ whatever a
    # year column claims and its county digits are already FIPS. Swapping one
    # returned New York County for Chautauqua.
    df <- tibble::tibble(countyrs = c("CA037", "NY013"),
                         fipsctyr = c("06037", "36061"),
                         year = 1999)
    out <- suppressMessages(add_county_fips(df, countyrs))
    expect_equal(out$county_fips, c("06037", "36013"))   # 36013 = Chautauqua
})

test_that("an NA-year row is sourced under the era it inherits", {
    # The scheme detector decodes this row as pre-2003 by inheriting 1999 from
    # its neighbour. The swap has to agree, or the state half says pre-2003 while
    # the county half stays a rank -- 06019 (Fresno) returned next to the row's
    # own fipsctyr saying 06075.
    df <- tibble::tibble(countyrs = c("05019", "05019"),
                         fipsctyr = c("06037", "06075"),
                         year = c(1999, NA))
    out <- suppressMessages(add_county_fips(df, countyrs))
    expect_equal(out$county_fips, c("06037", "06075"))

    # ...but a frame with no year at all inherits nothing and is not guessed.
    none <- tibble::tibble(countyrs = "06037", fipsctyr = "08031")
    expect_equal(
        suppressMessages(add_county_fips(none, countyrs, scheme = "fips")$county_fips),
        "06037"
    )
})

test_that("a forced scheme discarded by the swap is reported", {
    df <- tibble::tibble(countyrs = "05019", fipsctyr = "06037", year = 1999)
    expect_warning(suppressMessages(add_county_fips(df, countyrs, scheme = "abbrev")),
                   "was ignored")
    # ...but "fips" agrees with the sibling, so it is not an override
    expect_no_warning(suppressMessages(add_county_fips(df, countyrs, scheme = "fips")))
})

test_that("an empty code set lets the data year pick the scheme", {
    # Reachable only through the internal today, but it is the guard that stops
    # an all-foreign modern frame being labelled pre-2003.
    expect_equal(.detect_fips_scheme(character(0), year = 2019), "abbrev")
    expect_equal(.detect_fips_scheme(character(0), year = 1999), "nchs")
    expect_equal(.detect_fips_scheme(character(0)), "nchs")
})

test_that("a pre-1982 frame does not lend its era to a year-less row", {
    # "all known years are pre-2003" used to collapse to the literal 2000, which is
    # inside the sourced window -- so a frame whose only year was 1980 handed its
    # NA-year row a swap-eligible era and sourced it from a field that does not
    # exist before 1982. Two byte-identical countyrs, opposite treatment.
    df <- tibble::tibble(countyrs = c("05019", "05019"),
                         fipsctyr = c("06001", "06037"),
                         year = c(1980, NA))
    out <- suppressMessages(add_county_fips(df, countyrs))
    expect_equal(out$county_fips, c("06019", "06019"))
})

test_that("a straddling frame lends no era to a year-less row", {
    # Known years on both sides of 2002/2003 agree on nothing, so the NA-year row
    # must fall through to being reported, not swapped.
    rlang::reset_message_verbosity("narcan_fips_cols_missing")
    df <- tibble::tibble(countyrs = c("05019", "CA037", "06037"),
                         fipsctyr = c("06037", NA, "08031"),
                         year = c(1999, 2019, NA))
    out <- suppressMessages(suppressWarnings(add_county_fips(df, countyrs)))
    expect_equal(out$county_fips[3], "06037")     # not 08031 from the sibling
})

test_that("an inherited era is reported as decoded, not as undetermined", {
    # The guardrail reads the same effective year the swap does, so it must not
    # tell the caller a row "cannot be determined" after inheriting its era.
    rlang::reset_message_verbosity("narcan_fips_cols_missing")
    df <- tibble::tibble(countyrs = c("05019", "05019"), year = c(1999, NA))
    msg <- testthat::capture_messages(add_county_fips(df, countyrs))
    expect_match(paste(msg, collapse = " "), "pre-2003 row\\(s\\) were decoded")
    expect_no_match(paste(msg, collapse = " "), "cannot be determined")
})

test_that("a row whose own state is foreign or a territory is not swapped", {
    # The swap corrects the county half of a valid US record. A countyrs whose state
    # half is "00" (foreign/unknown) or a territory code has no US county to correct,
    # and overwriting it from the sibling manufactured one -- 0.5.3 returned NA.
    for (code in c("00123", "62001")) {
        df <- tibble::tibble(countyrs = code, fipsctyr = "06037", year = 1999)
        out <- suppressMessages(suppressWarnings(add_county_fips(df, countyrs)))
        expect_true(is.na(out$county_fips), info = code)
    }
})

test_that("the 2003 upper bound on the swap is enforced", {
    # Relaxing `yr <= 2002` used to leave the whole suite green, yet it is the guard
    # that stops a sibling overwriting a correct modern county.
    df <- tibble::tibble(countyrs = c("06037", "06075"),
                         fipsctyr = c("08031", "08031"),
                         year = c(2002, 2003))
    out <- suppressMessages(suppressWarnings(add_county_fips(df, countyrs)))
    expect_equal(out$county_fips[2], "06075")   # 2003 row keeps its own county
    expect_equal(out$county_fips[1], "08031")   # 2002 row is sourced
})

test_that("a fully-sourced frame does not trip the rank guardrail", {
    # Dropping `!swapped` from the guardrail made a wholly correct frame announce that
    # its counties were wrong and -- the notice being once-per-session -- silenced the
    # next call that genuinely was.
    rlang::reset_message_verbosity("narcan_fips_cols_missing")
    good <- tibble::tibble(countyrs = c("05019", "05019"),
                           fipsctyr = c("06037", "06075"), year = 1999)
    msg <- testthat::capture_messages(add_county_fips(good, countyrs))
    expect_no_match(paste(msg, collapse = " "), "alphabetical rank within the state")

    bare <- tibble::tibble(countyrs = "05019", year = 1999)
    expect_message(add_county_fips(bare, countyrs), "alphabetical rank")
})
