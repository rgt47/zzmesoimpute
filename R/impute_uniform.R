#' Impute below-detection values by a uniform draw on (0, LOD)
#'
#' Replaces each left-censored observation with an independent draw from a
#' Uniform(0, `lod`) distribution. This is the incumbent Meso Scale Discovery
#' (MSD) lab method (a single random imputation); it injects sub-threshold
#' variability but does not propagate imputation uncertainty and assumes a
#' uniform sub-LOD distribution. Provided primarily as a benchmark comparator.
#'
#' @param x Numeric vector of measured concentrations. Censored entries may be
#'   `NA`/`NaN`; their value is ignored and replaced.
#' @param lod Numeric limit of detection, either a single value or one value
#'   per element of `x`. Must be finite and positive at censored positions.
#' @param censored Logical vector marking left-censored (below-LOD)
#'   observations. Defaults to `is.na(x)`; for MSD data supply the explicit
#'   below-range indicator instead.
#' @param seed Optional integer. When supplied, `set.seed(seed)` is called
#'   before drawing so the imputation is reproducible.
#'
#' @return A numeric vector the same length as `x`, with censored entries
#'   replaced by uniform draws and observed entries unchanged.
#' @examples
#' x <- c(5.2, NA, 3.1, NA)
#' impute_uniform(x, lod = 1.5, seed = 1)
#' @export
impute_uniform <- function(x, lod, censored = is.na(x), seed = NULL) {
  lod <- .validate_censor_args(x, lod, censored)
  if (!is.null(seed)) set.seed(seed)
  out <- as.numeric(x)
  n_cens <- sum(censored)
  if (n_cens > 0L) {
    out[censored] <- stats::runif(n_cens, min = 0, max = lod[censored])
  }
  out
}
