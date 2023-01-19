# title: "Load DataWarehouse"
# name: "Vincent Tam"
# course: "CS5200"
# semester: "Fall 2022"
# December 4, 2022

# install required packages if not installed
if(!"RMariaDB" %in% (.packages())){require(RMariaDB)}
if(!"data.table" %in% (.packages())){require(data.table)}
if(!"DBI" %in% (.packages())){require(DBI)}

# Load RMariaDB library
library(RMariaDB)

# Load data.table library for fread function
library(data.table)

# Load DBI library for functions (dbConnect, dbListTables, dbWriteTable)
library(DBI)

# NOTE: MariaDB is run locally, must execute "mysql.server start" in command line terminal prior to executing dbConnect

# create connection variable to MariaDB.
dbcon <- dbConnect(drv = RMariaDB::MariaDB(), username = NULL, password = Sys.getenv("MYSQL_PASSWORD"),host = "localhost")

# Import RSQLite library
library(RSQLite)

# Import DBI library
library(DBI)
 
# specify dbfile to connect to
dbfile = "PubmedArticlesDB.db"

# create dbcon variable
dbconLite <- dbConnect(RSQLite::SQLite(), dbfile)

#Create a new schema
CreateSchema<-paste0("CREATE SCHEMA IF NOT EXISTS PracticumIISchema;")
dbExecute(dbcon,CreateSchema)

#Use that schema
UseSchema<-paste0("USE SCHEMA PracticumIISchema;")
dbExecute(dbcon,UseSchema)

# table author_facts has two dimension tables (AuthorNameDim, AuthorTimeDim)
# Using R functions to create AuthorNameDim table
AuthorNameDim <-paste0(
  "CREATE TABLE PracticumIISchema.AuthorNameDim(",
  "AuthorNameDim_key INT NOT NULL PRIMARY KEY,",
  "Forename TEXT,",
  "Lastname TEXT,",
  "Initials TEXT,",
  "Suffix TEXT",
  ");"
)
dbExecute(dbcon,AuthorNameDim)

# Query from SQLite Database
SelectFromAuthors <- paste0(
  "SELECT AuthorID AS AuthorNameDim_key, Forename, LastName, Initials, Suffix FROM Authors"
)
dbExecute(dbconLite,SelectFromAuthors)

# Populate AuthorNameDim table
InsertIntoAuthorNameDim <- paste0(
  "INSERT INTO PracticumIISchema.AuthorNameDim (AuthorNameDim_key, Forename, LastName, Initials, Suffix)", SelectFromAuthors 
)
dbExecute(dbcon,InsertIntoAuthorNameDim)

# table author_facts has two dimension tables (AuthorNameDim, AuthorTimeDim)
# Using R functions to create AuthorTimeDim table
AuthorTimeDim <-paste0(
  "CREATE TABLE PracticumIISchema.AuthorTimeDim(",
  "AuthorTimeDim_key INT NOT NULL PRIMARY KEY,",
  "NumArticlesWritten INT,",
  "YearWritten INT",
  ");"
)
dbExecute(dbcon,AuthorTimeDim)

# Get AuthorID from SQLite Database in order to perform necessary queries
SelectAuthorID <- paste0( "SELECT AuthorID FROM Authors")
dbExecute(dbconLite,SelectAuthorID)

# Query the number of Articles written by a specific author identified by AuthorID
SelectNumArticlesWritten <- paste0(
  "SELECT COUNT(*) FROM Articles INNER JOIN Article_Authors on Articles.ArticleID = Article_Authors.ArticleID 
  WHERE Article_Authors.AuthorID = ", SelectAuthorID
)
dbExecute(dbconLite,SelectNumArticlesWritten)

# Query the Year an article was written by a specific author identified by AuthorID
SelectYearWritten <- paste0(
  "SELECT YEAR(PubDate) FROM Journals INNER JOIN Articles on Journals.ArticleID = Articles.ArticleID INNER JOIN Article_Authors on Articles.ArticleID = Article_Authors.ArticleID 
  WHERE Article_Authors.AuthorID = ",SelectAuthorID
)
dbExecute(dbconLite,SelectYearWritten)

# Populate AuthorTimeDim table
InsertIntoAuthorTimeDim <- paste0(
  "INSERT INTO PracticumIISchema.AuthorTimeDim (AuthorTimeDim_key, NumArticlesWritten, YearWritten) ", 
  "VALUES (",
  SelectAuthorID,", ",
  SelectNumArticlesWritten,", ",
  SelectYearWritten,
  ");"
)
dbExecute(dbcon,InsertIntoAuthorTimeDim)

