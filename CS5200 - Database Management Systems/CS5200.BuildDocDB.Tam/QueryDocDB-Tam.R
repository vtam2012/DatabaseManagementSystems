### Query Document Database
###
### Author: TAM, VINCENT
### Course: CS5200
### Term: FALL 2022

# assumes that you have set up the database structure by running CreateFStruct.R

# Query Parameters (normally done via a user interface)

quarter <- "Q2"
year <- "2021"
customer <- "Medix"

# write code below

# Function to get path to store the report in

genReportPath <- function(customer, year, quarter)
{
  return(file.path("docDB/reports", year, quarter, customer))
}

# Function to get the file name of the report in pdf format

genReportReportFileName <- function(customer, year, quarter)
{
  return(paste(customer, year, quarter, "pdf", sep = ".", collapse = NULL))
}

# Function to create a .lock file in the directory where the report will be stored
# returns 0 on success and -1 on failure

setLock <- function(customer, year, quarter)
{
  filePath <- paste(genReportPath(customer, year, quarter),".lock", sep = "/", collapse = NULL)
  if (file.exists(filePath)) {
    return(-1)
  } else {
    file.create(filePath)
    return(0)
  }
}

# Function to copy the report from the working directory to the correct directory
# returns 0 on success and -1 on failure

storeReport <- function(customer, year, quarter)
{
  lockFilePath <- paste(genReportPath(customer, year, quarter),".lock", sep = "/", collapse = NULL)
  filePath <- genReportPath(customer, year, quarter)
  if (file.exists(lockFilePath)) {
    file.copy(genReportReportFileName(customer, year, quarter), filePath)
    return(0)
  } else {
    return(-1)
  }
}

# Function to remove the .lock file from the directory where the report will be stored
# returns 0 on success and -1 on failure

relLock <- function(customer, year, quarter)
{
  lockFilePath <- paste(genReportPath(customer, year, quarter),".lock", sep = "/", collapse = NULL)
  if (file.exists(lockFilePath)) {
    file.remove(lockFilePath)
    return(0)
  } else {
    return(-1)
  }
}


# test that all functions work

# Test genReportPath 

if("docDB/reports/2021/Q2/Medix" == genReportPath(customer, year, quarter)){
  return(TRUE)
}

# Test genReportReportFileName

if("Medix.2021.Q2.pdf" == genReportReportFileName(customer, year, quarter)){
  return(TRUE)
}

# Test setLock

setLock(customer,year,quarter)
lockFilePath <- paste(genReportPath(customer, year, quarter),".lock", sep = "/", collapse = NULL)
if(file.exists((lockFilePath))){
  return(TRUE)
}

# Test storeReport
# Lock currently exists, so should be successful and return 0
storeReport(customer, year, quarter)

# Test relLock
relLock(customer, year, quarter)
lockFilePath <- paste(genReportPath(customer, year, quarter),".lock", sep = "/", collapse = NULL)
if(!file.exists((lockFilePath))){
  return(TRUE)
}

# Test storeReport again
# Lock does not exist, so should be unsuccessful and return -1

# first remove existing report
file.remove(paste(genReportPath(customer, year, quarter),genReportReportFileName(customer, year, quarter), sep = "/", collapse = NULL))
## try storing report (should be unsuccessful as lock file does not exist)
storeReport(customer, year, quarter)

