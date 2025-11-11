# for point prevalence analysis-----
info(logger, "Instantiating denominator cohort")

for (i in 1:length(denominator_age_groups)){
  outcomeCohortId <- omopgenerics::settings(cdm$study_population) |>
    dplyr::filter(
      if(denominator_age_groups[i] == 1) cohort_name %in% c("bexsero", "trumenba", "men_b", "men_b_at_least_2_doses", "men_b_at_least_3_doses", "men_b_exact_1_dose", "men_b_exact_2_doses", "men_b_exact_3_doses")
      else if (denominator_age_groups[i] == 2) cohort_name %in% c("men_c", "men_c_exact_1_dose", "bexsero", "trumenba", "men_b", "men_b_at_least_2_doses", "men_b_at_least_3_doses", "men_b_exact_1_dose", "men_b_exact_2_doses", "men_b_exact_3_doses")
      else if (denominator_age_groups[i] == 18) cohort_name %in% c("mcv4", "mcv4_exact_1_dose", "menveo", "nimenrix")) |>
    dplyr::pull("cohort_definition_id")
  
    info(logger, paste0("Estimating point prevalence at age ", denominator_age_groups[i]))
    results[[paste0("point_prevalence_age_", denominator_age_groups[i])]] <- estimatePointPrevalence(
      cdm = cdm,
      denominatorTable = paste0("denominator_", denominator_age_groups[i]),
      outcomeTable = "study_population",
      outcomeCohortId = outcomeCohortId,
      interval = c("quarters", "years")
    )
}

outcomeCohortId18 <- omopgenerics::settings(cdm$study_population) |>
  dplyr::filter(cohort_name %in% c("mcv4", "mcv4_exact_1_dose", "menveo", "nimenrix")) |>
  dplyr::pull("cohort_definition_id")

results[["point_prevalence_age_12_18"]] <- estimatePointPrevalence(
  cdm = cdm,
  denominatorTable = "denominator_12_18",
  outcomeTable = "study_population",
  outcomeCohortId = outcomeCohortId,
  interval = c("quarters", "years")
)

for (i in 1:length(denominator_age_groups)){
  outcomeCohortId <- omopgenerics::settings(cdm$study_population) |>
    dplyr::filter(
      if(denominator_age_groups[i] == 1) cohort_name %in% c("bexsero", "trumemba", "men_b", "men_b_at_least_2_doses", "men_b_at_least_3_doses", "men_b_exact_1_dose", "men_b_exact_2_doses", "men_b_exact_3_doses")
      else if (denominator_age_groups[i] == 2) cohort_name %in% c("men_c", "men_c_exact_1_dose", "bexsero", "trumemba", "men_b", "men_b_at_least_2_doses", "men_b_at_least_3_doses", "men_b_exact_1_dose", "men_b_exact_2_doses", "men_b_exact_3_doses")
      else if (denominator_age_groups[i] == 18) cohort_name %in% c("mcv4", "mcv4_exact_1_dose", "menveo", "nimenrix")) |>
    dplyr::pull("cohort_definition_id")
  
  info(logger, paste0("Estimating point prevalence at age ", denominator_age_groups[i]))
  results[[paste0("point_prevalence_prior_observation_age_", denominator_age_groups[i])]] <- estimatePointPrevalence(
    cdm = cdm,
    denominatorTable = paste0("denominator_prior_observation_", denominator_age_groups[i]),
    outcomeTable = "study_population",
    outcomeCohortId = outcomeCohortId,
    interval = c("quarters", "years")
  )
}
