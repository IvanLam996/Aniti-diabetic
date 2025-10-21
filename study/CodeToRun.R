# renv ----
renv::restore()

# load required packages ----
library(omopgenerics)
library(CDMConnector)
library(CodelistGenerator)
library(IncidencePrevalence)
library(PatientProfiles)
library(CohortCharacteristics)
library(DrugUtilisation)
library(CohortConstructor)
library(OmopSketch)
library(dplyr)
library(stringr)
library(DBI)
library(log4r)
library(here)
library(RPostgres)
library(odbc)

# database details -----
db <- DBI::dbConnect("....")

# The name of your database to be used when reporting results
db_name <- "...."

# The name of the schema that contains the OMOP CDM with patient-level data
cdm_schema <- "...."

# The name of the schema where results tables will be created
write_schema <- "...."

# A prefix that will be used when creating any tables during the study execution
write_prefix <- "...."

cdm <- cdmFromCon(db, 
                  cdmName = db_name,
                  cdmSchema = cdm_schema, 
                  writeSchema = write_schema, 
                  writePrefix = write_prefix)

# set minimum cell count ----
min_cell_count <- 5

# run study -----
source("RunStudy.R")
