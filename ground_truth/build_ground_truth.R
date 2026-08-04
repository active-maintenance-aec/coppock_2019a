# coppock_2019a/ground_truth/build_ground_truth.R
# Output: ground_truth/coppock_2019a_ground_truth.csv
# Depends on: maintained/output/ (run run_all.R first), original/, ground_truth/published_claims.csv,
#   ground_truth/published_table_a1.csv, ground_truth/published_appendix_tables.csv,
#   maintained/in_text_claims.R
# Description: Assemble the ground truth table. Every published number enters through
#   ground_truth/published_claims.csv, the extraction of the numeric claims in the article
#   and its online appendix, and is used only as a comparison target; no published number
#   is an input to any computation here or anywhere in maintained/. Every value_rewrite
#   entry is read back out of maintained/output/, and every value_script entry out of the
#   deposit's own committed output in original/, so neither column can drift from what it
#   describes.
#
#   The last section is the coverage gate. Every claim the extraction marks as needing a
#   block must be checked twice: by a row here where it is a pipeline or descriptive claim,
#   and by a block in maintained/in_text_claims.R that reaches the same number from the same
#   outputs by its own path. The gate runs that file non-interactively and counts what it
#   printed, because a block that errors, or that ends in a bare expression and so prints
#   nothing under source(), satisfies a scan for markers completely while checking nothing.

library(here)
library(tidyverse)

here::i_am("ground_truth/build_ground_truth.R")

options(width = 200)

out <- function(f) read_csv(here::here("maintained", "output", f), show_col_types = FALSE)

# The published side ----
# published_claims.csv is the extraction: every numeric claim the article and the online
# appendix make, carrying the string the page prints and the number of decimals it prints
# it to. It is the only place a published number is written down, and paper() and digits()
# are the only ways one enters this file. value_paper is forced to character in every
# reader: a column whose entries all look numeric is guessed as double, and that silently
# turns the article's 0.90 into 0.9 and destroys the printed precision every comparison
# here depends on.

published_claims <- read_csv(
  here::here("ground_truth", "published_claims.csv"),
  col_types = cols(.default = col_character(), value_paper = col_character())
)

stopifnot(!anyDuplicated(published_claims$claim_id))

paper <- function(id) {
  value <- published_claims$value_paper[published_claims$claim_id == id]
  stopifnot(length(value) == 1)
  value
}

digits_of <- function(id) {
  value <- as.integer(published_claims$digits[published_claims$claim_id == id])
  stopifnot(length(value) == 1, !is.na(value))
  value
}

published_a1 <- read_csv(here::here("ground_truth", "published_table_a1.csv"),
                         col_types = cols(.default = col_character()))
published_appendix <- read_csv(here::here("ground_truth", "published_appendix_tables.csv"),
                               col_types = cols(.default = col_character()))

# The archive side ----
# The deposit ships the objects and text files its own scripts wrote, so value_script is
# read out of original/ rather than produced by re-running anything. Two of the deposit's
# own appendix tables were damaged by mistyped sink() calls, which is why the appendix rows
# below take no value_script.

archive_env <- new.env()
load(here::here("original", "coppock_generalizability_analysis_results.RData"), envir = archive_env)
archive_results <- as_tibble(archive_env$results)

archive_table_2 <-
  read_lines(here::here("original", "coppock_generalizability_table_2.txt")) |>
  str_subset("^\\d+\\s") |>
  str_squish() |>
  str_split(" ", simplify = TRUE) |>
  as_tibble(.name_repair = "minimal") |>
  set_names(c("row", "sample", "n_comparisons", "n_sig", "n_sig_holm")) |>
  mutate(across(c(n_comparisons, n_sig, n_sig_holm), as.numeric))

archive_simulation <- new.env()
load(here::here("original", "coppock_generalizability_simulation_results.RData"), envir = archive_simulation)
archive_power <- as_tibble(archive_simulation$df) |>
  transmute(n_per_arm = n / 2, sd_tau = het_param, power = value)

# The rewrite side ----

results <- read_rds(here::here("maintained", "output", "analysis_results.rds"))
ri <- read_rds(here::here("maintained", "output", "ri_results.rds"))
correlations <- out("text_correlations.csv")
table_2 <- out("table_2_ri_heterogeneity.csv")
table_a1 <- out("table_a1_ate_summary.csv")
figure_2 <- out("figure_2_study_estimates.csv")
figure_3 <- out("figure_3_mt_original_scatter.csv")
figure_4 <- out("figure_4_power_simulation.csv")

