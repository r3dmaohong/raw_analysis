#單一目標欄位
#最終篩選欄位
#原始DF : total.data

#OutputData
#OrigiData
#targerCol

#OrigiData=total.data
#targerCol="職務小類名稱"
#GroupByCol = "area.work"
#----GroupByCol = c("date", "area.work")
#filename="AreaJobDemand"
#fixed: date

library(tidyr) #separate_rows()

JobTrend <- function(OrigiData, targetCol, GroupByCol, filename, top_N=25){
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
  if(length(names(OutputData)[grepl("編號", names(OutputData))])==1){
    OutputData <- OutputData[, c(names(OutputData)[grepl("編號", names(OutputData))], "date", GroupByCol, targetCol), with=FALSE] %>% unique
  }else{
    names(OutputData)
    uniColN <- readline(prompt="Enter the index of col name which should be used as unique index: ")
    OutputData <- OutputData[, c(names(OutputData)[as.numeric(uniColN)], "date", GroupByCol, targetCol), with=FALSE] %>% unique
  } 
  gc()
  OutputData <- OutputData[ eval(parseTargetCol)!="工讀生", .N, by= c("date", GroupByCol, targetCol)]
  OutputData <- OutputData[eval(parse(text=paste0("order(", paste("date", GroupByCol, "-N", sep=", "), ")")))]
  OutputData[, percentage:=N/sum(N), by=c("date", GroupByCol)]
  cat(GroupByCol, " : ", unique(OutputData[,eval(parse(text=GroupByCol))]))
  
  ##Status
  #pb <- txtProgressBar(min = 0, max = total, style = 3)
  #total <- 20
  
  ##Backup 
  totalOutputData <- OutputData
  
  ##change freq to a new standard
  ##fixed: date
  standard.OutputData <- OutputData[date==OutputData$date[1]]
  OutputData <- OutputData[, head(.SD, top_N), by=c("date", GroupByCol)]
  OutputData$Freq <- sapply(1:nrow(OutputData), function(x){
    #OutputData$N[x] - standard.OutputData$N[which(standard.OutputData[,eval(parse(text=targetCol))]==OutputData[,eval(parse(text=targetCol))][x] & standard.OutputData[,eval(parse(text=GroupByCol))]==OutputData[,eval(parse(text=GroupByCol))][x])]
    if(standard.OutputData$N[which(standard.OutputData[,eval(parse(text=targetCol))]==OutputData[,eval(parse(text=targetCol))][x] & standard.OutputData[,eval(parse(text=GroupByCol))]==OutputData[,eval(parse(text=GroupByCol))][x])] %>% toString != ""){
      return(OutputData$N[x] - standard.OutputData$N[which(standard.OutputData[,eval(parse(text=targetCol))]==OutputData[,eval(parse(text=targetCol))][x] & standard.OutputData[,eval(parse(text=GroupByCol))]==OutputData[,eval(parse(text=GroupByCol))][x])])
    }
    return(OutputData$N[x])
  })
  gc()
  #setTxtProgressBar(pb, 5)
  
  ##Set ranking
  OutputData$rank <-  0
  countdown <- 0
  for(i in 1:nrow(OutputData)){
    if(i==1){
      OutputData$rank[i] <- 1
    }else{
      if(OutputData[,eval(parse(text=GroupByCol))][i]==OutputData[,eval(parse(text=GroupByCol))][i-1]){
        if(OutputData$percentage [i]==OutputData$percentage [i-1]){
          OutputData$rank[i] <- OutputData$rank[i-1]
          countdown <- countdown + 1
        }else{
          OutputData$rank[i] <- OutputData$rank[i-1] + 1 + countdown
          countdown <- 0
        }      
      }else{
        OutputData$rank[i] <- 1
        countdown <- 0
      }
    } 
  }
  
  OutputData$percentage <- paste0(format(round(OutputData$percentage*100,2), nsmall=2), "%")
  #Generate index
  OutputData[,index:=paste(eval(parse(text=GroupByCol)), eval(parse(text=targetCol)), sep="_")]
  
  ##Historical changes...
  totalOutputData$Freq <- sapply(1:nrow(totalOutputData), function(x){
    if(standard.OutputData$N[which(standard.OutputData[,eval(parse(text=targetCol))]==totalOutputData[,eval(parse(text=targetCol))][x] & standard.OutputData[,eval(parse(text=GroupByCol))]==totalOutputData[,eval(parse(text=GroupByCol))][x])] %>% toString != ""){
      return(totalOutputData$N[x] - standard.OutputData$N[which(standard.OutputData[,eval(parse(text=targetCol))]==totalOutputData[,eval(parse(text=targetCol))][x] & standard.OutputData[,eval(parse(text=GroupByCol))]==totalOutputData[,eval(parse(text=GroupByCol))][x])])
    }
    return(totalOutputData$N[x])
  })
  
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
  ##不動產經紀人 => 不動產經紀人/營業員
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

EncodingCheck <- function(tmp){
  if(is.list(tmp)){
    for(i in 1:ncol(tmp)){
      tryCatch({
        print(Encoding(tmp[[i]]) %>% unique)
      }, error = function(e) {
        ##conditionMessage(e)
      })
    }
  }else{
    for(i in 1:ncol(tmp)){
      tryCatch({
        print(Encoding(tmp[,i]) %>% unique)
      }, error = function(e) {
        ##conditionMessage(e)
      })
    }
  }
  
}