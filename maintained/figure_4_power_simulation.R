# coppock_2019a/maintained/figure_4_power_simulation.R
# Output: output/figure_4_power_simulation.pdf, output/figure_4_power_simulation.png
# Depends on: helpers.R, original/coppock_generalizability_simulation_results.RData
# Description: Power curve from simulation: probability of rejecting homogeneity null by N and SD(tau).

source(here::here("maintained", "helpers.R"))

# Inputs ----
# The archive ships the simulation results and comments out the simulation that
# produced them, noting that it "takes a *very* long time to run". The object
# loaded here is `df`, built by melt(powers_mat) in that commented-out block.

load(here::here("original", "coppock_generalizability_simulation_results.RData"))

gg_df <- df |>
  mutate(n_per_arm = n / 2)

# Figure ----

g <- ggplot(gg_df, aes(x = n_per_arm, y = value, group = het_param, color = het_param)) +
  geom_line() +
  geom_vline(xintercept = 500, linetype = "dashed") +
  geom_hline(yintercept = 0.8, linetype = "dashed") +
  annotate("text", x = 575, y = 0.85, label = "sigma[tau] %~~% 0.20", parse = TRUE) +
  scale_y_continuous(breaks = seq(0, 1, 0.2)) +
  scale_color_gradient(
    low = "gainsboro", high = "black",
    guide = guide_colorbar(bquote(sigma[tau]))
  ) +
  xlab("Number of Subjects Per Arm") +
  ylab("Probability of Rejecting Null of Homogeneity") +
  theme_bw() +
  theme(legend.key.height = unit(6, "lines"))

ggsave(here::here("maintained", "output", "figure_4_power_simulation.pdf"), plot = g, height = 7, width = 7)
ggsave(here::here("maintained", "output", "figure_4_power_simulation.png"), plot = g, height = 7, width = 7, dpi = 300)
