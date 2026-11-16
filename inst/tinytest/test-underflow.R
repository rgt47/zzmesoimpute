# --- regressions: zero imputes from exp() underflow ---------------
#
# Imputations for values below a positive limit of detection must lie
# in (0, lod]. Checking only is.finite() misses exact zeros, which are
# finite. Each case below returned 0 before the fix.

# Two identical detected values give a degenerate fit at which the MI
# draws underflow to exactly 0 (previously c(2, 2, 0, 0), with warnings).
xd <- c(2, 2, NA, NA)
expect_error(
  suppressWarnings(impute_mi_lognormal(xd, lod = 1, m = 3, seed = 1)),
  "non-positive imputations \\(mu = ",
  info = "MI zero-underflow: proper MI refuses a degenerate fit")
expect_error(
  suppressWarnings(impute_mi_lognormal(xd, lod = 1, m = 3, seed = 1,
                                       param_uncertainty = FALSE)),
  "non-positive imputations \\(mu = ",
  info = "MI zero-underflow: improper MI refuses a degenerate fit")

# impute_mle(): a converged fit on 20000 detected values, plus one
# censored observation whose own limit is 40 log units below them, gave
# a conditional mean of exactly 0 with no warning.
set.seed(5)
xm <- c(stats::rlnorm(20000, 0, 1), NA)
lod_m <- c(rep(1e-3, 20000), exp(-40))
cm <- c(rep(FALSE, 20000), TRUE)
expect_error(impute_mle(xm, lod = lod_m, censored = cm),
  "non-positive conditional means \\(mu = ",
  info = "MLE zero-underflow: a zero conditional mean is refused")

# impute_ros(): detected values 300 orders of magnitude apart give a
# fitted line steep enough that the left-tail fill underflows to 0.
xr <- c(1e-150, 1e150, rep(NA, 30))
expect_error(impute_ros(xr, lod = 1e-160),
  "non-positive imputations \\(intercept = ",
  info = "ROS zero-underflow: a zero fitted value is refused")

# Substitution and uniform draws reach 0 only through a subnormal lod.
expect_error(impute_substitution(c(1, NA), lod = 5e-324),
  "underflowed to 0",
  info = "substitution zero-underflow: lod * fraction of 0 is refused")
expect_error(impute_uniform(c(1, rep(NA, 20)), lod = 5e-324, seed = 1),
  "underflowed to 0",
  info = "uniform zero-underflow: a zero draw is refused")

# Well-conditioned data are unaffected: every impute is in (0, lod].
set.seed(8)
xw <- stats::rlnorm(80, 0, 1)
cw <- xw < 0.5
xw[cw] <- NA
mi <- impute_mi_lognormal(xw, 0.5, cw, m = 5, seed = 3)
expect_true(all(vapply(mi, function(z) all(z[cw] > 0 & z[cw] <= 0.5),
                       logical(1))),
  info = "zero-underflow guard: MI on well-conditioned data still works")
expect_true(all(impute_mle(xw, 0.5, cw)[cw] > 0),
  info = "zero-underflow guard: MLE on well-conditioned data still works")
expect_true(all(impute_ros(xw, 0.5, cw)[cw] > 0),
  info = "zero-underflow guard: ROS on well-conditioned data still works")