# text: one value out of text_correlations.csv, by a claim name that has to identify it
# uniquely. The assertion is what keeps a widened output file from silently turning a
# scalar into a vector and a ground truth row into a list column.
text_value <- function(name) {
  hits <- correlations$value_script[correlations$claim == name]
  stopifnot(length(hits) == 1, !is.na(hits))
  hits
}

t2_cell <- function(d, sample_name, column) {
  value <- d[[column]][d$sample == sample_name]
  stopifnot(length(value) == 1)
  as.numeric(value)
}

# Cell-by-cell coverage of the two estimate tables ----
# Table A1 prints 90 entries, each an estimate, a standard error and a significance star.
# The seventeen online appendix tables print the same 90 estimates to three decimals with
# their standard errors beneath. Both are compared entry by entry against the
# transcriptions, and the ground truth carries the counts.

entry_of <- function(est, se, p) {
  if_else(p < 0.05, sprintf("%.2f (%.2f)*", est, se), sprintf("%.2f (%.2f)", est, se))
}

a1_cells <- published_a1 |>
  inner_join(results |> transmute(study, dv, term, sample, entry = entry_of(est, se, p)),
             by = c("study", "dv", "term", "sample")) |>
  inner_join(
    archive_results |> transmute(study, dv, term, sample,
                                 entry_archive = entry_of(est, se, p)),
    by = c("study", "dv", "term", "sample")
  ) |>
  mutate(agrees = entry == entry_paper, agrees_archive = entry_archive == entry_paper)

stopifnot(nrow(a1_cells) == nrow(published_a1))

appendix_cells <- published_appendix |>
  inner_join(results |> transmute(study, dv, term, sample,
                                  est_rewrite = sprintf("%.3f", est),
                                  se_rewrite = sprintf("%.3f", se)),
             by = c("study", "dv", "term", "sample")) |>
  mutate(agrees = est_rewrite == est_paper & se_rewrite == se_paper)

stopifnot(nrow(appendix_cells) == nrow(published_appendix))

# Rows ----
# gt_row appends one row. claim_id ties it to the extraction; value_script is what the
# deposit's own committed output holds; value_rewrite is what maintained/output/ holds.

gt_rows <- list()

gt_row <- function(claim_id, table_figure, claim, value_script, value_rewrite,
                   defect_locus = NA_character_, holds = NA_real_, notes = "") {
  gt_rows[[length(gt_rows) + 1]] <<- tibble(
    claim_id = as.character(claim_id),
    table_figure = as.character(table_figure),
    claim = as.character(claim),
    value_script = as.numeric(value_script),
    value_rewrite = as.numeric(value_rewrite),
    holds = holds,
    defect_locus = defect_locus,
    notes = notes
  )
}

# The correlations and the significance match rate ----

archive_wide <- archive_results |>
  select(study, term, dv, sample, est, p) |>
  pivot_wider(names_from = sample, values_from = c(est, p))
archive_gfk <- archive_wide |> filter(!is.na(est_gfk))

gt_row("intro_n_pairs", "Text, p. 2", "Pairs of estimates entering the correlation",
       nrow(archive_wide), nrow(results |> filter(sample == "original")))
gt_row("intro_correlation", "Text, p. 2", "MTurk-original correlation",
       cor(archive_wide$est_mt, archive_wide$est_original),
       text_value("cor_mt_original_all"))
gt_row("results_pairs", "Text, p. 8", "Original-MTurk pairs of coefficients",
       nrow(archive_wide), nrow(results |> filter(sample == "original")))
gt_row("results_correlation", "Text, p. 8", "MTurk-original correlation, restated",
       cor(archive_wide$est_mt, archive_wide$est_original),
       text_value("cor_mt_original_all"))
gt_row("results_cor_mt_orig_gfk", "Text, p. 8",
       "MTurk-original correlation on the TESS/GfK subset",
       cor(archive_gfk$est_mt, archive_gfk$est_original),
       text_value("cor_mt_original_gfk_subset"))
gt_row("results_cor_gfk_mt", "Text, p. 8", "TESS/GfK-MTurk correlation",
       cor(archive_gfk$est_gfk, archive_gfk$est_mt), text_value("cor_mt_gfk"))
gt_row("results_cor_gfk_orig", "Text, p. 8", "TESS/GfK-original correlation",
       cor(archive_gfk$est_gfk, archive_gfk$est_original), text_value("cor_gfk_original"))

