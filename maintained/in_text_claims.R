# coppock_2019a/maintained/in_text_claims.R
# Output: printed CLAIM lines only; no files
# Depends on: maintained/output/, ground_truth/published_claims.csv, helpers.R
# Description: One block per numeric claim the published article makes that the pipeline
#   can reach, each carrying the article's own sentence verbatim and then recomputing the
#   number from the pipeline's committed output. This is the second instrument: it never
#   reads ground_truth/coppock_2019a_ground_truth.csv, it never refits a model, and it
#   reaches every quantity by its own path, so where it and build_ground_truth.R disagree
#   one of them is wrong.
#
#   Every block prints a line of the form
#
#       CLAIM <claim_id> = <value> || <label>
#
#   which build_ground_truth.R parses to check coverage against
#   ground_truth/published_claims.csv. The value is printed to the precision that file
#   records for the claim, so it can be laid against the page without being rounded a
#   second time.
#
#   Quotes are the sentences the article prints, however wrong. Where a sentence is wrong
#   that is recorded in the ground truth and in coppock_2019a_errata.pdf, never by editing
#   the quote. The published PDF has no text layer for its mathematical symbols, so the
#   quotes below write sigma-tau as "sigma_tau" and the approximation sign as "~=".

source(here::here("maintained", "helpers.R"))
library(excheckr)

options(width = 200)

out <- function(f) read_csv(here::here("maintained", "output", f), show_col_types = FALSE)

results <- read_rds(here::here("maintained", "output", "analysis_results.rds"))
ri <- read_rds(here::here("maintained", "output", "ri_results.rds"))
table_2 <- out("table_2_ri_heterogeneity.csv")
table_a1 <- out("table_a1_ate_summary.csv")
figure_2 <- out("figure_2_study_estimates.csv")
figure_3 <- out("figure_3_mt_original_scatter.csv")
figure_4 <- out("figure_4_power_simulation.csv")

# The extraction, read for the article's own statement of each claim. Reading the
# transcription is not the prohibited read; reading the comparison would be.
published_claims <- read_csv(
  here::here("ground_truth", "published_claims.csv"),
  col_types = cols(.default = col_character(), value_paper = col_character())
)

# The corrections this paper's errata note publishes, read from the spine errata.qmd writes
# rather than from the note's prose. A claim an entry names is scored against the correction
# and not against the sentence the article prints, so a corrected claim that drifted back to
# the published value stops the run instead of quietly reading as a match.
errata_entries <- read_csv(here::here("errata_entries.csv"),
                           col_types = cols(.default = col_character()))

published_a1 <- read_csv(here::here("ground_truth", "published_table_a1.csv"),
                         col_types = cols(.default = col_character()))
published_appendix <- read_csv(here::here("ground_truth", "published_appendix_tables.csv"),
                               col_types = cols(.default = col_character()))

# The scoring machinery comes from excheckr, which carries the verdict ladder, the
# typography parser and the printed form this file used to define for itself. What is passed
# here is what the package cannot know: the extraction, the errata spine, and the shape of
# the printed line. format = "id" is the CLAIM <id> = <value> || [verdict] <label> line
# ground_truth/build_ground_truth.R parses, and it must stay exactly that.
#
# The label stays at the call site rather than being fetched from the extraction's claim
# column, because half of this file's labels are glued from a loop variable and count a
# table's reproduced cells against its published total. That sentence is about the check
# rather than about the article, so the extraction is not where it lives.
#
# The precision is no longer named twice. It used to be read out of the extraction's digits
# column so that the two instruments could not drift apart on rounding; measured on
# 2026-08-20, claim_digits() reproduces all 200 of this extraction's declared digits from
# the typography of value_paper alone, and the four rows it cannot are rows with no
# published value that no block reaches. The article's own statement is what the column was
# recording.
# expect_column carries the two claims this article's own record already declares cannot be
# compared at printed precision, so the declaration lives beside the published value rather
# than being typed again in the block that prints it. Table 2's MTurk cell moves with the R
# 3.6.0 sample() change and the maintained pipeline keeps the current sampler; Table 2's
# TESS/GfK cell holds the Original count, because that column reproduces the deposited output
# file in its alphabetical row order rather than the table's printed one. The extraction's
# notes column carries the full reason for each, and the ground truth files them as
# defect_locus = environment and paper_internal. PROCEDURES makes both README findings rather
# than errata: a corrected Table 2 would need the retired sampler, which maintained/output/
# deliberately cannot produce.
claim_start(published = published_claims, errata = errata_entries, format = "id",
            expect_column = "expect")

