# Tests for impute_mle(): censored-lognormal conditional-mean imputation.

library(zzmesoimpute)

set.seed(42)
truth <- rlnorm(400, meanlog = 0, sdlog = 1)
lod <- 0.6
cens <- truth < lod
x <- truth
x[cens] <- NA

res <- impute_mle(x, lod = lod, censored = cens)

# Detected values untouched.
expect_equal(res[!cens], truth[!cens],
  info = "detected observations unchanged")

# Imputed values strictly below the detection limit and positive.
imp <- res[cens]
expect_true(all(imp > 0 & imp < lod),
  info = "conditional-mean imputes lie in (0, lod)")

# Length and type.
expect_equal(length(res), length(x))
expect_true(is.numeric(res))

# The fitted lognormal recovers the truth reasonably (loose tolerance).
fit <- zzmesoimpute:::.fit_censored_lognormal(x, rep(lod, length(x)), cens)
expect_true(abs(fit$mu - 0) < 0.15,
  info = "MLE mu close to true meanlog = 0")
expect_true(abs(fit$sigma - 1) < 0.15,
  info = "MLE sigma close to true sdlog = 1")

# Deterministic: repeated calls identical (no RNG).
expect_identical(
  impute_mle(x, lod = lod, censored = cens),
  impute_mle(x, lod = lod, censored = cens),
  info = "imputation is deterministic"
)

# No censoring returns x unchanged.
expect_equal(impute_mle(c(1, 2, 3), lod = 0.5,
  censored = c(FALSE, FALSE, FALSE)), c(1, 2, 3))

# Per-element lod honoured (two analytes with different limits).
lod2 <- ifelse(seq_along(x) <= 200, 0.6, 1.0)
cens2 <- truth < lod2
x2 <- truth
x2[cens2] <- NA
res2 <- impute_mle(x2, lod = lod2, censored = cens2)
expect_true(all(res2[cens2] < lod2[cens2]),
  info = "each impute respects its own lod")