archive_orig_sig <- archive_wide$p_original <= 0.05
archive_mt_sig <- archive_wide$p_mt <= 0.05

gt_row("results_orig_sig", "Text, p. 8", "Coefficients significant in the original studies",
       sum(archive_orig_sig), text_value("n_orig_sig"))
gt_row("results_replicated", "Text, p. 8", "Of those, also significant on MTurk",
       sum(archive_orig_sig & archive_mt_sig), text_value("n_orig_sig_replicated_in_mt"))
gt_row("results_orig_nonsig", "Text, p. 8", "Coefficients not significant in the original studies",
       sum(!archive_orig_sig), text_value("n_orig_nonsig"))
gt_row("results_nonsig_maintained", "Text, p. 8", "Of those, also not significant on MTurk",
       sum(!archive_orig_sig & !archive_mt_sig), text_value("n_orig_nonsig_also_nonsig_mt"))
gt_row("results_formula_replicated", "Text, p. 8",
       "Replicated significant coefficients, restated inside the formula",
       sum(archive_orig_sig & archive_mt_sig), text_value("n_orig_sig_replicated_in_mt"))
gt_row("results_formula_nonsig", "Text, p. 8",
       "Replicated null coefficients, restated inside the formula",
       sum(!archive_orig_sig & !archive_mt_sig), text_value("n_orig_nonsig_also_nonsig_mt"))
gt_row("results_formula_orig_sig", "Text, p. 8",
       "Originally significant coefficients, restated inside the formula",
       sum(archive_orig_sig), text_value("n_orig_sig"))
gt_row("results_formula_orig_nonsig", "Text, p. 8",
       "Originally null coefficients, restated inside the formula",
       sum(!archive_orig_sig), text_value("n_orig_nonsig"))
gt_row("results_replication_rate", "Text, p. 8", "Replication rate as a percentage",
       100 * (sum(archive_orig_sig & archive_mt_sig) +
                sum(!archive_orig_sig & !archive_mt_sig)) / nrow(archive_wide),
       100 * as.numeric(text_value("overall_replication_rate")))

# Design counts the pipeline can reach ----

n_replication_versions <- results |> filter(sample != "original") |> distinct(study, sample) |> nrow()
n_studies <- n_distinct(results$study)
n_gfk_studies <- results |> filter(sample == "gfk") |> distinct(study) |> nrow()
n_gfk_pairs <- results |> filter(sample == "gfk") |> nrow()
archive_replication_versions <- archive_results |> filter(sample != "original") |>
  distinct(study, sample) |> nrow()

gt_row("abstract_n_replications", "Abstract", "Replication experiments reported",
       archive_replication_versions, n_replication_versions)
gt_row("intro_n_replication_studies", "Text, p. 2", "Replication studies, restated",
       archive_replication_versions, n_replication_versions)
gt_row("results2_replications", "Text, p. 10", "Replications the heterogeneity test covers",
       archive_replication_versions, n_replication_versions)
gt_row("intro_n_study_pairs", "Text, p. 2", "Study pairs behind the correlation",
       n_distinct(archive_results$study), n_studies)
gt_row("results_12_pairs", "Text, p. 8", "Study pairs, restated",
       n_distinct(archive_results$study), n_studies)
gt_row("results_heading_studies", "Results I heading, p. 5", "Studies the section covers",
       n_distinct(archive_results$study), n_studies)
gt_row("results2_original_studies", "Text, p. 10", "Original studies in the test",
       n_distinct(archive_results$study), n_studies)
gt_row("text_original_studies", "Text, p. 10", "Original studies, restated in the sentence",
       n_distinct(archive_results$study), n_studies)
gt_row("results2_total_studies", "Text, p. 10", "Study versions the test covers",
       n_distinct(archive_results$study) + archive_replication_versions,
       n_studies + n_replication_versions)
gt_row("results_40_coefficients", "Text, p. 8", "Coefficients behind the correlation",
       nrow(archive_wide), nrow(results |> filter(sample == "original")))
gt_row("results_both_platforms", "Text, pp. 5-6", "Studies replicated on both platforms",
       n_distinct(archive_gfk$study), n_gfk_studies)
gt_row("results_three_cases", "Text, p. 5", "Cases with a fresh probability sample",
       n_distinct(archive_gfk$study), n_gfk_studies)
gt_row("results_gfk_studies", "Text, p. 8", "Studies with a TESS/GfK version",
       n_distinct(archive_gfk$study), n_gfk_studies)
