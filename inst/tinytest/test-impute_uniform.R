# Tests for impute_uniform(): uniform-draw imputation on (0, LOD).

library(zzmesoimpute)

x <- c(5.2, NA, 3.1, NA, 0.8)
lod <- 1.5

res <- impute_uniform(x, lod = lod, seed = 1)

# Observed values are untouched.
expect_equal(res[c(1, 3, 5)], x[c(1, 3, 5)],
  info = "non-censored entries are returned unchanged")

# Censored draws land strictly inside (0, lod).
imp <- res[c(2, 4)]
expect_true(all(imp > 0 & imp < lod),
  info = "imputed values fall in the open interval (0, lod)")

# Reproducible under a fixed seed; varies without one.
expect_identical(
  impute_uniform(x, lod = lod, seed = 1),
  impute_uniform(x, lod = lod, seed = 1),
  info = "same seed yields identical draws"
)

# Output length and type.
expect_equal(length(res), length(x))
expect_true(is.numeric(res))

# Per-element lod vector is honoured.
lod_vec <- c(1, 2, 3, 4, 5)
res_vec <- impute_uniform(rep(NA_real_, 5), lod = lod_vec, seed = 2)
expect_true(all(res_vec > 0 & res_vec < lod_vec),
  info = "vector lod applied element-wise")

# Explicit censoring indicator overrides is.na default.
xx <- c(0.4, 5.0, 0.2)
cens <- c(TRUE, FALSE, TRUE)
res_c <- impute_uniform(xx, lod = 1, censored = cens, seed = 3)
expect_equal(res_c[2], 5.0,
  info = "non-censored kept even when its value is below lod")
expect_true(res_c[1] < 1 && res_c[3] < 1)

# No censored values: returns x unchanged as numeric.
expect_equal(
  impute_uniform(c(1, 2, 3), lod = 0.5, censored = c(FALSE, FALSE, FALSE)),
  c(1, 2, 3)
)

# Input validation.
expect_error(impute_uniform(c(1, NA), lod = -1),
  info = "non-positive lod at a censored position errors")
expect_error(impute_uniform(c(1, 2), lod = 1, censored = c(TRUE)),
  info = "censored length mismatch errors")
expect_error(impute_uniform("a", lod = 1),
  info = "non-numeric x errors")
