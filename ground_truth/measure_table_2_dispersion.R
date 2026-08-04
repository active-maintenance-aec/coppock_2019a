# coppock_2019a/ground_truth/measure_table_2_dispersion.R
# Output: ground_truth/table_2_seed_dispersion.csv
# Depends on: original/ (run download_original.R first)
# Description: How far Table 2's counts of significant homogeneity tests move from run to
#   run. This asks a question about the deposited procedure rather than about the maintained
#   rewrite, so it is not part of run_all.R; its output is committed and read by README.qmd.
#
#   The randomization inference test draws 100 permutations per grid point, so a p-value is
#   a multiple of 0.01 and a count of how many fall at or below 0.05 is only weakly pinned
#   by a seed. Running the procedure over a range of seeds, under the rejection sampler R
#   has used since 3.6.0 and under the rounding sampler it used before, measures how much of
#   the disagreement between the published table, the published text and the deposited
#   output could be run-to-run variation.
#
#   It takes about a minute per seed, so a full sweep is roughly half an hour. Set
#   TABLE_2_SEEDS to a shorter comma-separated list to check the script quickly.

library(here)
library(tidyverse)

here::i_am("ground_truth/measure_table_2_dispersion.R")

seeds <- as.integer(str_split_1(
  Sys.getenv("TABLE_2_SEEDS", "343,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15"), ","
))
rounding_seeds <- as.integer(str_split_1(
  Sys.getenv("TABLE_2_ROUNDING_SEEDS", "343,16,17,18,19,20,21,22"), ","
))

source(here::here("original", "coppock_generalizability_ri_functions.R"))
load(here::here("original", "coppock_generalizability_studies.RData"))

run_test <- function(data, y_col, z_col) {
  data |>
    group_by(sample) |>
    reframe(
      homogenous_fx_test(
        !!sym(y_col), !!sym(z_col), data = pick(everything()), verbose = FALSE
      )$summary_df
    )
}

