# Tests for impute_substitution(): LOD * fraction imputation.

library(zzmesoimpute)

x <- c(5.2, NA, 3.1, NA, 0.8)
lod <- 1.5

# Default fraction is 1/2 (LOD/2).
res <- impute_substitution(x, lod = lod)
expect_equal(res[c(2, 4)], c(lod * 0.5, lod * 0.5),
  info = "default substitution is LOD/2")
expect_equal(res[c(1, 3, 5)], x[c(1, 3, 5)],
  info = "non-censored entries unchanged")

# LOD/sqrt(2).
res2 <- impute_substitution(x, lod = lod, fraction = 1 / sqrt(2))
expect_equal(res2[2], lod / sqrt(2),
  info = "fraction = 1/sqrt(2) gives LOD/sqrt(2)")

# Deterministic: repeated calls identical, no seed needed.
expect_identical(
  impute_substitution(x, lod = lod),
  impute_substitution(x, lod = lod),
  info = "substitution is deterministic"
)

# Per-element lod vector.
lod_vec <- c(1, 2, 3, 4, 5)
res_vec <- impute_substitution(rep(NA_real_, 5), lod = lod_vec)
expect_equal(res_vec, lod_vec * 0.5,
  info = "vector lod applied element-wise")

# Explicit censoring indicator.
xx <- c(0.4, 5.0, 0.2)
res_c <- impute_substitution(xx, lod = 2, censored = c(TRUE, FALSE, TRUE))
expect_equal(res_c, c(1.0, 5.0, 1.0),
  info = "only censored positions substituted")

# Output type and length.
expect_equal(length(res), length(x))
expect_true(is.numeric(res))

# Input validation.
expect_error(impute_substitution(x, lod = lod, fraction = 0),
  info = "fraction = 0 errors")
expect_error(impute_substitution(x, lod = lod, fraction = 1.5),
  info = "fraction > 1 errors")
expect_error(impute_substitution(c(1, NA), lod = 0),
  info = "non-positive lod at a censored position errors")
