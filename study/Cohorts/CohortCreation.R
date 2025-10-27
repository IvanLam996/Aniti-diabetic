
# denominator cohort - for point prevalence analysis -----
info(logger, "Instantiating denominator cohort")

# create the denominator cohort stratifying by age and sex
cdm <- generateDenominatorCohortSet(
  cdm = cdm,
  name = "denominator",
  ageGroup = list(c(18, 44), c(45, 64), c(65, 150)), 
  sex = c("Female", "Male", "Both"),
  cohortDateRange = c(study_period_start, "2025-01-01")
) 

#  Add ethnicity as a column
cdm$denominator <- cdm$denominator |>
  left_join(
    cdm$person |>
      addConceptName(column = "race_concept_id", nameStyle = "ethnicity") |>
      select(subject_id = "person_id", "ethnicity"),
    by = "subject_id"
  ) |>
  compute(name = "denominator")

#  Add the townsend index as a column
cdm$denominator <- cdm$denominator |>
  left_join(
    cdm$measurement |> 
      filter(measurement_concept_id == 715996) |>
      select(subject_id = "person_id", townsend = "value_as_number"),
    by = "subject_id"
  ) |>
  compute(name = "denominator")

# to use estimateIncidence(strata = list(c("ethnicity", "townsend")))

# Creating GLP1 cohort based on codelists
info(logger, "Instantiating GLP1 cohorts")
cdm$glp1_codelist <- CohortConstructor::conceptCohort(
  cdm = cdm, 
  conceptSet = codelist[c("glp1")],
  name = "glp1_codelist",
  exit = "event_start_date"
) 

# Creating SGLT2 cohort based on codelists
info(logger, "Instantiating sglt2 cohorts")
cdm$sglt2_codelist <- CohortConstructor::conceptCohort(
  cdm = cdm, 
  conceptSet = codelist[c("sglt2")],
  name = "sglt2_codelist",
  exit = "event_start_date"
) 

# Creating DPP4 cohort based on codelists
info(logger, "Instantiating dpp4 cohorts")
cdm$dpp4_codelist <- CohortConstructor::conceptCohort(
  cdm = cdm, 
  conceptSet = codelist[c("dpp4")],
  name = "dpp4_codelist",
  exit = "event_start_date"
) 
# Reading codelists
info(logger, "read codelists")
pathCodelists <- file.path(here::here(), "Codelists", "OutputFolder")
codelist <- omopgenerics::importCodelist(pathCodelists, type = "csv")


cdm <- omopgenerics::bind(
  cdm$glp1_codelist,
  cdm$sglt2_codelist,
  cdm$dpp4_codelist,
  name = "study_population"
)
