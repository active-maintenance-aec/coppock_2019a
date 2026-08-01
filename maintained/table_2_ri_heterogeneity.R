# coppock_2019a/maintained/table_2_ri_heterogeneity.R
# Output: output/table_2_ri_heterogeneity.csv, output/table_2_ri_heterogeneity.tex,
#         output/ri_results.rds
# Depends on: helpers.R, original/coppock_generalizability_ri_functions.R,
#             original/coppock_generalizability_studies.RData
# Description: Randomization inference tests of treatment effect homogeneity, one per
#   treatment-versus-control comparison, reproducing Table 2.
#
# The 90 tests take about a minute. They are recomputed every run rather than read back
# from output/ri_results.rds, because a script that skips its own work when its output
# already exists cannot be checked by diffing that output.

source(here::here("maintained", "helpers.R"))
source(here::here("original", "coppock_generalizability_ri_functions.R"))

load(here::here("original", "coppock_generalizability_studies.RData"))

# The original seed. The permutations drawn under it changed with R 3.6.0, which
# replaced the rounding sampler with the rejection sampler; see the report.
set.seed(343)

# One test per treatment-versus-control comparison ----
# verbose = FALSE suppresses the per-test progress bar; it does not touch the
# random stream.

run_test <- function(data, y_col, z_col) {
  data |>
    group_by(sample) |>
    reframe(
      homogenous_fx_test(
        !!sym(y_col), !!sym(z_col), data = pick(everything()), verbose = FALSE
      )$summary_df
    )
}

concealed_carry <- run_test(concealed_carry_stacked, "dv_gun_s", "Z_gun")

immigration_1 <- run_test(filter(immigration_stacked, Z_brader_pos_neg != "control"), "brader_num_imm_s", "Z_brader_pos_neg")
immigration_2 <- run_test(filter(immigration_stacked, Z_brader_pos_neg != "control"), "brader_neg_impact_s", "Z_brader_pos_neg")
immigration <- bind_rows(immigration_1, immigration_2)

death_penalty <- run_test(filter(death_penalty_stacked, Z_CP_3 != "control"), "CP_dv_s", "Z_CP_3")

superordinate_id_1 <- run_test(superordinate_id_stacked, "willing_s", "Z_identity")
superordinate_id_2 <- run_test(superordinate_id_stacked, "willing_s", "Z_particularism")
superordinate_id <- bind_rows(superordinate_id_1, superordinate_id_2)

patriot_act <- run_test(patriot_act_stacked, "PA_support_s", "T1_condition_name")

# Elite endorsements ----
# Assignment probabilities differ by party identification, so the test is run
# within pid_3 and the resulting p-values are combined by Fisher's method.

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

# Remaining studies ----

mental_illness_1 <- run_test(mental_illness_stacked, "mcginty_magazines_s", "Z_mcginty_news")
mental_illness_2 <- run_test(mental_illness_stacked, "mcginty_magazines_s", "Z_mcginty_policy")
mental_illness_3 <- run_test(mental_illness_stacked, "mcginty_SMI_danger_s", "Z_mcginty_news")
mental_illness_4 <- run_test(mental_illness_stacked, "mcginty_SMI_danger_s", "Z_mcginty_policy")
mental_illness <- bind_rows(mental_illness_1, mental_illness_2, mental_illness_3, mental_illness_4)

system_threat_1 <- run_test(system_threat_stacked, "craig_num_imm_s", "Z_craig")
system_threat_2 <- run_test(system_threat_stacked, "craig_wol_s", "Z_craig")
system_threat <- bind_rows(system_threat_1, system_threat_2)

expert_economists_1 <- run_test(expert_economists_stacked, "agree_1_s", "Z_expert_1")
expert_economists_2 <- run_test(expert_economists_stacked, "agree_2_s", "Z_expert_2")
expert_economists_3 <- run_test(expert_economists_stacked, "agree_3_s", "Z_expert_3")
expert_economists_4 <- run_test(expert_economists_stacked, "agree_4_s", "Z_expert_4")
expert_economists_5 <- run_test(expert_economists_stacked, "agree_5_s", "Z_expert_5")
expert_economists <- bind_rows(expert_economists_1, expert_economists_2, expert_economists_3,
                               expert_economists_4, expert_economists_5)

free_trade_1 <- run_test(free_trade_stacked, "Y_Hiscox_s", "Z_Hiscox_expert")
free_trade_2 <- run_test(free_trade_stacked, "Y_Hiscox_s", "Z_Hiscox_valence")
free_trade <- bind_rows(free_trade_1, free_trade_2)

polarization_1 <- run_test(filter(polarization_stacked, Z_Levendusky != "placebo"), "L_ex_s", "Z_Levendusky")
polarization_2 <- run_test(filter(polarization_stacked, Z_Levendusky != "placebo"), "L_dif_s", "Z_Levendusky")
polarization <- bind_rows(polarization_1, polarization_2)

frame_breadth_1 <- run_test(frame_breadth_stacked, "Y_crime_s", "Z_crime_Y_crime")
frame_breadth_2 <- run_test(frame_breadth_stacked, "Y_health_s", "Z_health_Y_health")
frame_breadth_3 <- run_test(frame_breadth_stacked, "Y_stimulus_s", "Z_stimulus_Y_stimulus")
frame_breadth_4 <- run_test(frame_breadth_stacked, "Y_terror_s", "Z_terror_Y_terror")
frame_breadth <- bind_rows(frame_breadth_1, frame_breadth_2, frame_breadth_3, frame_breadth_4)

ri_results <- bind_rows(
  concealed_carry = concealed_carry, immigration = immigration,
  death_penalty = death_penalty, superordinate_id = superordinate_id,
  patriot_act = patriot_act, elite_endorsements = elite_endorsements,
  mental_illness = mental_illness, system_threat = system_threat,
  expert_economists = expert_economists, free_trade = free_trade,
  polarization = polarization, frame_breadth = frame_breadth,
  .id = "study"
)

write_rds(ri_results, here::here("maintained", "output", "ri_results.rds"))

# Table 2 ----

table_2 <- ri_results |>
  mutate(max_pval_adjust = p.adjust(max_pval, "holm")) |>
  group_by(sample) |>
  summarise(
    n_comparisons = n(),
    n_sig = sum(max_pval <= 0.05, na.rm = TRUE),
    n_sig_holm = sum(max_pval_adjust <= 0.05, na.rm = TRUE),
    .groups = "drop"
  )

write_csv(table_2, here::here("maintained", "output", "table_2_ri_heterogeneity.csv"))
print(table_2)

tex_out <- kable(
  table_2,
  format = "latex",
  col.names = c("Sample", "N Comparisons", "N Significant", "N Significant (Holm)"),
  caption = "Tests of Treatment Effect Heterogeneity",
  booktabs = TRUE
) |>
  kable_styling(latex_options = "hold_position")

write_lines(as.character(tex_out), here::here("maintained", "output", "table_2_ri_heterogeneity.tex"))
