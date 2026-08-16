# zzmesoimpute Package Review: Gap Analysis

*2026-08-15 16:39 PDT*

Referee-grade review of the R package `zzmesoimpute` 0.0.0.9000
(imputation strategies for below-detection-limit assay data), rooted at
`~/prj/sfw/14-zzmesoimpute/zzmesoimpute`. No earlier dated review exists
in `docs/`; this is the first. Every claim below is tagged with its
epistemic status: verified (ran it, observed output), inspected (read
the source), inferred, or unverified.

Review environment: R 4.6.1 (2026-06-24), aarch64-apple-darwin25.4.0
(macOS, Apple Silicon), host library (renv skipped on host per the
project `.Rprofile`).

## 1. Verdict

**Not ready for CRAN submission**, but close on the mechanical axis and
farther on the documentation axis. `R CMD check --as-cran` (local
macOS): **0 errors, 0 warnings, 2 NOTEs** (verified). The check is
clean because the code that runs is small and well tested, not because
the package is finished. What blocks release:

- A real functional defect class: the censored-lognormal fitter never
  checks optimizer convergence, so degenerate inputs silently produce
  `NaN` imputes (`impute_mle`) and exact-zero imputes
  (`impute_mi_lognormal`) on documented paths (verified, Section 3).
- Release version still `0.0.0.9000`; no `NEWS.md`; LICENSE file is an
  MIT-style stub (`COPYRIGHT HOLDER: Your Name`) under a GPL-3
  declaration (verified).
- No package-level help topic, no vignette, and the two data-ingest
  exports (`read_meso`, `meso_headers`) have no examples and cannot
  have runnable ones until an example export ships in `inst/extdata`
  (verified).

## 2. `R CMD check` and tooling results

### 2.1 rcmdcheck (verified)

Command:
`rcmdcheck::rcmdcheck(path, args = c('--as-cran', '--no-manual'), error_on = 'never')`.
Duration 1m 43.5s. Status: `0 errors | 0 warnings | 2 notes`. All
Suggests (`tinytest`, `writexl`) were installed, so the test suite
including the `read_meso` fixtures ran in full; nothing was skipped
for missing Suggests. Notes verbatim:

1. `checking CRAN incoming feasibility ... NOTE`: 'New submission' and
   'Version contains large components (0.0.0.9000)'.
   Diagnosis: development version string in a release candidate. Fix:
   set `Version: 0.1.0` (or similar) at release; the 'New submission'
   half is informational and unavoidable.
2. `checking for hidden files and directories ... NOTE`: `.zzcollab`
   and `.zzcollab-state` found in the tarball. Diagnosis: zzcollab
   scaffolding not excluded. Fix: add `^\.zzcollab$` and
   `^\.zzcollab-state$` to `.Rbuildignore`.

The check ran the examples and the full tinytest suite
(`Running 'tinytest.R' [5s/16s] OK`); non-ASCII check and
code/documentation mismatch checks passed (verified from the log).

### 2.2 DESCRIPTION and repository hygiene

- `License: GPL-3` in DESCRIPTION, but the root `LICENSE` file is the
  two-line `YEAR:`/`COPYRIGHT HOLDER:` MIT template, with the
  placeholder `Your Name` never filled in (verified by reading the
  file). Because `^LICENSE$` is in `.Rbuildignore` the tarball does
  not carry the contradiction, so the check stays silent, but the
  repository states two different licenses and names a nonexistent
  copyright holder. Fix: delete the stub or replace it with the GPL-3
  text, and keep `License: GPL-3` unmodified.
- `URL` and `BugReports` present and both URLs resolve
  (`urlchecker::url_check()`: 'All URLs are correct!', verified).
- Imports are minimal (`readxl`, `stats`) and every cross-package call
  is `::`-qualified (inspected, all files in `R/`). `writexl` is used
  only in `inst/tinytest/test-read_meso.R` behind a
  `requireNamespace()` guard with `exit_file()` (inspected).
- No `NEWS.md` anywhere in the package root (verified by listing).
- Citation metadata lives only in a root `CITATION.cff`, which is
  `.Rbuildignore`d; there is no `inst/CITATION`, so
  `citation('zzmesoimpute')` will fall back to auto-generated output
  (inspected; the fallback behavior itself is inferred, not run).
