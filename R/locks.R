#' @title Acquire a file lock
#' @param out.file The output file path to lock
#' @param timeout Timeout in seconds
#'
#' @return A lock handle
#' @noRd
#' @keywords internal
#' @importFrom filelock lock
acquire.lock <- function(out.file, timeout = 60) {
  lcf <- paste0(out.file, ".lock")
  dir.create(dirname(lcf), recursive = TRUE, showWarnings = FALSE)
  lock <- filelock::lock(lcf, timeout = timeout)
  if (is.null(lock)) stop("Failed to acquire lock: ", lcf)
  lock
}

#' @title Release a file lock
#'
#' @param lock The lock handle returned by acquire.lock()
#' @noRd
#' @keywords internal
#' @importFrom filelock unlock
release.lock <- function(lock) {
  filelock::unlock(lock)
}