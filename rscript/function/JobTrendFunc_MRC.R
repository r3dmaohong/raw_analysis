###MapReduce like concept : Job Trend Function

#��@�ؼ����
#�̲׿z�����
#��lDF : total.data

#OutputData
#OrigiData
#targerCol

#OrigiData=total.data
#targerCol="¾�Ȥp���W��"
#GroupByCol = "area.work"
#----GroupByCol = c("date", "area.work")
#filename="AreaJobDemand"
#fixed: date

library(tidyr) #separate_rows()
library(stringr) #str_split_fixed()

## Export Historical changes of data
##----------------------------------
JobTrend_unitHistory <- function(OrigiData, targetCol, GroupByCol){
  gc()
  parseTargetCol  <- parse(text=targetCol)
  #parseGroupByCol <- parse(text=paste0("by = .(", paste0(GroupByCol, collapse=", "), ")"))
  
  ##The col of jobs changes it's format to using comma pasting multiple jobs...
  if(grepl(",", OrigiData[,eval(parseTargetCol)]) %>% any){
    cat("Separating rows...\n")
    OutputData <- separate_rows(OrigiData, eval(parseTargetCol), sep = ",") %>% unique
  }else{
    OutputData <- OrigiData
  }
  gc()
  
  setDT(OutputData)
  if(length(names(OutputData)[grepl("�s��", names(OutputData))])==1){
    OutputData <- OutputData[, c(names(OutputData)[grepl("�s��", names(OutputData))], "date", GroupByCol, targetCol), with=FALSE] %>% unique
  }else{
    names(OutputData)
    uniColN <- readline(prompt="Enter the index of col name which should be used as unique index: ")
    OutputData <- OutputData[, c(names(OutputData)[as.numeric(uniColN)], "date", GroupByCol, targetCol), with=FALSE] %>% unique
  } 
  gc()
  OutputData <- OutputData[ eval(parseTargetCol)!="�uŪ��", .N, by= c("date", GroupByCol, targetCol)]
  OutputData <- OutputData[eval(parse(text=paste0("order(", paste("date", GroupByCol, "-N", sep=", "), ")")))]
  #OutputData[, percentage:=N/sum(N), by=c("date", GroupByCol)]
  cat(GroupByCol, " : ", unique(OutputData[,eval(parse(text=GroupByCol))]))

  ## Fill all missing value...
  
  
  return(OutputData) 

}
##----------------------------------
## End

## Fill missing value in Historical changes of data
##--------------------------------------------------
FillMissingJobRow <- function(datHistory, targetCol, GroupByCol){
  
  ## 1. Generate total index
  ## 2. check out what index is missing
  ## 3. Fill the missing index
  totalIndex <- eval(
    parse(text = 
            paste0(
              "apply(expand.grid(unique(datHistory$date), 
                                  unique(datHistory$", GroupByCol, "), 
                                  unique(datHistory$", targetCol, ")), 
                      1, 
                      paste, collapse='_')"
            )
            )
  )
  partcialIndex <- eval(
    parse(text = 
            paste0(
              "paste(datHistory$date,
                         datHistory$", GroupByCol, ",
                         datHistory$", targetCol, ",
                         sep = '_')"
            )
    )
  )
    
  tmp <- rbind(datHistory,
               data.frame(str_split_fixed(totalIndex[!(totalIndex %in% partcialIndex)], "_", 3), stringsAsFactors = FALSE) %>%
                 `colnames<-`(names(datHistory)[1:3]) %>% cbind(data.frame("N" = 0))
  )
  
  eval(parse(
    text = 
      paste0(
        "tmp %>% arrange(", paste0(names(datHistory)[1:2], collapse = ", "), ")"
      )
  ))
}
##--------------------------------------------------
## End


