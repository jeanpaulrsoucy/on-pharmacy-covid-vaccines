# Download current and historical COVID-19 pharmacy vaccine locations in Ontario

# load packages
library(aws.s3)
library(dplyr)
library(stringr)

# create directory for downloaded files
dir.create("data", showWarnings = FALSE)

# get list of files in archive and extract dates
cat("Getting file list...", fill = TRUE)
files <- get_bucket(bucket = "data.opencovid.ca",
                    prefix = "archive/on/vaccine-pharmacy-locations-webpage/",
                    region = "us-east-2")
files <- unlist(lapply(files, function(x) x[["Key"]]), use.names = FALSE)
files <- data.frame(
  file_key = files,
  file_date = as.Date(str_sub(files, -21, -12))
)

# in case there is more than 1 file for a single date, pick the last one
if (max(table(files$file_date)) > 1) {
  cat("More than one file per date. Trimming download file list...", fill = TRUE)
  files <- files %>%
    group_by(file_date) %>%
    slice_tail(n = 1) %>%
    ungroup
} else {
  cat("Only one file per date. No need to trim download file list.", fill = TRUE)
}

# if data directory exists, only download new files
if (dir.exists("data")) {
  files_existing <- list.files("data")
  files_existing <- as.Date(str_sub(files_existing, -21, -12))
  files <- files[!files$file_date %in% files_existing, ]
} else {
  dir.create("data")
}

# download files if there are any new ones, otherwise skip
if (nrow(files) > 0) {
  for (key in files$file_key) {
    save_object(key,
                file = paste("data", basename(key), sep = "/"),
                bucket = "data.opencovid.ca", region = "us-east-2")
    cat(key, fill = TRUE) # print progress
  }
  cat("New files have been downloaded.", fill = TRUE)
} else {
  cat("No new files to download.", fill = TRUE)
}