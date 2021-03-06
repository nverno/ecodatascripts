### vis_functions.R --- 
## Filename: vis_functions.R
## Description: Helper functions for visuals
## Author: Noah Peart
## Created: Tue Mar 24 14:09:20 2015 (-0400)
## Last-Updated: Wed Mar 25 18:12:42 2015 (-0400)
##           By: Noah Peart
######################################################################
source("~/work/ecodatascripts/vars/heights/prep.R")  # preps data, adds canhts

library(rgl)
library(plyr)
library(dplyr)

## Get predictions for years/species
## spec: must match individual species or species grouping that was fit
get_preds <- function(spec, years, modtype="gompertz", inds="full", hh=FALSE,
                      cols = list(stat="STAT", ht="HTTCR", dbh="DBH", canht="canht")) {
    species <- unique(pp$SPEC)
    specs <- list(maples=grep("^AC", species, value = T),           # ACSA, ACPE, ACSP
                  hardwoods=grep("^AC|FA", species, value = T),     # maples + FAGR
                  betula=grep("^BE", species, value = T))           # All betulas
    base_dir <- paste0("~/work/ecodatascripts/vars/heights/", modtype, "/", inds, "/")
    source(paste0(base_dir, "model.R"))  # load the model
    par_dir <- paste0(base_dir, "/", tolower(spec), "/")
    keep_cols <- c("SPEC", "ELEV", "canht")
    sppgroup <- spec
    dat <- pp
    if(hh) {
        dat <- tp  # use transect data for HH
        cols$ht = "HT"
    }
    if (spec %in% names(specs)) sppgroup <- specs[[spec]]
    ps <- lapply(years, FUN = function(yr){
        pars <- readRDS(paste0(par_dir, tolower(spec), "_", yr, ".rds"))
        stat <- paste0(cols$stat, yr)
        dbh <- paste0(cols$dbh, yr)
        ht <- paste0(cols$ht, yr)

        ## Prep data
        if (hh) dd <- prep_hh(dat, yr=yr, spec=toupper(sppgroup))
        else dd <- prep_data(dat, yr=yr, spec=toupper(sppgroup))

        ## Get predictions
        if (inds == "full") pred <- {
            do.call(modtype, list(pars, dd[,dbh], dd[,"ELEV"], dd[,"canht"]))
        } else if (inds == "elev") {
            pred <- do.call(modtype, list(pars, dd[,dbh], dd[,"ELEV"]))
        } else {
            pred <- do.call(modtype, list(pars, dd[,dbh], dd[,"canht"]))
        }
        
        res <- cbind(dd[,c(dbh, ht, keep_cols)], pred=pred)
        names(res) <- gsub("[[:digit:]]", "", tolower(names(res)))  # don't track yrs here
        attr(res, "ps") <- pars
        attr(res, "yr") <- yr
        attr(res, "mod") <- get(modtype)
        attr(res, "modname") <- modtype
        attr(res, "inds") <- inds
        attr(res, "spec") <- spec
        attr(res, "hh") <- hh
        attr(res, "cols") <- cols
        res
    })
    names(ps) <- lapply(years, FUN=function(yr) paste0(spec, yr))
    return( ps )
}

plot_preds <- function(preds) {
    ## Plots predicted points
    require(rgl)
    dat <- preds[[1]]
    cols <- palette()[1:length(preds)]
    modtype <- attr(dat, "modname")  # model type used
    inds <- attr(dat, "inds")  # independent vars
    spec <- attr(dat, "spec")
    plot3d(xyz.coords(dat[, "dbh"], dat[, "elev"], dat[, "pred"]), alpha = 0.2,
           xlab = "DBH", ylab = "Elevation", zlab = "Height", col=cols[1],
           main = paste0(modtype, " allometric model predictions (,", inds, ") for ", spec))
    if (length(preds) > 1) {
        for (i in 2:length(preds)) {
            dat <- preds[[i]]
            points3d(xyz.coords(dat[, "dbh"], dat[, "elev"], dat[, "pred"]), col=cols[i])
        }
    }
    yrs <- lapply(preds, FUN = function(x) attr(x, "yr"))
    legend3d("topleft", legend=yrs, text.col=cols)
}

add_pred_lines <- function(preds) {
    cols <- palette()[1:length(preds)]
    for (i in 1:length(preds)) {
        dat <- preds[[i]]
        hh <- attr(dat, "hh")
        inds <- attr(dat, "inds")
        mod <- attr(dat, "mod")
        ps <- attr(dat, "ps")
        x <- seq(0, max(dat[,"dbh"]), length=50) # min(dat[,"dbh"])
        elevs <- unique(dat[,"elev"])

        if (hh || inds == "full") {
            combos <- dat %>% select(elev, canht) %>% distinct(elev, canht) %>%
                arrange(elev)
            chts <- combos[["canht"]]
            elevs <- combos[["elev"]]
            if (hh) z <- outer(x, chts, mod, ps=ps)
            else z <- outer(x, elevs, mod, ps=ps,
                            canht=rep(chts, each=length(x)))
        } else {
            z <- outer(x, elevs, mod, ps=ps)
        }
        for (j in 1:ncol(z)) {
            lines3d(xyz.coords(x, rep(elevs[j], length(x)), z = z[,j]),
                    col=cols[i], lwd=2, alpha = 0.2)
        }
    }
}

add_observed <- function(preds, col=NULL) {
    require(rgl)
    colors <- palette()[1:length(preds)]
    if(!missing(col))
        colors <- col

    for (i in 1:length(preds)) {
        dat <- preds[[i]]
        hh <- attr(dat, "hh")
        if (hh) {
            points3d(xyz.coords(dat[, "dbh"], dat[, "elev"], dat[, "ht"]),
                     col=colors[i], pch = 16, pwd=2)
        } else {
            points3d(xyz.coords(dat[, "dbh"], dat[, "elev"], dat[, "httcr"]),
                     col=colors[i], pch = 16, pwd=2)
        }
    }
}
