#' Format a path
#'
#' Normalize and validate a path (optionally, within a certain directory).
#'
#' @param path The path to normalize.
#' @param dir (Optional) the directory to append to the beginning of the path.
#'  \code{NULL} (default) to not append any directory, leaving \code{path}
#'  unchanged.
#' @param mode The mode for \code{\link{file.access}} to verify existence,
#'  writing permission, or reading permission. Use NA (default) to not perform
#'  any is.
#'
#' @return The normalized path, or \code{NULL} if the path was \code{NULL}.
#'
#' @keywords internal
#' 
format_path <- function(path, dir=NULL, mode=NA) {

  # Do nothing if the path is NULL.
  if (is.null(path)) { return(path) }

  # Append dir if provided.
  if (!is.null(dir)) { path <- file.path(dir, path) }
  path <- normalizePath(path, mustWork=FALSE)

  # Get the full file path (for Linux: previous normalizePath() does not get
  #   full file path if dir did not exist.)
  path <- file.path(
    normalizePath(dirname(path), mustWork=FALSE),
    basename(path)
  )

  # Check existence/writing permission/reading permission of the path.
  #   [NOTE]: This goes against this advice: 
  #   "Please note that it is not a good idea to use this
  #   function to test before trying to open a file. On a multi-tasking system,
  #   it is possible that the accessibility of a file will change between the
  #   time you call file.access() and the time you try to open the file. It is
  #   better to wrap file open attempts in try.
  stopifnot(all(mode %in% c(NA, 0, 2, 4)))
  for(m in mode) {
    if (is.na(mode)) { next }
    if (any(file.access(dirname(path), m) != 0)) {
      stop(paste0(
        "The directory \"", dirname(path), "\"",
        c(
          " doesn't exist. ", "",
          " is not writeable. Does it exist? ", "",
          "is not readable. Does it exist? "
        )[m+1],
        "Check and try again.\n"
      ))
    }
  }

  path
}

#' Is this an existing file path?
#'
#' Simple check if something is an existing file.
#'
#' @param x The potential file name
#'
#' @return Logical. Is \code{x} an existing file?
#'
#' @keywords internal
#'
is.fname <- function(x){
  if(!(length(x)==1 & is.character(x))){ return(FALSE) }
  file.exists(x) & !dir.exists(x)
}

#' Format a path for \code{\link{system}}
#' 
#' Right now, it uses \code{shQuote}
#'
#' @param R_path The name of the file. It should be properly formatted: if it
#'  exists, \code{file.exists(R_path)} should be \code{TRUE}.
#'
#' @return The name of the file
#'
#' @keywords internal
#' 
sys_path <- function(R_path) {
  shQuote(path.expand(R_path))
}

#' Get kwargs
#' 
#' Get the names of the arguments of a function as a character vector.
#'
#' @param fun The function to get the argument names for.
#'
#' @return The names of the arguments of \code{fun} as a character vector
#'
#' @keywords internal
#' 
get_kwargs <- function(fun) {
  kwargs <- names(as.list(args(fun)))
  kwargs <- kwargs[seq(length(kwargs)-1)] # last is empty
  kwargs
}

#' Merges two kwargs 
#' 
#' Merge two kwarg lists. If a kwarg is present in both lists but with different
#'  values, an error is raised.
#' @param kwargsA The first list of kwargs.
#' @param kwargsB The second list of kwargs. If duplicates are present, the default
#'  message recommends the user to remove the kwarg here in favor of placing the
#'  correct one in \code{kwargsA}.
#' @param labelA (Optional) Descriptor of \code{kwargsA} for error statement. Default "first kwarg(s)".
#' @param labelB (Optional) Descriptor of \code{kwargsB} for error statement. Default "second kwarg(s)".
#' @param extraMsg (Optional) Extra text for error statement. "\[DEFAULT\]" (default) will use this message:
#'  "Note that a kwarg only has to be provided to one of these. Place the correct value in the first
#'  location and remove the kwarg from the second location".
#'
#' @return A list with the union of \code{kwargsA} and \code{kwargsB}
#'
#' @keywords internal
#' 
merge_kwargs <- function(kwargsA, kwargsB,
  labelA="first kwarg(s)", labelB="second kwarg(s)",
  extraMsg="[DEFAULT]") {

  # Identify repeated kwargs.
  repeatedB_bool <- names(kwargsB) %in% names(kwargsA)
  repeated <- names(kwargsB)[repeatedB_bool]
  # Stop if any repeated kwargs differ.
  kwargs_mismatch <- !mapply(identical, kwargsA[repeated], kwargsB[repeated])
  if (sum(kwargs_mismatch) > 0) {
    if(identical(extraMsg, "[DEFAULT]")){
      extraMsg <- "Note that a kwarg only has to be provided to one of these. \
        Place the correct value in the first location and remove the kwarg \
        from the second location"
    }
    stop(paste0(
      "A keyword argument(s) was provided twice with different values. Here is the kwarg(s) in disagreement:\n",
      "The ", labelA, " was:\n",
      "\"", paste0(kwargsA[kwargs_mismatch], collapse="\", \""), "\".\n",
      "The ", labelB, " was:\n",
      "\"", paste0(kwargsB[kwargs_mismatch], collapse="\", \""), "\".\n",
      extraMsg
    ))
  }
  kwargs <- c(kwargsA, kwargsB[!repeatedB_bool])
}