gt_row("results_gfk_coefficients", "Text, p. 8", "Coefficients in those studies",
       nrow(archive_gfk), n_gfk_pairs)
gt_row("intro_df", "Text, p. 2", "Degrees of freedom of the correlation",
       nrow(archive_wide) - 2, nrow(results |> filter(sample == "original")) - 2)
gt_row("results_df", "Text, p. 8", "Degrees of freedom, restated",
       nrow(archive_wide) - 2, nrow(results |> filter(sample == "original")) - 2)
gt_row("results_df_mt_orig_gfk", "Text, p. 8", "Degrees of freedom on the TESS/GfK subset",
       nrow(archive_gfk) - 2, n_gfk_pairs - 2)
gt_row("results_df_gfk_mt", "Text, p. 8", "Degrees of freedom, TESS/GfK against MTurk",
       nrow(archive_gfk) - 2, n_gfk_pairs - 2)
gt_row("results_df_gfk_orig", "Text, p. 8", "Degrees of freedom, TESS/GfK against original",
       nrow(archive_gfk) - 2, n_gfk_pairs - 2)

# Figures 2 and 3 ----

versions_per_study <- figure_2 |> distinct(study_factor, version) |> count(study_factor)

gt_row("fig2_facets", "Figure 2", "Facets, one per study",
       n_distinct(archive_results$study), n_distinct(figure_2$study_factor))
gt_row("fig2_points", "Figure 2", "Estimates plotted",
       nrow(archive_results), nrow(figure_2))
gt_row("fig2_top_facets", "Figure 2", "Facets carrying two study versions",
       NA, sum(versions_per_study$n == 2))
gt_row("fig2_bottom_facets", "Figure 2", "Facets carrying three study versions",
       NA, sum(versions_per_study$n == 3))
gt_row("fig2_two_versions", "Figure 2", "Versions in each two-version facet",
       NA, min(versions_per_study$n))
gt_row("fig2_three_versions", "Figure 2", "Versions in each three-version facet",
       NA, max(versions_per_study$n))
gt_row("fig2_ci_level", "Figure 2", "Confidence level of the plotted intervals", NA,
       100 * (2 * pnorm(unique(round((figure_2$ui - figure_2$est) / figure_2$se, 2))) - 1))
gt_row("fig3_points", "Figure 3", "Coefficient pairs plotted",
       nrow(archive_wide), nrow(figure_3))
gt_row("fig3_ci_level", "Figure 3", "Confidence level of the plotted intervals", NA,
       100 * (2 * pnorm(unique(round((figure_3$mt_ui - figure_3$mt) / figure_3$mt_se, 2))) - 1))

# Figure 4 and the power sentence ----

power_at <- function(d, sd) {
  value <- d$power[d$n_per_arm == 500 & d$sd_tau == sd]
  stopifnot(length(value) == 1)
  value
}

gt_row("sim_parameters", "Text, p. 10", "Simulation parameters varied", NA,
       sum(c(n_distinct(figure_4$n_per_arm), n_distinct(figure_4$sd_tau)) > 1))
gt_row("fig4_het_02", "Figure 4", "Heterogeneity scale named for the high-power claim",
       max(archive_power$sd_tau[archive_power$sd_tau <= 0.2]),
       max(figure_4$sd_tau[figure_4$sd_tau <= 0.2]))
gt_row("fig4_het_01", "Figure 4", "Heterogeneity scale named for the moderate-power claim",
       max(archive_power$sd_tau[archive_power$sd_tau <= 0.1]),
       max(figure_4$sd_tau[figure_4$sd_tau <= 0.1]))
gt_row("fig4_power_at_02", "Figure 4",
       "Simulated power at 0.2 SD and 500 subjects per arm",
       power_at(archive_power, 0.2), power_at(figure_4, 0.2), "paper_internal",
       notes = paste0("The deposited simulation the figure is drawn from gives ",
                      sprintf("%.2f", power_at(figure_4, 0.2)),
                      " at 500 subjects per arm; the sentence reads the height of the ",
                      "figure's own dashed guide line rather than the curve, which first ",
                      "reaches 0.8 at ",
                      min(figure_4$n_per_arm[figure_4$sd_tau == 0.2 & figure_4$power >= 0.8]),
                      " subjects per arm"))
