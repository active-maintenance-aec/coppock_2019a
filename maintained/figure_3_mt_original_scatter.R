# coppock_2019a/maintained/figure_3_mt_original_scatter.R
# Output: output/figure_3_mt_original_scatter.csv, output/figure_3_mt_original_scatter.pdf,
#         output/figure_3_mt_original_scatter.png
# Depends on: analysis_ate_estimates.R output, helpers.R
# Description: Scatterplot of MTurk vs original ATE estimates with CIs.

source(here::here("maintained", "helpers.R"))

# Inputs ----

results <- read_rds(here::here("maintained", "output", "analysis_results.rds"))

load(here::here("original", "coppock_generalizability_study_data.RData"))
study_df <- published_study_labels(study_df)

results <- results |>
  left_join(study_df, by = "study") |>
  left_join(dvs_df, by = "dv") |>
  left_join(coefficients_df, by = "term")

# Plot data ----

ests <- results |>
  select(study, term, est, dv, sample) |>
  pivot_wider(names_from = sample, values_from = est)

ses <- results |>
  select(study, term, se, dv, sample) |>
  pivot_wider(names_from = sample, values_from = se, names_glue = "{sample}_se")

ps <- results |>
  select(study, term, p, dv, sample) |>
  pivot_wider(names_from = sample, values_from = p, names_glue = "{sample}_p")

gg_df <- ests |>
  left_join(ses, by = c("study", "term", "dv")) |>
  left_join(ps, by = c("study", "term", "dv")) |>
  mutate(
    original_sig = factor(
      original_p <= 0.05,
      levels = c(TRUE, FALSE),
      labels = c("Significant", "Not Significant")
    ),
    mt_ui = mt + 1.96 * mt_se,
    mt_li = mt - 1.96 * mt_se,
    original_ui = original + 1.96 * original_se,
    original_li = original - 1.96 * original_se
  )

# The plotted pairs and interval endpoints, written out so the figure can be diffed by
# something other than its own timestamp.
write_csv(
  gg_df |> select(study, dv, term, mt, mt_se, original, original_se, mt_li, mt_ui,
                  original_li, original_ui, original_sig),
  here::here("maintained", "output", "figure_3_mt_original_scatter.csv")
)

# Figure ----

g <- ggplot(gg_df, aes(x = mt, y = original, color = original_sig)) +
  geom_point(aes(shape = original_sig)) +
  geom_rug() +
  geom_segment(aes(x = mt, xend = mt, y = original_ui, yend = original_li), alpha = 0.2) +
  geom_segment(aes(x = mt_ui, xend = mt_li, y = original, yend = original), alpha = 0.2) +
  coord_cartesian(xlim = c(-1, 1), ylim = c(-1, 1)) +
  geom_hline(yintercept = 0, linetype = "dashed", alpha = 0.3) +
  geom_vline(xintercept = 0, linetype = "dashed", alpha = 0.3) +
  stat_smooth(
    aes(color = NULL, weight = 1 / mt_se^2),
    method = "lm", fullrange = TRUE, alpha = 0.1, color = "grey"
  ) +
  xlab("Mechanical Turk Version Standardized Estimate") +
  ylab("Original Version Standardized Estimate") +
  theme_bw() +
  theme(legend.position = "bottom") +
  guides(
    color = guide_legend("Original Study"),
    shape = guide_legend("Original Study")
  )

ggsave(here::here("maintained", "output", "figure_3_mt_original_scatter.pdf"), plot = g, height = 7, width = 7)
ggsave(here::here("maintained", "output", "figure_3_mt_original_scatter.png"), plot = g, height = 7, width = 7, dpi = 300)
