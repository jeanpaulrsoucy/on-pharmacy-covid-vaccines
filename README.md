# COVID-19 pharmacy vaccine locations

The purpose of this repository is to assist in downloading and processing current and historical COVID-19 pharmacy vaccine location data in Ontario.

## Data sources

Current data are from Ontario's [COVID-19 pharmacy vaccine locations](https://covid-19.ontario.ca/vaccine-locations) webpage.

Archived data are from the [Archive of Canadian COVID-19 Data](https://github.com/ccodwg/Covid19CanadaArchive), which is maintained by the [COVID-19 Canada Open Data Working Group](https://opencovid.ca/).

## Running the script

Run `process_data.R`. This script will automatically create the directories to hold the raw data (`data`) and processed tables (`out`). Current and archived data will be downloaded automatically by calling `download_data.R`.
