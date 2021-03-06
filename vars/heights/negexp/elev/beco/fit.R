### fit.R --- 
## Filename: fit.R
## Description: Fit BECOs only using elevation (no canopy)
## Author: Noah Peart
## Created: Tue Mar 17 20:35:37 2015 (-0400)
## Last-Updated: Fri Mar 20 14:56:51 2015 (-0400)
##           By: Noah Peart
######################################################################
source("~/work/ecodatascripts/vars/heights/negexp/elev/model.R")            # model/fit functions
source("~/work/ecodatascripts/vars/heights/prep.R")                         # data prep
source("~/work/ecodatascripts/vars/heights/canopy/load_canopy.R")           # canopy functions
source("~/work/ecodatascripts/vars/heights/extra_beco.R")                   # extra birch data
library(dplyr)
library(magrittr)

################################################################################
##
##                                 Run fits
##
################################################################################
## Can only fit for 98 and 10
base_dir <- "~/work/ecodatascripts/vars/heights/negexp/elev/beco/"
yrs <- c(86, 98, 10)  # Note: only 98 uses extra BECOs
spec <- c("beco")
can_func <- "can_hts"  # canopy functions defined in canopy directory

for (yr in yrs) {
    if (yr == 98) dat <- join_extra_beco(pp, becos98)  # using extra becos
    else dat <- prep_data(dat=pp, yr=yr, spec=spec, can_func=can_func)
    ps <- readRDS(paste0(base_dir, "beco_", yr, ".rds"))
    ps$gamma <- NULL  # decided to kill intercept param

    method <- "SANN" # "Nelder-Mead"
    maxit <- 1e6

    summary(fit <- run_fit(dat, ps, yr, method=method, maxit=maxit))  # SANN first
    summary(fit2 <- run_fit(dat, as.list(coef(fit)), yr))             # the Nelder-Mead

    ## save parameters
    ps <- as.list(coef(fit2))
    saveRDS(ps, file=paste0(base_dir, "beco_", yr, ".rds"))
}
