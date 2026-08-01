# coppock_2019a/run_all.R
# Runs the whole reproduction in order: fetch and verify the deposited archive, then
# the ATE estimates every other script reads, then the published tables and figures,
# then the in-text quantities.
# Every script is self-contained and can also be run on its own.
#
# Runtime is about a minute, dominated by table_2_ri_heterogeneity.R, which recomputes
# 90 randomization inference tests.

library(here)
here::i_am("run_all.R")

# Deposited archive ----
# Downloads from Dataverse on a fresh clone; verifies checksums either way.
source(here::here("download_original.R"))

# Estimates ----
# Every table and figure below reads output/analysis_results.rds.
source(here::here("maintained", "analysis_ate_estimates.R"))

# Tables ----
source(here::here("maintained", "table_a1_ate_summary.R"))
source(here::here("maintained", "table_2_ri_heterogeneity.R"))

# Figures ----
source(here::here("maintained", "figure_2_study_estimates.R"))
source(here::here("maintained", "figure_3_mt_original_scatter.R"))
source(here::here("maintained", "figure_4_power_simulation.R"))

# In-text quantities ----
source(here::here("maintained", "text_correlations.R"))
