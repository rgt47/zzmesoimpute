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