# One row per estimate, one column per sample. build_ground_truth.R reaches the same
# quantities through maintained/output/text_correlations.csv; this file builds them from
# the estimates, which is the independent path.
wide <- results |>
  select(study, term, dv, sample, est, se, p) |>
  pivot_wider(names_from = sample, values_from = c(est, se, p))

gfk_rows <- wide |> filter(!is.na(est_gfk))

n_pairs <- nrow(wide)
n_gfk_pairs <- nrow(gfk_rows)

# Abstract ----

# "I provide evidence from a series of 15 replication experiments that results derived
#  from convenience samples like Amazon's Mechanical Turk are similar to those obtained
#  from national samples."
claim("abstract_n_replications",
      results |> filter(sample != "original") |> distinct(study, sample) |> nrow(),
      "study-by-sample replication versions in the estimates")

# Introduction ----

# "To preview the results presented below, I find a strong degree of correspondence
#  between national probability samples and MTurk: the cross-sample correlation of 40
#  pairs of average treatment effect estimates derived from 12 pairs of studies is 0.85
#  (df = 38)."
claim("intro_n_pairs", n_pairs, "original-MTurk pairs of estimates")
claim("intro_n_study_pairs", n_distinct(results$study), "studies contributing those pairs")
claim("intro_correlation", cor(wide$est_mt, wide$est_original),
      "Pearson correlation of the MTurk and original estimates")
claim("intro_df", n_pairs - 2, "degrees of freedom, pairs minus two")

# "I will then present results from 15 replication studies, showing that in large part,
#  original findings are replicated on both convenience and probability samples."
claim("intro_n_replication_studies",
      results |> filter(sample != "original") |> distinct(study, sample) |> nrow(),
      "study-by-sample replication versions, restated in the roadmap")

# Results I: Replications of 12 survey experiments ----

# Table 1, the N Estimates column. "The number of treatment effect estimates in each study
#  (reported in Table 1) is a function of the number of treatment arms and dependent
#  variables."
estimate_counts <- results |>
  filter(sample == "original") |>
  count(study)

for (s in estimate_counts$study) {
  claim(str_glue("t1_estimates_{s}"),
        estimate_counts$n[estimate_counts$study == s],
        str_glue("estimates reported for {s}"))
}

# Section heading: "RESULTS I: REPLICATIONS OF 12 SURVEY EXPERIMENTS"
claim("results_heading_studies", n_distinct(results$study),
      "studies the replication section covers")

# "I selected seven studies, four of which (Brader 2005; Nicholson 2012; McGinty, Webster
#  and Barry 2013; Craig and Richeson 2014) I replicated on MTurk, and three of which
#  (Hiscox 2006; Levendusky and Malhotra 2016; Hopkins and Mummolo 2017) I replicated both
#  on MTurk and TESS/GfK."
claim("results_both_platforms", n_distinct(gfk_rows$study),
      "studies carrying a TESS/GfK version as well as an MTurk one")

# "The approach adopted here is to replicate survey experiments originally conducted on
#  nationally representative samples with MTurk subjects and, in three cases, with fresh
#  nationally representative samples."
claim("results_three_cases", n_distinct(gfk_rows$study),
      "studies replicated on a fresh nationally representative sample")

# "I limited the number of dependent variables analyzed in each study to two."
#  A descriptive claim, and what it means depends on what counts as a study. Under the
#  deposit's own twelve groupings two of them carry more; under the appendix's numbering,
#  which splits those same groupings into fifteen studies, none does.
dvs_per_study <- results |> distinct(study, dv) |> count(study)
claim("methods_max_dvs", max(dvs_per_study$n),
      str_glue("most dependent variables in any of the deposit's {nrow(dvs_per_study)} ",
               "study groupings; the article says two, and the groupings carrying more are ",
               "{str_c(dvs_per_study$study[dvs_per_study$n > 2], collapse = ' and ')}"))

