#' Impute below-detection values by simple substitution
#'
#' Replaces each left-censored observation with a fixed fraction of the limit
#' of detection, `lod * fraction`. Common choices are `fraction = 1/2`
#' (LOD/2) and `fraction = 1/sqrt(2)` (LOD/sqrt(2); Hornung and Reed, 1990).
#' Substitution is deterministic and simple but biases variance estimates and
#' any quantity sensitive to the sub-LOD distribution.
#'
#' @param x Numeric vector of measured concentrations. Censored entries may be
#'   `NA`/`NaN`; their value is ignored and replaced.
#' @param lod Numeric limit of detection, either a single value or one value
#'   per element of `x`. Must be finite and positive at censored positions.
#' @param censored Logical vector marking left-censored (below-LOD)
#'   observations. Defaults to `is.na(x)`.
#' @param fraction Single number in `(0, 1]` multiplied by `lod`. Defaults to
#'   `0.5` (LOD/2).
#'
#' @return A numeric vector the same length as `x`, with censored entries
#'   replaced by `lod * fraction` and observed entries unchanged.
#' @examples
#' x <- c(5.2, NA, 3.1, NA)
#' impute_substitution(x, lod = 1.5)
#' impute_substitution(x, lod = 1.5, fraction = 1 / sqrt(2))
#' @export
impute_substitution <- function(x, lod, censored = is.na(x), fraction = 0.5) {
  if (!is.numeric(fraction) || length(fraction) != 1L || is.na(fraction) ||
    fraction <= 0 || fraction > 1) {
    stop("`fraction` must be a single number in (0, 1].", call. = FALSE)
  }
  lod <- .validate_censor_args(x, lod, censored)
  out <- as.numeric(x)
  out[censored] <- lod[censored] * fraction
  out
}
