# for point prevalence analysis-----
info(logger, "Instantiating denominator cohort")

estimatePeriodPrevalence(cdm=cdm, denominatorTable = person, outcomeCohortId = glp1_codelist)

# to create the age groups
cdm <- generateTargetDenominatorCohortSet(
  cdm = cdm, 
  name = "denominator",
  targetCohortTable = "study_population"
)

drug_cohorts <- c("glp1", "sglt2", "dpp4")
all_prevalence_estimates <- list()

for (drug in drug_cohorts){
  
  prev_estimate <- estimatePeriodPrevalence(
    cdm=cdm, 
    denominatorTable= "denominator",
    outcomeTable = paste0(drug, "_codelist"),
    interval = "Years",
    # strata = list(c("ethnicity", "townsend"))
  )
  
  all_prevalence_estimates[[drug]] <- prev_estimate
}

final_prevalence_results <- bind(all_prevalence_estimates)

# to create a table
tablePrevalence(final_prevalence_results)

# to export the csv file
exportSummarisedResult(final_prevalence_results, fileName = "my_results.csv")

# to import the csv
importSummarisedResult(path = "my_results.csv")
