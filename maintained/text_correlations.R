# coppock_2019a/maintained/text_correlations.R
# Output: output/text_correlations.csv
# Depends on: analysis_ate_estimates.R output, helpers.R
# Description: Cross-sample correlations and the significance match rate cited in the text.

source(here::here("maintained", "helpers.R"))

# Inputs ----

results <- read_rds(here::here("maintained", "output", "analysis_results.rds"))

# One row per estimate, one column per sample ----

ests <- results |>
  select(study, term, dv, sample, est) |>
  pivot_wider(names_from = sample, values_from = est)

ses <- results |>
  select(study, term, dv, sample, se) |>
  pivot_wider(names_from = sample, values_from = se, names_glue = "{sample}_se")

sig <- results |>
  mutate(sig = p <= 0.05) |>
  select(study, term, dv, sample, sig) |>
  pivot_wider(names_from = sample, values_from = sig, names_glue = "{sample}_sig")

results_wide <- ests |>
  left_join(ses, by = c("study", "term", "dv")) |>
  left_join(sig, by = c("study", "term", "dv"))

# Cross-sample correlations ----
# The GfK correlations use only the 10 estimates that have a GfK version.

cor_mt_orig_all <- with(results_wide, cor(mt, original))
cor_mt_orig_gfk <- with(filter(results_wide, !is.na(gfk)), cor(mt, original))
cor_mt_gfk <- with(filter(results_wide, !is.na(gfk)), cor(mt, gfk))
cor_gfk_orig <- with(filter(results_wide, !is.na(gfk)), cor(gfk, original))

# Significance match rate ----

n_orig_sig <- sum(results_wide$original_sig, na.rm = TRUE)
n_orig_nonsig <- sum(!results_wide$original_sig, na.rm = TRUE)
n_replicated <- with(results_wide, sum(original_sig & mt_sig, na.rm = TRUE))
n_nonsig_maintained <- with(results_wide, sum(!original_sig & !mt_sig, na.rm = TRUE))
replication_rate <- (n_replicated + n_nonsig_maintained) / (n_orig_sig + n_orig_nonsig)

# Output ----

out <- tibble(
  claim = c("cor_mt_original_all", "cor_mt_original_gfk_subset",
            "cor_mt_gfk", "cor_gfk_original",
            "n_orig_sig", "n_orig_nonsig",
            "n_orig_sig_replicated_in_mt", "n_orig_nonsig_also_nonsig_mt",
            "overall_replication_rate"),
  value_script = c(cor_mt_orig_all, cor_mt_orig_gfk,
                   cor_mt_gfk, cor_gfk_orig,
                   n_orig_sig, n_orig_nonsig,
                   n_replicated, n_nonsig_maintained,
                   replication_rate)
)

write_csv(out, here::here("maintained", "output", "text_correlations.csv"))
print(out, n = Inf)
