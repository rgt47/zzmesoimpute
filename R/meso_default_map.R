#' Default Meso Scale Discovery column map
#'
#' The mapping used by [read_meso()] to rename Meso Scale Discovery (MSD)
#' export columns to canonical snake_case names. It is a named character
#' vector whose **names are the canonical output names** and whose **values
#' are case-insensitive regular expressions** matched against the trimmed
#' header labels of the export.
#'
#' The patterns are written to absorb the labelling differences seen across
#' MSD software versions, e.g. `Calc. Conc` vs `Calc. Concentration`,
#' `Calc. Low` vs `Detection Limits: Calc. Low`, and `Standard Conc` vs
#' `Standard Concentration`. Each pattern must match at most one header in a
#' given file (an ambiguous match is an error).
#'
#' To support a non-standard export, copy this vector and override or add
#' entries, e.g.
#' `read_meso(path, col_map = c(meso_default_map(), my_field = "^My Label$"))`.
#' Use [meso_headers()] to inspect a file's actual labels first.
#'
#' @return A named character vector, canonical name = header regex.
#' @seealso [read_meso()], [meso_headers()], [meso_required_cols()]
#' @examples
#' meso_default_map()[c("calc_conc", "calc_low")]
#' @export
meso_default_map <- function() {
  c(
    plate_name      = "^Plate Name$",
    sample          = "^Sample$",
    detection_range = "^Detection Range$",
    assay           = "^Assay$",
    well            = "^Well$",
    calc_bottom     = "Calc\\. Bottom$",
    dilution        = "^Dilution$",
    std_conc        = "^(Standard |Std\\.? *)?Conc(entration)?$",
    signal          = "^Signal$",
    mean            = "^Mean$",
    cv              = "^%? *CV$",
    calc_conc       = "Calc\\. Conc(entration)?$",
    calc_conc_mean  = "Calc\\. Conc.*Mean$",
    excluded        = "^Excluded$",
    calc_low        = "Calc\\. Low$",
    recovery        = "^%? *Recovery$",
    recovery_mean   = "^%? *Recovery Mean$"
  )
}

#' Canonical MSD columns required by the imputation pipeline
#'
#' The canonical names that [read_meso()] insists on finding (it errors if any
#' is absent). These are the fields the below-detection imputation depends on.
#'
#' @return A character vector of required canonical column names.
#' @seealso [read_meso()], [meso_default_map()]
#' @examples
#' meso_required_cols()
#' @export
meso_required_cols <- function() {
  c(
    "plate_name", "sample", "detection_range", "assay",
    "calc_conc", "calc_low", "cv", "excluded"
  )
}

# Canonical columns coerced to numeric on read.
.meso_numeric_cols <- c(
  "calc_bottom", "dilution", "std_conc", "signal", "mean", "cv",
  "calc_conc", "calc_conc_mean", "calc_low", "recovery", "recovery_mean"
)

# Canonical columns kept as character on read.
.meso_character_cols <- c(
  "plate_name", "sample", "detection_range", "assay", "well", "excluded"
)
