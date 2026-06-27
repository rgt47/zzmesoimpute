# Tests for read_meso() / meso_headers() against synthetic MSD-shaped
# fixtures. No real clinical data is used (the source data is governed by a
# data-use agreement); fixtures reproduce the structural quirks only:
#   - a multi-row preamble with the header marker not on row 1,
#   - differing label wording across MSD software versions,
#   - a variable number of trailing columns.

if (!requireNamespace("writexl", quietly = TRUE)) exit_file("writexl absent")
library(zzmesoimpute)

# Write a character matrix (rows x cols) to a temp .xlsx with no col names,
# so arbitrary preamble and header rows can be placed literally.
write_grid <- function(rows) {
  m <- do.call(rbind, lapply(rows, function(r) r))
  df <- as.data.frame(m, stringsAsFactors = FALSE)
  f <- tempfile(fileext = ".xlsx")
  writexl::write_xlsx(df, f, col_names = FALSE)
  f
}

na_ <- NA_character_

## Fixture A: "MESO-207 style" -- a genuine multi-row header. On the marker
## row (row 5) BOTH the standard-conc and calc-conc columns read just "Conc";
## the disambiguating fragments ("Standard", "Calc.", "Algorithm",
## "Detection") sit on the two rows above (rows 3-4). 15 columns.
fixture_a <- function() {
  blank15 <- rep(na_, 15)
  title <- c("Experiment Data Table", rep(na_, 14))
  upper2 <- c(na_, na_, na_, na_, na_, "Algorithm", na_,
    na_, na_, na_, na_, na_, na_, na_, "Detection")
  upper1 <- c(na_, na_, na_, na_, na_, "Parameter:", na_,
    "Standard", na_, na_, na_, "Calc.", "Calc. Conc.", na_, "Limits:")
  header <- c("Plate Name", "Sample", "Detection Range", "Assay", "Well",
    "Calc. Bottom", "Dilution", "Conc", "Signal", "Mean", "CV",
    "Conc", "Mean", "Excluded", "Calc. Low")
  d1 <- c("P1", "S001", "In Detection Range", "CRP", "A01",
    "100", "1", "0", "5000", "5100", "2", "180", "179", "no", "2.5")
  d2 <- c("P1", "1001001", "Below Detection Range", "CRP", "A02",
    "100", "1", "0", "10", "12", "5", "NaN", "179", "no", "2.5")
  d3 <- c("P1", "1001002", "In Detection Range", "CRP", "A03",
    "100", "1", "0", "900", "905", "3", "50", "179", "no", "2.5")
  write_grid(list(title, blank15, upper2, upper1, header, d1, d2, d3))
}

## Fixture B: "MESO_300 style" -- header marker on row 3, full labels,
## 17 columns (appended % Recovery / % Recovery Mean).
fixture_b <- function() {
  blank17 <- rep(na_, 17)
  title <- c("Experiment Data Table", rep(na_, 16))
  header <- c("Plate Name", "Sample", "Detection Range", "Assay", "Well",
    "Algorithm Parameter: Calc. Bottom", "Dilution",
    "Standard Concentration", "Signal", "Mean", "CV",
    "Calc. Concentration", "Calc. Conc. Mean", "Excluded",
    "Detection Limits: Calc. Low", "% Recovery", "% Recovery Mean")
  d1 <- c("P9", "S001", "In Detection Range", "CRP", "A01",
    "90", "1", "0", "5000", "5100", "2", "180", "179", "no", "2.5",
    "98", "99")
  d2 <- c("P9", "1001001", "Below Fit Curve Range", "CRP", "A02",
    "90", "1", "250", "10", "12", "5", "NaN", "179", "no", "2.5",
    "95", "99")
  d3 <- c("P9", "1001002", "In Detection Range", "CRP", "A03",
    "90", "1", "0", "900", "905", "3", "50", "179", "no", "2.5",
    "97", "99")
  write_grid(list(title, blank17, header, d1, d2, d3))
}

fa <- fixture_a()
fb <- fixture_b()

# --- meso_headers finds the right row and label count ----------------------
expect_equal(length(meso_headers(fa)), 15L,
  info = "MESO-207-style header has 15 labels on the Plate Name row")
expect_equal(length(meso_headers(fb)), 17L,
  info = "MESO_300-style header has 17 labels")
expect_true("Plate Name" %in% meso_headers(fa))

# --- both layouts parse to the same canonical required schema --------------
ra <- read_meso(fa)
rb <- read_meso(fb)

expect_true(all(meso_required_cols() %in% names(ra)),
  info = "all required canonical columns present (fixture A)")
expect_true(all(meso_required_cols() %in% names(rb)),
  info = "all required canonical columns present (fixture B)")

expect_equal(nrow(ra), 3L)
expect_equal(nrow(rb), 3L)

# --- type coercion and NaN handling ----------------------------------------
expect_true(is.numeric(ra$calc_conc))
expect_true(is.na(ra$calc_conc[2]),
  info = "'NaN' string becomes NA in numeric calc_conc")
expect_equal(ra$calc_conc[3], 50)
expect_equal(ra$calc_low, c(2.5, 2.5, 2.5))
expect_true(is.character(ra$detection_range))
expect_equal(ra$detection_range[2], "Below Detection Range")

# --- label-variant resolution across files ---------------------------------
# 'Calc. Concentration' (B) and 'Calc. Conc' (A) both map to calc_conc, and
# are not confused with 'Calc. Conc. Mean'.
expect_equal(rb$calc_conc[3], 50)
expect_false(is.na(rb$calc_conc_mean[1]))
expect_equal(rb$calc_conc_mean[1], 179)
# 'Detection Limits: Calc. Low' (B) resolves to calc_low.
expect_equal(rb$calc_low, c(2.5, 2.5, 2.5))

# --- extra columns: dropped by default, kept on request --------------------
expect_false("recovery" %in% names(read_meso(fb, required = character(0),
  col_map = meso_default_map()[1:15])),
  info = "recovery dropped when not in the supplied map")
expect_true(all(c("recovery", "recovery_mean") %in% names(rb)),
  info = "recovery columns mapped by the default map for fixture B")
expect_equal(rb$recovery, c(98, 95, 97))

# --- user override of the default map --------------------------------------
# Rename a canonical output column by editing the map's names.
m_custom <- meso_default_map()
names(m_custom)[names(m_custom) == "assay"] <- "analyte"
rc <- read_meso(fa, col_map = m_custom,
  required = c("plate_name", "sample", "detection_range", "analyte",
    "calc_conc", "calc_low", "cv", "excluded"))
expect_true("analyte" %in% names(rc) && !("assay" %in% names(rc)),
  info = "user can rename a canonical output column via col_map")
expect_equal(rc$analyte, c("CRP", "CRP", "CRP"))

# --- ambiguous match: one pattern hitting several headers errors ------------
expect_error(read_meso(fa, col_map = c(meso_default_map(), greedy = "Conc")),
  info = "a pattern matching multiple headers is ambiguous -> error")

# --- error paths -----------------------------------------------------------
expect_error(meso_headers(fa, header_marker = "Nonexistent"),
  info = "missing header marker errors")
# Drop a required column from the map -> required check fails.
expect_error(read_meso(fa, col_map = meso_default_map()[
  setdiff(names(meso_default_map()), "calc_low")]),
  info = "missing required column errors")
