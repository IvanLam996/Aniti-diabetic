# denominator cohort - for point prevalence analysis -----
info(logger, "Instantiating denominator cohort")

for (i in seq_along(denominator_age_groups)){
  cdm <- generateDenominatorCohortSet(
    cdm = cdm,
    name = paste0("denominator_", denominator_age_groups[i]),
    ageGroup = list(c(denominator_age_groups[i], denominator_age_groups[i])), 
    sex = c("Female", "Male", "Both"),
    cohortDateRange = c(
      study_period_start,
      study_period_end
    )
  ) 
  
  cdm[[paste0("denominator_", denominator_age_groups[i])]] <- cdm[[paste0("denominator_", denominator_age_groups[i])]] |>
    CohortConstructor::renameCohort(cohortId = 1,
                                    newCohortName = paste0("denominator_no_prior_observation_cohort_female_age_", denominator_age_groups[i])) |>
    CohortConstructor::renameCohort(cohortId = 2,
                                    newCohortName = paste0("denominator_no_prior_observation_cohort_male_age_", denominator_age_groups[i])) |>
    CohortConstructor::renameCohort(cohortId = 3,
                                    newCohortName = paste0("denominator_no_prior_observation_cohort_age_", denominator_age_groups[i]))
}

cdm <- generateDenominatorCohortSet(
  cdm = cdm,
  name = "denominator_12_18",
  ageGroup = list(c(12, 18)), 
  sex = c("Female", "Male", "Both"),
  cohortDateRange = c(
    study_period_start,
    study_period_end
  )
) 

cdm[["denominator_12_18"]] <- cdm[["denominator_12_18"]] |>
  CohortConstructor::renameCohort(cohortId = 1,
                                  newCohortName = "denominator_no_prior_observation_cohort_female_age_12_18") |>
  CohortConstructor::renameCohort(cohortId = 2,
                                  newCohortName = "denominator_no_prior_observation_cohort_male_age_12_18") |>
  CohortConstructor::renameCohort(cohortId = 3,
                                  newCohortName = "denominator_no_prior_observation_cohort_age_12_18")

for (i in seq_along(denominator_age_groups)){
  cdm <- generateDenominatorCohortSet(
    cdm = cdm,
    name = paste0("denominator_prior_observation_", denominator_age_groups[i]),
    ageGroup = list(c(denominator_age_groups[i], denominator_age_groups[i])), 
    sex = c("Female", "Male", "Both"),
    cohortDateRange = c(
      study_period_start,
      study_period_end
    ),
    daysPriorObservation = if (i %in% c(1,2)) {study_prior_observation[i] - 56} else {study_prior_observation[i]}
  ) 
  
  cdm[[paste0("denominator_prior_observation_", denominator_age_groups[i])]] <- cdm[[paste0("denominator_prior_observation_", denominator_age_groups[i])]] |>
    CohortConstructor::renameCohort(cohortId = 1,
                                    newCohortName = paste0("denominator_prior_observation_cohort_female_age_", denominator_age_groups[i])) |>
    CohortConstructor::renameCohort(cohortId = 2,
                                    newCohortName = paste0("denominator_prior_observation_cohort_male_age_", denominator_age_groups[i])) |>
    CohortConstructor::renameCohort(cohortId = 3,
                                    newCohortName = paste0("denominator_prior_observation_cohort_age_", denominator_age_groups[i]))
}

# Reading codelists
info(logger, "read codelists")
pathCodelists <- file.path(here::here(), "Codelists", "OutputFolder")
codelist <- omopgenerics::importCodelist(pathCodelists, type = "csv")

# Instantiate Cohorts ----
info(logger, "Instantiating cohorts")
# Creating MCV4 cohort based on codelists
info(logger, "Instantiating MCV4 cohorts")
cdm$mcv4_codelist <- CohortConstructor::conceptCohort(
  cdm = cdm, 
  conceptSet = codelist[c("mcv4")],
  name = "mcv4_codelist",
  exit = "event_start_date"
) 

# Creating MCV4 cohort based on singular codes
mcv4_alternative <- list(
  "group_a" = 509079, 
  "group_c" = 509081,
  "group_w" = 514012,
  "group_y" = 514015
) |> 
  omopgenerics::newCodelist()

cdm$mcv4_alternative <- conceptCohort(
  cdm = cdm, 
  conceptSet = mcv4_alternative,
  name = "mcv4_alternative",
  exit = "event_start_date"
) 

