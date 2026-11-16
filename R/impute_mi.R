#' Multiple imputation of below-detection values from a censored lognormal
#'
#' Fits a left-censored lognormal by maximum likelihood and draws `m` completed
#' datasets. Each completion (i) optionally draws fresh parameters
#' \eqn{(\mu^*, \log\sigma^*)} from their asymptotic sampling distribution
#' (Rubin's proper multiple imputation, propagating estimation uncertainty),
#' then (ii) replaces each censored observation with a draw from the fitted
#' normal truncated above at `log(lod)`, back-transformed to the concentration
#' scale. Detected observations are carried through unchanged.
#'
#' Analyze the `m` completions separately and combine with Rubin's rules to
#' obtain inferences that reflect the missing-below-LOD information.
#'
#' @param x Numeric vector of concentrations. Censored entries may be
#'   `NA`/`NaN`.
#' @param lod Numeric limit of detection, length 1 or `length(x)`.
#' @param censored Logical vector marking left-censored observations. Defaults
#'   to `is.na(x)`.
#' @param m Number of completed datasets to return (default 20).
#' @param seed Optional integer; sets the RNG for reproducibility.
#' @param param_uncertainty If `TRUE` (default), draw parameters per imputation
#'   for proper MI; if `FALSE`, condition on the MLE (improper MI).
#'
#' @return A list of length `m`, each element a numeric vector the length of
#'   `x` with censored entries imputed and detected entries unchanged. An
#'   error naming the fitted parameters is raised, rather than returning
#'   completions, when any imputed value is non-finite or not strictly
#'   positive (for example, exact zeros from `exp()` underflow at a
#'   degenerate fit).
#' @references Rubin, D. B. (1987). *Multiple Imputation for Nonresponse in
#'   Surveys*. Wiley.
#' @seealso [impute_mle()], [impute_ros()]
#' @examples
#' set.seed(1)
#' x <- rlnorm(50, 0, 1)
#' lod <- 0.5
#' cens <- x < lod
#' x[cens] <- NA
#' imps <- impute_mi_lognormal(x, lod = lod, censored = cens, m = 5, seed = 1)
#' length(imps)
#' @export
impute_mi_lognormal <- function(x, lod, censored = is.na(x), m = 20,
                                seed = NULL, param_uncertainty = TRUE) {
  lod <- .validate_censor_args(x, lod, censored)
  if (!is.numeric(m) || length(m) != 1L || is.na(m) || m < 1) {
    stop("`m` must be a single positive integer.", call. = FALSE)
  }
  m <- as.integer(m)
  base <- as.numeric(x)
  if (!any(censored)) {
    return(replicate(m, base, simplify = FALSE))
  }
  fit <- .fit_censored_lognormal(x, lod, censored)
  .check_fit(fit, "impute_mi_lognormal")
  cc <- log(lod[censored])
  k <- sum(censored)
  use_unc <- isTRUE(param_uncertainty)
  if (use_unc && is.null(fit$vcov)) {
    # Falling back without saying so would hand back improper multiple
    # imputation under the name of proper: the completions would share
    # one parameter value, the between-imputation variance would omit
    # estimation uncertainty, and Rubin's rules would then report
    # intervals that are too narrow.
    warning(
      "impute_mi_lognormal(): the parameter covariance is not ",
      "available, so estimation uncertainty cannot be propagated. ",
      "Falling back to improper multiple imputation, conditioning on ",
      "the MLE; Rubin's rules will understate the total variance.",
      call. = FALSE
    )
    use_unc <- FALSE
  }

  .with_seed(seed, {
  degenerate <- 0L
  draws <- vector("list", m)
  for (i in seq_len(m)) {
    if (use_unc) {
      par <- .rmvnorm1(fit$par, fit$vcov)
      if (is.null(par)) {
        degenerate <- degenerate + 1L
        par <- fit$par
      }
      mu <- par[1]
      s <- exp(par[2])
    } else {
      mu <- fit$mu
      s <- fit$sigma
    }
    upper <- pmax(stats::pnorm((cc - mu) / s), .Machine$double.eps)
    u <- stats::runif(k, min = 0, max = upper)
    out <- base
    out[censored] <- exp(mu + s * stats::qnorm(u))
    draws[[i]] <- out
  }
  if (degenerate > 0L) {
    warning(
      "impute_mi_lognormal(): the parameter covariance was not ",
      "positive definite for ", degenerate, " of ", m,
      " completions, which therefore condition on the MLE rather ",
      "than drawing fresh parameters. Those completions contribute ",
      "no estimation uncertainty.",
      call. = FALSE
    )
  }
  # A finiteness check alone misses exp() underflow: a degenerate fit
  # (two identical detected values give mu = -727, sigma = 9e125)
  # returns imputes of exactly 0, which is finite but lies outside
  # (0, lod] and would enter a log-scale analysis as -Inf.
  usable <- vapply(
    draws,
    function(z) all(is.finite(z)) && all(z[censored] > 0),
    logical(1)
  )
  if (!all(usable)) {
    stop(
      "impute_mi_lognormal(): the fitted lognormal produced ",
      "non-finite or non-positive imputations (mu = ",
      format(fit$mu, digits = 4), ", sigma = ",
      format(fit$sigma, digits = 4), "). This follows a degenerate ",
      "fit, usually one that did not converge; inspect the number of ",
      "detected values.",
      call. = FALSE
    )
  }
  draws
  })
}
