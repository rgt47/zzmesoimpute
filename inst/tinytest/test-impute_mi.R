# Tests for impute_mi_lognormal(): proper multiple imputation.

library(zzmesoimpute)

set.seed(7)
truth <- rlnorm(300, 0, 1)
lod <- 0.6
cens <- truth < lod
x <- truth
x[cens] <- NA

imps <- impute_mi_lognormal(x, lod = lod, censored = cens, m = 10, seed = 1)

# Returns m completed vectors.
expect_equal(length(imps), 10L)
expect_true(all(vapply(imps, length, integer(1)) == length(x)))

# Detected values unchanged in every completion.
expect_true(all(vapply(imps, function(v) {
  isTRUE(all.equal(v[!cens], truth[!cens]))
}, logical(1))), info = "detected entries carried through")

# Censored draws fall below the detection limit.
expect_true(all(vapply(imps, function(v) all(v[cens] < lod & v[cens] > 0),
  logical(1))), info = "imputed draws lie in (0, lod)")

# Reproducible under a fixed seed.
again <- impute_mi_lognormal(x, lod = lod, censored = cens, m = 10, seed = 1)
expect_identical(imps, again, info = "same seed reproduces draws")

# Different completions actually differ (stochastic imputation).
expect_false(isTRUE(all.equal(imps[[1]][cens], imps[[2]][cens])),
  info = "completions are not identical")

# Proper MI (param uncertainty) has at least as much between-imputation
# spread as improper MI conditioned on the MLE.
set.seed(11)
proper <- impute_mi_lognormal(x, lod = lod, censored = cens, m = 40,
  seed = 2, param_uncertainty = TRUE)
improper <- impute_mi_lognormal(x, lod = lod, censored = cens, m = 40,
  seed = 2, param_uncertainty = FALSE)
cens_mean <- function(lst) vapply(lst, function(v) mean(v[cens]), numeric(1))
expect_true(stats::var(cens_mean(proper)) >= stats::var(cens_mean(improper)),
  info = "parameter uncertainty widens between-imputation variance")

# Input validation.
expect_error(impute_mi_lognormal(x, lod = lod, censored = cens, m = 0),
  info = "m < 1 errors")

# No censoring: m copies of x.
flat <- impute_mi_lognormal(c(1, 2, 3), lod = 0.5,
  censored = c(FALSE, FALSE, FALSE), m = 3)
expect_equal(length(flat), 3L)
expect_equal(flat[[1]], c(1, 2, 3))