gt_row("fig4_power_at_01", "Figure 4",
       "Simulated power at 0.1 SD and 500 subjects per arm",
       power_at(archive_power, 0.1), power_at(figure_4, 0.1), "paper_internal",
       notes = paste0("The deposited simulation gives ",
                      sprintf("%.2f", power_at(figure_4, 0.1)),
                      " at 500 subjects per arm; the published 0.6 is the power at 0.2 SD, ",
                      "not at 0.1 SD"))

# Table 1 ----

archive_estimate_counts <- archive_results |> filter(sample == "original") |> count(study)
estimate_counts <- results |> filter(sample == "original") |> count(study)

for (s in estimate_counts$study) {
  gt_row(str_glue("t1_estimates_{s}"), "Table 1",
         str_glue("Estimates reported for {s}"),
         archive_estimate_counts$n[archive_estimate_counts$study == s],
         estimate_counts$n[estimate_counts$study == s])
}

sample_size_rows <- published_claims |>
  filter(str_starts(claim_id, "t1_n_"))

for (i in seq_len(nrow(sample_size_rows))) {
  gt_row(sample_size_rows$claim_id[i], "Table 1", sample_size_rows$claim[i], NA, NA,
         "rewrite",
         notes = paste0("The maintained rewrite's analysis scripts export estimates only, ",
                        "so maintained/output/ carries no analysis sample size to compare ",
                        "this against; the deposited appendix script prints one"))
}

# Table 2 and the sentences that quote it ----

t2_note <- paste0(
  "Table 2's N Significant column reproduces the deposited output file read in that ",
  "file's own row order, which is alphabetical and the reverse of the table's printed ",
  "one, so the Original and TESS/GfK entries are interchanged. See the report."
)

for (s in c("original", "mt", "gfk")) {
  gt_row(str_glue("t2_{s}_n_comparisons"), "Table 2",
         str_glue("Table 2, {s}, comparisons tested"),
         t2_cell(archive_table_2, s, "n_comparisons"),
         t2_cell(table_2, s, "n_comparisons"))
  gt_row(str_glue("t2_{s}_n_sig_holm"), "Table 2",
         str_glue("Table 2, {s}, significant after the Holm correction"),
         t2_cell(archive_table_2, s, "n_sig_holm"),
         t2_cell(table_2, s, "n_sig_holm"))
}

gt_row("t2_original_n_sig", "Table 2", "Table 2, original, significant before correction",
       t2_cell(archive_table_2, "original", "n_sig"), t2_cell(table_2, "original", "n_sig"),
       "paper_internal", notes = t2_note)
gt_row("t2_mt_n_sig", "Table 2", "Table 2, MTurk, significant before correction",
       t2_cell(archive_table_2, "mt", "n_sig"), t2_cell(table_2, "mt", "n_sig"),
       "environment",
       notes = paste0("The deposited output and the published table agree at 9. The R 3.6.0 ",
                      "sampler change moves the count: one MTurk test has a maximum p-value ",
                      "of exactly 0.05 under the deposit's own draw and none does under the ",
                      "current one."))
gt_row("t2_gfk_n_sig", "Table 2", "Table 2, TESS/GfK, significant before correction",
       t2_cell(archive_table_2, "gfk", "n_sig"), t2_cell(table_2, "gfk", "n_sig"),
       "paper_internal", notes = t2_note)

gt_row("text_original_n_comparisons", "Text, p. 10",
       "Original comparisons tested, as the text states them",
       t2_cell(archive_table_2, "original", "n_comparisons"),
       t2_cell(table_2, "original", "n_comparisons"))
gt_row("text_mt_n_comparisons", "Text, p. 10",
       "MTurk comparisons tested, as the text states them",
       t2_cell(archive_table_2, "mt", "n_comparisons"),
       t2_cell(table_2, "mt", "n_comparisons"))
gt_row("text_gfk_n_comparisons", "Text, p. 10",
       "TESS/GfK comparisons tested, as the text states them",
       t2_cell(archive_table_2, "gfk", "n_comparisons"),
       t2_cell(table_2, "gfk", "n_comparisons"))

gt_row("text_original_n_sig", "Text, p. 10",
       "Original comparisons the text says rejected homogeneity",
       t2_cell(archive_table_2, "original", "n_sig"), t2_cell(table_2, "original", "n_sig"),
       "unresolved",
       notes = paste0("The text says 1, the published table says 1 in a cell that belongs to ",
                      "the TESS/GfK row, the deposit's own output says 2 and a current run ",
                      "says 1. One original test has a maximum p-value of exactly 0.05 under ",
                      "the deposit's draw, which Table 2's own rule counts as significant and ",
                      "a strict inequality does not, so the sentence is not settled either ",
                      "way and no correction is proposed."))
