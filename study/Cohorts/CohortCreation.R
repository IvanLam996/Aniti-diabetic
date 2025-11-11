
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


# Optionally, if townsend_score is continuous, you might want to create quintiles for stratification
# dplyr::mutate(
#   townsend_quintile = dplyr::ntile(cdm$person$townsend, 5) # Creates 5 groups (quintiles)
# ) |>
#   # Stratify by ethnicity and Townsend score (using quintiles for this example)
#   dplyr::group_by(ethnicity_name, townsend_quintile) |>
#   dplyr::summarise(
#     number_of_persons = dplyr::n_distinct(person_id),
#     # Add any other summary statistics you need here
#     .groups = "drop" # Ensures the output is ungrouped
#   ) |>
#   dplyr::collect() # Use collect() to bring the results into R's memory if working with a database backend

codelist <- omopgenerics::importCodelist(codelistOutputFolder, type = "csv")

# Creating GLP1 cohort based on codelists
info(logger, "Instantiating GLP1 cohorts")
cdm$glp1_codelist <- CohortConstructor::conceptCohort(
  cdm = cdm, 
  conceptSet = codelist[c("glp1")],
  name = "glp1_codelist",
  exit = "event_start_date"
) |>
  exitAtObservationEnd()

# Creating SGLT2 cohort based on codelists
info(logger, "Instantiating sglt2 cohorts")
cdm$sglt2_codelist <- CohortConstructor::conceptCohort(
  cdm = cdm, 
  conceptSet = codelist[c("sglt2")],
  name = "sglt2_codelist",
  exit = "event_start_date"
) |>
  exitAtObservationEnd()

# Creating DPP4 cohort based on codelists
info(logger, "Instantiating dpp4 cohorts")
cdm$dpp4_codelist <- CohortConstructor::conceptCohort(
  cdm = cdm, 
  conceptSet = codelist[c("dpp4")],
  name = "dpp4_codelist",
  exit = "event_start_date"
) |>
  exitAtObservationEnd()

# Creating Diabetes cohort based on codelists
info(logger, "Instantiating diabetes cohorts")
cdm$dm_codelist <- CohortConstructor::conceptCohort(
  cdm = cdm, 
  conceptSet = codelist[c("dm")],
  name = "dm_codelist",
  exit = "event_start_date"
) |>
  exitAtObservationEnd()

# Reading codelists
info(logger, "read codelists")
pathCodelists <- file.path(here::here(), "Codelists", "OutputFolder")
codelist <- omopgenerics::importCodelist(pathCodelists, type = "csv")

cdm <- omopgenerics::bind(
  cdm$glp1_codelist,
  cdm$sglt2_codelist,
  cdm$dpp4_codelist,
  name = "study_population"
) |>
  unionCohorts()

diabetes_df <- read.csv("~/Aniti-diabetic/study/Codelists/OutputFolder/dm.csv")

# Convert to a named list for newCodelist()
diabetes_concepts <- list(
  "Diabetes" = as.numeric(diabetes_df$concept_id)
) |> newCodelist()

# --- Metformin Codelist ---
metformin_df <- read.csv("~/Aniti-diabetic/study/Codelists/OutputFolder/metformin.csv", sheet = "metformin")

# Convert to a named list for newCodelist()
metformin_concepts <- list(
  "Metformin" = as.numeric(metformin_df$concept_id)
) |> newCodelist()

# 1. Create a cohort for individuals with a diabetes diagnosis
cdm <- CohortConstructor::conceptCohort(
  cdm = cdm,
  conceptSet = diabetes_concepts,
  name = "diabetes_cohort",
  table = "condition_occurrence"
)

# 2. Create a cohort for individuals exposed to metformin
cdm <- generateDrugUtilisationCohortSet(
  cdm = cdm,
  conceptSet = metformin_concepts,
  name = "metformin_cohort",
  gapEra = 0, # Assuming you want to collapse continuous exposures
  # exitObservationPeriod = TRUE
)

# 3. Define the study population: diabetes patients with only metformin as first-line
cdm$study_population <- cdm$diabetes_cohort |>
  # Join with metformin exposures
  dplyr::left_join(
    cdm$metformin_cohort |> 
      dplyr::select(subject_id, cohort_start_date, cohort_end_date) |>
      dplyr::rename(metformin_start_date = cohort_start_date, metformin_end_date = cohort_end_date),
    by = "subject_id"
  ) |>
  # Filter for metformin exposure after diabetes diagnosis
  dplyr::filter(
    metformin_start_date >= cohort_start_date
  ) |>
  # Keep only the first metformin exposure after diabetes diagnosis
  dplyr::group_by(subject_id) |>
  dplyr::arrange(subject_id, metformin_start_date) |>
  dplyr::slice_head(n = 1) |>
  dplyr::ungroup() |>
  # # Exclude individuals with any other anti-diabetic drug exposure before or at the same time as metformin
  # # This requires defining concept sets for other anti-diabetic drugs and creating a temporary cohort for them
  # # For demonstration, let's assume glp1_codelist, sglt2_codelist, dpp4_codelist represent other anti-diabetic drugs
  # # You would need to create a combined codelist of all other anti-diabetic drugs
  # dplyr::anti_join(
  #   cdm$drug_exposure |>
  #     dplyr::filter(drug_concept_id %in% c(cdm$glp1_codelist, cdm$sglt2_codelist, cdm$dpp4_codelist)) |>
  #     dplyr::select(person_id, drug_exposure_start_date) |>
  #     dplyr::rename(subject_id = person_id, other_drug_start_date = drug_exposure_start_date),
  #   by = "subject_id",
  #   # Joining criteria to exclude if other drugs were taken before or at the same time as the first metformin
  #   # Adjust time window as per your definition of "first-line"
  #   relationship = c("other_drug_start_date <= metformin_start_date")
  # ) |>
  # Select desired columns and rename for consistency
  dplyr::transmute(
    cohort_definition_id = 1, # Assign a single cohort ID for this study population
    subject_id = subject_id,
    cohort_start_date = cohort_start_date, # Diabetes diagnosis date as cohort start
    cohort_end_date = metformin_end_date # End of first metformin exposure as cohort end
  ) |>
  newCohortTable(
    cohortSet = tibble(cohort_definition_id = 1, cohort_name = "study_population")
  )
