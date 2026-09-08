# --- regressions -------------------------------------------------

# set.seed() inside an exported function writes to .Random.seed in the
# global environment, repositioning the caller's stream. The seed
# argument must make one call reproducible without that side effect.
seed_is_local <- function(f) {
  set.seed(99)
  before <- stats::rnorm(3)
  set.seed(99)
  invisible(f())
  after <- stats::rnorm(3)
  isTRUE(all.equal(before, after))
}
x <- c(5.2, NA, 3.1, NA)
expect_true(
  seed_is_local(function() impute_uniform(x, lod = 1.5, seed = 1)),
  info = "impute_uniform() restores the caller's RNG stream")

set.seed(4)
xm <- stats::rlnorm(40, 0, 1)
cm <- xm < 0.5
xm[cm] <- NA
expect_true(
  seed_is_local(function()
    impute_mi_lognormal(xm, 0.5, cm, m = 3, seed = 7)),
  info = "impute_mi_lognormal() restores the caller's RNG stream")

# The seed must still do its job.
expect_equal(impute_uniform(x, 1.5, seed = 1),
             impute_uniform(x, 1.5, seed = 1),
  info = "the same seed reproduces the same draw")
expect_false(isTRUE(all.equal(impute_uniform(x, 1.5, seed = 1),
                              impute_uniform(x, 1.5, seed = 2))),
  info = "different seeds give different draws")

# optim()'s convergence code was computed and never consulted. With 50
# observations and 2 detected it failed to converge in 98 of 150
# simulated datasets, and the resulting estimates are not MLEs. Two
# identical detected values drive it to mu = -258, sigma = 159, where
# the conditional mean overflows to NaN.
xz <- c(rep(NA, 18), 2, 2)
cz <- is.na(xz)
expect_warning(
  try(impute_mle(xz, lod = 1, censored = cz), silent = TRUE),
  "did not converge",
  info = "a non-converged fit is reported")
expect_error(
  suppressWarnings(impute_mle(xz, lod = 1, censored = cz)),
  "non-finite",
  info = "NaN conditional means are refused, not returned")

# A silent fallback from proper to improper multiple imputation would
# understate the total variance under Rubin's rules, so it must warn.
expect_null(zzmesoimpute:::.rmvnorm1(c(1, 2),
                                     matrix(c(1, 2, 2, 1), 2)),
  info = ".rmvnorm1() signals a non-positive-definite covariance
          instead of returning the mean")
expect_true(is.numeric(zzmesoimpute:::.rmvnorm1(c(1, 2), diag(2))),
  info = ".rmvnorm1() still draws from a valid covariance")

# Proper MI must carry more between-imputation variance than improper.
set.seed(3)
xp <- stats::rlnorm(60, 0, 1)
cp <- xp < 0.5
xp[cp] <- NA
bv <- function(l) var(vapply(l, function(z) mean(log(z)), numeric(1)))
expect_true(
  bv(impute_mi_lognormal(xp, 0.5, cp, m = 40, seed = 2,
                         param_uncertainty = TRUE)) >
    bv(impute_mi_lognormal(xp, 0.5, cp, m = 40, seed = 2,
                           param_uncertainty = FALSE)),
  info = "proper MI propagates estimation uncertainty")
