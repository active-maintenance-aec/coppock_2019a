# coppock_2019a/maintained/helpers.R
# Shared packages and helper functions sourced by every script in maintained/.

library(here)
library(tidyverse)
library(estimatr)
library(metap)
library(knitr)
library(kableExtra)

here::i_am("maintained/helpers.R")

# Table A1 cell formatting ----
# "est (se)" to two decimals, starred at p < 0.05, blank where a sample has no
# version of the study.
format_entry <- function(est, se, p) {
  if (is.na(p)) return(NA_character_)
  entry <- sprintf("%.2f (%.2f)", est, se)
  if (p < 0.05) entry <- paste0(entry, "*")
  entry
}

# Blank a figure PDF's embedded timestamps ----
# R's pdf() device stamps /CreationDate and /ModDate with the wall clock, so an
# otherwise deterministic pipeline writes a different file on every run. The epoch
# string is the same width as what it replaces, which keeps the cross-reference byte
# offsets valid, and a file with no timestamp is left alone.
blank_pdf_timestamps <- function(path) {
  epoch <- charToRaw("D:19700101000000")
  raw_pdf <- readBin(path, "raw", file.size(path))
  hits <- grepRaw("D:[0-9]{14}", raw_pdf, all = TRUE)
  if (length(hits) == 0) return(invisible(path))
  for (h in hits) raw_pdf[h:(h + length(epoch) - 1L)] <- epoch
  writeBin(raw_pdf, path)
  invisible(path)
}
