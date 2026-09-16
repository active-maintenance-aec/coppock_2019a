# coppock_2019a/maintained/figure_2_study_estimates.R
# Output: output/figure_2_study_estimates.csv, output/figure_2_study_estimates.pdf,
#         output/figure_2_study_estimates.png
# Depends on: analysis_ate_estimates.R output, helpers.R
# Description: Faceted coefficient plot of ATE estimates by study and sample.

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
# Estimates are ordered within each facet by the original study's estimate.

estimates <- results |>
  mutate(
    ui = est + 1.96 * se,
    li = est - 1.96 * se,
    entry = paste0(term, dv)
  )

study_order <- estimates |>
  filter(sample == "original") |>
  arrange(est) |>
  pull(entry)

gg_df <- estimates |>
  mutate(
    entry = factor(entry, levels = study_order),
    version = factor(
      sample,
      levels = c("gfk", "mt", "original"),
      labels = c("TESS/GfK", "Mechanical Turk", "Original")
    )
  )

# The plotted estimates and interval endpoints, written out so the figure can be diffed
# by something other than its own timestamp.
write_csv(
  gg_df |> select(study_factor, dv_name, coef_name, version, est, se, li, ui),
  here::here("maintained", "output", "figure_2_study_estimates.csv")
)

# Figure ----

g <- ggplot(gg_df, aes(x = est, y = entry, group = version, color = version, shape = version)) +
  geom_point(position = position_dodge(width = 0.5), size = 3) +
  geom_linerange(aes(xmin = li, xmax = ui), position = position_dodge(width = 0.5)) +
  geom_vline(xintercept = 0, linetype = "dashed", alpha = 0.5) +
  xlab("Standardized Treatment Effect Estimates") +
  scale_color_brewer(palette = "Dark2", guide = guide_legend(reverse = TRUE)) +
  guides(
    color = guide_legend("Study Version"),
    shape = guide_legend("Study Version")
  ) +
  facet_wrap(~study_factor, scales = "free", ncol = 3) +
  theme_bw() +
  theme(
    legend.position = "bottom",
    legend.key.width = unit(4, "lines"),
    axis.text.y = element_blank(),
    axis.ticks.y = element_blank(),
    axis.title.y = element_blank(),
    strip.background = element_blank()
  )

ggsave(here::here("maintained", "output", "figure_2_study_estimates.pdf"), plot = g, height = 11, width = 8.5)
ggsave(here::here("maintained", "output", "figure_2_study_estimates.png"), plot = g, height = 11, width = 8.5, dpi = 300)
