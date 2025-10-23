# 1. Install the environment --------------------
#install.packages("renv") # if not already installed, install renv from CRAN

# this should prompt you to install the various packages required for the study
renv::activate()
renv::restore() # if asked to install or update any package, answer "y" in the console

library(CDMConnector)
library(DBI)
library(readxl)
library(omopgenerics)
library(janitor)
library(here)
library(dplyr)
library(purrr)
library(RPostgres)

db <- DBI::dbConnect(drv = Postgres(),
                     dbname = "cdm_gold_202501",
                     host = "163.1.65.51",
                     port = "5432",
                     user = "ilam",
                     password = "SpringnOxford2025!")

cdm <- CDMConnector::cdmFromCon(
  con = db,
  cdmSchema = "public_100k",
  writeSchema = "results",
  writePrefix = "anti_diabetic"
)

codelistOutputFolder <- here::here("OutputFolder")

if (!dir.exists(codelistOutputFolder)) {
  dir.create(codelistOutputFolder)
}

file_path <- here("input", "codelist_anti_diabetic.xlsx")
sheet_names <- excel_sheets(file_path)
codelist <- map_dfr(sheet_names, ~
                      read_excel(file_path, sheet = .x) |>
                      clean_names() |>
                      mutate(outcome_name = .x)
)

codelist <- codelist |>
  dplyr::group_by(.data$outcome_name) |>
  dplyr::group_split()
names(codelist) <- codelist |>
  purrr::map_chr(\(x) unique(x$outcome_name))
codelist <- codelist |>
  purrr::map(\(x) {
    CodelistGenerator::getDescendants(cdm = cdm, conceptId = x$concept_id) |>
      dplyr::pull("concept_id")
  }) |>
  omopgenerics::newCodelist()

names(codelist) <- tolower(names(codelist))

codelist |> omopgenerics::exportCodelist(codelistOutputFolder, type = "csv")