cdm$mcv4_alternative_cohort <- cdm$mcv4_alternative |>
  CohortConstructor::subsetCohorts(cohortId = 1, 
                                   name = "mcv4_alternative_cohort") |>
  CohortConstructor::requireCohortIntersect(
    targetCohortTable = "mcv4_alternative",
    window = c(0,0),
    cohortId = 1,
    targetCohortId = 2,
    name = "mcv4_alternative_cohort"
  ) |>
  CohortConstructor::requireCohortIntersect(
    targetCohortTable = "mcv4_alternative",
    window = c(0,0),
    cohortId = 1,
    targetCohortId = 3,
    name = "mcv4_alternative_cohort"
  ) |>
  CohortConstructor::requireCohortIntersect(
    targetCohortTable = "mcv4_alternative",
    window = c(0,0),
    cohortId = 1,
    targetCohortId = 4,
    name = "mcv4_alternative_cohort"
  ) |>
  CohortConstructor::renameCohort(
    cohortId = 1,
    newCohortName = "mcv4_alternative_cohort"
  ) 

# Binding MCV4 cohorts
cdm <- CohortConstructor::bind(
  cdm$mcv4_codelist,
  cdm$mcv4_alternative_cohort,
  name = "mcv4"
)  

cdm$mcv4 <- cdm$mcv4 |>
  CohortConstructor::unionCohorts(name = "mcv4") |>
  CohortConstructor::renameCohort(cohortId = 1,
                                  newCohortName = "mcv4") 

cdm$mcv4_at_least_1_dose <- cdm$mcv4 |>
  CohortConstructor::exitAtObservationEnd(
    name = "mcv4_at_least_1_dose",
    limitToCurrentPeriod = FALSE
  )

cdm$mcv4_exact_1_dose <- cdm$mcv4_at_least_1_dose |>
  PatientProfiles::addCohortIntersectDate(
    targetCohortTable = "mcv4",
    window = c(1, Inf),
    name = "mcv4_exact_1_dose"
  ) |>
  CohortConstructor::requireIsFirstEntry(
    name = "mcv4_exact_1_dose"
  ) |>
  CohortConstructor::exitAtFirstDate(
    dateColumns = c("mcv4_1_to_inf", "cohort_end_date")
  ) |>
  CohortConstructor::renameCohort(cohortId = 1,
                                  newCohortName = "mcv4_exact_1_dose")

# Creating Men C cohort
info(logger, "Instantiating Men C cohort")
cdm$men_c <- cdm |>
  CohortConstructor::conceptCohort(
    conceptSet = codelist[c("men_c")],
    name = "men_c",
    exit = "event_start_date"
  ) |>
  CohortConstructor::requireCohortIntersect(
    targetCohortTable = "mcv4_alternative_cohort", 
    window = c(0, 0),
    intersections = c(0, 0),
    name = "men_c"
  ) 

cdm$men_c_at_least_1_dose <- cdm$men_c |>
  CohortConstructor::exitAtObservationEnd(
    name = "men_c_at_least_1_dose",
    limitToCurrentPeriod = FALSE
  ) 

cdm$men_c_exact_1_dose <- cdm$men_c_at_least_1_dose |>
  PatientProfiles::addCohortIntersectDate(
    targetCohortTable = "men_c",
    window = c(1, Inf),
    name = "men_c_exact_1_dose"
  ) |>
  CohortConstructor::requireIsFirstEntry(
    name = "men_c_exact_1_dose"
  ) |>
  CohortConstructor::exitAtFirstDate(
    dateColumns = c("men_c_1_to_inf", "cohort_end_date")
  ) |>
  CohortConstructor::renameCohort(cohortId = 1,
                                  newCohortName = "men_c_exact_1_dose")

# Creating Men B cohort
info(logger, "Instantiating Men B cohorts")
cdm$men_b <- cdm |>
  CohortConstructor::conceptCohort(
    conceptSet = codelist[c("men_b")],
    name = "men_b",
    exit = "event_start_date"
  )  |>
  DrugUtilisation::requirePriorDrugWashout(days = 14) 

cdm$men_b_at_least_1_dose <- cdm$men_b |>
  CohortConstructor::exitAtObservationEnd(
    name = "men_b_at_least_1_dose",
    limitToCurrentPeriod = FALSE
  )

cdm$men_b_at_least_2_doses <- cdm$men_b |>
  CohortConstructor::requireCohortIntersect(
    targetCohortTable = "men_b", 
    window = c(-Inf, Inf),
    intersections = c(2,Inf),
    name = "men_b_at_least_2_doses"
  ) |>
  CohortConstructor::requireCohortIntersect(
    targetCohortTable = "men_b", 
    window = c(-Inf, -1),
    intersections = c(1,1),
    name = "men_b_at_least_2_doses"
  ) |>
  CohortConstructor::renameCohort(cohortId = 1,
                                  newCohortName = "men_b_at_least_2_doses")|> 
  CohortConstructor::exitAtObservationEnd(
    name = "men_b_at_least_2_doses",
    limitToCurrentPeriod = FALSE
  )

