# Tests for impute_ros(): single-detection-limit lognormal ROS.

library(zzmesoimpute)

set.seed(99)
truth <- rlnorm(400, 0, 1)
lod <- 0.6
cens <- truth < lod
x <- truth
x[cens] <- NA

res <- impute_ros(x, lod = lod, censored = cens)

# Detected values untouched.
expect_equal(res[!cens], truth[!cens], info = "detected entries unchanged")

# Imputed values are below the detection limit and positive.
imp <- res[cens]
expect_true(all(imp > 0 & imp <= lod),
  info = "ROS fills lie in (0, lod]")

# Length / type.
expect_equal(length(res), length(x))
expect_true(is.numeric(res))

# Deterministic (least squares, no RNG).
expect_identical(
  impute_ros(x, lod = lod, censored = cens),
  impute_ros(x, lod = lod, censored = cens),
  info = "ROS is deterministic"
)

# ROS recovers the mean better than naive LOD/2 substitution here.
true_mean <- mean(truth)
ros_err <- abs(mean(res) - true_mean)
sub_err <- abs(mean(impute_substitution(x, lod = lod, censored = cens)) -
  true_mean)
expect_true(ros_err <= sub_err,
  info = "ROS mean error no worse than LOD/2 substitution")

# Multiple distinct detection limits among censored -> error.
lod_vec <- ifelse(seq_along(x) <= 200, 0.6, 1.2)
cens_v <- truth < lod_vec
xv <- truth
xv[cens_v] <- NA
expect_error(impute_ros(xv, lod = lod_vec, censored = cens_v),
  info = "multiple detection limits are rejected")

# Too few detected values -> error.
expect_error(
  impute_ros(c(NA, NA, NA, 5), lod = 1,
    censored = c(TRUE, TRUE, TRUE, FALSE)),
  info = "needs at least two detected values"
)

# No censoring returns x unchanged.
expect_equal(impute_ros(c(1, 2, 3), lod = 0.5,
  censored = c(FALSE, FALSE, FALSE)), c(1, 2, 3))
