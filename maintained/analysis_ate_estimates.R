# coppock_2019a/maintained/analysis_ate_estimates.R
# Output: output/analysis_results.rds
# Depends on: helpers.R, original/coppock_generalizability_studies.RData
# Description: Estimates ATE by study and sample; saves results tibble.

source(here::here("maintained", "helpers.R"))

load(here::here("original", "coppock_generalizability_studies.RData"))

# Study 1: Concealed Carry ------------------------------------------------

concealed_carry <-
  concealed_carry_stacked |>
  group_by(sample) |>
  reframe(commarobust_tidy(lm(dv_gun_s ~ Z_gun, weights = weights, data = pick(everything()))))

# Study 2: Immigration ----------------------------------------------------

immigration_1 <-
  immigration_stacked |>
  filter(Z_brader_pos_neg != "control") |>
  group_by(sample) |>
  reframe(commarobust_tidy(lm(brader_num_imm_s ~ Z_brader_pos_neg, weights = weights, data = pick(everything()))))

immigration_2 <-
  immigration_stacked |>
  filter(Z_brader_pos_neg != "control") |>
  group_by(sample) |>
  reframe(commarobust_tidy(lm(brader_neg_impact_s ~ Z_brader_pos_neg, weights = weights, data = pick(everything()))))

immigration <- bind_rows(immigration_1, immigration_2)

# Study 3: Death Penalty --------------------------------------------------

death_penalty <-
  death_penalty_stacked |>
  filter(Z_CP_3 != "control") |>
  group_by(sample) |>
  reframe(commarobust_tidy(lm(CP_dv_s ~ Z_CP_3, weights = weights, data = pick(everything()))))

# Study 4: Superordinate Identity -----------------------------------------

superordinate_id <-
  superordinate_id_stacked |>
  group_by(sample) |>
  reframe(commarobust_tidy(lm(willing_s ~ Z_identity + Z_particularism, data = pick(everything()))))

# Study 5: Patriot Act ----------------------------------------------------

patriot_act <-
  patriot_act_stacked |>
  group_by(sample) |>
  reframe(commarobust_tidy(lm(PA_support_s ~ T1_condition_name, weights = weights, data = pick(everything()))))

# Study 6: Elite Endorsements ---------------------------------------------
# Must control for pid because of differential assignment probabilities.

elite_endorsements_1 <-
  elite_endorsements_stacked |>
  filter(Z_imm_match != "control") |>
  mutate(Z_match = Z_imm_match) |>
  group_by(sample) |>
  reframe(commarobust_tidy(lm(imm_dv_s ~ Z_match + pid_3, weights = weights, data = pick(everything()))))

elite_endorsements_2 <-
  elite_endorsements_stacked |>
  filter(Z_fore_match != "control") |>
  mutate(Z_match = Z_fore_match) |>
  group_by(sample) |>
  reframe(commarobust_tidy(lm(fore_dv_s ~ Z_match + pid_3, weights = weights, data = pick(everything()))))

elite_endorsements <- bind_rows(elite_endorsements_1, elite_endorsements_2)

# Study 7: Mental Illness -------------------------------------------------

mental_illness_1 <-
  mental_illness_stacked |>
  group_by(sample) |>
  reframe(commarobust_tidy(lm(mcginty_magazines_s ~ Z_mcginty_news + Z_mcginty_policy, weights = weights, data = pick(everything()))))

mental_illness_2 <-
  mental_illness_stacked |>
  group_by(sample) |>
  reframe(commarobust_tidy(lm(mcginty_SMI_danger_s ~ Z_mcginty_news + Z_mcginty_policy, weights = weights, data = pick(everything()))))

mental_illness <- bind_rows(mental_illness_1, mental_illness_2)

# Study 8: System Threat --------------------------------------------------

system_threat_1 <-
  system_threat_stacked |>
  group_by(sample) |>
  reframe(commarobust_tidy(lm(craig_num_imm_s ~ Z_craig, weights = weights, data = pick(everything()))))

system_threat_2 <-
  system_threat_stacked |>
  group_by(sample) |>
  reframe(commarobust_tidy(lm(craig_wol_s ~ Z_craig, weights = weights, data = pick(everything()))))

