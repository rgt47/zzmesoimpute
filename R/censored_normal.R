#' Fit a left-censored lognormal by maximum likelihood
#'
#' Internal. Treats concentrations as lognormal: on the log scale the data are
#' a normal sample left-censored at `log(lod)`. Maximises the censored normal
#' log-likelihood (detected points contribute a density, censored points the
#' cumulative probability below their limit) over `(mu, log sigma)`.
#'
#' @param x Numeric concentrations (censored entries are ignored).
#' @param lod Numeric limit of detection, recycled to `length(x)`.
#' @param censored Logical, `TRUE` where left-censored.
#' @return A list with `mu`, `sigma`, the parameter vector `par`
#'   (`c(mu, log sigma)`), its asymptotic covariance `vcov` (or `NULL`), and
#'   the optimiser `convergence` code.
#' @keywords internal
#' @noRd
.fit_censored_lognormal <- function(x, lod, censored) {
  y <- log(as.numeric(x))
  cpt <- log(as.numeric(lod))
  det <- !censored
  yd <- y[det]
  if (sum(det) < 2L) {
    stop("Need at least two detected values to fit the censored lognormal.",
      call. = FALSE
    )
  }
  cc <- cpt[censored]
  negll <- function(par) {
    mu <- par[1]
    s <- exp(par[2])
    ll_det <- sum(stats::dnorm(yd, mu, s, log = TRUE))
    ll_cen <- if (length(cc)) {
      sum(stats::pnorm(cc, mu, s, log.p = TRUE))
    } else {
      0
    }
    -(ll_det + ll_cen)
  }
  start <- c(mean(yd), log(stats::sd(yd) + 1e-8))
  fit <- stats::optim(start, negll, method = "BFGS", hessian = TRUE)
  vcov <- tryCatch(solve(fit$hessian), error = function(e) NULL)
  list(
    mu = fit$par[1], sigma = exp(fit$par[2]), par = fit$par,
    vcov = vcov, convergence = fit$convergence
  )
}

#' One draw from a multivariate normal
#'
#' Internal. Cholesky-based single draw; falls back to the mean if the
#' covariance is not positive definite.
#'
#' @param mu Mean vector.
#' @param sigma Covariance matrix.
#' @return A numeric vector the length of `mu`.
#' @keywords internal
#' @noRd
.rmvnorm1 <- function(mu, sigma) {
  ch <- tryCatch(chol(sigma), error = function(e) NULL)
  if (is.null(ch)) {
    return(mu)
  }
  as.numeric(mu + t(ch) %*% stats::rnorm(length(mu)))
}