# One full pass of the 90 tests, returning Table 2 ----
one_pass <- function() {
  concealed_carry <- run_test(concealed_carry_stacked, "dv_gun_s", "Z_gun")
  immigration_1 <- run_test(filter(immigration_stacked, Z_brader_pos_neg != "control"), "brader_num_imm_s", "Z_brader_pos_neg")
  immigration_2 <- run_test(filter(immigration_stacked, Z_brader_pos_neg != "control"), "brader_neg_impact_s", "Z_brader_pos_neg")
  immigration <- bind_rows(immigration_1, immigration_2)
  death_penalty <- run_test(filter(death_penalty_stacked, Z_CP_3 != "control"), "CP_dv_s", "Z_CP_3")
  superordinate_id_1 <- run_test(superordinate_id_stacked, "willing_s", "Z_identity")
  superordinate_id_2 <- run_test(superordinate_id_stacked, "willing_s", "Z_particularism")
  superordinate_id <- bind_rows(superordinate_id_1, superordinate_id_2)
  patriot_act <- run_test(patriot_act_stacked, "PA_support_s", "T1_condition_name")

  elite_endorsements_1 <- elite_endorsements_stacked |>
    filter(Z_imm_match != "control") |>
    group_by(pid_3, sample) |>
    reframe(homogenous_fx_test(imm_dv_s, Z_imm_match, data = pick(everything()), verbose = FALSE)$summary_df) |>
    group_by(sample, condition_names, dv) |>
    summarise(max_pval = metap::sumlog(max_pval)$p, .groups = "drop")
  elite_endorsements_2 <- elite_endorsements_stacked |>
    filter(Z_fore_match != "control") |>
    group_by(pid_3, sample) |>
    reframe(homogenous_fx_test(fore_dv_s, Z_fore_match, data = pick(everything()), verbose = FALSE)$summary_df) |>
    group_by(sample, condition_names, dv) |>
    summarise(max_pval = metap::sumlog(max_pval)$p, .groups = "drop")
  elite_endorsements <- bind_rows(elite_endorsements_1, elite_endorsements_2)

  mental_illness <- bind_rows(
    run_test(mental_illness_stacked, "mcginty_magazines_s", "Z_mcginty_news"),
    run_test(mental_illness_stacked, "mcginty_magazines_s", "Z_mcginty_policy"),
    run_test(mental_illness_stacked, "mcginty_SMI_danger_s", "Z_mcginty_news"),
    run_test(mental_illness_stacked, "mcginty_SMI_danger_s", "Z_mcginty_policy")
  )
  system_threat <- bind_rows(
    run_test(system_threat_stacked, "craig_num_imm_s", "Z_craig"),
    run_test(system_threat_stacked, "craig_wol_s", "Z_craig")
  )
  expert_economists <- bind_rows(
    run_test(expert_economists_stacked, "agree_1_s", "Z_expert_1"),
    run_test(expert_economists_stacked, "agree_2_s", "Z_expert_2"),
    run_test(expert_economists_stacked, "agree_3_s", "Z_expert_3"),
    run_test(expert_economists_stacked, "agree_4_s", "Z_expert_4"),
    run_test(expert_economists_stacked, "agree_5_s", "Z_expert_5")
  )
  free_trade <- bind_rows(
    run_test(free_trade_stacked, "Y_Hiscox_s", "Z_Hiscox_expert"),
    run_test(free_trade_stacked, "Y_Hiscox_s", "Z_Hiscox_valence")
  )
  polarization <- bind_rows(
    run_test(filter(polarization_stacked, Z_Levendusky != "placebo"), "L_ex_s", "Z_Levendusky"),
    run_test(filter(polarization_stacked, Z_Levendusky != "placebo"), "L_dif_s", "Z_Levendusky")
  )
  frame_breadth <- bind_rows(
    run_test(frame_breadth_stacked, "Y_crime_s", "Z_crime_Y_crime"),
    run_test(frame_breadth_stacked, "Y_health_s", "Z_health_Y_health"),
    run_test(frame_breadth_stacked, "Y_stimulus_s", "Z_stimulus_Y_stimulus"),
    run_test(frame_breadth_stacked, "Y_terror_s", "Z_terror_Y_terror")
  )

  ri <- bind_rows(
    concealed_carry = concealed_carry, immigration = immigration,
    death_penalty = death_penalty, superordinate_id = superordinate_id,
    patriot_act = patriot_act, elite_endorsements = elite_endorsements,
    mental_illness = mental_illness, system_threat = system_threat,
    expert_economists = expert_economists, free_trade = free_trade,
    polarization = polarization, frame_breadth = frame_breadth,
    .id = "study"
  )

  ri |>
    mutate(max_pval_adjust = p.adjust(max_pval, "holm")) |>
    group_by(sample) |>
    summarise(
      n_comparisons = n(),
      n_sig = sum(max_pval <= 0.05, na.rm = TRUE),
      n_sig_holm = sum(max_pval_adjust <= 0.05, na.rm = TRUE),
      .groups = "drop"
    )
}

# Sweep ----
# The sampler is restored explicitly rather than through on.exit(), which does not reliably
# fire at the top level of a sourced file, and the restoration is asserted.

sweep <- function(seed, sampler) {
  if (sampler == "rounding") {
    suppressWarnings(RNGkind(sample.kind = "Rounding"))
  } else {
    RNGkind(sample.kind = "Rejection")
  }
  set.seed(seed)
  one_pass() |> mutate(seed = seed, sampler = sampler)
}

dispersion <- bind_rows(
  map(seeds, sweep, sampler = "rejection"),
  map(rounding_seeds, sweep, sampler = "rounding")
) |>
  select(sampler, seed, sample, n_comparisons, n_sig, n_sig_holm) |>
  arrange(sampler, seed, sample)

RNGkind(sample.kind = "Rejection")
stopifnot(RNGkind()[3] == "Rejection")

write_csv(dispersion, here::here("ground_truth", "table_2_seed_dispersion.csv"))

print(dispersion |>
        summarise(runs = n(), lowest = min(n_sig), highest = max(n_sig), .by = c(sampler, sample)))
