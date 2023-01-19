# title: "Load XML to Database"
# name: "Vincent Tam"
# course: "CS5200"
# semester: "Fall 2022"
# December 4, 2022

# Import RSQLite library
library(RSQLite)

# Import DBI library
library(DBI)

# specify dbfile to connect to
dbfile = "PubmedArticlesDB.db"

# create dbcon variable
dbcon <- dbConnect(RSQLite::SQLite(), dbfile)

# Using R functions to create Articles table
Articles <-paste0(
  "CREATE TABLE Articles (",
  "ArticleID INT PRIMARY KEY NOT NULL,",
  "Language TEXT NOT NULL,",
  "ArticleTitle TEXT NOT NULL,",
  "ArticleType TEXT NOT NULL",
  ");"
)
dbExecute(dbcon,Articles)

# Using R functions to create Journals table
Journals <-paste0(
  "CREATE TABLE Journals (",
  "JournalID INT PRIMARY KEY,",
  "ISSN TEXT NOT NULL,",
  "CitedMedium CHECK(CitedMedium IN ('Print','Internet')),",
  "Volume TEXT NOT NULL,",
  "Issue TEXT NOT NULL,",
  "PubDate DATE,",
  "Title TEXT NOT NULL,",
  "ISOAbbreviation TEXT NOT NULL,",
  "ArticleID INT NOT NULL,",
  "FOREIGN KEY (ArticleID) REFERENCES Article (ArticleID)",
  ");"
) 
dbExecute(dbcon,Journals)

# Using R functions to create Authors table
# AuthorID is synthetic surrogate key, increments automatically for each insert.
Authors <-paste0(
  "CREATE TABLE Authors (",
  "AuthorID INT IDENTITY(1,1) PRIMARY KEY,",
  "LastName TEXT,",
  "ForeName TEXT,",
  "Initials TEXT,",
  "Suffix TEXT",
  ");"
)
dbExecute(dbcon,Authors)

# Using R functions to create Article_Authors table to match Articles to Authors.
Article_Authors <-paste0(
  "CREATE TABLE Article_Authors (",
  "ArticleID INT NOT NULL,",
  "AuthorID INT NOT NULL,",
  "FOREIGN KEY (ArticleID) REFERENCES Article (ArticleID),",
  "FOREIGN KEY (AuthorID) REFERENCES Author (AuthorID)",
  ")"
)
dbExecute(dbcon,Article_Authors)


# load XML library
library(XML)

# Create xmlFile variable
xmlFile <- "./pubmed-tfm-xml/pubmed22n0001-tf.xml"

# Create validated DOM from XML File 
xmlDoc <- xmlParse(xmlFile, validate = T)

# Create root variable 
PubmedArticleSet<-xmlRoot(xmlDoc)

#Get number of PubmedArticles in tthe Article set.
numPubmedArticles <- xmlSize(PubmedArticleSet)

# Since we know that there is one Article for all entries, we can create a dataframe first before writing into SQL
Articles.df <- data.frame(ArticleID = vector(mode = "integer", length = numPubmedArticles),
                          Language = vector(mode = "character", length = numPubmedArticles),
                          ArticleTitle = vector(mode = "character", length = numPubmedArticles),
                          ArticleType = vector(mode = "character", length = numPubmedArticles),
                          stringsAsFactors = F)

# Similarly we know that there is one Journal entry for each Article when looking at the XML file.
# Therefore the number of Journals is equal to the number of Articles, then we can create a pre-allocated data frame too.
Journals.df <- data.frame(JournalID = vector(mode = "integer", length = numPubmedArticles),
                          ISSN = vector(mode = "character", length = numPubmedArticles),
                          CitedMedium  = vector(mode = "character", length = numPubmedArticles),
                          Volume = vector(mode = "character", length = numPubmedArticles),
                          Issue = vector(mode = "character", length = numPubmedArticles),
                          PubDate = structure(rep(NA_real_, numPubmedArticles), class="Date"),
                          Title = vector(mode = "character", length = numPubmedArticles),
                          ISOAbbreviation = vector(mode = "character", length = numPubmedArticles),
                          ArticleID = vector(mode = "integer", length = numPubmedArticles),
                          stringsAsFactors = F)

