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

# Ground truth ----
# Reads every value_rewrite back out of maintained/output/, so it has to run last. It also
# runs in_text_claims.R under capture.output as its coverage gate, so that file necessarily
# runs twice per pipeline: once silently for the gate, and once below for the readable log.
source(here::here("ground_truth", "build_ground_truth.R"))

# In-text claims ----
# The second instrument. One block per numeric claim the article makes that the pipeline
# can reach, each recomputing the number from maintained/output/ by its own path.
source(here::here("maintained", "in_text_claims.R"))

# Deposited archive, again ----
# The check at the top of this file is a precondition: it says original/ was intact
# before anything ran. Nothing above writes to original/, and this second pass is what
# demonstrates it rather than assuming it. Nothing is downloaded; the files are already
# present and are re-checked against the manifest on checksum, byte size and membership.
source(here::here("download_original.R"))
