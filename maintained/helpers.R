# coppock_2019a/maintained/helpers.R
# Shared packages and helper functions sourced by every script in maintained/.

library(here)
library(tidyverse)
library(sandwich)
library(lmtest)
library(estimatr)
library(metap)
library(knitr)
library(kableExtra)

# commarobust_tidy ----
# The archive's estimates come from commarobust::commarobust_tidy(). That package
# was retired by its author in November 2018 in favour of estimatr; its current
# GitHub head exports nothing at all and loads only to print a message saying so,
# and its last working code sits on a branch called "legacy". Depending on it is
# therefore not an option. The retired commarobust(fit) was exactly
#   lmtest::coeftest(fit, sandwich::vcovHC(fit, type = "HC2")),
# HC2 being the Neyman variance the paper reports, so that call is inlined here.
# Returns a tibble with columns term, est, se, t, p, dv.
commarobust_tidy <- function(fit) {
  cr_mat <- coeftest(fit, vcovHC(fit, type = "HC2"))[]
  tibble(
    term = rownames(cr_mat),
    est = cr_mat[, "Estimate"],
    se = cr_mat[, "Std. Error"],
    t = cr_mat[, "t value"],
    p = cr_mat[, "Pr(>|t|)"],
    dv = as.character(formula(fit)[[2]])
  )
}

# Table A1 cell formatting ----
# "est (se)" to two decimals, starred at p < 0.05, blank where a sample has no
# version of the study.
format_entry <- function(est, se, p) {
  if (is.na(p)) return(NA_character_)
  entry <- sprintf("%.2f (%.2f)", est, se)
  if (p < 0.05) entry <- paste0(entry, "*")
  entry
}
