#' Replace the data in a \code{"xifti"}
#'
#' Replace the data in a \code{"xifti"} with new data from a data matrix.
#'
#' If the \code{"xifti"} has \eqn{V} grayordinates and \eqn{T} measurements\,
#'  \code{newdata} should be a \eqn{V \times Q} matrix. If \eqn{Q}
#'  is not equal to \eqn{T}, then any column names or label tables will be
#'  removed. (A "dlabel" will be converted to a "dscalar".)
#' @inheritParams xifti_Param
#' @param newdata The \eqn{V \times T} matrix of data values to replace those
#'  in \code{xifti} with. The left cortex vertices should be at the top, right
#'  cortex vertices in the middle, and subcortex vertices at the bottom (when
#'  present).
#'
#'  If \code{newdata} is instead a \eqn{V \times Q} matrix where \eqn{Q} is not
#'  \eqn{T}, then any column names or label tables will be removed.
#'  (A "dlabel" will be converted to a "dscalar".)
#'
#'  Can also be a length-one vector to set all values equally.
#' @param newnames Replaces the names in the \code{xifti}. If \code{NULL}
#'  (default), keep the original names, except if the number of columns
#'  in \code{newdata} doesn't match that of \code{xifti}, in which case
#'  no names will be used.
#' @param subcortex_by_bs If subcortical data is being provided in 
#'  \code{newdata}, are the locations ordered by brain structure? Default: 
#'  \code{FALSE}. The \code{"xifti"} data matrix is not ordered by brain 
#'  structure, but CIFTI files and most other CIFTI packages do sort subcortical
#'  data by brain structure first, and then array index second. 
#' @return The new \code{"xifti"}
#'
#' @family manipulating xifti
#' @export
newdata_xifti <- function(xifti, newdata, newnames=NULL, subcortex_by_bs=FALSE) {
  stopifnot(is.xifti(xifti))
  stopifnot(is.logical(subcortex_by_bs))
  stopifnot(length(subcortex_by_bs)==1)

  xifti_dim <- dim(xifti)

  newdata_dim <- dim(newdata)
  if (is.null(newdata_dim)) { 
    if (length(newdata) == 1) {
      newdata <- matrix(newdata, nrow=xifti_dim[1], ncol=xifti_dim[2])
    } else {
      if (length(newdata) != xifti_dim[1]) {
        stop(
          "`xifti` and `newdata` do not have the same dimensions.\n",
          "The `xifti` has ", xifti_dim[1], " grayordinates and ", xifti_dim[2], " measurements.\n",
          "Meanwhile, `newdata` is length ", length(newdata), "."
        )
      }
      newdata <- matrix(newdata, nrow=xifti_dim[1])
    }
    newdata_dim <- dim(newdata)
  }
  if (ncol(newdata) == 0) { stop("Empty `newdata`.") }
  stopifnot(length(newdata_dim)==2)
  class(newdata) <- "numeric"

  xifti_dim <- dim(xifti)
  same_columns <- TRUE
  if (!all(xifti_dim == newdata_dim)) {
    # Transposed input.
    if (all(xifti_dim == rev(newdata_dim))) {
      warning("Transposing `newdata`.\n")
      newdata <- t(newdata)

    # Different number of columns.
    } else if (xifti_dim[1] == newdata_dim[1]) {
      xifti <- select_xifti(xifti, rep(1, newdata_dim[2]))
      same_columns <- FALSE
      if (!is.null(xifti$meta$cifti$intent) && xifti$meta$cifti$intent == 3007) {
        warning("Mismatch # columns: converting to `dscalar`.\n")
        xifti <- convert_xifti(xifti, "dscalar")
      }
    # Error.
    } else {
      stop(
        "`xifti` and `newdata` do not have the same dimensions.\n",
        "The `xifti` has ", xifti_dim[1], " grayordinates and ", xifti_dim[2], " measurements.\n",
        "Meanwhile, `newdata` is ", newdata_dim[1], " by ", newdata_dim[2], "."
      )
    }
  }

  # For `dlabel` xifti, check that newdata values are valid.
  if (!is.null(xifti$meta$cifti$intent) && xifti$meta$cifti$intent == 3007) {
    # [TO DO] `convert_to_dscalar`
    for (cc in seq(xifti_dim[2])) {
      if (!all(newdata[,cc] %in% xifti$meta$cifti$labels[[cc]]$Key)) {
        warning("`newdata` has values that are not in the label table for column ", cc, ". Converting to `dscalar`.")
        xifti <- convert_to_dscalar(xifti)
        break
      }
    }
  }

  # New data.
  V_start <- 0
  for (bs in names(xifti$data)) {
    if (!is.null(xifti$data[[bs]])) {
      V_bs <- nrow(xifti$data[[bs]])
      dat_idx <- if (bs=="subcort" && subcortex_by_bs) {
        seq(V_start+1, V_bs+V_start)[order(order(xifti$meta$subcort$labels))]
      } else {
        seq(V_start+1, V_bs+V_start)
      }
      xifti$data[[bs]] <- newdata[dat_idx,,drop=FALSE]
      V_start <- V_bs+V_start
    }
  }

  # New names.
  if (!is.null(newnames)) {
    if (length(newnames) != newdata_dim[2]) {
      stop("The length of `newnames` does not match the number of columns in the new `xifti`.")
    }
    if (!is.null(xifti$meta$cifti$intent) && xifti$meta$cifti$intent == 3002) {
      warning("The dtseries intent (3002) does not use column names. Ignoring `newnames`.")
    } else {
      xifti$meta$cifti$names <- newnames
    }
  } else if (!same_columns) {
    if (!(is.null(xifti$meta$cifti$intent) || xifti$meta$cifti$intent == 3002)) {
      xifti$meta$cifti$names <- paste("Column", seq(ncol(newdata)))
    }
  }

  if (!is.xifti(xifti)) { stop("Could not make a valid \"xifti\" object.") }
  xifti
}
