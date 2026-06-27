#' Validate shared censoring arguments
#'
#' Internal helper shared by the imputation strategies. Checks types and
#' lengths, recycles a scalar `lod` to the length of `x`, and verifies that
#' `lod` is usable (finite and positive) at every censored position.
#'
#' @param x Numeric vector of measured concentrations.
#' @param lod Numeric limit of detection, length 1 or `length(x)`.
#' @param censored Logical vector, `TRUE` where the value is left-censored.
#' @return The `lod` vector recycled to `length(x)`.
#' @keywords internal
#' @noRd
.validate_censor_args <- function(x, lod, censored) {
  if (!is.numeric(x)) stop("`x` must be numeric.", call. = FALSE)
  if (!is.numeric(lod)) stop("`lod` must be numeric.", call. = FALSE)
  if (!is.logical(censored)) stop("`censored` must be logical.", call. = FALSE)
  n <- length(x)
  if (length(censored) != n) {
    stop("`censored` must have the same length as `x`.", call. = FALSE)
  }
  if (anyNA(censored)) stop("`censored` must not contain NA.", call. = FALSE)
  if (length(lod) == 1L) lod <- rep(lod, n)
  if (length(lod) != n) {
    stop("`lod` must have length 1 or length(x).", call. = FALSE)
  }
  if (any(censored)) {
    bad <- censored & (!is.finite(lod) | lod <= 0)
    if (any(bad)) {
      stop("`lod` must be finite and > 0 at all censored positions.",
        call. = FALSE
      )
    }
  }
  lod
}
