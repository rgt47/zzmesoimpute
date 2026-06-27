#' Impute below-detection values by regression on order statistics (ROS)
#'
#' Semiparametric lognormal ROS for a single detection limit. Detected values
#' are assigned probability plotting positions in the upper \eqn{1 - p_e}
#' fraction of the distribution (where \eqn{p_e} is the censored proportion),
#' a least-squares line is fitted to `log(detected)` against the normal
#' quantiles of those positions, and the censored observations are filled from
#' the fitted line at plotting positions spread through the lower \eqn{p_e}
#' fraction. Unlike substitution, ROS uses the shape of the detected data to
#' reconstruct a plausible left tail, which typically improves estimates of
#' the mean and standard deviation.
#'
#' This implementation assumes a **single** detection limit among the censored
#' observations. Apply it per assay or analyte (where the limit is constant);
#' supplying multiple distinct limits is an error. Fully multiply-censored ROS
#' (Helsel and Cohn, 1988) is not yet implemented.
#'
#' @param x Numeric vector of concentrations (positive where detected).
#'   Censored entries may be `NA`/`NaN`.
#' @param lod Numeric limit of detection, length 1 or `length(x)`. All censored
#'   observations must share one limit.
#' @param censored Logical vector marking left-censored observations. Defaults
#'   to `is.na(x)`.
#'
#' @return A numeric vector the length of `x`. Censored entries are replaced by
#'   ROS-fitted values (each below the detection limit), returned in ascending
#'   order across the censored positions; detected entries are unchanged.
#' @references Helsel, D. R. and Cohn, T. A. (1988). Estimation of descriptive
#'   statistics for multiply censored water quality data. *Water Resources
#'   Research*, 24(12), 1997-2004.
#' @seealso [impute_mle()], [impute_mi_lognormal()]
#' @examples
#' set.seed(1)
#' x <- rlnorm(50, 0, 1)
#' lod <- 0.5
#' cens <- x < lod
#' x[cens] <- NA
#' head(impute_ros(x, lod = lod, censored = cens))
#' @export
impute_ros <- function(x, lod, censored = is.na(x)) {
  lod <- .validate_censor_args(x, lod, censored)
  out <- as.numeric(x)
  if (!any(censored)) {
    return(out)
  }
  limits <- unique(lod[censored])
  if (length(limits) > 1L) {
    stop(
      "impute_ros() supports a single detection limit among censored ",
      "values; apply it per assay/group. Got: ",
      paste(format(limits), collapse = ", "), call. = FALSE
    )
  }
  dl <- limits[1]
  det <- !censored
  d <- sum(det)
  k <- sum(censored)
  n <- d + k
  if (d < 2L) {
    stop("Need at least two detected values for ROS.", call. = FALSE)
  }
  pe <- k / n
  yd <- sort(log(out[det]))
  pp_det <- pe + (1 - pe) * (seq_len(d) - 0.5) / d
  coefs <- stats::coef(stats::lm(yd ~ stats::qnorm(pp_det)))
  a <- coefs[1]
  b <- coefs[2]
  pp_cen <- pe * (seq_len(k) - 0.5) / k
  fill <- exp(a + b * stats::qnorm(pp_cen))
  fill <- pmin(fill, dl)
  out[which(censored)] <- fill
  out
}