gt_row("text_mt_n_sig", "Text, p. 10",
       "MTurk comparisons the text says rejected homogeneity",
       t2_cell(archive_table_2, "mt", "n_sig"), t2_cell(table_2, "mt", "n_sig"),
       "unresolved",
       notes = paste0("The text says 8, the published table and the deposit's output say 9, ",
                      "and a current run says 8. One MTurk test sits at exactly 0.05 under ",
                      "the deposit's draw, so the sentence is not settled either way."))
gt_row("text_gfk_n_sig", "Text, p. 10",
       "TESS/GfK comparisons the text says rejected homogeneity",
       t2_cell(archive_table_2, "gfk", "n_sig"), t2_cell(table_2, "gfk", "n_sig"),
       "paper_internal",
       notes = paste0("The text says 0. The deposit's own output says 1, a current run says ",
                      "1, and the published table says 2 in a cell that belongs to the ",
                      "original row. No count of 0 is produced by the deposited code."))

# Table A1 ----

for (s in c("original", "mt", "gfk")) {
  cells <- a1_cells |> filter(sample == s)
  gt_row(str_glue("ta1_{s}_entries"), "Table A1",
         str_glue("Table A1 {s} entries reproduced of {nrow(cells)} published"),
         sum(cells$agrees_archive), sum(cells$agrees))
}

# Online appendix regression tables ----

for (k in 1:17) {
  cells <- appendix_cells |> filter(appendix_table == str_glue("Appendix Table {k}"))
  gt_row(str_glue("appx_t{k}_treatment_cells"), str_glue("Online Appendix Table {k}"),
         str_glue("Treatment estimate and standard error cells reproduced of ",
                  "{2 * nrow(cells)} published"),
         NA, 2 * sum(cells$agrees),
         notes = paste0("The deposited appendix script writes these tables as text, but two ",
                        "of its sink() calls are mistyped and the deposited files for ",
                        "appendix Tables 1 and 15 do not survive, so no value_script is ",
                        "read for any of them."))
  other <- published_claims |> filter(claim_id == str_glue("appx_t{k}_other_cells"))
  gt_row(str_glue("appx_t{k}_other_cells"), str_glue("Online Appendix Table {k}"),
         other$claim, NA, NA, "rewrite",
         notes = paste0("The maintained rewrite drops the intercept and the party ",
                        "identification covariate before writing its estimates and exports ",
                        "neither sample sizes nor R-squared, so maintained/output/ carries ",
                        "none of these cells."))
}

# Descriptive claims ----
# These have no printed number to compare, so the verdict lives in holds and match stays NA.

dvs_per_study <- results |> distinct(study, dv) |> count(study)
gt_row("methods_max_dvs", "Text, p. 6",
       "Most dependent variables in any of the deposit's study groupings",
       max(archive_results |> distinct(study, dv) |> count(study) |> pull(n)),
       max(dvs_per_study$n), "unresolved", holds = NA_real_,
       notes = paste0("The article says it limited the number of dependent variables per ",
                      "study to two. Under the deposit's twelve groupings the largest is ",
                      max(dvs_per_study$n), "; under the online appendix's numbering, which ",
                      "splits the same data into fifteen studies, none exceeds two, so the ",
                      "sentence does not identify the quantity it constrains."))

gt_row("fn5_persuasion_magnitude", "Footnote 5", "Mean absolute standardized effect",
       mean(abs(archive_results$est)), mean(abs(results$est)), holds = 1,
       notes = paste0("The footnote hedges the figure with a tilde, so it is read as an ",
                      "approximation and holds at the one decimal it states."))

archive_sign_flips <- sum(archive_orig_sig & archive_mt_sig &
                            sign(archive_wide$est_original) != sign(archive_wide$est_mt))
rewrite_wide <- results |> select(study, term, dv, sample, est, p) |>
  pivot_wider(names_from = sample, values_from = c(est, p))
rewrite_sign_flips <- sum(rewrite_wide$p_original <= 0.05 & rewrite_wide$p_mt <= 0.05 &
                            sign(rewrite_wide$est_original) != sign(rewrite_wide$est_mt))
gt_row("results_zero_sign_flips", "Text, p. 8",
       "Pairs significant in both versions with opposite signs",
       archive_sign_flips, rewrite_sign_flips,
       holds = as.numeric(rewrite_sign_flips == 0))

