## Create the MCOD fixed width format dictionary
library(dplyr)
library(tibble)
library(usethis)
library(here)
library(purrr)
library(fs)

## For 1979 to 2004, just use NBER dictionaries
if (!file_exists(here("inst", "extdata", "fwf_dicts_1979_2004.RDS"))) {
    fwf_dicts_1979_2004 <- purrr::map_dfr(.x = 1979:2004,
                                      .f = ~ narcan:::.dct_to_fwf_df(.x) %>%
                                          mutate(year = .x))
    saveRDS(fwf_dicts_1979_2004,
            here("inst", "extdata", "fwf_dicts_1979_2004.RDS"),
            compress = "xz")
} else {
    fwf_dicts_1979_2004 <- readRDS(here("inst", "extdata", "fwf_dicts_1979_2004.RDS"))
}

## Starting in 2005, they added race recode 40 and the public files
## dropped geographic information so we will just repeat. They also added
## a few columns we will add here.
##
## NOTE: The race recode 40 variable exists in the 2005-2011 data BUT IT
## DOES NOT DO ANYTHING. The variable isn't actually available until 2012 so
## this core removes it from the FWF dictionary  (at the end of the file)
## just to avoid the confusion.
mcod_fwf_dicts <- bind_rows(
    fwf_dicts_1979_2004,
    fwf_dicts_1979_2004 %>%
        filter(year == 2004) %>%
        mutate(year = 2005) %>%
        add_case(
            name = "racer40",
            type = "n",
            start = 489,
            end = 490,
            year = 2005
        ) %>%
        add_case(
            name = "tobacco_use",
            type = "c",
            start = 142,
            end = 142,
            year = 2005
        ) %>%
        add_case(
            name = "pregnancy_status",
            type = "n",
            start = 143,
            end = 143,
            year = 2005
        ) %>%
        add_case(
            name = "certifier",
            type = "c",
            start = 110,
            end = 110,
            year = 2005
        )
)

## No changes for 2006 to 2019 so we just repeat
for (y in 2006:2019) {
    mcod_fwf_dicts <- mcod_fwf_dicts %>%
        bind_rows(
            mcod_fwf_dicts %>%
                filter(year == 2005) %>%
                mutate(year = y)
        )
}

## 2020 added occupation
mcod_fwf_dicts <- mcod_fwf_dicts %>%
    bind_rows(
        mcod_fwf_dicts %>%
            filter(year == 2019) %>%
            add_case(
                name = "occupation",
                type = "c",
                start = 806,
                end = 809
            ) %>%
            add_case(
                name = "occupationr",
                type = "c",
                start = 810,
                end = 811
            ) %>%
            add_case(
                name = "industry",
                type = "c",
                start = 812,
                end = 815
            ) %>%
            add_case(
                name = "industryr",
                type = "c",
                start = 816,
                end = 817
            ) %>%
            mutate(year = 2020)
    )

