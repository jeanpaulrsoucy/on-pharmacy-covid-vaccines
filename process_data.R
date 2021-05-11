# Process current and historical COVID-19 pharmacy vaccine locations in Ontario

# load packages
library(rvest)
library(stringr)

# download data
source("download_data.R")

# create directory for processed files
dir.create("out", showWarnings = FALSE)

# list files
files <- list.files("data", full.names = TRUE)
files <- data.frame(
  file_name = files,
  file_date = as.Date(str_sub(files, -21, -12))
)

# if today's file is not in the archive, add the live webpage to the file list
date_today <- as.Date(Sys.Date())
if (date_today %in% files$file_date) {
 cat("Today's webpage is already in the archive. No need to add it to the file list.", fill = TRUE) 
} else {
  cat("Today's webpage is not yet in the archive. Adding the live webpage to the file list...", fill = TRUE)
  files <- rbind(files,
                 data.frame(
                   file_name = "https://covid-19.ontario.ca/vaccine-locations",
                   file_date = date_today
                 ))
}

# function to process data and write results
process_data <- function(file_name, file_date) {
  
  # load webpage and list pharmacy cards
  webpage <- read_html(file_name) %>%
    html_nodes(xpath = '//*[@class="ontario-assessment-centre-card__wrapper"]')
  
  # number of pharmacies
  n_pharms <- length(webpage)
  
  # create table
  pharms <- data.frame(
    name = character(n_pharms),
    address_street = character(n_pharms),
    address_city = character(n_pharms),
    address_province = character(n_pharms),
    address_postal_code = character(n_pharms),
    address_country = character(n_pharms),
    phu = character(n_pharms),
    vaccine_astrazeneca = integer(n_pharms),
    vaccine_pfizer = integer(n_pharms),
    vaccine_moderna = integer(n_pharms),
    vaccine_johnsonjohnson = integer(n_pharms)
  )
  
  # extract name, address and PHU from each each pharmacy card
  for (i in 1:length(webpage)) {
    
    ## extract data
    dat <- webpage[i] %>%
      html_elements("p")
    
    ## fill in table
    pharms[i, "name"] <- dat[1] %>% html_text
    pharms[i, "address_street"] <- dat[2] %>% html_text
    pharms[i, "address_city"] <- dat[3] %>% html_text %>% str_sub(0, -5)
    pharms[i, "address_province"] <- "Ontario"
    pharms[i, "address_postal_code"] <- dat[4] %>% html_text
    pharms[i, "address_country"] <- "Canada"
    
    ## fill PHU, if available
    if (file_date < as.Date("2021-04-23")) {
      # get PHU
      pharms[i, "phu"] <- dat[length(dat)] %>% html_text
    } else {
      # PHU was only provided prior to 2021-04-23
      pharms[i, "phu"] <- NA
    }
    
    ## fill vaccine type
    if (file_date < as.Date("2021-04-29")) {
      # assume all vaccines are AZ before this date
      pharms[i, "vaccine_astrazeneca"] <- 1
    } else {
      # Pfizer pilot began 2021-04-30, but pharmacies began being listed the day prior
      dat_vaccine <- webpage[i] %>%
        html_elements("div") %>% `[`(7) %>% html_text
      pharms[i, "vaccine_astrazeneca"] <- ifelse(
        grepl("AstraZeneca", dat_vaccine), 1, 0
      )
      pharms[i, "vaccine_pfizer"] <- ifelse(
        grepl("Pfizer", dat_vaccine), 1, 0
      )
      pharms[i, "vaccine_moderna"] <- ifelse(
        grepl("Moderna", dat_vaccine), 1, 0
      )
      # # Johnson & Johnson not offered yet
      # pharms[i, "vaccine_johnsonjohnson"] <- ifelse(
      #   grepl("Johnson & Johnson", dat_vaccine), 1, 0
      # )
    }
  }
  
  # write file
  write.csv(pharms, paste0("out/pharms_", file_date, ".csv"), row.names = FALSE)
  
  # print progress
  cat(as.character(file_date), fill = TRUE)
  
}

# # process only the most recent date of data
# process_data(files[nrow(files), "file_name"], files[nrow(files), "file_date"])

# process every date of data
invisible(apply(files, 1, function(x) process_data(x["file_name"], x["file_date"])))
