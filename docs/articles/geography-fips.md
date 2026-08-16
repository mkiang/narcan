# Harmonizing geography with FIPS

County identifiers are not stable across data years. New counties
appear, a few merge or are renamed, and – more disruptively – NCHS does
not encode state the same way in every era. Public
multiple-cause-of-death (MCOD) files use NCHS numeric state codes
through 2002 and 2-letter postal abbreviations from 2003 on, and the
numeric schemes overlap while meaning different states (NCHS `"06"` is
Colorado; FIPS `"06"` is California).
[`add_county_fips()`](https://mkiang.github.io/narcan/reference/add_county_fips.md)
translates whichever scheme a file uses into one 5-digit `county_fips`
that is comparable across years.

**Public-data caveat.** Public-use MCOD carries state and county
geography only through **2004**. From 2005 on, any sub-national analysis
requires the restricted NCHS All-County files. Every example below
therefore uses data years **1999-2004**, and nothing here works for
later years without the restricted data.

All data here are small synthetic frames plus bundled narcan crosswalks
(`st_fips_map`, `ihme_fips`); no chunk downloads anything and no
restricted NCHS records are used.

[`library`](https://rdrr.io/r/base/library.html)`(`[`narcan`](https://github.com/mkiang/narcan)`)`

## `state_abbrev_to_fips()` – one column at a time

The simplest helper maps a postal abbreviation to its zero-padded
2-digit state FIPS. Pair the input with the output to see the mapping:

`abbrevs`` ``<-`` `[`c`](https://rdrr.io/r/base/c.html)`(``"CA"``, ``"NY"``, ``"TX"``, ``"PA"``)`` `[`data.frame`](https://rdrr.io/r/base/data.frame.html)`(``abbrev ``=`` ``abbrevs``, state_fips ``=`` `[`state_abbrev_to_fips`](https://mkiang.github.io/narcan/reference/state_abbrev_to_fips.md)`(``abbrevs``)``)`` ``#> abbrev state_fips`` ``#> 1 CA 06`` ``#> 2 NY 36`` ``#> 3 TX 48`` ``#> 4 PA 42`

`"CA"` becomes `"06"`, not `"6"` – the zero-padding is what lets the
result feed a FIPS-keyed join. Unrecognized abbreviations and the
foreign/unknown code `"ZZ"` return `NA` (with a warning) rather than
passing through unconverted.

## `add_county_fips()` – the core call

Feed
[`add_county_fips()`](https://mkiang.github.io/narcan/reference/add_county_fips.md)
the raw county column as **character** (`countyrs` for county of
residence, `countyoc` for occurrence). A numeric column is refused,
because numeric input has already dropped the leading zero (`01001`
reads as `1001`, whose first two digits parse as a different state).
Pass `year` – a scalar or a `year` column – so the coding scheme is
chosen deterministically.

### Both halves of the code change, not just the state

The state prefix is the obvious half. The county half is the one that
bites.

Before 2003 the last three digits of `countyrs` are the county’s
**alphabetical rank within its state**, not its FIPS code. NCHS `05019`
is Los Angeles; FIPS `06019` is Fresno. Translating the state prefix and
keeping the rank produces a code that looks like a county and is not the
right one, for about 97% of pre-2003 records, with no error and no `NA`.

The raw record settles it. From data year 1982 the MCOD file carries a
genuine FIPS geography block next to the NCHS one – `fipsctyr` for
residence and `fipsctyo` for occurrence, each a complete 5-digit state +
county – and
[`import_mcod_fwf()`](https://mkiang.github.io/narcan/reference/import_mcod_fwf.md)
reads both. When you pass `countyrs` for a pre-2003 year and `fipsctyr`
is present,
[`add_county_fips()`](https://mkiang.github.io/narcan/reference/add_county_fips.md)
takes the geography from it.

Start with a small synthetic frame that straddles the 2002/2003
boundary, shaped the way
[`import_mcod_fwf()`](https://mkiang.github.io/narcan/reference/import_mcod_fwf.md)
returns one. The 1999-2002 rows carry NCHS numeric state codes plus the
record’s own FIPS county; the 2003-2004 rows carry postal abbreviations
and a county half that is already FIPS, so they need no companion
column:

`deaths`` ``<-`` ``tibble``::`[`tibble`](https://tibble.tidyverse.org/reference/tibble.html)`(`` `` id ``=`` ``1``:``5``,`` `` year ``=`` `[`c`](https://rdrr.io/r/base/c.html)`(``1999L``, ``2001L``, ``2002L``, ``2003L``, ``2004L``)``,`` `` countyrs ``=`` `[`c`](https://rdrr.io/r/base/c.html)`(``"05019"``, ``"33031"``, ``"44057"``, ``"CA075"``, ``"TX201"``)``,`` `` fipsctyr ``=`` `[`c`](https://rdrr.io/r/base/c.html)`(``"06037"``, ``"36061"``, ``"48113"``, ``NA``, ``NA``)`` ``)`` ``deaths`` ``#> ``# A tibble: 5 × 4`` ``#> id year countyrs fipsctyr`` ``#> ``<int>`` ``<int>`` ``<chr>`` ``<chr>`` `` ``#> ``1`` 1 ``1``999 05019 06037 `` ``#> ``2`` 2 ``2``001 33031 36061 `` ``#> ``3`` 3 ``2``002 44057 48113 `` ``#> ``4`` 4 ``2``003 CA075 ``NA`` `` ``#> ``5`` 5 ``2``004 TX201 ``NA`

Now harmonize. The call adds four columns – `state_substr` and
`county_substr` (the two halves actually decoded), `st_fips` (2-digit
state) and `county_fips` (5-digit state + county) – decoding each row
under its own era’s scheme. It also reports, once per session, that it
took the pre-2003 geography from `fipsctyr`; that notice appears in the
output below:

`harmonized`` ``<-`` `[`add_county_fips`](https://mkiang.github.io/narcan/reference/add_county_fips.md)`(``deaths``, ``countyrs``)`` ``` #> add_county_fips(): sourced pre-2003 county geography from `fipsctyr` for 3 row(s). The `countyrs` county digits are an alphabetical rank, not FIPS. This message is shown once per session; wrap the call in suppressMessages() to silence it. ``` ``#> ``This message is displayed once per session.`` ``harmonized``[`[`c`](https://rdrr.io/r/base/c.html)`(``"id"``, ``"year"``, ``"countyrs"``, ``"st_fips"``, ``"county_fips"``)``]`` ``#> ``# A tibble: 5 × 5`` ``#> id year countyrs st_fips county_fips`` ``#> ``<int>`` ``<int>`` ``<chr>`` ``<chr>`` ``<chr>`` `` ``#> ``1`` 1 ``1``999 05019 06 06037 `` ``#> ``2`` 2 ``2``001 33031 36 36061 `` ``#> ``3`` 3 ``2``002 44057 48 48113 `` ``#> ``4`` 4 ``2``003 CA075 06 06075 `` ``#> ``5`` 5 ``2``004 TX201 48 48201`

Read the before/after together. Row 1’s raw `countyrs` is `"05019"`:
NCHS state `05` is California, and `019` is the nineteenth California
county alphabetically – Los Angeles. The answer is `"06037"`, taken from
`fipsctyr`. Had the rank been carried through, the result would have
been `"06019"`, which is a real county (Fresno) and the wrong one. In
2003 California enters instead through the abbreviation `"CA"`, giving
`"06075"`, and no companion column is needed because the county half is
already FIPS. Codes that cannot be placed – `"ZZ"` foreign residence,
FIPS state `"00"`, a county masked to `"999"` on the public file, or a
territory code such as NCHS `"62"`, which narcan does not cover – yield
`NA` in `st_fips`/`county_fips` rather than a spurious string. The
`state_substr` and `county_substr` columns keep the literal code, so you
can still count how much of a public extract is masked.

Note also that `county_substr` reads `"037"`, not the `"019"` in the
input: on a row sourced this way, both halves come from `fipsctyr`. The
same is true of the other two pre-2003 rows – in every one of them the
county digits change, which is the point. A rank and a FIPS county code
agree only when a county’s alphabetical position happens to equal its
FIPS number, and since FIPS county codes step by two (001, 003, 005 …)
while ranks step by one, that happens only at rank `001` – the first
county alphabetically in each state. Roughly 97% of pre-2003 records got
a wrong county from the old code.

If you are working with a frame that has no `fipsctyr`/`fipsctyo` – a
hand-built extract, say –
[`add_county_fips()`](https://mkiang.github.io/narcan/reference/add_county_fips.md)
reports the opposite thing, once per session: that the county half is a
rank and the result is not usable for county-level work.
`use_fips_cols = "no"` restores the old behavior but does **not** buy
you silence; it swaps the first notice for the second, because the
returned county is then the one the notice is warning about. Use
[`suppressMessages()`](https://rdrr.io/r/base/message.html) if you want
a quiet call. Data years 1979-1981 are the one span with no remedy at
all – no FIPS county was recorded, so the true county cannot be
recovered from the file and only `st_fips` is usable. Those years report
it too – but both notices share one once-per-session identifier, so if
an earlier call in the same session already raised the rank notice, a
later 1979-1981 frame will be silent. Do not rely on the message to tell
you which years you are looking at; check the data years.

Neither notice depends on `scheme`. That argument selects how the
*state* half is decoded; `use_fips_cols` selects where the *county* half
comes from. Pinning `scheme = "nchs"` on 1999 data still sources the
county from `fipsctyr`.

## The bundled crosswalks

Both helpers read `st_fips_map`, which lines up state name, postal
abbreviation, FIPS code, and NCHS code so the two numeric schemes can be
told apart:

[`head`](https://rdrr.io/r/utils/head.html)`(``st_fips_map``)`` ``#> ``# A tibble: 6 × 4`` ``#> name abbrev fips nchs`` ``#> ``<chr>`` ``<chr>`` ``<dbl>`` ``<dbl>`` ``#> ``1`` Alabama AL 1 1`` ``#> ``2`` Alaska AK 2 2`` ``#> ``3`` Arizona AZ 4 3`` ``#> ``4`` Arkansas AR 5 4`` ``#> ``5`` California CA 6 5`` ``#> ``6`` Colorado CO 8 6`

`ihme_fips` handles the other half of the problem – counties that split,
merge, or are renamed over a long series. It collapses unstable
`orig_fips` codes to a temporally stable `ihme_fips` (from
Dwyer-Lindgren et al., JAMA 2016), so a county can be compared across
periods:

[`head`](https://rdrr.io/r/utils/head.html)`(``ihme_fips``)`` ``#> state group orig_fips ihme_fips`` ``#> 1 Alaska 1 02158 02158`` ``#> 2 Alaska 1 02270 02158`` ``#> 3 Alaska 2 02140 02188`` ``#> 4 Alaska 2 02188 02188`` ``#> 5 Alaska 3 02010 02013`` ``#> 6 Alaska 3 02013 02013`

For a multi-year county analysis, remap `county_fips` through
`ihme_fips` before comparing – several Alaska areas and Virginia
independent cities are otherwise not comparable across the 1999-2004
window.

## From FIPS to denominators

Once `county_fips` or a `state_fips` column exists, it is the join key
for sub-national denominators.
[`add_county_fips()`](https://mkiang.github.io/narcan/reference/add_county_fips.md)
names its state column `st_fips`;
[`add_pop_counts()`](https://mkiang.github.io/narcan/reference/add_pop_counts.md)
keys on `state_fips`, so rename `st_fips` to `state_fips` for a state
join, or use the 5-digit `county_fips` directly for a county join (see
the companion
[`vignette("population-denominators")`](https://mkiang.github.io/narcan/articles/population-denominators.md)).
As above, this path is only valid for **1999-2004** public data – 2005+
sub-national denominators require the restricted NCHS All-County files.

## See also

- [`vignette("population-denominators")`](https://mkiang.github.io/narcan/articles/population-denominators.md)
  – sub-national denominators use these FIPS-harmonized geographies as
  their join key.
- [`vignette("getting-started")`](https://mkiang.github.io/narcan/articles/getting-started.md)
  – the package overview and where this vignette fits in the pipeline.