JobTrend_standard <- function(datHistory, targetCol, GroupByCol, filename, top_N=25){
  stopifnot(class(datHistory$date)=="numeric")
  
  ## Reorder and get standard
  datHistory          <- datHistory[order(datHistory$date),]
  standard.datHistory <- datHistory[date==datHistory$date[1]]
  
  ##Historical changes...
  datHistory$Freq <- sapply(1:nrow(datHistory), function(x){
    if(standard.datHistory$N[which(standard.datHistory[,eval(parse(text=targetCol))]==datHistory[,eval(parse(text=targetCol))][x] & standard.datHistory[,eval(parse(text=GroupByCol))]==datHistory[,eval(parse(text=GroupByCol))][x])] %>% toString != ""){
      return(datHistory$N[x] - standard.datHistory$N[which(standard.datHistory[,eval(parse(text=targetCol))]==datHistory[,eval(parse(text=targetCol))][x] & standard.datHistory[,eval(parse(text=GroupByCol))]==datHistory[,eval(parse(text=GroupByCol))][x])])
    }
    return(datHistory$N[x])
  })
  
  ## Create index
  datHistory[,index:=paste(eval(parse(text=GroupByCol)), eval(parse(text=targetCol)), sep="_")]
  
  ## Encode problem
  #datHistory[, names(datHistory) := lapply(.SD, function(x) {if (is.character(x)) Encoding(x) <- "unknown"; x})]
  for(i in 1:ncol(datHistory)){
    if(sum(is.na(datHistory[[i]] %>% iconv("UTF-8")))<(nrow(datHistory)/2)){
      #print(i)
      datHistory[[i]] <- datHistory[[i]] %>% iconv("UTF-8")
    }
  }
  
  #datHistory <- datHistory[, eval(parse(text=paste0(".(date, ", GroupByCol, ", ",  targetCol, ", Freq, index)")))]
  
  ##Add missing standard
  for(dateIndex in unique(datHistory$date)[1:(length(unique(datHistory$date))-1)]){
    
    missingStandard    <- datHistory$index[which(datHistory$date==tail(unique(datHistory$date), 1))][!(datHistory$index[which(datHistory$date==tail(unique(datHistory$date), 1))] %in% 
                                                                                                                        datHistory$index[which(datHistory$date==dateIndex)])]
    if(missingStandard %>% toString != ""){
      missingStandardSpt <- missingStandard %>% strsplit("_")
      missingArea        <- sapply(1:length(missingStandard), function(x) missingStandardSpt[[x]][1])
      missingJob         <- sapply(1:length(missingStandard %>% strsplit("_")), function(x) missingStandardSpt[[x]][2])
      
      datHistory <- rbind(datHistory, eval(parse(text=paste0("data.table(date=dateIndex, ", GroupByCol, "=missingArea, ", targetCol, "=missingJob, Freq=0, index=missingStandard)"))))
      #datHistory$index[which(datHistory$date==dateIndex)]
      #datHistory$index[which(datHistory$date==tail(unique(datHistory$date), 1))]
    }
  }
  datHistory <- datHistory[eval(parse(text=paste0("order(", paste(paste("date", GroupByCol, sep=", "), "index", sep=", "), ")")))]
  #datHistory <- datHistory[, eval(parse(text=paste0(".(date, ", GroupByCol, ", ",  targetCol, ", Freq)")))]
  
  
  datHistory <- datHistory[eval(parse(text=paste0(GroupByCol,"!='' & ", targetCol,"!=''"))),]
  datHistory[, names(datHistory) := lapply(.SD, function(x) {if (is.character(x)) Encoding(x) <- "unknown"; x})]
  for(i in 1:ncol(datHistory)){
    datHistory[[i]] <- ifelse(is.na(iconv(datHistory[[i]], "UTF-8")), datHistory[[i]], iconv(datHistory[[i]], "UTF-8"))
  }
  
  datHistory <- datHistory[eval(parse(text=paste0("order(", paste(paste("date", GroupByCol, sep=", "), "index", sep=", "), ")")))]
  latestDat <- datHistory[date==max(date)]
  datHistory <- datHistory[, eval(parse(text=paste0(".(date, ", GroupByCol, ", ",  targetCol, ", Freq)")))]
  
  latestDat <- latestDat[eval(parse(text=paste0("order(", paste(paste("date", GroupByCol, sep=", "), "-percentage", sep=", "), ")")))]
  ##Set ranking
  latestDat$rank <-  0
  countdown <- 0
  for(i in 1:nrow(latestDat)){
    if(i==1){
      latestDat$rank[i] <- 1
    }else{
      if(latestDat[,eval(parse(text=GroupByCol))][i]==latestDat[,eval(parse(text=GroupByCol))][i-1]){
        if(latestDat$percentage [i]==latestDat$percentage [i-1]){
          latestDat$rank[i] <- latestDat$rank[i-1]
          countdown <- countdown + 1
        }else{
          latestDat$rank[i] <- latestDat$rank[i-1] + 1 + countdown
          countdown <- 0
        }      
      }else{
        latestDat$rank[i] <- 1
        countdown <- 0
      }
    } 
  }
  latestDat <- latestDat[, eval(parse(text=paste0(".(rank, ", GroupByCol, ", ",  targetCol, ", percentage)")))]
  latestDat <- latestDat[, head(.SD, top_N), by=c(GroupByCol)]
  
  
  write.csv(latestDat, paste0("output\\per.month\\", format(Sys.time(), "%Y%m%d_"), filename, ".csv"), row.names=F)
  write.csv(datHistory, paste0("output\\per.month\\", format(Sys.time(), "%Y%m%d_"), filename, "_History.csv"), row.names=F)
  gc()
  cat("\nCompleted.")
}