- No `Language: en-US` field; `spelling` warned about the default
  (verified).
- `.Rbuildignore` correctly excludes `analysis/`, `docs/`, CI,
  container, and zzcollab configuration files, except the two hidden
  directories noted above (inspected).
- No `.onLoad`/`.onAttach` in the package at all, so no startup-message
  or options-mangling risk (inspected: no such functions in `R/`).
- All files in `R/` end with a trailing newline (verified by a byte
  check) and contain no non-ASCII characters (verified via the check
  log).

### 2.3 Automated tooling

- `covr::package_coverage()`: **94.69%** overall (verified). Per file:
  `utils.R` 76.47%, `censored_normal.R` 83.87%, `read_meso.R` 95.89%,
  all six user-facing function files 100%. The uncovered lines are
  exactly the interesting ones: the `< 2` detected-values error in
  `.fit_censored_lognormal()` (R/censored_normal.R:22-24), the
  `.rmvnorm1()` non-positive-definite fallback
  (R/censored_normal.R:60), several validation branches in
  `R/utils.R`, and the whole `keep_unmapped = TRUE` branch of
  `read_meso()` (R/read_meso.R:167-169), a documented feature with
  zero test coverage.
- `lintr::lint_package()`: 63 lints (verified). In `R/` only three: two
  `object_usage_linter` warnings in `R/impute_ros.R:63-64` ('yd',
  'pp_det' assigned but may not be used), which are false positives
  caused by the variables being used inside the `lm(yd ~
  stats::qnorm(pp_det))` formula (inspected), and one indentation lint
  at `R/impute_substitution.R:27`. The remaining 60 are
  `indentation_linter` style complaints in `inst/tinytest/` and one
  `infix_spaces_linter` in `tests/tinytest.R`. Nothing substantive.
- `spelling::spell_check_package()`: ran, en-US default (verified).
  Mostly domain jargon (MSD, LOD, ROS, Helsel, Cohn), but it caught
  genuine British spellings in user-facing documentation: 'Analyse'
  (impute_mi_lognormal.Rd:46), 'analysed' (README.md:44), 'labelling'
  (meso_default_map.Rd:20). The internal roxygen in
  `R/censored_normal.R:4,13` also has 'Maximises' and 'optimiser'
  (verified by grep). These violate the project's US-English standard.
  Add `inst/WORDLIST` for the legitimate jargon and fix the variants.
- `codetools::checkUsagePackage(all = TRUE)`: only benign findings
  (verified): unused `e` parameters in `tryCatch` handlers, `lod`/`m`
  'changed by assignment' (deliberate recycling/coercion), and the two
  `impute_ros` formula false positives. No
  'no visible binding for global variable' findings.
- `goodpractice::gp()`: **not run**; the package is not installed in
  this library and was not installed per the review's
  no-heavy-installs rule.

## 3. Functional bugs

These are defects on documented paths. All were reproduced by running
the installed package (verified) unless noted.

### 3.1 No convergence check on the censored-lognormal fit (the worst finding)

`.fit_censored_lognormal()` (R/censored_normal.R:39-44) returns
`fit$convergence` but **no caller ever examines it**, and there is no
guard against a degenerate fit. With two identical detected values
(`sd(yd) == 0`, a perfectly plausible occurrence with assay data
rounded at low concentrations):

```r
zzmesoimpute:::.fit_censored_lognormal(c(2, 2, NA, NA), rep(1, 4),
  c(FALSE, FALSE, TRUE, TRUE))
# $mu = -727, $sigma = 9e+125, $convergence = 1 (NOT converged),
# $vcov = NULL   (verified)
```

Consequences, both silent:

- `impute_mle(c(2, 2, NA, NA), lod = 1)` returns `c(2, 2, NaN, NaN)`
  with no error or warning (verified). The `@return` promises
  'censored entries replaced by their conditional means'.