# Footnote 5: "The substantive results of these experiments, while not the focus of the
#  present study, indicate that subjects can be persuaded to change their political
#  opinions in the direction of the appeal by ~0.2 SD."
claim("fn5_persuasion_magnitude", mean(abs(results$est)),
      "mean absolute standardized treatment effect across all 90 estimates")

# "On the horizontal axis of each facet, I have plotted the average treatment effect
#  estimates with 95 percent confidence intervals."
claim("fig2_ci_level",
      100 * (2 * pnorm(unique(round((figure_2$ui - figure_2$est) / figure_2$se, 2))) - 1),
      "confidence level implied by the Figure 2 interval half-widths")

# "The study-by-study results are presented in Figure 2."
claim("fig2_facets", n_distinct(figure_2$study_factor), "facets of Figure 2, one per study")
claim("fig2_points", nrow(figure_2), "estimates plotted across the twelve facets")

# "The top nine facets compare two versions of each study (original and MTurk), while the
#  bottom three compare three versions (original, MTurk, and TESS/GfK)."
versions_per_study <- figure_2 |> distinct(study_factor, version) |> count(study_factor)
claim("fig2_top_facets", sum(versions_per_study$n == 2), "facets carrying two study versions")
claim("fig2_two_versions", min(versions_per_study$n), "versions in each of those facets")
claim("fig2_bottom_facets", sum(versions_per_study$n == 3), "facets carrying three study versions")
claim("fig2_three_versions", max(versions_per_study$n), "versions in each of those facets")

# "Altogether, I estimated 40 original-MTurk pairs of coefficients. Of the 25 coefficients
#  that were originally significant, 18 were significant in the MTurk replications, all
#  with the correct sign. Of the 15 coefficients that were not originally significant, 11
#  were not significant in the MTurk replications either, for an overall replication rate
#  (narrowly defined) of (18 + 11)/(25 + 15) = 72.5 percent."
orig_sig <- wide$p_original <= 0.05
mt_sig <- wide$p_mt <= 0.05
n_orig_sig <- sum(orig_sig)
n_orig_nonsig <- sum(!orig_sig)
n_replicated <- sum(orig_sig & mt_sig)
n_nonsig_maintained <- sum(!orig_sig & !mt_sig)

claim("results_pairs", n_pairs, "original-MTurk pairs of coefficients estimated")
claim("results_orig_sig", n_orig_sig, "coefficients significant in the original studies")
claim("results_replicated", n_replicated, "of those, also significant on MTurk")
claim("results_orig_nonsig", n_orig_nonsig, "coefficients not significant in the original studies")
claim("results_nonsig_maintained", n_nonsig_maintained, "of those, also not significant on MTurk")
claim("results_formula_replicated", n_replicated, "the same count, restated inside the formula")
claim("results_formula_nonsig", n_nonsig_maintained, "the same count, restated inside the formula")
claim("results_formula_orig_sig", n_orig_sig, "the same count, restated inside the formula")
claim("results_formula_orig_nonsig", n_orig_nonsig, "the same count, restated inside the formula")
claim("results_replication_rate",
      100 * (n_replicated + n_nonsig_maintained) / (n_orig_sig + n_orig_nonsig),
      "replication rate, narrowly defined, as a percentage")

# "In zero cases did two versions of the same study return statistically significant
#  coefficients with opposite signs."
claim("results_zero_sign_flips",
      sum(orig_sig & mt_sig & sign(wide$est_original) != sign(wide$est_mt)),
      "pairs significant in both versions with opposite signs")

# "In the case of these 12 pairs of studies (40 coefficients), the correlation between the
#  MTurk and original coefficients is 0.85 (df = 38)."
claim("results_12_pairs", n_distinct(results$study), "study pairs, restated")
claim("results_40_coefficients", n_pairs, "coefficients, restated")
claim("results_correlation", cor(wide$est_mt, wide$est_original),
      "Pearson correlation of the MTurk and original coefficients")
claim("results_df", n_pairs - 2, "degrees of freedom, coefficients minus two")

# "Figure 3 plots each coefficient with 95 percent confidence intervals for both the
#  original and MTurk versions."
claim("fig3_ci_level",
      100 * (2 * pnorm(unique(round((figure_3$mt_ui - figure_3$mt) / figure_3$mt_se, 2))) - 1),
      "confidence level implied by the Figure 3 interval half-widths")
claim("fig3_points", nrow(figure_3), "coefficient pairs plotted in Figure 3")

