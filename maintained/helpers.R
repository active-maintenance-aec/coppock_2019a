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

# The published study label, where the deposit's differs ----
# The deposited study table calls the polarization study `Levendusky and
# Malhotra (2015)`, which is its online-first year; the published article's
# reference list gives Political Communication 33(2):283-301, 2016, and its
# Table 1 and its Figure 2 both print 2016. The page governs, so every consumer
# of study_df relabels through this one place: figure 2 sets the label as a
# facet strip and Table A1 sets it as a row group, and a fix made in one of
# them would leave the two disagreeing.
#
# NOTHING IN THE GROUND TRUTH COMPARES A LABEL. All seven of Figure 2's claims
# carry match_rewrite = 1 because the values agree; the year was found by
# comparing the artwork's text layer with the published figure's band as a
# multiset, which is the remaster's R5 check and the only one that reaches a
# label.
# study_label is a character column and study_factor is a FACTOR whose level
# order is the order the published Table A1 and Figure 2 set their studies in.
# The two therefore relabel differently, and that is not a detail: an earlier
# version of this function sent both through as.character(), which dropped the
# levels and re-sorted Table A1's twelve study blocks alphabetically. Nothing
# in the ground truth compares a row order either.
published_study_labels <- function(study_df) {
  published <- c("Levendusky and Malhotra (2015)" = "Levendusky and Malhotra (2016)")
  swap <- function(x) unname(coalesce(published[x], x))
  study_df |>
    mutate(study_label = swap(study_label),
           study_factor = fct_relabel(study_factor, swap))
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
