#' Locate the header row of an MSD export
#'
#' Internal. Returns the index of the first row containing a cell equal
#' (case-insensitively, trimmed) to `marker`.
#'
#' @param raw A data frame of the raw sheet read with `col_names = FALSE`.
#' @param marker The header-marker label, e.g. `"Plate Name"`.
#' @return Integer row index.
#' @keywords internal
#' @noRd
.find_header_row <- function(raw, marker) {
  marker_norm <- tolower(trimws(marker))
  is_header <- function(r) {
    any(tolower(trimws(as.character(r))) == marker_norm, na.rm = TRUE)
  }
  hits <- which(vapply(seq_len(nrow(raw)),
    function(i) is_header(raw[i, ]), logical(1)
  ))
  if (length(hits) == 0L) {
    stop(sprintf("Header row not found: no cell equal to '%s'.", marker),
      call. = FALSE
    )
  }
  hits[1]
}

#' Top row of a (possibly multi-row) MSD header block
#'
#' Internal. MSD exports split a column label across several rows (e.g.
#' "Detection Limits:" / "Calc. Low"). Starting at the marker row `h`, walk
#' upward while rows remain non-empty, stopping at the first fully blank row
#' (which separates the header block from the experiment title). Returns the
#' index of the topmost header-fragment row.
#'
#' @param raw Raw sheet read with `col_names = FALSE`.
#' @param h Marker row index.
#' @return Integer index of the top header row (`<= h`).
#' @keywords internal
#' @noRd
.header_top <- function(raw, h) {
  row_nonempty <- function(i) {
    v <- trimws(as.character(unlist(raw[i, ], use.names = FALSE)))
    any(!is.na(v) & nzchar(v))
  }
  t <- h
  while (t > 1L && row_nonempty(t - 1L)) t <- t - 1L
  t
}

#' Compose column labels across a header block
#'
#' Internal. For each column, concatenate the non-empty trimmed cells from
#' rows `t:h` (top to bottom) into a single label, e.g. "Standard" + "Conc"
#' becomes "Standard Conc".
#'
#' @param raw Raw sheet read with `col_names = FALSE`.
#' @param t,h Top and marker (bottom) row indices of the header block.
#' @return Character vector of composed labels, one per column.
#' @keywords internal
#' @noRd
.compose_labels <- function(raw, t, h) {
  vapply(seq_len(ncol(raw)), function(j) {
    cells <- trimws(as.character(raw[[j]][t:h]))
    cells <- cells[!is.na(cells) & nzchar(cells)]
    paste(cells, collapse = " ")
  }, character(1))
}

#' Inspect the header labels of an MSD export
#'
#' Reads a Meso Scale Discovery (MSD) export, finds the header row by locating
#' the `header_marker` cell, and returns the (non-empty) column labels on that
#' row. Use this to build or adjust a `col_map` for [read_meso()].
#'
#' @param path Path to the `.xlsx` export.
#' @param sheet Sheet name or index (default 1).
#' @param header_marker The label identifying the header row. Default
#'   `"Plate Name"`.
#' @return A character vector of header labels.
#' @seealso [read_meso()], [meso_default_map()]
#' @export
meso_headers <- function(path, sheet = 1, header_marker = "Plate Name") {
  raw <- suppressMessages(
    readxl::read_excel(path, sheet = sheet, col_names = FALSE)
  )
  h <- .find_header_row(raw, header_marker)
  labels <- .compose_labels(raw, .header_top(raw, h), h)
  labels[nzchar(labels)]
}

#' Read a Meso Scale Discovery export into a canonical table
#'
#' Generic ingest for Meso Scale Discovery (MSD) immunoassay exports. The
#' header row is found by locating the `header_marker` cell (rather than a
#' fixed `skip`), and columns are renamed to canonical snake_case names via a
#' user-overridable `col_map`. This handles MSD layouts that differ in the
#' number of preamble rows, in label wording, and in the number of trailing
#' columns (e.g. an appended `% Recovery` / `% Recovery Mean`).
#'
#' @param path Path to the `.xlsx` export.
#' @param sheet Sheet name or index (default 1).
#' @param col_map Named character vector, canonical name = header regex. See
#'   [meso_default_map()]. Override or extend it for non-standard exports.
#' @param header_marker Label identifying the header row (default
#'   `"Plate Name"`).
#' @param na Strings to treat as missing (default `c("NaN", "..", "")`).
#' @param required Canonical names that must be present; an error is raised if
#'   any is missing. Default [meso_required_cols()]. Pass `character(0)` to
#'   disable the check.
#' @param keep_unmapped If `TRUE`, columns not matched by `col_map` are
#'   retained under their original labels. Default `FALSE` (they are dropped).
#'
#' @return A data frame with one row per measurement and canonical columns.
#'   Concentration-like columns are coerced to numeric; identifier columns to
#'   character.
#' @seealso [meso_default_map()], [meso_headers()], [meso_required_cols()]
#' @export
read_meso <- function(path, sheet = 1, col_map = meso_default_map(),
                      header_marker = "Plate Name",
                      na = c("NaN", "..", ""),
                      required = meso_required_cols(),
                      keep_unmapped = FALSE) {
  raw <- suppressMessages(
    readxl::read_excel(path, sheet = sheet, col_names = FALSE)
  )
  h <- .find_header_row(raw, header_marker)
  labels <- .compose_labels(raw, .header_top(raw, h), h)

  dat <- suppressMessages(
    readxl::read_excel(path,
      sheet = sheet, skip = h, col_names = FALSE, na = na
    )
  )

  n_use <- min(ncol(dat), length(labels))
  dat <- dat[, seq_len(n_use), drop = FALSE]
  labels <- labels[seq_len(n_use)]

  out <- list()
  matched <- logical(length(labels))
  for (canon in names(col_map)) {
    idx <- which(grepl(col_map[[canon]], labels, ignore.case = TRUE,
      perl = TRUE
    ))
    if (length(idx) == 0L) next
    if (length(idx) > 1L) {
      stop(sprintf(
        "col_map['%s'] matched %d headers: %s",
        canon, length(idx), paste(labels[idx], collapse = ", ")
      ), call. = FALSE)
    }
    out[[canon]] <- dat[[idx]]
    matched[idx] <- TRUE
  }

  miss <- setdiff(required, names(out))
  if (length(miss)) {
    stop(sprintf(
      "Required columns not found in '%s': %s",
      basename(path), paste(miss, collapse = ", ")
    ), call. = FALSE)
  }

  res <- as.data.frame(out, stringsAsFactors = FALSE, check.names = FALSE)

  if (keep_unmapped) {
    for (j in which(!matched)) {
      lab <- labels[j]
      if (!is.na(lab) && lab != "") res[[lab]] <- dat[[j]]
    }
  }

  for (nm in intersect(names(res), .meso_numeric_cols)) {
    res[[nm]] <- suppressWarnings(as.numeric(res[[nm]]))
  }
  for (nm in intersect(names(res), .meso_character_cols)) {
    res[[nm]] <- as.character(res[[nm]])
  }

  res
}