#' Match user inputs to expected values
#'
#' Match each user input to an expected/allowed value. 
#' 
#' Raise a warning if either
#'  several user inputs match the same expected value, or at least one could not
#'  be matched to any expected value. \code{ciftiTools} uses this function to
#'  match keyword arguments for a function call. Another use is to match
#'  brainstructure labels ("left", "right", or "subcortical").
#'
#' @param user Character vector of user input. These will be matched to
#'  \code{expected} using \code{match.arg()}.
#' @param expected Character vector of expected/allowed values.
#' @param fail_action If any value in \code{user} could not be
#'  matched, or repeated matches occurred, what should happen? Possible values
#'  are \code{"stop"} (default; raises an error), \code{"warning"}, and
#'  \code{"nothing"}.
#' @param user_value_label How to refer to the user input in a stop or warning
#'  message. If \code{NULL}, no label is used.
#'
#' @return The matched user inputs
#'
#' @keywords internal
#' 
match_input <- function(
  user, expected,
  fail_action=c("stop", "warning", "message", "nothing"),
  user_value_label=NULL) {

  fail_action <- match.arg(
    fail_action,
    c("stop", "warning", "message", "nothing")
  )
  unrecognized_FUN <- switch(fail_action,
    stop=stop,
    warning=warning,
    message=message,
    nothing=invisible
  )

  if (!is.null(user_value_label)) {
    user_value_label <- paste0("\"", user_value_label, "\" ")
  }
  msg <- paste0(
    "The user-input values ", user_value_label,
    "did not match their expected values. ",
    "Either several matched the same value, ",
    "or at least one did not match any.\n\n",
    "The user inputs were:\n",
    "\t\"", paste0(user, collapse="\", \""), "\".\n",
    "The expected values were:\n",
    "\t\"", paste0(expected, collapse="\", \""), "\".\n"
  )

  tryCatch(
    {
      matched <- match.arg(user, expected, several.ok=TRUE)
      if (length(matched) != length(user)) { stop() }
      return(matched)
    },
    error = function(e) {
      unrecognized_FUN(msg)
    },
    finally = {
    }
  )

  invisible(NULL)
}

#' Do these character vectors match exactly?
#' 
#' Checks if a user-defined character vector matches an expected character
#'  vector. That is, they share the same lengths and entries in the same order.
#'  For vectors of the same lengths, the result is \code{all(a == b)}.
#' 
#' Attributes are ignored.
#'
#' @param user Character vector of user input. 
#' @param expected Character vector of expected/allowed values.
#' @param fail_action If any value in \code{user} could not be
#'  matched, or repeated matches occurred, what should happen? Possible values
#'  are \code{"message"} (default), \code{"warning"}, \code{"stop"}, and
#'  \code{"nothing"}.
#'
#' @return Logical. Do \code{user} and \code{expected} match?
#' 
#' @keywords internal
#' 
match_exactly <- function(
  user, expected,
  fail_action=c("message", "warning", "stop", "nothing")) {

  fail_action <- match.arg(fail_action, c("message", "warning", "stop", "nothing"))
  unrecognized_FUN <- switch(fail_action,
    message=message,
    warning=warning,
    stop=stop,
    nothing=invisible
  )

  msg <- paste0(
    #"Mismatch between:\n",
    "\t\"", paste0(user, collapse="\", \""), "\".\n",
    "and:\n",
    "\t\"", paste0(expected, collapse="\", \""), "\".\n"
  )

  if (length(user) != length(expected)) {
    msg <- paste0("Different lengths:\n", msg)
    unrecognized_FUN(msg)
    return(FALSE)
  }

  if (!all(user == expected)) {
    msg <- paste0("Mismatch:\n", msg)
    unrecognized_FUN(msg)
    return(FALSE)
  }

  return(TRUE)
}

#' Print suppressible message
#' 
#' Print message only if ciftiTools Option "suppress_msgs" is \code{FALSE}.
#' 
#' @param msg The message
#' @keywords internal
#' 
#' @return \code{NULL}, invisibly
#' 
ciftiTools_msg <- function(msg){
  if (!ciftiTools.getOption("suppress_msgs")) { 
    cat(msg); cat("\n") 
  }
  invisible(NULL)
}

#' Print suppressible warning
#' 
#' Print warning only if ciftiTools Option "suppress_msgs" is \code{FALSE}.
#' 
#' @param warn The warning message
#' @keywords internal
#' 
#' @return \code{NULL}, invisibly
#' 
ciftiTools_warn <- function(warn){
  if (!ciftiTools.getOption("suppress_msgs")) { 
    warning(warn, immediate. = TRUE) 
  }
  invisible(NULL)
}

#' All integers?
#'
#' Check if a data vector or matrix is all integers.
#'
#' @param x The data vector or matrix
#' @keywords internal
#'
#' @return Logical. Is \code{x} all integers?
#'
all_integers <- function(x){
  if (!is.numeric(x)) { return(FALSE) }
  non_integer <- max(abs(x - round(x)))
  non_integer==0 && !is.na(non_integer)
}