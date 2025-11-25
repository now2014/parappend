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