cdm$men_b_at_least_3_doses <- cdm$men_b |>
  CohortConstructor::requireCohortIntersect(
    targetCohortTable = "men_b", 
    window = c(-Inf, Inf),
    intersections = c(3,Inf),
    name = "men_b_at_least_3_doses"
  ) |>
  CohortConstructor::requireCohortIntersect(
    targetCohortTable = "men_b", 
    window = c(-Inf, -1),
    intersections = c(2,2),
    name = "men_b_at_least_3_doses"
  ) |>
  CohortConstructor::renameCohort(cohortId = 1,
                                  newCohortName = "men_b_at_least_3_doses")|> 
  CohortConstructor::exitAtObservationEnd(
    name = "men_b_at_least_3_doses",
    limitToCurrentPeriod = FALSE
  )

cdm$men_b_exact_1_dose <- cdm$men_b_at_least_1_dose |>
  PatientProfiles::addCohortIntersectDate(
    targetCohortTable = "men_b",
    window = c(1, Inf),
    name = "men_b_exact_1_dose"
  ) |>
  CohortConstructor::requireIsFirstEntry(
    name = "men_b_exact_1_dose"
  ) |>
  CohortConstructor::exitAtFirstDate(
    dateColumns = c("men_b_1_to_inf", "cohort_end_date")
  ) |>
  CohortConstructor::renameCohort(cohortId = 1,
                                  newCohortName = "men_b_exact_1_dose")

cdm$men_b_exact_2_doses <- cdm$men_b_at_least_2_doses |>
  PatientProfiles::addCohortIntersectDate(
    targetCohortTable = "men_b",
    window = c(1, Inf),
    name = "men_b_exact_2_doses"
  ) |>
  CohortConstructor::requireIsFirstEntry(
    name = "men_b_exact_2_doses"
  ) |>
  CohortConstructor::exitAtFirstDate(
    dateColumns = c("men_b_1_to_inf", "cohort_end_date")
  ) |>
  CohortConstructor::renameCohort(cohortId = 1,
                                  newCohortName = "men_b_exact_2_doses")

cdm$men_b_exact_3_doses <- cdm$men_b_at_least_3_doses |>
  PatientProfiles::addCohortIntersectDate(
    targetCohortTable = "men_b",
    window = c(1, Inf),
    name = "men_b_exact_3_doses"
  ) |>
  CohortConstructor::requireIsFirstEntry(
    name = "men_b_exact_3_doses"
  ) |>
  CohortConstructor::exitAtFirstDate(
    dateColumns = c("men_b_1_to_inf", "cohort_end_date")
  ) |>
  CohortConstructor::renameCohort(cohortId = 1,
                                  newCohortName = "men_b_exact_3_doses")

# Creating Bexsero cohort
info(logger, "Instantiating Bexsero cohorts")
cdm$bexsero <- cdm |>
  CohortConstructor::conceptCohort(
    conceptSet = codelist[c("bexsero")],
    name = "bexsero",
    exit = "event_start_date"
  ) |>
  DrugUtilisation::requirePriorDrugWashout(days = 14) |>
  CohortConstructor::exitAtObservationEnd(
    name = "bexsero",
    limitToCurrentPeriod = FALSE
  )

# Creating Trumenba cohort
info(logger, "Instantiating Trumenba cohorts")
cdm$trumenba <- cdm |>
  CohortConstructor::conceptCohort(
    conceptSet = codelist[c("trumenba")],
    name = "trumenba",
    exit = "event_start_date"
  ) |>
  DrugUtilisation::requirePriorDrugWashout(days = 14) |>
  CohortConstructor::exitAtObservationEnd(
    name = "trumenba",
    limitToCurrentPeriod = FALSE
  )

# Creating Menveo cohort
info(logger, "Instantiating Menveo cohorts")
cdm$menveo <- cdm |>
  CohortConstructor::conceptCohort(
    conceptSet = codelist[c("menveo")],
    name = "menveo",
    exit = "event_start_date"
  ) |>
  CohortConstructor::requireIsFirstEntry() |>
  CohortConstructor::exitAtObservationEnd(
    name = "menveo",
    limitToCurrentPeriod = FALSE
  )

# Creating Nimenrix cohort
info(logger, "Instantiating Nimenrix cohorts")
cdm$nimenrix <- cdm |>
  CohortConstructor::conceptCohort(
    conceptSet = codelist[c("nimenrix")],
    name = "nimenrix",
    exit = "event_start_date"
  ) |>
  CohortConstructor::requireIsFirstEntry() |>
  CohortConstructor::exitAtObservationEnd(
    name = "nimenrix",
    limitToCurrentPeriod = FALSE
  )

cdm <- omopgenerics::bind(
  cdm$mcv4_at_least_1_dose,
  cdm$mcv4_exact_1_dose,
  cdm$men_c_at_least_1_dose,
  cdm$men_c_exact_1_dose,
  cdm$men_b_at_least_1_dose,
  cdm$men_b_at_least_2_doses,
  cdm$men_b_at_least_3_doses,
  cdm$men_b_exact_1_dose,
  cdm$men_b_exact_2_doses,
  cdm$men_b_exact_3_doses,
  cdm$bexsero,
  cdm$trumenba,
  cdm$menveo,
  cdm$nimenrix,
  name = "study_population"
)
