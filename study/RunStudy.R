# start log ----
resultsFolder <- here::here("Results")
log_file <- paste0(here::here(resultsFolder), "/log.txt")
logger <- create.logger()
logfile(logger) <- log_file
level(logger) <- "INFO"

if (!dir.exists(resultsFolder)) {
  dir.create(resultsFolder)
}

# CDM manipulations -----
info(logger, "Manipulating CDM object")
# drop anyone missing sex or year of birth
cdm$person <- cdm$person |>
  filter(
    !is.na(gender_concept_id),
    !is.na(year_of_birth)
  )

# Shared study parameters ----
info(logger, "Setting up study parameters")
study_period_start <- as.Date("2015-01-01")
study_period_end <- as.Date(NA)
denominator_age_groups <- c(18, Inf)
study_sex <- c("Both", "Male", "Female")
study_prior_observation <- c(365)

# Instantiate Cohorts ----
info(logger, "Starting to instantiate cohorts")
source(here::here("Cohorts", "CohortCreation.R"))

# Results object  ----
results <- list()

# Get cdm summary ----
info(logger, "Getting cdm summary")
results[["snapshot"]] <- summariseOmopSnapshot(cdm)
results[["obs_period"]] <- summariseObservationPeriod(cdm$observation_period)

# Get cohort summary ----
cohortIds <- omopgenerics::settings(cdm$study_population) |>
  dplyr::select("cohort_definition_id") |>
  dplyr::pull()

ids <- CDMConnector::cohortCount(cdm$study_population) |>
  dplyr::filter(.data$number_subjects == 0) |>
  dplyr::pull("cohort_definition_id")

for (i in seq_along(cohortIds)){
  if (i %in% ids) {
    cli::cli_warn(message = c("!" = paste0("cohort_definition_id ", i, " is empty. Skipping code use for this cohort.")))
    results[[paste0("index_event_", i)]] <- omopgenerics::emptySummarisedResult()
  } else {
    codes <- omopgenerics::cohortCodelist(cdm[["study_population"]], cohortIds[[i]])
    if (length(codes) > 0) {
      results[[paste0("index_event_", i)]] <- CodelistGenerator::summariseCohortCodeUse(
        x = codes,
        cdm = cdm,
        cohortTable = "study_population",
        cohortId = cohortIds[[i]],
        timing = "entry",
        countBy = c("record", "person"),
        byConcept = TRUE
      )
    }
  }
}

results[["cohort_count"]] <- summariseCohortCount(cohort = cdm$study_population)
results[["cohort_attrition"]] <- summariseCohortAttrition(cohort = cdm$study_population)

# Run characteristics analysis ----
info(logger, "Starting point prevalence analysis")
source(here::here("Analyses", "Characteristics.R"))

# Run point prevalence analysis ----
info(logger, "Starting point prevalence analysis")
source(here::here("Analyses", "PointPrevalence.R"))

# Export all the results ----
info(logger, "Exporting results")
results_export <- results |>
  vctrs::list_drop_empty() |>
  omopgenerics::bind() |>
  omopgenerics::newSummarisedResult()
exportSummarisedResult(results_export,
  minCellCount = min_cell_count,
  path = here::here("Results")
)