## 2021 had dramatic changes. Namely, they no longer use bridged race,
## they also removed population information and education coding, there
## is no more hispanic recoding, they added race checkboxes, they moved the
## location of race recode 40, etc. To keep this transparent, I copied the
## raw tribble information here, which just shows the changes from 2020 to
## 2021.
##
## NOTE: While the data dictionary shows the following columns the
## ACTUAL DATA FILE DOES NOT SEEM TO MATCH THE DICTIONARY. Need to use the
## 2020 data file so just going to comment this out for now.
# mcod_fwf_dicts <- mcod_fwf_dicts %>%
#     bind_rows(
#         tibble::tribble(
#             ~name, ~type, ~start, ~end,
#             "rectype",   "n",     19,   19,
#             "restatus",   "n",     20,   20,
#             "stateoc",   "c",     21,   22,
#             "countyoc",   "c",     21,   25,
#             "exstatoc",   "c",     26,   27,
#             "popsizoc",   "n",     28,   28,
#             "staters",   "c",     29,   30,
#             "statersr",   "c",     33,   34,
#             "countyrs",   "c",     33,   37,
#             "cityrs",   "c",     38,   42,
#             "popsize",   "c",     43,   43,
#             "metro",   "c",     44,   44,
#             "exstares",   "c",     45,   46,
#             # "pmsares",   "c",     47,   50,
#             "popsizrs",   "c",     51,   51,
#             #  "popmsa",   "c",     52,   52,
#             # "cmsares",   "n",     53,   54,
#             "statbth",   "c",     55,   56,
#             "statbthr",   "c",     59,   60,
#             # "educ89",   "n",     61,   62,
#             "educ",   "n",     63,   63,
#             "educflag",   "n",     64,   64,
#             "monthdth",   "n",     65,   66,
#             "sex",   "c",     69,   69,
#             "age",   "n",     70,   73,
#             "ageflag",   "n",     74,   74,
#             "ager52",   "n",     75,   76,
#             "ager27",   "n",     77,   78,
#             "ager12",   "n",     79,   80,
#             "ager22",   "n",     81,   82,
#             "placdth",   "n",     83,   83,
#             "marstat",   "c",     84,   84,
#             "weekday",   "n",     85,   85,
#             "year",   "n",    102,  105,
#             "injwork",   "c",    106,  106,
#             "mandeath",   "n",    107,  107,
#             "methdisp",   "c",    108,  108,
#             "autopsy",   "c",    109,  109,
#             "certifier",   "c",    110,  110,
#             "tobacco_use",   "c",    142,  142,
#             "pregnancy_status",  "n",    143,  143,
#             "activity",   "n",    144,  144,
#             "injury",   "n",    145,  145,
#             "ucod",   "c",    146,  149,
#             "ucr358",   "n",    150,  152,
#             "ucr113",   "n",    154,  156,
#             "ucr130",   "n",    157,  159,
#             "ucr39",   "n",    160,  161,
#             "eanum",   "n",    163,  164,
#             "econdp_1",   "n",    165,  165,
#             "econds_1",   "n",    166,  166,
#             "enicon_1",   "c",    167,  170,
#             "econdp_2",   "n",    172,  172,
#             "econds_2",   "n",    173,  173,
#             "enicon_2",   "c",    174,  177,
#             "econdp_3",   "n",    179,  179,
#             "econds_3",   "n",    180,  180,
#             "enicon_3",   "c",    181,  184,
#             "econdp_4",   "n",    186,  186,
#             "econds_4",   "n",    187,  187,
#             "enicon_4",   "c",    188,  191,
#             "econdp_5",   "n",    193,  193,
#             "econds_5",   "n",    194,  194,
#             "enicon_5",   "c",    195,  198,
#             "econdp_6",   "n",    200,  200,
#             "econds_6",   "n",    201,  201,
#             "enicon_6",   "c",    202,  205,
#             "econdp_7",   "n",    207,  207,
#             "econds_7",   "n",    208,  208,
#             "enicon_7",   "c",    209,  212,
#             "econdp_8",   "n",    214,  214,
#             "econds_8",   "n",    215,  215,
#             "enicon_8",   "c",    216,  219,
#             "econdp_9",   "n",    221,  221,
#             "econds_9",   "n",    222,  222,
#             "enicon_9",   "c",    223,  226,
#             "econdp_10",   "n",    228,  228,
#             "econds_10",   "n",    229,  229,
#             "enicon_10",   "c",    230,  233,
#             "econdp_11",   "n",    235,  235,
#             "econds_11",   "n",    236,  236,
#             "enicon_11",   "c",    237,  240,
#             "econdp_12",   "n",    242,  242,
#             "econds_12",   "n",    243,  243,
#             "enicon_12",   "c",    244,  247,
#             "econdp_13",   "n",    249,  249,
#             "econds_13",   "n",    250,  250,
#             "enicon_13",   "c",    251,  254,
#             "econdp_14",   "n",    256,  256,
#             "econds_14",   "n",    257,  257,
#             "enicon_14",   "c",    258,  261,
#             "econdp_15",   "n",    263,  263,
#             "econds_15",   "n",    264,  264,
#             "enicon_15",   "c",    265,  268,
#             "econdp_16",   "n",    270,  270,
#             "econds_16",   "n",    271,  271,
#             "enicon_16",   "c",    272,  275,
#             "econdp_17",   "n",    277,  277,
#             "econds_17",   "n",    278,  278,
#             "enicon_17",   "c",    279,  282,
#             "econdp_18",   "n",    284,  284,
#             "econds_18",   "n",    285,  285,
#             "enicon_18",   "c",    286,  289,
#             "econdp_19",   "n",    291,  291,
#             "econds_19",   "n",    292,  292,
#             "enicon_19",   "c",    293,  296,
#             "econdp_20",   "n",    298,  298,
#             "econds_20",   "n",    299,  299,
#             "enicon_20",   "c",    300,  303,
#             "ranum",   "n",    341,  342,
#             "record_1",   "c",    344,  347,
#             "record_2",   "c",    349,  352,
#             "record_3",   "c",    354,  357,
#             "record_4",   "c",    359,  362,
#             "record_5",   "c",    364,  367,
#             "record_6",   "c",    369,  372,
#             "record_7",   "c",    374,  377,
#             "record_8",   "c",    379,  382,
#             "record_9",   "c",    384,  387,
#             "record_10",   "c",    389,  392,
#             "record_11",   "c",    394,  397,
#             "record_12",   "c",    399,  402,
#             "record_13",   "c",    404,  407,
#             "record_14",   "c",    409,  412,
#             "record_15",   "c",    414,  417,
#             "record_16",   "c",    419,  422,
#             "record_17",   "c",    424,  427,
#             "record_18",   "c",    429,  432,
#             "record_19",   "c",    434,  437,
#             "record_20",   "c",    439,  442,
#             #  "race",   "n",    445,  446,
#             # "brace",   "n",    447,  447,
#             "raceimp",   "n",    448,  448,
#             # "racer3",   "n",    449,  449,
#             # "racer5",   "n",    450,  450,
#             "hispanic",   "n",    484,  486,
#             # "hspanicr",   "n",    488,  488,
#             # "racer40",   "n",    489,  490,
#             "check_white",   "n",    489,  489,
#             "check_black",   "n",    490,  490,
#             "check_aian",    "n",    491,  491,
#             "check_asianindian", "n",    492,  492,
#             "check_chinese",   "n",    493,  493,
#             "check_filipino",   "n",    494,  494,
#             "check_japanese",   "n",    495,  495,
#             "check_korean",   "n",    496,  496,
#             "check_vietnamese",  "n",    497,  497,
#             "check_otherasian",  "n",    498,  498,
#             "check_hawaiian",   "n",    499,  499,
#             "check_guamanian",   "n",    500,  500,
#             "check_samoan",   "n",    501,  501,
#             "check_otherpi",   "n",    502,  502,
#             "check_other",   "n",    503,  503,
#             "racer40",   "n",    804,  805,
#             "occupation",   "c",    806,  809,
#             "occupationr",   "c",    810,  811,
#             "industry",   "c",    812,  815,
#             "industryr",   "c",    816,  817
#         ) %>%
#             mutate(year = 2021)
# )
mcod_fwf_dicts <- bind_rows(
    mcod_fwf_dicts,
    mcod_fwf_dicts %>%
        filter(year == 2020) %>%
        mutate(year = 2021)
)

## Remove racer40 from 2005 to 2011 because the variable exists (i.e., it is
## in the data dictionary) but does not actually contain the values until 2012.
mcod_fwf_dicts <- mcod_fwf_dicts[-which(mcod_fwf_dicts$year < 2012 &
                          mcod_fwf_dicts$name == "racer40"), ]

mcod_fwf_dicts <- mcod_fwf_dicts %>%
    arrange(year, start)

usethis::use_data(mcod_fwf_dicts, overwrite = TRUE)
usethis::use_data(mcod_fwf_dicts, internal = TRUE, overwrite = TRUE)