# "For the three studies (ten coefficients) replicated in parallel on MTurk and on fresh
#  TESS/GfK samples (Hiscox 2006; Levendusky and Malhotra 2016; Hopkins and Mummolo 2017),
#  the replication picture is even rosier. The correlation of the MTurk and original
#  estimates is 0.90 (df = 8); TESS/GfK estimates with the MTurk estimates, 0.96 (df = 8);
#  TESS/GfK with the original estimates, 0.85 (df = 8)."
claim("results_gfk_studies", n_distinct(gfk_rows$study), "studies with a TESS/GfK version")
claim("results_gfk_coefficients", n_gfk_pairs, "coefficients in those studies")
claim("results_cor_mt_orig_gfk", cor(gfk_rows$est_mt, gfk_rows$est_original),
      "MTurk-original correlation on the TESS/GfK subset")
claim("results_df_mt_orig_gfk", n_gfk_pairs - 2, "degrees of freedom of that correlation")
claim("results_cor_gfk_mt", cor(gfk_rows$est_gfk, gfk_rows$est_mt),
      "TESS/GfK-MTurk correlation")
claim("results_df_gfk_mt", n_gfk_pairs - 2, "degrees of freedom of that correlation")
claim("results_cor_gfk_orig", cor(gfk_rows$est_gfk, gfk_rows$est_original),
      "TESS/GfK-original correlation")
claim("results_df_gfk_orig", n_gfk_pairs - 2, "degrees of freedom of that correlation")

# Results II: Testing the null of treatment effect homogeneity ----

# "I conducted a small simulation study that varied two parameters: the number of subjects
#  per treatment arm and the degree of treatment effect heterogeneity."
claim("sim_parameters",
      sum(c(n_distinct(figure_4$n_per_arm), n_distinct(figure_4$sd_tau)) > 1),
      "simulation parameters taking more than one value")

# "The MTurk versions of the experiments studied here typically employ 500 subjects per
#  treatment arm, suggesting that we would be well powered (power ~= 0.8) to detect
#  treatment effect heterogeneity on the scale of 0.2 SD, and moderately powered for
#  0.1 SD (power ~= 0.6)."
at_500 <- figure_4 |> filter(n_per_arm == 500)
claim("fig4_het_02", max(at_500$sd_tau[at_500$sd_tau <= 0.2]),
      "simulation grid value nearest the 0.2 SD scale the sentence names")
claim("fig4_power_at_02", at_500$power[at_500$sd_tau == 0.2],
      "simulated power at 0.2 SD and 500 subjects per arm")
claim("fig4_het_01", max(at_500$sd_tau[at_500$sd_tau <= 0.1]),
      "simulation grid value nearest the 0.1 SD scale the sentence names")
claim("fig4_power_at_01", at_500$power[at_500$sd_tau == 0.1],
      "simulated power at 0.1 SD and 500 subjects per arm")

# "The main results of the heterogeneity test applied to the present set of 27 studies
#  (12 original and 15 replications) are displayed in Table 2."
n_original_versions <- results |> filter(sample == "original") |> distinct(study) |> nrow()
n_replication_versions <- results |> filter(sample != "original") |> distinct(study, sample) |> nrow()
claim("results2_total_studies", n_original_versions + n_replication_versions,
      "study versions the heterogeneity test is applied to")
claim("results2_original_studies", n_original_versions, "original studies among them")
claim("results2_replications", n_replication_versions, "replications among them")

# "Among the original 12 studies, just 1 of the 40 treatment versus control comparisons
#  revealed evidence of effect heterogeneity. Among the MTurk replications, 8 of 40
#  treatments were shown to have heterogeneous effects. On the TESS/GfK replications, 0 of
#  10 tests were significant."
claim("text_original_studies", n_original_versions,
      "original studies, restated at the head of the sentence")
claim("text_original_n_sig", table_2$n_sig[table_2$sample == "original"],
      "original comparisons rejecting the null of homogeneity")
claim("text_original_n_comparisons", table_2$n_comparisons[table_2$sample == "original"],
      "original treatment-versus-control comparisons tested")
claim("text_mt_n_sig", table_2$n_sig[table_2$sample == "mt"],
      "MTurk comparisons rejecting the null of homogeneity")
claim("text_mt_n_comparisons", table_2$n_comparisons[table_2$sample == "mt"],
      "MTurk comparisons tested")
