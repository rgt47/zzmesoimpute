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
#' Analyse the `m` completions separately and combine with Rubin's rules to
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
#'   `x` with censored entries imputed and detected entries unchanged.
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
  if (!is.null(seed)) set.seed(seed)
  base <- as.numeric(x)
  if (!any(censored)) {
    return(replicate(m, base, simplify = FALSE))
  }
  fit <- .fit_censored_lognormal(x, lod, censored)
  cc <- log(lod[censored])
  k <- sum(censored)
  use_unc <- isTRUE(param_uncertainty) && !is.null(fit$vcov)

  draws <- vector("list", m)
  for (i in seq_len(m)) {
    if (use_unc) {
      par <- .rmvnorm1(fit$par, fit$vcov)
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
  draws
}