system_threat <- bind_rows(system_threat_1, system_threat_2)

# Study 9: Expert Economists ----------------------------------------------

expert_economists_1 <-
  expert_economists_stacked |>
  group_by(sample) |>
  reframe(commarobust_tidy(lm(agree_1_s ~ Z_expert_1, weights = weights, data = pick(everything()))))

expert_economists_2 <-
  expert_economists_stacked |>
  group_by(sample) |>
  reframe(commarobust_tidy(lm(agree_2_s ~ Z_expert_2, weights = weights, data = pick(everything()))))

expert_economists_3 <-
  expert_economists_stacked |>
  group_by(sample) |>
  reframe(commarobust_tidy(lm(agree_3_s ~ Z_expert_3, weights = weights, data = pick(everything()))))

expert_economists_4 <-
  expert_economists_stacked |>
  group_by(sample) |>
  reframe(commarobust_tidy(lm(agree_4_s ~ Z_expert_4, weights = weights, data = pick(everything()))))

expert_economists_5 <-
  expert_economists_stacked |>
  group_by(sample) |>
  reframe(commarobust_tidy(lm(agree_5_s ~ Z_expert_5, weights = weights, data = pick(everything()))))

expert_economists <- bind_rows(
  expert_economists_1, expert_economists_2, expert_economists_3,
  expert_economists_4, expert_economists_5
)

# Studies 10 and 11: Free Trade -----------------------------------------------

free_trade <-
  free_trade_stacked |>
  group_by(sample) |>
  reframe(commarobust_tidy(lm(Y_Hiscox_s ~ Z_Hiscox_expert + Z_Hiscox_valence, weights = weights, data = pick(everything()))))

# Studies 12 and 13: Polarization ---------------------------------------------

polarization_1 <-
  polarization_stacked |>
  filter(Z_Levendusky != "placebo") |>
  group_by(sample) |>
  reframe(commarobust_tidy(lm(L_ex_s ~ Z_Levendusky, weights = weights, data = pick(everything()))))

polarization_2 <-
  polarization_stacked |>
  filter(Z_Levendusky != "placebo") |>
  group_by(sample) |>
  reframe(commarobust_tidy(lm(L_dif_s ~ Z_Levendusky, weights = weights, data = pick(everything()))))

polarization <- bind_rows(polarization_1, polarization_2)

# Studies 14 and 15: Frame Breadth --------------------------------------------

frame_breadth_1 <-
  frame_breadth_stacked |>
  group_by(sample) |>
  reframe(commarobust_tidy(lm(Y_crime_s ~ Z_crime_Y_crime, weights = weights, data = pick(everything()))))

frame_breadth_2 <-
  frame_breadth_stacked |>
  group_by(sample) |>
  reframe(commarobust_tidy(lm(Y_health_s ~ Z_health_Y_health, weights = weights, data = pick(everything()))))

frame_breadth_3 <-
  frame_breadth_stacked |>
  group_by(sample) |>
  reframe(commarobust_tidy(lm(Y_stimulus_s ~ Z_stimulus_Y_stimulus, weights = weights, data = pick(everything()))))

frame_breadth_4 <-
  frame_breadth_stacked |>
  group_by(sample) |>
  reframe(commarobust_tidy(lm(Y_terror_s ~ Z_terror_Y_terror, weights = weights, data = pick(everything()))))

frame_breadth <- bind_rows(frame_breadth_1, frame_breadth_2, frame_breadth_3, frame_breadth_4)

# Combine all results -----------------------------------------------------

results <- bind_rows(
  concealed_carry   = concealed_carry,
  immigration       = immigration,
  death_penalty     = death_penalty,
  superordinate_id  = superordinate_id,
  patriot_act       = patriot_act,
  elite_endorsements = elite_endorsements,
  mental_illness    = mental_illness,
  system_threat     = system_threat,
  expert_economists = expert_economists,
  free_trade        = free_trade,
  polarization      = polarization,
  frame_breadth     = frame_breadth,
  .id = "study"
) |>
  filter(term != "(Intercept)", term != "pid_3Republican")

write_rds(results, here::here("maintained", "output", "analysis_results.rds"))
