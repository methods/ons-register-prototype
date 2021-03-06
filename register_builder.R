
source("fluff.R")
source("register_index_page_builder.R")

buildHomepage <- function(path, registers) {
  copyAssets("templates/files",".")
  registerValues <- paste("<dd><a href=\"",registers,"\">",registers,"<span class=\"visuallyhidden\"></a></dd>")
  registerLinks <- paste(registerValues, collapse = "")
  lines <- fluff("templates/homepage.htm", c("RegisterLinks"), c(registerLinks))
  write(lines, path)
}

buildRegister <- function(data, registerName, registerPath, detailFields, assetPath = "templates/files", idField = "id", linkFields = F) {
  copyAssets(assetPath, registerPath)
  buildRootRecord(data, registerName, registerPath)
  buildRecordsIndexPages(data, registerName, registerPath, detailFields, idField, linkFields)
  buildSingleRecordsPages(data, registerName, registerPath, idField, linkFields)
}

# Create the root register page
# Example: https://country.register.gov.uk/
buildRootRecord <- function(data, registerName, registerPath) {
  fieldList <- paste(colnames(data), collapse=", ")
  lines <- fluff("templates/template.htm", 
                 c("RegisterTitle", "RegisterLink", "RecordCount", "FieldList"),
                 c(registerName, "", nrow(data), fieldList))
  json <- paste("{\"title\":\"", registerName, "\", \"register\":\"", registerPath, 
                "\", \"records\":", nrow(data),"}", sep="")
  write(x = lines, file = paste(registerPath,"index.htm",sep="/"))
  write(x = json, file = paste(registerPath,"data.json",sep="/"))
}

# Create the details page for individual register items
# Example: https://country.register.gov.uk/record/VA
buildSingleRecordsPages <- function(data, registerName, registerPath,  idField, linkFields) {
  ids <- data[, idField]
  
  dir.create(paste(registerPath, "record", sep="/"))
  for(id in ids) {
    item <- data[data[,idField] == id, ]
    
    dir.create(paste(registerPath, "record", id, sep="/"))
    
    json <- toJSON(item)
    write(json, paste(registerPath, "record", id,"data.json", sep="/"))
    
    html <- fluffSingleRecordsPage(item, registerName, 1, idField, linkFields)
    write(html, paste(registerPath, "record", id,"index.html", sep="/"))
  }
}

valueLink <- function(fieldName, fieldValue, linkToRoot) {
  elements <- strsplit(fieldName, ".", fixed = T)[[1]]
  if(length(elements) == 1) {
    return("")
  } else {
    return(paste(linkToRoot,elements[1],"record",fieldValue, sep = "/"))
  }
}

fluffSingleRecordsPage <- function(data, registerName, row, idField, linkFields) {
  rowData = c()
  cols <- colnames(data)
  for(i in 1:ncol(data)) {
    
    fieldname <- cols[i]
    fieldvalue <- data[row, i]
    
    if(linkFields) {
      link <- paste("../../../fields/record/",cols[i], sep="")
    } else {
      link <- "#"
    }
    
    vLink <- valueLink(fieldname, fieldvalue, "../../..")
    if(vLink == "") {
      newRows <- fluff(url = "templates/record/id/tablecell.htm", 
                     replaceFields = c("FieldName", "FieldValue", "FieldLink"), 
                     withValues = c(cols[i], data[row, i], link))
      rowData <- c(rowData,newRows)
    } else {
      newRows <- fluff(url = "templates/record/id/linkedtablecell.htm", 
                       replaceFields = c("FieldName", "FieldValue", "FieldLink", "ValueLink"), 
                       withValues = c(cols[i], data[row, i], link, vLink))
      rowData <- c(rowData,newRows)
    }
    
  }
  rowData <- paste(rowData, collapse = " ")
  fullData <- fluff(url = "templates/record/id/template.htm", 
               replaceFields = c("RegisterTitle", "RegisterLink", "ItemId", "RowData"),
               withValues = c(registerName, "", data[row, idField], rowData))
  return(fullData)
}

readRegisterFile <- function(path) {
  df <- read.csv(path, stringsAsFactors = F)
  df[,"start-date"] <- ""
  df[, "end-date"] <- ""
  df
}

