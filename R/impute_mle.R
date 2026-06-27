#' Impute below-detection values by censored-lognormal conditional means
#'
#' Fits a left-censored lognormal by maximum likelihood (internal helper
#' `.fit_censored_lognormal()`) and replaces each censored observation
#' with its model-based conditional expectation \eqn{E[X \mid X < L]}, where
#' \eqn{L} is that observation's limit of detection. This is a deterministic,
#' parametric single imputation: it uses all of the data (detected and
#' censored) to estimate the distribution, but like any single imputation it
#' does not propagate estimation or imputation uncertainty (use
#' [impute_mi_lognormal()] for that).
#'
#' For \eqn{Y = \log X \sim N(\mu, \sigma^2)} and \eqn{c = \log L},
#' \deqn{E[X \mid X < L] = e^{\mu + \sigma^2/2}\,
#'   \frac{\Phi((c - \mu - \sigma^2)/\sigma)}{\Phi((c - \mu)/\sigma)}.}
#'
#' @param x Numeric vector of concentrations (must be positive where
#'   detected). Censored entries may be `NA`/`NaN`.
#' @param lod Numeric limit of detection, length 1 or `length(x)`.
#' @param censored Logical vector marking left-censored observations. Defaults
#'   to `is.na(x)`.
#'
#' @return A numeric vector the length of `x`, censored entries replaced by
#'   their conditional means (capped below `lod`), detected entries unchanged.
#' @references
#'   Helsel, D. R. (2012). *Statistics for Censored Environmental Data Using
#'   Minitab and R* (2nd ed.). Wiley.
#' @seealso [impute_mi_lognormal()], [impute_ros()]
#' @examples
#' set.seed(1)
#' x <- rlnorm(50, 0, 1)
#' lod <- 0.5
#' cens <- x < lod
#' x[cens] <- NA
#' head(impute_mle(x, lod = lod, censored = cens))
#' @export
impute_mle <- function(x, lod, censored = is.na(x)) {
  lod <- .validate_censor_args(x, lod, censored)
  out <- as.numeric(x)
  if (!any(censored)) {
    return(out)
  }
  fit <- .fit_censored_lognormal(x, lod, censored)
  mu <- fit$mu
  s <- fit$sigma
  cc <- log(lod[censored])
  den <- pmax(stats::pnorm((cc - mu) / s), .Machine$double.eps)
  num <- stats::pnorm((cc - mu - s^2) / s)
  em <- exp(mu + s^2 / 2) * num / den
  out[censored] <- pmin(em, lod[censored])
  out
}
