# Cross-cutting invariants. This file previously held a single
# expect_true(TRUE), which asserts nothing about the package.

set.seed(20260908)
x <- stats::rlnorm(80, 0, 1)
lod <- 0.4
cens <- x < lod
x[cens] <- NA

# Every strategy returns one value per observation, leaves detected
# values untouched, and puts imputed values in (0, lod].
strategies <- list(
  substitution = function() impute_substitution(x, lod, cens),
  uniform = function() impute_uniform(x, lod, cens, seed = 1),
  ros = function() impute_ros(x, lod, cens),
  mle = function() impute_mle(x, lod, cens)
)
for (nm in names(strategies)) {
  v <- strategies[[nm]]()
  expect_equal(length(v), length(x),
    info = paste(nm, "returns one value per observation"))
  expect_true(all(is.finite(v)),
    info = paste(nm, "returns finite values"))
  expect_equal(v[!cens], x[!cens],
    info = paste(nm, "leaves detected values unchanged"))
  expect_true(all(v[cens] > 0 & v[cens] <= lod),
    info = paste(nm, "imputes into (0, lod]"))
}

# The multiple-imputation variant returns m completions with the same
# guarantees, and the completions must actually differ.
imps <- impute_mi_lognormal(x, lod, cens, m = 10, seed = 2)
expect_equal(length(imps), 10L,
  info = "MI returns m completions")
for (v in imps) {
  expect_equal(v[!cens], x[!cens],
    info = "MI leaves detected values unchanged")
  expect_true(all(v[cens] > 0 & v[cens] <= lod),
    info = "MI imputes into (0, lod]")
}
expect_true(var(vapply(imps, function(z) mean(z), numeric(1))) > 0,
  info = "MI completions are not identical")

# With nothing censored every strategy is the identity.
xf <- stats::rlnorm(20, 0, 1)
none <- rep(FALSE, 20)
expect_equal(impute_substitution(xf, 0.001, none), xf,
  info = "substitution is the identity with no censoring")
expect_equal(impute_mle(xf, 0.001, none), xf,
  info = "mle is the identity with no censoring")
expect_equal(impute_ros(xf, 0.001, none), xf,
  info = "ros is the identity with no censoring")
