library(tidyverse)
library(tidycensus)

options(tigris_use_cache = TRUE)

# Define ACS variable codes for family structure and demographics
vars <- c(
  total_pop              = "B01003_001",
  kids_under_18          = "B09001_001",
  median_age             = "B01002_001",
  median_income          = "B19013_001",
  white_nh               = "B03002_003",
  black_nh               = "B03002_004",
  asian_nh               = "B03002_006",
  hispanic               = "B03002_012",
  total_households       = "B11001_001",
  family_households      = "B11001_002",
  married_couple_fam     = "B11001_003",
  male_householder_fam   = "B11001_005",
  female_householder_fam = "B11001_006",
  nonfamily_households   = "B11001_007",
  married_with_kids      = "B11003_003",
  single_father_kids     = "B11003_010",
  single_mother_kids     = "B11003_016"
)

# 1. Download 20-year history (2005-2024, skipping 2020) for Sarasota County using 1-year ACS
years <- setdiff(2005:2024, 2020)

sarasota_history <- years |>
  map(\(yr) {
    get_acs(
      geography = "county",
      variables = vars,
      state = "FL",
      county = "Sarasota",
      year = yr,
      survey = "acs1",
      output = "wide"
    ) |>
      mutate(year = yr)
  }) |>
  list_rbind() |>
  select(year, GEOID, NAME, ends_with("E")) |>
  rename_with(\(x) str_remove(x, "E$"), .cols = -c(year, GEOID, NAME))

# 2. Download census-tract level data for Sarasota County (5-year ACS)
sarasota_tracts <- get_acs(
  geography = "tract",
  variables = vars,
  state = "FL",
  county = "Sarasota",
  year = 2022,
  survey = "acs5",
  output = "wide"
) |>
  select(GEOID, NAME, ends_with("E")) |>
  rename_with(\(x) str_remove(x, "E$"), .cols = -c(GEOID, NAME))

# 3. Download all Florida counties with map geometry (5-year ACS)
fl_counties <- get_acs(
  geography = "county",
  variables = vars,
  state = "FL",
  year = 2022,
  survey = "acs5",
  output = "wide",
  geometry = TRUE
) |>
  select(GEOID, NAME, ends_with("E")) |>
  rename_with(\(x) str_remove(x, "E$"), .cols = -c(GEOID, NAME, geometry))

# Save datasets to the data/ folder
dir.create("data", showWarnings = FALSE)
write_csv(sarasota_history, "data/sarasota_history.csv")
write_rds(sarasota_history, "data/sarasota_history.rds")
write_csv(sarasota_tracts, "data/sarasota_census.csv")
write_rds(sarasota_tracts, "data/sarasota_census.rds")
write_rds(fl_counties, "data/fl_counties.rds")