shared <- ri |>
  mutate(rejects = max_pval <= 0.05) |>
  summarise(n_rejecting = sum(rejects), .by = c(study, dv, condition_names)) |>
  filter(n_rejecting >= 2)
gt_row("text_one_shared_case", "Text, pp. 10-11",
       "Comparisons rejecting homogeneity in more than one sample",
       NA, nrow(shared), holds = as.numeric(nrow(shared) == 1),
       notes = paste0("The one comparison is in ", str_c(unique(shared$study), collapse = ", "),
                      ", which is the Hiscox (2006) study the sentence names."))

gt_row("fig4_typical_arm", "Figure 4",
       "Subjects per treatment arm the MTurk replications typically employ",
       NA, NA, "rewrite", holds = NA_real_,
       notes = paste0("The maintained rewrite exports no sample sizes and no treatment arm ",
                      "counts, so nothing in maintained/output/ can be compared against this."))

gt <- bind_rows(gt_rows)

# Verdicts ----
# value_paper is carried as the string the article prints, because the number alone does
# not record its own precision: 0.90 and 0.9 are the same double. A value agrees when the
# computed number, printed to the page's own precision, gives the same digits.

normalise_paper <- function(txt) {
  txt |>
    str_replace_all("−", "-") |>
    str_remove_all(",") |>
    str_replace("^(-?)\\.", "\\10")
}

render <- function(value, digits) {
  if_else(is.na(value), NA_character_, sprintf(paste0("%.", digits, "f"), value))
}

gt <- gt |>
  mutate(
    paper_id = "coppock_2019a",
    digits = map_int(claim_id, digits_of),
    paper_number = parse_double(normalise_paper(map_chr(claim_id, paper))),
    value_paper = render(paper_number, digits),
    match = if_else(is.na(value_script) | is.na(value_paper), NA_real_,
                    as.numeric(render(value_script, digits) == value_paper)),
    match_rewrite = if_else(is.na(value_rewrite) | is.na(value_paper), NA_real_,
                            as.numeric(render(value_rewrite, digits) == value_paper))
  )

# The render is also a stricter gate than the numeric transcription check beside it: it
# catches a digits entry that is right about the value and wrong about the precision.
transcription <- gt |>
  mutate(extraction = normalise_paper(map_chr(claim_id, paper))) |>
  filter(!is.na(value_paper), value_paper != extraction,
         abs(parse_double(extraction) - paper_number) > 1e-9)
stopifnot(nrow(transcription) == 0)

# Gate: a locus and a verdict go together ----
# Three states. An adverse row, meaning either verdict is 0 or holds is 0, must carry a
# locus, because a zero otherwise reads as a failure of the rewrite and here almost never
# is. A clean match must not carry one. A row with no verdict may.

gt <- gt |>
  mutate(
    adverse = (!is.na(match) & match == 0) | (!is.na(match_rewrite) & match_rewrite == 0) |
      (!is.na(holds) & holds == 0),
    clean = !adverse &
      ((!is.na(match) & match == 1) | (!is.na(match_rewrite) & match_rewrite == 1) |
         (!is.na(holds) & holds == 1))
  )

locus_gate <- gt |>
  filter((adverse & is.na(defect_locus)) | (clean & !is.na(defect_locus)))

if (nrow(locus_gate) > 0) {
  print(select(locus_gate, claim_id, table_figure, claim, match, match_rewrite, holds, defect_locus),
        n = 60)
  stop("Rows carrying an adverse verdict with no locus, or a clean match with one.")
}

# Gate: coverage ----
# Every pipeline and descriptive claim needs a row here, and every claim the extraction
# marks as needing a block needs one in maintained/in_text_claims.R.

stopifnot(!anyDuplicated(gt$claim_id), !any(is.na(gt$claim_id)))

must_have_row <- published_claims |> filter(claim_type %in% c("pipeline", "descriptive"))
rowless <- setdiff(must_have_row$claim_id, gt$claim_id)
unknown <- setdiff(gt$claim_id, published_claims$claim_id)

if (length(rowless) > 0 || length(unknown) > 0) {
  stop(str_glue(
    "Coverage gate failed. Claims with no ground truth row ({length(rowless)}): ",
    "{str_c(head(rowless, 40), collapse = ', ')}. ",
    "Ground truth rows naming a claim the extraction does not carry ({length(unknown)}): ",
    "{str_c(head(unknown, 40), collapse = ', ')}."
  ))
}