- `impute_mi_lognormal(c(2, 2, NA, NA), lod = 1, m = 3, seed = 1)`
  returns three identical completions `c(2, 2, 0, 0)` (verified):
  imputed concentrations of exactly zero, where the documentation and
  the package's own test invariant promise draws in `(0, lod)`, and
  where a downstream `log()` produces `-Inf`.

Fix: after `optim()`, stop (or at minimum warn) when
`convergence != 0`, and validate that the fitted `sigma` is finite and
positive. The `d < 2` guard at R/censored_normal.R:21 is necessary but
not sufficient; `d >= 2` with zero spread still explodes.

### 3.2 Proper MI silently degrades to improper MI

`impute_mi_lognormal()` sets
`use_unc <- isTRUE(param_uncertainty) && !is.null(fit$vcov)`
(R/impute_mi.R:53). When the Hessian is singular, `vcov` is `NULL` and
the function silently conditions on the MLE, changing the statistical
meaning of the call (between-imputation variance is understated, so
Rubin's-rules intervals are too narrow) without any warning (inspected;
the degenerate case in 3.1, where all completions were identical, is a
verified instance). `.rmvnorm1()` has the same silent fallback to the
mean when `chol()` fails (R/censored_normal.R:58-61, inspected). Both
downgrades should at least `warning()`.

### 3.3 No positivity validation of detected values

The docs for `impute_mle` and `impute_ros` say `x` 'must be positive
where detected', but nothing checks it:

- A detected `0` yields `Error: non-finite value supplied by optim`,
  an opaque internal error that names neither the argument nor the fix
  (verified).
- A detected negative value first emits `NaNs produced` warnings from
  `log()`, then the same optim error (verified).

Fix: in `.validate_censor_args()` (or the model-based imputers), check
`all(x[!censored] > 0)` and produce a named, actionable error.

### 3.4 `m` is silently truncated despite the error message

`impute_mi_lognormal(..., m = 2.7)` passes validation and returns 2
completions (verified). The validation message at R/impute_mi.R:42
claims '`m` must be a single positive integer', but non-integers are
accepted and truncated by `as.integer()`. Either reject non-integers
or round-and-warn; do not truncate silently.

### 3.5 `seed` arguments mutate global RNG state

`impute_uniform(..., seed = )` and `impute_mi_lognormal(..., seed = )`
call `set.seed(seed)` (R/impute_uniform.R:27, R/impute_mi.R:45),
overwriting the caller's `.Random.seed` without restoration (verified:
global `.Random.seed` differs after a seeded call). A user who
`set.seed(123)` for a session-level analysis and then calls
`impute_uniform(..., seed = 99)` has their RNG stream silently
replaced. CRAN policy also discourages `set.seed()` inside package
code. Fix: save `.Random.seed` and restore it via
`on.exit(add = TRUE)`, or drop the `seed` arguments and document that
callers should seed.

### 3.6 `impute_ros` cap engages silently and produces at-limit ties

With few detected values, the fitted line can put all censored fills
above the limit; `pmin(fill, dl)` (R/impute_ros.R:70) then imputes
every censored entry as exactly `lod`:

```r
impute_ros(c(NA, 5, NA, 7, NA), lod = 2)
# [1] 2 5 2 7 2   (verified)
```

The `@return` says fills are 'each below the detection limit'; here
they equal it, tied, with no warning. For 'below detection' data an
at-limit impute is a distinctly non-conservative outcome. Warn when
the cap engages (the same applies, less severely, to the `pmin(em,
lod)` cap in `impute_mle`, whose docs say 'capped below `lod`' when
the cap is at `lod`; inspected).

### 3.7 `read_meso` silent column truncation (edge, unverified)

`n_use <- min(ncol(dat), length(labels))` (R/read_meso.R:135) silently
drops trailing data columns if the second (skip-based) read is wider
than the header read. I did not construct a triggering file; flagged
as an inspected risk, not a verified defect. A `warning()` when
`ncol(dat) != length(labels)` would cost nothing.

## 4. Help system

Counts (verified against `NAMESPACE` and `man/`):

- Exports: **9** (`impute_substitution`, `impute_uniform`,
  `impute_ros`, `impute_mle`, `impute_mi_lognormal`, `read_meso`,
  `meso_headers`, `meso_default_map`, `meso_required_cols`).