# Using R functions to create authors_facts table
author_facts <-paste0(
  "CREATE TABLE PracticumIISchema.author_facts (",
  "AuthorNameDim_key INT,",
  "AuthorTimeDim_key INT,",
  "CONSTRAINT PRIMARY KEY (AuthorNameDim_key, AuthorTimeDim_key)",
  ");"
)
dbExecute(dbcon,author_facts)

# table journal_facts has two dimension tables (JournalNameDim, JournalTimeDim)
# Using R functions to create JournalNameDim table
JournalNameDim <-paste0(
  "CREATE TABLE PracticumIISchema.JournalNameDim (",
  "JournalNameDim_key INT NOT NULL PRIMARY KEY,",
  "ISSN TEXT,",
  "Title TEXT,",
  ");"
)
dbExecute(dbcon,JournalNameDim)

# Query from SQLite Database 
SelectFromJournals <- paste0(
  "SELECT JournalID AS JournalNameDim_key, ISSN, Title FROM Journals"
)
dbExecute(dbconLite,SelectFromJournals)

# Populate JournalNameDim table
InsertIntoJournalNameDim <- paste0(
  "INSERT INTO PracticumIISchema.JournalNameDim (JournalNameDim_key, ISSN, Title) ", SelectFromJournals
)
dbExecute(dbcon,InsertIntoJournalNameDim)

# table journal_facts has two dimension tables (JournalNameDim, JournalTimeDim)
# Using R functions to create JournalTimeDim table
JournalTimeDim <-paste0(
  "CREATE TABLE PracticumIISchema.JournalTimeDim (",
  "JournalTimeDim_key INT NOT NULL PRIMARY KEY,",
  "NumofArticles INT,",
  "YearPublished INT,",
  "MonthPublished INT,",
  "QuarterPublished INT,",
  ");"
)
dbExecute(dbcon,JournalTimeDim)

# Get JournalID from SQLite Database in order to perform necessary queries
SelectJournalID <- paste0( "SELECT JournalID FROM Journals")
dbExecute(dbconLite,SelectJournalID)

# Query number of articles in  a specific journal was published identified by JournalID
SelectNumArticlesPublished <- paste0(
  "SELECT COUNT(*) FROM Journals INNER JOIN Articles ON Journals.ArticleID = Articles.Article ID WHERE JournalID = ", SelectJournalID
)
dbExecute(dbconLite,SelectNumArticlesPublished)

# Query the Year a specific journal was published identified by JournalID
SelectYearPublished <- paste0(
  "SELECT YEAR(PubDate) FROM Journals WHERE JournalID = ", SelectJournalID
)
dbExecute(dbconLite,SelectYearPublished)

# Query the Month a specific journal was published identified by JournalID
SelectMonthPublished <- paste0(
  "SELECT MONTH(PubDate) FROM Journals WHERE JournalID = ", SelectJournalID
)
dbExecute(dbconLite,SelectMonthPublished)

if(SelectMonthPublished < 4){
  QuarterPublished <- 1
}else if(SelectMonthPublished >= 4  & SelectMonthPublished < 7 ){
  QuarterPublished <- 2
}else if(SelectMonthPublished >= 7  & SelectMonthPublished < 10 ){
  QuarterPublished <- 3
}else if(SelectMonthPublished >= 10  & SelectMonthPublished < 13 ){
  QuarterPublished <- 4
}

# Populate JournalTimeDim table
InsertIntoJournalTimeDim <- paste0(
  "INSERT INTO PracticumIISchema.JournalTimeDim (JournalTimeDim_key, NumofArticles, YearPublished, MonthPublished, QuarterPublished) ", 
  "VALUES (",
  JournalTimeDim_key,", ",
  SelectNumArticlesPublished,", ",
  SelectYearPublished,", ",
  SelectMonthPublished,", ",
  QuarterPublished,
  ");"
)
dbExecute(dbcon,InsertIntoJournalTimeDim)

# Using R functions to create journal_facts table
journal_facts <-paste0(
  "CREATE TABLE PracticumIISchema.journal_facts (",
  "JournalNameDim_key INT,",
  "JournalTimeDim_key INT,",
  "CONSTRAINT PRIMARY KEY (JournalNameDim_key, JournalTimeDim_key)",
  ");"
)

dbExecute(dbcon,journal_facts)

#Disconnect From Databases
dbDisconnect(dbcon)
dbDisconnect(dbconLite)
