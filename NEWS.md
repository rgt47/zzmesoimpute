# zzmesoimpute 0.2.0

## Correctness fixes

* **`impute_uniform()` and `impute_mi_lognormal()` no longer reposition
  the caller's random stream.** Both called `set.seed()` directly, which
  writes `.Random.seed` in the global environment. Supplying `seed`
  therefore made the imputation reproducible at the cost of silently
  changing every random draw the user made afterwards, including in a
  script that had set its own seed. Both now seed and restore around
  the draw, so `seed` still reproduces a call and nothing leaks.

* **A censored-lognormal fit that failed to converge was used without
  comment.** `.fit_censored_lognormal()` recorded `optim()`'s
  convergence code and nothing ever read it. Non-convergence is not
  rare in the sparse-detection regime this package exists to serve:
  with 50 observations and 2 detected, `optim()` reported failure in 98
  of 150 simulated datasets. `impute_mle()` and `impute_mi_lognormal()`
  now warn.

* **`impute_mle()` could return `NaN` concentrations.** Two identical
  detected values drive the fit to mu = -258.8, sigma = 158.9, where
  `exp(mu + sigma^2/2)` overflows and `Inf * 0` gives `NaN`. The
  imputed vector was returned as though it were data. Non-finite
  conditional means are now an error naming the fitted parameters.
  `impute_mi_lognormal()` checks its completions the same way.

* **Proper multiple imputation could silently become improper.**
  `.rmvnorm1()` returned the mean vector when the parameter covariance
  was not positive definite, which looks like a draw but carries no
  variability, and `impute_mi_lognormal()` also dropped to conditioning
  on the MLE whenever `vcov` was `NULL`. Either path leaves the
  completions sharing one parameter value, so the between-imputation
  variance omits estimation uncertainty and Rubin's rules report
  intervals that are too narrow. `.rmvnorm1()` now returns `NULL` to
  signal the failure and both fallbacks warn.

## Tests

* `test-basic.R` held a single `expect_true(TRUE)`. It now checks, for
  every strategy, that detected values are untouched, that imputed
  values land in `(0, lod]`, that results are finite, and that an
  uncensored input is returned unchanged; and that the multiple
  imputation returns `m` distinct completions.
* New `test-rng-and-convergence.R` covers the four fixes above.
* Suite grows from 77 assertions to 126.

# zzmesoimpute 0.1.0

First release. Imputation strategies for left-censored (below limit of
detection) concentrations from multiplexed immunoassays such as Meso
Scale Discovery.

## Imputation strategies

All five share a common interface, so that they can be substituted for
one another when benchmarking.

* `impute_substitution()` for the simple substitution rules.
* `impute_uniform()` for uniform draws below the detection limit.
* `impute_ros()` for regression on order statistics.
* `impute_mle()` for censored maximum likelihood.
* `impute_mi_lognormal()` for multiple imputation under a lognormal
  model.

## Reading assay data

* `read_meso()` reads a Meso Scale Discovery export.
* `meso_headers()`, `meso_default_map()`, and `meso_required_cols()`
  describe and map the expected columns.