- Documented: 9 of 9; `@param` coverage matches formals (verified via
  the check's code/documentation mismatch pass plus reading all nine
  roxygen blocks).
- With `@examples`: **7 of 9**. Missing: `read_meso` and
  `meso_headers`, the entire ingest front end. Root cause: no example
  `.xlsx` ships with the package (`inst/` contains only `tinytest/`,
  verified). Ship a small synthetic export in `inst/extdata` (the test
  fixtures already know how to build one) and write examples against
  it.
- With a substantive `@return`: 9 of 9; returns describe element
  types and lengths, not bare classes (inspected). `read_meso`'s
  return could name the canonical columns explicitly rather than
  pointing at `meso_required_cols()`, but it is usable.
- `@seealso` cross-links: **7 of 9**. `impute_substitution` and
  `impute_uniform` are island topics (verified by grep); a user
  landing there is never pointed to the better methods, which is
  exactly the comparison this package exists to enable.
- Doc-vs-code mismatches found: 4. (a) `impute_mle` 'capped below
  `lod`' vs `pmin(em, lod)` capping at `lod` (inspected); (b)
  `impute_ros` 'each below the detection limit' vs verified at-limit
  fills (Section 3.6); (c) `impute_mi_lognormal` implies draws inside
  `(0, lod)` vs verified exact-zero imputes (Section 3.1); (d) the
  README's method table cites Cohen (1959) for `impute_mle` while the
  Rd cites only Helsel (2012); Cohen appears nowhere in the package
  documentation (verified by grep).

Front door and long-form docs:

- **No package-level topic**: no `_PACKAGE` roxygen block, so
  `?zzmesoimpute` resolves to nothing (verified: no
  `zzmesoimpute-package.Rd` in `man/`). This is the single cheapest
  documentation fix with the highest payoff.
- `README.md` exists, is generated from `README.Rmd`, and is good: it
  states the censoring framing, tabulates the five strategies with
  references, and shows a worked example. The example runs verbatim
  and reproduces the README's printed output exactly, including the
  seeded draws (verified, Section 5).
- **No vignettes**: `vignettes/` is an empty directory (verified). The
  DESCRIPTION's headline claim, benchmarking the incumbent lab method
  against censored-data methods, is never demonstrated end to end
  anywhere in the package; the README defers to an external companion
  compendium. A single 'from MSD export to Rubin-combined estimate'
  vignette covering `read_meso()` through `impute_mi_lognormal()`
  would close the largest gap. As it stands the ingest-to-imputation
  hand-off (deriving `censored` from `detection_range`, `lod` from
  `calc_low`) is documented nowhere.
