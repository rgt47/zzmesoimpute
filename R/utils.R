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

#' Run an expression under a temporary RNG seed
#'
#' Internal. `set.seed()` writes to `.Random.seed` in the global
#' environment, so calling it inside an exported function silently
#' repositions the caller's random stream: every subsequent draw in the
#' user's script changes, and any reproducibility they had arranged is
#' lost. This saves the stream, seeds, and restores it on exit, so the
#' seed argument makes one call reproducible without leaking.
#'
#' @param seed Integer seed, or `NULL` to leave the stream alone.
#' @param expr Expression to evaluate.
#' @return The value of `expr`.
#' @keywords internal
#' @noRd
.with_seed <- function(seed, expr) {
  if (is.null(seed)) {
    return(expr)
  }
  has_old <- exists(".Random.seed", envir = globalenv(), inherits = FALSE)
  if (has_old) {
    old <- get(".Random.seed", envir = globalenv(), inherits = FALSE)
    on.exit(assign(".Random.seed", old, envir = globalenv()), add = TRUE)
  } else {
    on.exit(
      suppressWarnings(rm(".Random.seed", envir = globalenv())),
      add = TRUE
    )
  }
  set.seed(seed)
  expr
}

#' Warn when the censored-lognormal fit did not converge
#'
#' Internal. `optim()` reports a convergence code that the package
#' computed and then ignored. In the sparse-detection regime the fit
#' frequently fails to converge: with 50 observations and 2 detected
#' values it did so in 98 of 150 simulated datasets, returning parameter
#' estimates that are not maximum-likelihood estimates of anything.
#'
#' @param fit Result of `.fit_censored_lognormal()`.
#' @param what Name of the calling function, used in the message.
#' @return `fit`, invisibly.
#' @keywords internal
#' @noRd
.check_fit <- function(fit, what) {
  if (!identical(fit$convergence, 0L) &&
    !identical(as.integer(fit$convergence), 0L)) {
    warning(
      what, "(): the censored-lognormal fit did not converge ",
      "(optim code ", fit$convergence, "). The imputed values are not ",
      "reliable. This is common when very few observations are ",
      "detected; check the number of detected values.",
      call. = FALSE
    )
  }
  invisible(fit)
}
