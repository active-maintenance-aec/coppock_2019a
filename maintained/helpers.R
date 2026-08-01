# coppock_2019a/maintained/helpers.R
# Shared packages and helper functions sourced by every script in maintained/.

library(here)
library(tidyverse)
library(estimatr)
library(metap)
library(knitr)
library(kableExtra)

# Table A1 cell formatting ----
# "est (se)" to two decimals, starred at p < 0.05, blank where a sample has no
# version of the study.
format_entry <- function(est, se, p) {
  if (is.na(p)) return(NA_character_)
  entry <- sprintf("%.2f (%.2f)", est, se)
  if (p < 0.05) entry <- paste0(entry, "*")
  entry
}