claim("text_gfk_n_sig", table_2$n_sig[table_2$sample == "gfk"],
      "TESS/GfK comparisons rejecting the null of homogeneity")
claim("text_gfk_n_comparisons", table_2$n_comparisons[table_2$sample == "gfk"],
      "TESS/GfK comparisons tested")

# "In only one case (Hiscox 2006), did the same treatment versus control comparisons
#  return a significant test statistic across samples."
shared <- ri |>
  mutate(rejects = max_pval <= 0.05) |>
  summarise(n_rejecting = sum(rejects), .by = c(study, dv, condition_names)) |>
  filter(n_rejecting >= 2)
claim("text_one_shared_case", nrow(shared),
      str_glue("comparisons rejecting in more than one sample, in study ",
               "{str_c(unique(shared$study), collapse = ', ')}"))

# Table 2 ----

# TABLE 2  Tests of Treatment Effect Heterogeneity
#   Study Site        N Comparisons   N Significant   N Significant (Holm)
#   Original                     40               1                      0
#   Mechanical Turk              40               9                      8
#   TESS/GfK                     10               2                      0
for (s in c("original", "mt", "gfk")) {
  cell <- table_2[table_2$sample == s, ]
  claim(str_glue("t2_{s}_n_comparisons"), cell$n_comparisons,
        str_glue("Table 2, {s}, comparisons tested"))
  claim(str_glue("t2_{s}_n_sig"), cell$n_sig,
        str_glue("Table 2, {s}, significant before correction"))
  claim(str_glue("t2_{s}_n_sig_holm"), cell$n_sig_holm,
        str_glue("Table 2, {s}, significant after the Holm correction"))
}

# Appendix: Table A1 ----
# TABLE A1  Original and Replication Average Treatment Effect Estimates
# Each cell is an estimate with its standard error in parentheses, starred at p < 0.05.
# The comparison is entry by entry against the transcription in
# ground_truth/published_table_a1.csv.

rewrite_entries <- results |>
  transmute(
    study, dv, term, sample,
    entry = if_else(p < 0.05,
                    sprintf("%.2f (%.2f)*", est, se),
                    sprintf("%.2f (%.2f)", est, se))
  )

a1_check <- published_a1 |>
  inner_join(rewrite_entries, by = c("study", "dv", "term", "sample"))
stopifnot(nrow(a1_check) == nrow(published_a1))

for (s in c("original", "mt", "gfk")) {
  agreeing <- a1_check |> filter(sample == s, entry == entry_paper)
  claim(str_glue("ta1_{s}_entries"), nrow(agreeing),
        str_glue("Table A1 {s} entries reproduced of ",
                 "{sum(a1_check$sample == s)} published"))
}

# Appendix: the online appendix regression tables ----
# Each of the seventeen tables prints its treatment coefficients to three decimals with a
# standard error beneath. Those are the same estimates Table A1 rounds to two, so the
# comparison is against the transcription in ground_truth/published_appendix_tables.csv.

appendix_check <- published_appendix |>
  inner_join(
    results |> transmute(study, dv, term, sample,
                         est_rewrite = sprintf("%.3f", est),
                         se_rewrite = sprintf("%.3f", se)),
    by = c("study", "dv", "term", "sample")
  ) |>
  mutate(agrees = est_rewrite == est_paper & se_rewrite == se_paper)
stopifnot(nrow(appendix_check) == nrow(published_appendix))

for (k in 1:17) {
  tab <- str_glue("Appendix Table {k}")
  rows_k <- appendix_check |> filter(appendix_table == tab)
  claim(str_glue("appx_t{k}_treatment_cells"), 2 * sum(rows_k$agrees),
        str_glue("appendix Table {k} treatment cells reproduced of ",
                 "{2 * nrow(rows_k)} published"))
}

# Gates ----
# The verdicts above are assertions only if something reads them. assert_claims() is what
# reads them: no claim ended on a failing verdict, every claim a quantity erratum names was
# printed and printed as corrected, the claims printed are exactly those the extraction
# declares need a block, and the verdict counts partition the claims.
assert_claims()

# The exemptions are counted, never merely allowed. A file that let the unasserted set grow
# in silence would report the same clean run whether it checked every claim or none.
invisible(claim_summary())
