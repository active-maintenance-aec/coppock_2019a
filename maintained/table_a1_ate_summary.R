# coppock_2019a/maintained/table_a1_ate_summary.R
# Output: output/table_a1_ate_summary.csv, output/table_a1_ate_summary.tex
# Depends on: analysis_ate_estimates.R output, helpers.R
# Description: Summary table of ATE estimates by study, DV, coefficient, and sample.

source(here::here("maintained", "helpers.R"))

# Inputs ----

results <- read_rds(here::here("maintained", "output", "analysis_results.rds"))

load(here::here("original", "coppock_generalizability_study_data.RData"))

results <- results |>
  left_join(study_df, by = "study") |>
  left_join(dvs_df, by = "dv") |>
  left_join(coefficients_df, by = "term")

# One row per estimate, one column per sample ----

ests <- results |>
  select(study_factor, coef_name, dv_name, sample, est) |>
  pivot_wider(names_from = sample, values_from = est)

ses <- results |>
  select(study_factor, coef_name, dv_name, sample, se) |>
  pivot_wider(names_from = sample, values_from = se, names_glue = "{sample}_se")

ps <- results |>
  select(study_factor, coef_name, dv_name, sample, p) |>
  pivot_wider(names_from = sample, values_from = p, names_glue = "{sample}_p")

# Table ----
# Repeated study names are blanked so each study heads its own block.

table_df <- ests |>
  left_join(ses, by = c("study_factor", "coef_name", "dv_name")) |>
  left_join(ps, by = c("study_factor", "coef_name", "dv_name")) |>
  arrange(study_factor, dv_name) |>
  mutate(
    original_entry = pmap_chr(list(original, original_se, original_p), format_entry),
    mt_entry = pmap_chr(list(mt, mt_se, mt_p), format_entry),
    gfk_entry = pmap_chr(list(gfk, gfk_se, gfk_p), format_entry),
    study_print = if_else(duplicated(study_factor), NA_character_, as.character(study_factor))
  ) |>
  select(study_factor, dv_name, coef_name, original_entry, mt_entry, gfk_entry, study_print)

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
