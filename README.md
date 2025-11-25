# parappend

`parappend` provides parallel-safe file appending for files, based on operating system file locking (filelock).
Suitable for:

- `parallel::mclapply`
- `parallel::parLapply`
- `future.apply`
- Any multi-process scenario

## Installation

```r
devtools::install_github("now2014/parappend")
```

## Example
```r
library(parappend)
df <- data.frame(x = 1:10, y = letters[1:10])
if(file.exists("parappend.test.tsv")) unlink("parappend.test.tsv")
myfun <- function(i) {
    Sys.sleep(runif(1, 0, 0.1))  # Sim
    parappend::parappend("parappend.test.tsv", df[i, , drop = FALSE])
}
tmp <- parallel::mclapply(seq_len(nrow(df)), myfun, mc.cores = 4)
# Verify the output
result <- data.table::fread("parappend.test.tsv")
print(result)
# Clean up
unlink("parappend.test.tsv")
unlink("parappend.test.tsv.lock")
```