# Iterate through each PubmedArticle
for(i in 1:numPubmedArticles){
  
  #a PubmedArticle Node
  aPubmedArticle<-PubmedArticleSet[[i]]
  
  # use PubmedArticle attribute for ArticleID, in XML <PubmedArticle PMID="1">
  PubmedArticleAttrs <- xmlAttrs(aPubmedArticle)
  ArticleID <- PubmedArticleAttrs[1]
  
  Language <- xmlValue(aPubmedArticle[[1]][[2]])
  ArticleTitle <- xmlValue(aPubmedArticle[[1]][[3]])
  Type <- xmlName(aPubmedArticle[[1]][[1]])
  
  # Populate Article Dataframe rows with correct values for each iteration
  Articles.df$ArticleID[i] <- ArticleID
  Articles.df$Language[i] <- Language
  Articles.df$ArticleTitle[i] <- ArticleTitle
  Articles.df$ArticleType[i] <- Type
  
  # Parse XML to get column information for the Journals
  ISSN <- xmlValue(aPubmedArticle[[1]][[1]][[1]])
  JournalAttrs <- xmlAttrs(aPubmedArticle[[1]][[1]][[1]])
  CitedMedium <- JournalAttrs[1]
  Volume <- xmlValue(aPubmedArticle[[1]][[1]][[2]][[1]])
  Issue <- xmlValue(aPubmedArticle[[1]][[1]][[2]][[2]])
  
  # Adjust the values for the PubDate as necessary.
  # We will combine Year, Month, and Day values to get a final PubDate Date object
  
  # if Year tag does not exist, set Year to "0000"
  if(is.null(aPubmedArticle[[1]][[1]][[2]][[3]][[1]])){
    PubYear <- "0000"
  }
  # else if the tag under PubDate is "MedlineDate", split the string to get the year.
  # For example <MedlineDate>1975 Nov-Dec</MedlineDate>, we just want PubYear = 1975
  else if(xmlName(aPubmedArticle[[1]][[1]][[2]][[3]][[1]]) %in% "MedlineDate"){
    MedlineDate <- strsplit(xmlValue(aPubmedArticle[[1]][[1]][[2]][[3]][[1]]), split = " ")
    PubYear <- MedlineDate[[1]][1]
  }
  # Otherwise just get the value under the Year tag
  else{
    PubYear <- xpathSApply(xmlDoc,paste0("(//PubmedArticleSet/PubmedArticle/Article/Journal/JournalIssue/PubDate/Year)","[", i, "]"), xmlValue)
  }

  # If Month tag doesn't exist, we assume that it was published at the beginning of the year "Jan"
  if(is.null(aPubmedArticle[[1]][[1]][[2]][[3]][[2]])){
     PubMonth <- "Jan"
  }
  # Again if the tag under PubDate is "MedlineDate", split the string to get the Month.
  # For example <MedlineDate>1975 Nov-Dec</MedlineDate>, we just want PubMonth = "Nov"
  # Use the first month that appears in the string.
  else if(xmlName(aPubmedArticle[[1]][[1]][[2]][[3]][[1]]) %in% "MedlineDate"){
    MedlineMonth <- strsplit(MedlineDate[[1]][2], split = "-")
    PubMonth <- MedlineMonth[[1]][1]
  }
  # Otherwise just get value from the Month tag
  else{
    PubMonth <- xpathSApply(xmlDoc,paste0("(//PubmedArticleSet/PubmedArticle/Article/Journal/JournalIssue/PubDate/Month)","[", i, "]"), xmlValue)
  }
  # Convert PubMonth from string to corresponding integer.
  if(!is.null(PubMonth)){
    if(PubMonth %in% "Jan"){
      PubMonth <- 1
    }
    if(PubMonth %in% "Feb"){
      PubMonth <- 2
    }
    if(PubMonth %in% "Mar"){
      PubMonth <- 3
    }
    if(PubMonth %in% "Apr"){
      PubMonth <- 4
    }
    if(PubMonth %in% "May"){
      PubMonth <- 5
    }
    if(PubMonth %in% "Jun"){
      PubMonth <- 6
    }
    if(PubMonth %in% "Jul"){
      PubMonth <- 7
    }
    if(PubMonth %in% "Aug"){
      PubMonth <- 8
    }
    if(PubMonth %in% "Sep"){
      PubMonth <- 9
    }
    if(PubMonth %in% "Oct"){
      PubMonth <- 10
    }
    if(PubMonth %in% "Nov"){
      PubMonth <- 11
    }
    if(PubMonth %in% "Dec"){
      PubMonth <- 12
    }
  }
  # If no Day is specified, assume that it is the first of the month
  if(is.null(aPubmedArticle[[1]][[1]][[2]][[3]][[3]])){
    PubDay <- "1"
  }
  # Otherwise get the value from the Day tag.
  else{
    PubDay <- xpathSApply(xmlDoc,paste0("(//PubmedArticleSet/PubmedArticle/Article/Journal/JournalIssue/PubDate/Day)","[", i, "]"), xmlValue)
  }
  # Combine Year, Month, and Day into date object and store as PubDate
  PubDate <- as.Date(paste0(PubYear,"-",PubMonth,"-",PubDay), format="%Y-%m-%d")
  JournalTitle <- xmlValue(aPubmedArticle[[1]][[1]][[3]])
  ISOAbbreviation <- xmlValue(aPubmedArticle[[1]][[1]][[4]])
  
  # Populate Journals Data Frame with correct values.
  Journals.df$JournalID[i] <- i
  Journals.df$ISSN[i] <- ISSN
  Journals.df$CitedMedium[i] <- CitedMedium 
  Journals.df$Volume[i] <- Volume
  Journals.df$Issue[i] <- Issue
  Journals.df$PubDate[i] <- PubDate
  Journals.df$Title[i] <- JournalTitle
  Journals.df$ISOAbbreviation[i] <- ISOAbbreviation
  Journals.df$ArticleID[i] <- ArticleID

  # Steps to get Author
  # Check if Collective Name exists, if it does, put it as the ForeName
  if(!is.null(aPubmedArticle[[1]][[4]][[i]][[1]])){
    if(!(xmlName(aPubmedArticle[[1]][[4]][[i]][[1]]) %in% "LastName")){
      CollectiveName <- xmlValue(aPubmedArticle[[1]][[4]][[i]][[1]])
    }
  }
  for(j in 1: xmlSize(aPubmedArticle[[1]][[4]])){
    AuthorLastName <- xpathSApply(xmlDoc,paste0("(//PubmedArticleSet/PubmedArticle/Article/AuthorList/Author/LastName)","[", j, "]"), xmlValue)
    if(is.null(CollectiveName)){
      AuthorForeName <- xpathSApply(xmlDoc,paste0("(//PubmedArticleSet/PubmedArticle/Article/AuthorList/Author/ForeName)","[", j, "]"), xmlValue)
    }
    else{
      AuthorForeName <- CollectiveName
    }
    AuthorInitials <- xpathSApply(xmlDoc,paste0("(//PubmedArticleSet/PubmedArticle/Article/AuthorList/Author/Initials)","[", j, "]"), xmlValue)
    if(is.null(aPubmedArticle[[1]][[4]][[j]][[4]])){
      AuthorSuffix <- ""
    }
    else{
      AuthorSuffix <- xpathSApply(xmlDoc,paste0("(//PubmedArticleSet/PubmedArticle/Article/AuthorList/Author/Suffix)","[", j, "]"), xmlValue)
    }
  }
  # Use an insert statement and insert each author entry into the SQL table manually
  InsertAuthor <-paste0(
    "INSERT INTO Authors (LastName, ForeName, Initials, Suffix) ",
    "VALUES (",'"',
    AuthorLastName,'", "',
    AuthorForeName,'", "',
    AuthorInitials,'", "',
    AuthorSuffix,'"',
    ');'
  )
  dbExecute(dbcon, InsertAuthor)
  
  # Similary manually insert into Article_Authors table which has ArticleID and AuthorID = j found earlier.
  InsertArticleAuthors <-paste0(
    "INSERT INTO Article_Authors (ArticleID, AuthorID) ",
    "VALUES (",'"',
    ArticleID,'", "',
    j,'"',
    ');'
  )
  dbExecute(dbcon, InsertArticleAuthors)
}

# Write Article and Journal Data Frames into SQL
dbWriteTable(dbcon, "Articles", Articles.df, overwrite = T)
dbWriteTable(dbcon, "Journals", Journals.df, overwrite = T)

# For Verification Select all from Tables
SelectArticles <-paste0(
  "SELECT * FROM ARTICLES;"
)
dbExecute(dbcon,SelectArticles)

SelectJournals <-paste0(
  "SELECT * FROM Journals;"
)
dbExecute(dbcon,SelectJournals)

SelectAuthors <-paste0(
  "SELECT * FROM Authors;"
)
dbExecute(dbcon,SelectAuthors)

SelectArticleAuthors <-paste0(
  "SELECT * FROM Article_Authors;"
)
dbExecute(dbcon,SelectArticleAuthors)

#Disconnect From Database
dbDisconnect(dbcon)