- Orphan exports (no example and no vignette coverage): `read_meso`,
  `meso_headers`. Every other export has a runnable example (verified
  by the check's example run).

## 5. User interface

### 5.1 First-use walkthrough (verified, run verbatim from the README)

```r
library(zzmesoimpute)
x        <- c(5.2, NA, 3.1, NA, 8.4, 2.7)
censored <- is.na(x)
impute_substitution(x, lod = 1.5, censored = censored, fraction = 0.5)
#> [1] 5.20 0.75 3.10 0.75 8.40 2.70
impute_uniform(x, lod = 1.5, censored = censored, seed = 1)
#> [1] 5.2000000 0.3982630 3.1000000 0.5581858 8.4000000 2.7000000
impute_mle(x, lod = 1.5, censored = censored)
#> [1] 5.200000 0.948786 3.100000 0.948786 8.400000 2.700000
completions <- impute_mi_lognormal(x, lod = 1.5, censored = censored,
                                   m = 5, seed = 1)
length(completions)
#> [1] 5
```

Four lines to a first real result; every printed value matched the
README byte for byte, including the stochastic ones (verified). No
guessing and no source-reading was needed for the imputation half.
The friction is entirely on the ingest half: a first-time user with an
MSD export has no example file, no example code, and no documented
recipe for turning `read_meso()` output (`calc_conc`, `calc_low`,
`detection_range`) into the `x`/`lod`/`censored` triple the imputers
want. That bridge exists only in the author's head and the companion
compendium.

### 5.2 Findings

Strengths, tersely: the five imputers share the exact signature
`impute_*(x, lod, censored, ...)` with identical first-argument
semantics, so the API is pipe-friendly and swap-one-symbol
benchmarkable; no function takes `...`, so a misspelled argument
(`sed = 1`) fails loudly with `unused argument` (verified); returns
are type-stable (single imputers always a numeric vector,
`impute_mi_lognormal` always a list of `m`, even with zero censoring;
verified); validation errors name the offending argument and the rule
(`` `lod` must have length 1 or length(x).``, verified); the
`meso_headers()` / `meso_default_map()` / `col_map` override design is
a genuinely good escape hatch for vendor format drift.

Weaknesses:

- **`censored = is.na(x)` default is a trap for the package's own
  target data.** MSD exports flag below-range wells in
  `detection_range` while `calc_conc` can be `NaN` or a number;
  only `impute_uniform`'s docs warn to pass the explicit indicator
  (inspected). The other four imputers repeat the default without the
  warning. Since the default silently changes which observations get
  imputed, either document the hazard on every imputer or provide the
  missing helper (e.g. something that derives `censored` and `lod`
  from a `read_meso()` frame), which would also fix the walkthrough
  gap in 5.1.
- Silent surprises catalogued in Section 3 (NaN/zero imputes, MI
  downgrade, cap engagement, `m` truncation, RNG clobbering) are all
  UI defects in the sense that matters: the user gets no signal.
- Error quality is good at the validation layer but collapses past it:
  `non-finite value supplied by optim` (Section 3.3) is the kind of
  message the entry point exists to prevent.
- Naming: `impute_mi_lognormal` breaks the otherwise uniform
  `impute_<strategy>` pattern by encoding the distribution; `impute_mle`
  is also lognormal but does not say so. Either both or neither should
  carry the suffix. Cheap to fix now, breaking later.
- Discoverability is otherwise good: two prefix families (`impute_*`,
  `meso_*`/`read_meso`), no internals exported, no print methods to
  audit (no S3 classes at all, inspected).

## 6. Coding practices

Checked and found sound (inspected across all of `R/`, plus the
verified check log):

- Assignment is uniformly `<-`; no `T`/`F`; `seq_len()`/`seq_along()`
  throughout; `vapply()` with type templates, no `sapply()`; `drop =
  FALSE` on the one matrix-style subset (R/read_meso.R:136); no
  `library()`/`require()` in `R/`; no `options()`/`par()` calls; all
  `stats::` and `readxl::` calls namespaced; errors use explicit
  `stop(..., call. = FALSE)` rather than bare `stopifnot()`; shared
  validation is centralized in `.validate_censor_args()`
  (R/utils.R:13) and called at every imputer entry point.
- No S3 methods exist, so no registration issues; no `class(x) ==`
  comparisons (inspected).
- No performance smells at current scale: no `rbind` growth, the only
  loops are over `m` imputations and header rows; `read_meso`'s
  per-column `grepl` scan is linear in columns (inspected; performance
  on large files unverified).

Findings:

- `set.seed()` in package code, twice (R/impute_uniform.R:27,
  R/impute_mi.R:45), without state restoration; Section 3.5. This is
  the one clear idiom violation.
- Missing convergence/positivity guards (Sections 3.1, 3.3) are
  validation-completeness defects in `R/censored_normal.R:39` and
  `R/utils.R:13`.
- `suppressMessages()` around both `readxl::read_excel()` calls
  (R/read_meso.R:83, 123, 129) also suppresses legitimate readxl
  coercion messages; consider narrowing (inspected; low priority).

Tests: behavioral, not merely structural. They assert statistical
invariants (proper MI has at least the between-imputation variance of
improper MI; ROS beats LOD/2 on mean recovery; MLE recovers the true
lognormal parameters within tolerance), reproducibility under seeds,
error paths, and per-element `lod` handling. Internals are correctly
accessed via `zzmesoimpute:::` (inst/tinytest/test-impute_mle.R:26), so
the suite passes under `R CMD check`, verified, not just `load_all()`.
Gaps: no test for `keep_unmapped = TRUE` (zero coverage,
R/read_meso.R:167-169), none for the degenerate-fit inputs of Section
3.1, none for `.rmvnorm1`'s fallback, and `test-basic.R` is a
placeholder `expect_true(TRUE)`.

## 7. Prioritized checklist

(a) CRAN blockers

- Add `^\.zzcollab$` and `^\.zzcollab-state$` to `.Rbuildignore`
  (clears NOTE 2).
- Set a release version (e.g. 0.1.0) and add `NEWS.md`.
- Resolve the LICENSE stub: remove it or replace with GPL-3 text;
  never ship `COPYRIGHT HOLDER: Your Name` in any form.
- Add a `_PACKAGE` roxygen block so `?zzmesoimpute` works.
- Add `Language: en-US` to DESCRIPTION and an `inst/WORDLIST`; fix
  'Analyse', 'analysed', 'labelling', 'Maximises', 'optimiser'.
- Run win-builder and R-hub (R-devel) before submitting; nothing
  non-portable was observed, but only macOS/R 4.6.1 was exercised.

(b) Bugs to fix before anyone depends on the behavior

- Check `optim` convergence and fitted-parameter sanity in
  `.fit_censored_lognormal()`; make `impute_mle` and
  `impute_mi_lognormal` error instead of returning `NaN`/`0`
  (Section 3.1).
- Warn on the proper-to-improper MI downgrade and the `.rmvnorm1`
  mean fallback (3.2).
- Validate positivity of detected `x` at entry (3.3).
- Reject or round-with-warning non-integer `m` (3.4).
- Stop clobbering global RNG state from `seed` arguments (3.5).
- Warn when the `lod` cap engages in `impute_ros`/`impute_mle`, and
  align the `@return` wording with the actual cap semantics (3.6).
- Warn on header/data column-count mismatch in `read_meso` (3.7).

(c) Documentation completion

- Ship a synthetic MSD export in `inst/extdata`; add `@examples` to
  `read_meso()` and `meso_headers()`.
- Write the end-to-end vignette (export -> `read_meso` -> derive
  `censored`/`lod` -> impute -> combine), which is also the only place
  the DESCRIPTION's benchmarking claim can be demonstrated.
- Add `@seealso` (or `@family imputation strategies`) to
  `impute_substitution` and `impute_uniform`.
- Reconcile the README's Cohen (1959) citation with the Rd references;
  move citation metadata into `inst/CITATION`.
- Document the `censored = is.na(x)` hazard on all five imputers, not
  just `impute_uniform`.

(d) Design decisions best made before first release (breaking later)

- Naming: `impute_mi_lognormal` vs `impute_mle`; encode the
  distributional assumption in both names or neither.
- The `seed` argument pattern: keep (with save/restore) or drop in
  favor of caller-managed seeding; decide once, uniformly.
- Whether `impute_ros`'s at-limit capping and `impute_mi`'s silent
  improper fallback should be errors rather than warnings.
- Whether to add the `read_meso`-to-imputer bridge helper; adding it
  later will reshape the recommended workflow.
- `test-basic.R` placeholder: delete or repurpose.

## 8. Not evaluated

- Platforms: win-builder, R-hub, R-devel, older R (back to the
  declared 4.1.0), Windows, Linux, and the project's own Docker
  container were not exercised. All results are from macOS ARM64,
  R 4.6.1, host library.
- `goodpractice::gp()`: not installed, not run.
- PDF manual build (`--no-manual` was passed); Rd->PDF rendering
  unverified.
- Vignette rendering: nothing to render (none exist).
- `read_meso()` against real MSD exports: only the synthetic fixtures
  in the test suite were exercised; behavior on genuine vendor files,
  multi-sheet workbooks, and large files is unverified, as is the
  column-truncation edge in Section 3.7.
- `keep_unmapped = TRUE` path of `read_meso()`: never executed by any
  test or by this review.
- Performance at scale (large plates, large `m`): unverified.
- The `impute_mle` at-limit cap engaging on real data: the probe drew
  no qualifying sample; behavior inferred from the ROS analogue and
  code reading, not observed.
- The companion compendium `zzmesoimputepaper` and everything under
  `analysis/`: out of scope, not reviewed.
