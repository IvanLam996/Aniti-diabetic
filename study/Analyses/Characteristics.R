# for characterisation analysis-----
info(logger, "Characterising cohorts")

starts <- seq(1, 146, by = 5)
ends <- starts + 4
ageGroup <- Map(c, starts, ends)
ageGroup[[1]][1] <- 0


# keep only those vaccinated during study period
cdm$study_population_characteristics <- cdm$study_population |>
  CohortConstructor::requireInDateRange(
    dateRange = c(study_period_start, study_period_end),
    name = "study_population_characteristics"
  )

# demographic info
results[["characteristics"]]  <- cdm$study_population_characteristics |>
  summariseCharacteristics(
    demographics = TRUE
  )

# stratified counts
results[["characteristics_counts"]] <- cdm$study_population_characteristics |>
  addSex() |> 
  addAge(
    ageGroup = ageGroup
  ) |>
  summariseCharacteristics(
    strata = list(c("sex", "age_group"), c("sex", "age"), "age_group", "age"),
    demographics = FALSE
  )
