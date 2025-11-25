#' @title Append data to a file with parallel safety
#' 
#' @param out.file The output file path
#' @param data The data to append (eg. a data.frame or data.table)
#' @param append Whether to append to the file (default: TRUE) or overwrite (FALSE)
#' @param col.names Whether to write column names (default: FALSE), defaults to TRUE if file does not exist.
#' @param sep The separator to use (default: "\\t")
#' @param quote Whether to quote character/factor columns (default: FALSE)
#' @param row.names Whether to write row names (default: FALSE)
#' @param na The string to use for missing values (default: "NA")
#' @param rm.lock Whether to remove the lock file after releasing the lock (default: FALSE)
#' @param max.retries Maximum number of retries to acquire lock (default: Inf)
#' @param time.sleep Time to wait (in seconds) between retries (default: 0.01)
#' @param ... Additional arguments passed to data.table::fwrite
#'
#' @return invisible()
#' 
#' @export
#' 
#' @examples
#' \dontrun{
#' df <- data.frame(x = 1:10, y = letters[1:10])
#' if(file.exists("parappend.test.tsv")) unlink("parappend.test.tsv")
#' myfun <- function(i) {
#'   Sys.sleep(runif(1, 0, 0.1))  # Simulate variable processing time
#'   parappend::parappend("parappend.test.tsv", df[i, , drop = FALSE])
#' }
#' tmp <- parallel::mclapply(seq_len(nrow(df)), myfun, mc.cores = 4)
#' # Verify the output
#' result <- data.table::fread("parappend.test.tsv")
#' print(result)
#' # Clean up
#' unlink("parappend.test.tsv")
#' unlink("parappend.test.tsv.lock")
#' 
#' }
#' @seealso \code{\link[data.table]{fwrite}}
#' @importFrom filelock lock unlock
#' @importFrom data.table fwrite
parappend <- function(out.file, data,
  append = TRUE, col.names = FALSE, sep = "\t",
  quote = FALSE, row.names = FALSE, na = "NA",
  rm.lock = FALSE, max.retries = Inf, time.sleep = 0.01, ...) {
  
  if (is.null(data) || nrow(data) == 0) return(invisible())
  
  # Acquire lock with retry logic
  lock <- NULL
  retries <- 0
  
  while (is.null(lock) && retries <= max.retries) {
    lock <- tryCatch({
      acquire.lock(out.file, timeout = time.sleep * 1000)  # timeout in ms
    }, error = function(e) {
      NULL
    })
    
    if (is.null(lock)) {
      retries <- retries + 1
      if (retries <= max.retries) {
        Sys.sleep(time.sleep)
      }
    }
  }
  
  if (is.null(lock)) {
    stop("Failed to acquire lock after ", max.retries, " retries for file: ", out.file)
  }
  
  # Ensure lock is released
  on.exit({
    release.lock(lock)
    if (rm.lock && file.exists(paste0(out.file, ".lock"))) {
      unlink(paste0(out.file, ".lock"))
    }
  })
  
  # Check file existence and set parameters INSIDE the lock
  file_exists <- file.exists(out.file)
  if (!file_exists) {
    append <- FALSE
    col.names <- TRUE
  } else if (!append) {
    # If not appending and file exists, we're overwriting
    col.names <- TRUE
  }
  
  # Ensure directory exists
  out.dir <- dirname(out.file)
  if (!dir.exists(out.dir)) {
    dir.create(out.dir, recursive = TRUE, showWarnings = FALSE)
  }
  
  # Write data
  data.table::fwrite(
    x = data,
    file = out.file,
    sep = sep,
    quote = quote,
    row.names = row.names,
    col.names = col.names,
    append = append,
    na = na,
    ...
  )
  
  invisible()
}