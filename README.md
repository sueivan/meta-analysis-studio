# Meta Analysis Studio V0.2

Local Windows R/Shiny prototype. **Not validated for publication use.** Statistical output must be independently checked against a known reference analysis before manuscript submission.

## Start

Install R and make Rscript available in PATH. Double-click `START_META.bat`. The first run installs `shiny` and `metafor` from CRAN (internet required). The app serves only `127.0.0.1:3838` and processes files locally.

Alternatively, in R console:

```r
install.packages(c('shiny','metafor'))
shiny::runApp('path/to/meta_studio_v02', launch.browser=TRUE)
```

## Data format

CSV with one row per independent study-level effect:

* Continuous: `study_id,n_t,mean_t,sd_t,n_c,mean_c,sd_c`
* Binary: `study_id,event_t,n_t,event_c,n_c`
* Generic: `study_id,yi,vi`

`t` = treatment; `c` = control. Use end-of-treatment values or precomputed, correctly derived change-score effects, not within-group pre/post effects as though they were between-group effects. For generic ratio effects, use log-scale yi and sampling variance vi. The app cannot automatically detect multiple arms, correlated effect sizes, duplicated populations, crossover designs, cluster adjustment, scale direction, or appropriate continuity correction. Verify these before use.

## Statistical specification

Random-effects model with REML tau-squared estimation, optionally Hartung-Knapp inference. MD and Hedges-corrected SMD via metafor::escalc; RR/OR analyzed on log scale. For binary outcomes with zero cells, 0.5 correction is applied to studies with zero cells by metafor::escalc. This choice requires sensitivity analysis in sparse datasets. Study number < 2, invalid counts/SD, and duplicate IDs are blocked.

**Limitations:** No subgroup analysis, meta-regression, publication-bias tests, Excel import, Word export, or automated fully reproducible script in this initial build. The script download is a parameter record, not a self-contained replay script. Claims to the contrary should not be made. Do not claim to have used R in a manuscript until analysis is actually executed on your computer.

Software Development: Professor Su Yuesheng / Medical Doctor