#test
datHistory[datHistory$¾�Ȥp���W��=="�Įv�U�z",]

  
  
  totalOutputData[,index:=paste(eval(parse(text=GroupByCol)), eval(parse(text=targetCol)), sep="_")]
  OutputData <- OutputData[date==max(date)]
  ##Rank, Area, Job, Percentage, Freq
  ##Keep the latest data
  OutputDemandJob <- OutputData[, eval(parse(text=paste0(".(rank, ", GroupByCol, ", ",  targetCol, ", percentage)")))]
  
  OutputData[, names(OutputData) := lapply(.SD, function(x) {if (is.character(x)) Encoding(x) <- "unknown"; x})]
  for(i in 1:ncol(OutputData)){
    if(sum(is.na(OutputData[[i]] %>% iconv("UTF-8")))<(nrow(OutputData)/2)){
      #print(i)
      OutputData[[i]] <- OutputData[[i]] %>% iconv("UTF-8")
    }
  }
  totalOutputData[, names(totalOutputData) := lapply(.SD, function(x) {if (is.character(x)) Encoding(x) <- "unknown"; x})]
  for(i in 1:ncol(totalOutputData)){
    if(sum(is.na(totalOutputData[[i]] %>% iconv("UTF-8")))<(nrow(totalOutputData)/2)){
      #print(i)
      totalOutputData[[i]] <- totalOutputData[[i]] %>% iconv("UTF-8")
    }
  }
  totalOutputData <- totalOutputData[index %in% OutputData$index, ]
  
  ##Check
  #tmp <- totalOutputData[OutputData$index %in% index, index] %>% table %>% data.frame
  #stopifnot(tmp$Freq %>% unique %>% length ==1)
  #tmp$.[tmp$Freq==min(tmp$Freq %>% unique)] %>% unique
  ##���ʲ��g���H => ���ʲ��g���H/��~��
  totalOutputData <- totalOutputData[, eval(parse(text=paste0(".(date, ", GroupByCol, ", ",  targetCol, ", Freq, index)")))]
  #apply(totalOutputData, 2, class)
  
  ##Add missing standard
  for(dateIndex in unique(totalOutputData$date)[1:(length(unique(totalOutputData$date))-1)]){
    
    missingStandard    <- totalOutputData$index[which(totalOutputData$date==tail(unique(totalOutputData$date), 1))][!(totalOutputData$index[which(totalOutputData$date==tail(unique(totalOutputData$date), 1))] %in% 
                                                                                                                        totalOutputData$index[which(totalOutputData$date==dateIndex)])]
    if(missingStandard %>% toString != ""){
      missingStandardSpt <- missingStandard %>% strsplit("_")
      missingArea        <- sapply(1:length(missingStandard), function(x) missingStandardSpt[[x]][1])
      missingJob         <- sapply(1:length(missingStandard %>% strsplit("_")), function(x) missingStandardSpt[[x]][2])
      
      totalOutputData <- rbind(totalOutputData, eval(parse(text=paste0("data.table(date=dateIndex, ", GroupByCol, "=missingArea, ", targetCol, "=missingJob, Freq=0, index=missingStandard)"))))
      #totalOutputData$index[which(totalOutputData$date==dateIndex)]
      #totalOutputData$index[which(totalOutputData$date==tail(unique(totalOutputData$date), 1))]
    }
  }
  totalOutputData <- totalOutputData[eval(parse(text=paste0("order(", paste(paste("date", GroupByCol, sep=", "), "index", sep=", "), ")")))]
  totalOutputData <- totalOutputData[, eval(parse(text=paste0(".(date, ", GroupByCol, ", ",  targetCol, ", Freq)")))]
  
  OutputDemandJob <- OutputDemandJob[eval(parse(text=paste0(GroupByCol,"!=''"))),]
  totalOutputData <- totalOutputData[eval(parse(text=paste0(GroupByCol,"!=''"))),]
  
  write.csv(OutputDemandJob, paste0("output\\per.month\\", format(Sys.time(), "%Y%m%d_"), filename, ".csv"), row.names=F)
  write.csv(totalOutputData, paste0("output\\per.month\\", format(Sys.time(), "%Y%m%d_"), filename, "_History.csv"), row.names=F)
  gc()
  cat("\nCompleted.")
}