# Gate: the second instrument ran, printed, and agrees ----
# maintained/in_text_claims.R is run here rather than read, and what it printed is counted:
# a block that errors at its first line, or that ends in a bare expression and so prints
# nothing under source(), passes a scan for markers while checking nothing at all. It is
# sourced into its own environment, because both files necessarily read the same outputs
# and name objects for what they hold, so a bare source() would replace this script's own
# published_claims and out() with the claims file's.

claims_output <- capture.output(
  source(here::here("maintained", "in_text_claims.R"), local = new.env())
)

printed <- tibble(line = str_subset(claims_output, "^CLAIM ")) |>
  transmute(
    claim_id = str_match(line, "^CLAIM ([^ ]+) = ")[, 2],
    value_in_text = str_match(line, "^CLAIM [^ ]+ = (.*?) \\|\\| ")[, 2]
  )

stopifnot(!anyDuplicated(printed$claim_id), !any(is.na(printed$claim_id)),
          !any(is.na(printed$value_in_text)))

declared <- published_claims$claim_id[published_claims$needs_block == "TRUE"]
blockless <- setdiff(declared, printed$claim_id)
invented <- setdiff(printed$claim_id, declared)

if (length(blockless) > 0 || length(invented) > 0) {
  stop(str_glue(
    "Coverage gate failed. Claims with no block ({length(blockless)}): ",
    "{str_c(head(blockless, 40), collapse = ', ')}. ",
    "Blocks naming a claim the extraction does not require ({length(invented)}): ",
    "{str_c(head(invented, 40), collapse = ', ')}."
  ))
}

stopifnot(nrow(printed) == length(declared))

# The two instruments must land on the same number. in_text_claims.R prints in the units
# and rounding the extraction records and never sees this file, so a disagreement is one of
# the two being wrong and it stops the build.
cross_check <- gt |>
  inner_join(printed, by = "claim_id") |>
  filter(!is.na(value_rewrite), render(value_rewrite, digits) != value_in_text)

if (nrow(cross_check) > 0) {
  print(select(cross_check, claim_id, value_paper, value_rewrite, value_in_text), n = 40)
  stop(str_glue("The ground truth and maintained/in_text_claims.R disagree on ",
                "{nrow(cross_check)} claims."))
}

# Gate: every published float has coverage ----
# Enumerated from the article's own front matter rather than from what the pipeline happens
# to produce, so a float with no coverage is visible instead of absent.

published_float_inventory <- c(
  "Figure 1", "Table 1", "Figure 2", "Figure 3", "Figure 4", "Table 2", "Table A1",
  as.character(str_glue("Online Appendix Table {1:17}"))
)

float_rows <- gt |> filter(str_starts(table_figure, "Table|Figure|Online Appendix"))
uncovered <- setdiff(published_float_inventory, float_rows$table_figure)
unlisted <- setdiff(float_rows$table_figure, published_float_inventory)

# Figure 1 is a stipulated illustration of the theory, and no script in the deposit or in
# the rewrite draws it, so it has no row and the reason is recorded here rather than left
# to be rediscovered.
stopifnot(identical(uncovered, "Figure 1"), length(unlisted) == 0)

gt <- gt |>
  select(paper_id, claim_id, table_figure, claim, value_script, value_paper, match,
         value_rewrite, match_rewrite, holds, defect_locus, notes)

write_csv(gt, here::here("ground_truth", "coppock_2019a_ground_truth.csv"))

print(gt |> select(claim_id, table_figure, claim, value_script, value_paper, match,
                   value_rewrite, match_rewrite, holds, defect_locus),
      n = nrow(gt))

print(count(gt, defect_locus))
print(count(published_claims, claim_type, needs_block))

print(str_glue(
  "Ground truth: {nrow(gt)} rows. Extraction: {nrow(published_claims)} published claims, ",
  "{length(declared)} of them requiring a block, and {nrow(printed)} printed by ",
  "maintained/in_text_claims.R. Rewrite matches published in ",
  "{sum(gt$match_rewrite == 1, na.rm = TRUE)} of {sum(!is.na(gt$match_rewrite))} comparable ",
  "rows; the deposit's own output matches in {sum(gt$match == 1, na.rm = TRUE)} of ",
  "{sum(!is.na(gt$match))}. Table A1: {sum(a1_cells$agrees)} of {nrow(a1_cells)} published ",
  "entries reproduced. Online appendix tables: {2 * sum(appendix_cells$agrees)} of ",
  "{2 * nrow(appendix_cells)} published treatment cells reproduced."
))
