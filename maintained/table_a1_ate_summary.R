# coppock_2019a/maintained/table_a1_ate_summary.R
# Output: output/table_a1_ate_summary.csv, output/table_a1_ate_summary.tex
# Depends on: analysis_ate_estimates.R output, helpers.R
# Description: Summary table of ATE estimates by study, DV, coefficient, and sample.

source(here::here("maintained", "helpers.R"))

# Inputs ----

results <- read_rds(here::here("maintained", "output", "analysis_results.rds"))

load(here::here("original", "coppock_generalizability_study_data.RData"))
study_df <- published_study_labels(study_df)

results <- results |>
  left_join(study_df, by = "study") |>
  left_join(dvs_df, by = "dv") |>
  left_join(coefficients_df, by = "term")

# The published page's own labels ----
# THE DEPOSIT'S LABELS ARE A PRE-COPYEDIT DRAFT AND THE PAGE GOVERNS THE WORDS.
# Cambridge sets both label columns in sentence case where the study data use
# title case, sets `Both/memory based` where they set `Both / Memory Based`,
# spells out `Positive + negative` where they abbreviate `Pos + Neg`, and sets a
# curly apostrophe in `Citizens rights frame`. 41 of this table's 64 labels
# differ. They are read off published pp. 15 and 16 and recorded in
# ground_truth/published_table_a1_labels.csv, which is a transcription like
# published_table_a1.csv beside it rather than a rule.
#
# NOTHING IN THE GROUND TRUTH COMPARES A LABEL, and neither does either remaster
# gate: a float's interior is dropped by rectangle on both sides. The remastered
# edition printed all 41 for as long as it has existed and read zero unexplained
# throughout. What found them is check_floats.py, which compares the words inside
# each float on both compiled PDFs.
#
# THIS IS NOT DONE IN published_study_labels, AND THAT IS DELIBERATE. The
# published article disagrees with itself about one study: Figure 2 on p. 7 sets
# `McGinty, Webster, and Barry (2013)` while Table A1, Table 1 and the body all
# set it without the Oxford comma. The deposit's label already matches Figure 2,
# so relabelling in the one shared place would correct this table and break that
# figure. A label the two published floats spell differently belongs to each
# float and not to the study.
a1_labels <- read_csv(here::here("ground_truth", "published_table_a1_labels.csv"),
                      col_types = cols(.default = col_character()))

# A label in the data that the transcription does not name STOPS the script,
# because a silent pass-through is how a pre-copyedit label reaches the page.
# study_factor is a FACTOR whose level order is the published study order, so it
# relabels through fct_relabel: as.character() would drop the levels and re-sort
# the twelve study blocks alphabetically.
page_label <- function(x, which) {
  map <- a1_labels[a1_labels$column == which, ]
  lookup <- set_names(map$published, map$deposit)
  swap <- function(v) {
    unknown <- setdiff(v, names(lookup))
    stopifnot(
      "a label in the data is not in published_table_a1_labels.csv" =
        length(unknown) == 0
    )
    unname(lookup[v])
  }
  if (is.factor(x)) fct_relabel(x, swap) else swap(x)
}

results <- results |>
  mutate(
    study_factor = page_label(study_factor, "study_factor"),
    dv_name = page_label(dv_name, "dv_name"),
    coef_name = page_label(coef_name, "coef_name")
  )

# One row per estimate, one column per sample ----
# The study, dv and term CODES are carried through beside their printed labels,
# because they are the only key anything outside this pipeline can join on.
# ground_truth/published_table_a1.csv records the published table in those same
# codes, and the remastered edition sets Table A 1 in the published row order
# over these values: without the codes it would have to match rows by their
# labels, which differ in case between the deposit and the page, or by their
# position, which is exactly what the two files do not share.

ests <- results |>
  select(study, dv, term, study_factor, coef_name, dv_name, sample, est) |>
  pivot_wider(names_from = sample, values_from = est)

ses <- results |>
  select(study, dv, term, study_factor, coef_name, dv_name, sample, se) |>
  pivot_wider(names_from = sample, values_from = se, names_glue = "{sample}_se")

ps <- results |>
  select(study, dv, term, study_factor, coef_name, dv_name, sample, p) |>
  pivot_wider(names_from = sample, values_from = p, names_glue = "{sample}_p")

# Table ----
# Repeated study names are blanked so each study heads its own block.

table_df <- ests |>
  left_join(ses, by = c("study", "dv", "term", "study_factor", "coef_name", "dv_name")) |>
  left_join(ps, by = c("study", "dv", "term", "study_factor", "coef_name", "dv_name")) |>
  arrange(study_factor, dv_name) |>
  mutate(
    original_entry = pmap_chr(list(original, original_se, original_p), format_entry),
    mt_entry = pmap_chr(list(mt, mt_se, mt_p), format_entry),
    gfk_entry = pmap_chr(list(gfk, gfk_se, gfk_p), format_entry),
    study_print = if_else(duplicated(study_factor), NA_character_, as.character(study_factor))
  ) |>
  select(study, dv, term, study_factor, dv_name, coef_name, original_entry, mt_entry,
         gfk_entry, study_print)

write_csv(table_df, here::here("maintained", "output", "table_a1_ate_summary.csv"))

tex_out <- table_df |>
  select(study_print, dv_name, coef_name, original_entry, mt_entry, gfk_entry) |>
  kable(
    format = "latex",
    col.names = c("Study", "Outcome", "Coefficient", "Original", "MTurk", "GfK"),
    caption = "Summary of ATE Estimates by Study, Sample, and Outcome",
    booktabs = TRUE,
    na = ""
  ) |>
  kable_styling(latex_options = c("hold_position", "scale_down"))

write_lines(as.character(tex_out), here::here("maintained", "output", "table_a1_ate_summary.tex"))
