rm(list = ls()) #Remove all objects in the environment
gc() ##Free up the memory

if(!exists("original_path"))
  original_path <- getwd()
setwd(file.path("DB4Raw"))
options(scipen=999)

##Libraries
library(pbapply)
library(data.table)
library(dplyr)
library(plyr)

# Demand
##Get all files' names.
files <- list.files(file.path("per.month", "�D�~"), full.names = TRUE)
files <- files[grepl("csv", files)]
##Import files
files.lists <- pblapply(files,function(file.name){
  file.list <- fread(file.name)
  ##Create new col:date by it's file name...
  date <- unlist(strsplit(file.name, "/"))[length(unlist(strsplit(file.name, "/")))] %>% gsub("[A-z.]", "", .) ##%>% substr(., 1, 7)
  file.list <- cbind(file.list, date)
  
  return(file.list)
})

##Combine all the lists into data frame.
total.data <- do.call(rbind, files.lists) # do.call(rbind.fill,files.lists)
rm(files.lists,files)
dim(total.data)
str(total.data)
names(total.data)
setDT(total.data)

##Import with encoding will face error...
##File's content itself is garbled...
names(total.data) <- names(total.data) %>% iconv(., "UTF-8")
cols <- 1:length(names(total.data))
total.data[, (cols) := lapply(.SD, function(x) iconv(x, "UTF-8"))]
if(length(names(total.data)) != length(unique(names(total.data))))
  total.data <- total.data[, unique(names(total.data)), with=F]
dim(total.data)
names(total.data)

## Top 25 job demand : by area
total.data <- total.data[ ���¾��=="N" ] # %>% filter(., ���¾��=="N")
total.data$¾���ݩ� %>% table
total.data <- total.data[ ¾���ݩ�=="��¾" | ¾���ݩ�=="������" ] # %>% filter(., ¾���ݩ�=="��¾" | ¾���ݩ�=="������")

## Working area transfer
total.data$area.work <- ""
North <- c("�x�_", "�s�_", "��", "���", "�s��")
Mid   <- c("�]��", "�x��", "����", "�n��", "���L")
South <- c("�Ÿq", "�x�n", "����", "�̪F")
East  <- c("�y��", "�Ὤ", "�x�F", "���", "����", "�s��")
Out   <- c(North, Mid, South, East)
total.data[ substr(total.data[,�u�@�a�I],1,2) %in% North, area.work:="�_���a��"]
total.data[ substr(total.data[,�u�@�a�I],1,2) %in% Mid, area.work:="�����a��"]
total.data[ substr(total.data[,�u�@�a�I],1,2) %in% South, area.work:="�n���a��"]
total.data[ substr(total.data[,�u�@�a�I],1,2) %in% East, area.work:="�F���P���q�a��"]
total.data[ !(substr(total.data[,�u�@�a�I],1,2) %in% Out) , area.work:="�D�x�W�a��"]

unique(total.data$area.work)
## Check areas which are outside Taiwan
total.data[ !(substr(total.data[,�u�@�a�I],1,3) %in% Out) , �u�@�a�I] %>% substr(., 1, 3) %>% table

total.data$date %>% unique
total.data$date <- total.data$date %>% substr(., 1, 5)
total.data$date <- as.integer(total.data$date)
total.data$date <- total.data$date - 1

#���ʲ��g���H => ���ʲ��g���H/��~��
total.data$¾�Ȥp���W��[total.data$¾�Ȥp���W��=="���ʲ��g���H"] <- "���ʲ��g���H/��~��"

## Top 25 Demanded Jobs
#top25_DemandJob <- total.data %>% filter(., ¾�Ȥp���W��!="�uŪ��") %>% group_by(date, area.work, ¾�Ȥp���W��) %>% 
#  summarize(.,Freq=n()) %>% arrange(.,date, area.work, -Freq) 
top25_DemandJob <- total.data[ ¾�Ȥp���W��!="�uŪ��", .N, by = .(date, area.work, ¾�Ȥp���W��)]
top25_DemandJob <- top25_DemandJob[order(date, area.work, -N)]
top25_DemandJob[, percentage:=N/sum(N), by=.(date, area.work)]
#top25_DemandJob <- top25_DemandJob %>% group_by(., date, area.work) %>% mutate(., percentage=Freq/sum(Freq))
unique(top25_DemandJob$area.work)

##Backup 
totalDemandJob <- top25_DemandJob

##change freq to a new standard
standard.top25_DemandJob <- top25_DemandJob[date==top25_DemandJob$date[1]]
#standard.top25_DemandJob <- top25_DemandJob %>% filter(., date==top25_DemandJob$date[1])
top25_DemandJob <- top25_DemandJob[, head(.SD, 25), by=.(date, area.work)]
#top25_DemandJob <- top25_DemandJob %>% group_by(date, area.work) %>% top_n(n = 25)
top25_DemandJob$Freq <- sapply(1:nrow(top25_DemandJob), function(x){
  top25_DemandJob$N[x] - standard.top25_DemandJob$N[which(standard.top25_DemandJob$¾�Ȥp���W��==top25_DemandJob$¾�Ȥp���W��[x] & standard.top25_DemandJob$area.work==top25_DemandJob$area.work[x])]
})

##Set ranking
top25_DemandJob$rank <-  0
countdown <- 0
for(i in 1:nrow(top25_DemandJob)){
  if(i==1){
    top25_DemandJob$rank[i] <- 1
  }else{
    if(top25_DemandJob$area.work[i]==top25_DemandJob$area.work[i-1]){
      if(top25_DemandJob$percentage [i]==top25_DemandJob$percentage [i-1]){
        top25_DemandJob$rank[i] <- top25_DemandJob$rank[i-1]
        countdown <- countdown + 1
      }else{
        top25_DemandJob$rank[i] <- top25_DemandJob$rank[i-1] + 1 + countdown
        countdown <- 0
      }      
    }else{
      top25_DemandJob$rank[i] <- 1
      countdown <- 0
    }
  } 
}

top25_DemandJob$percentage <- paste0(format(round(top25_DemandJob$percentage*100,2), nsmall=2), "%")
#Generate index
top25_DemandJob[,index:=paste(area.work, ¾�Ȥp���W��, sep="_")]

##Historical changes...
totalDemandJob$Freq <- sapply(1:nrow(totalDemandJob), function(x){
  if(standard.top25_DemandJob$N[which(standard.top25_DemandJob$¾�Ȥp���W��==totalDemandJob$¾�Ȥp���W��[x] & standard.top25_DemandJob$area.work==totalDemandJob$area.work[x])] %>% toString != ""){
    return(totalDemandJob$N[x] - standard.top25_DemandJob$N[which(standard.top25_DemandJob$¾�Ȥp���W��==totalDemandJob$¾�Ȥp���W��[x] & standard.top25_DemandJob$area.work==totalDemandJob$area.work[x])])
  }
  return(0)
})
totalDemandJob[,index:=paste(area.work, ¾�Ȥp���W��, sep="_")]
top25_DemandJob <- top25_DemandJob[date==max(date)]
##Rank, Area, Job, Percentage, Freq
##Keep the latest data
OutputDemandJob <- top25_DemandJob[, .(rank, area.work, ¾�Ȥp���W��, percentage, Freq)]
##Output of %in% is wrong
totalDemandJob <- totalDemandJob[index %in% top25_DemandJob$index, ]

##Check
tmp <- totalDemandJob[top25_DemandJob$index %in% index, index] %>% table %>% data.frame
stopifnot(tmp$Freq %>% unique %>% length ==1)
#tmp$.[tmp$Freq==min(tmp$Freq %>% unique)] %>% unique
##���ʲ��g���H => ���ʲ��g���H/��~��
totalDemandJob <- totalDemandJob[, .(date, area.work, ¾�Ȥp���W��, Freq)]
#apply(totalDemandJob, 2, class)

write.csv(OutputDemandJob, paste0("output\\per.month\\", format(Sys.time(), "%Y%m%d"), "_OutputDemandJob.csv"), row.names=F)
write.csv(totalDemandJob, paste0("output\\per.month\\", format(Sys.time(), "%Y%m%d"), "_totalDemandJob.csv"), row.names=F)

###################################################
###################################################
##############    I am a divider..   ##############
###################################################
###################################################

# Supply
##Import all files.
files <- list.files(file.path('per.month','�D¾'),full.names = TRUE)
files <- files[grepl("csv", files)]
##Import files
files.lists <- pblapply(files,function(file.name){
  file.list <- fread(file.name)
  date <- unlist(strsplit(file.name, "/"))[length(unlist(strsplit(file.name, "/")))] %>% gsub("[A-z.]", "", .) ##%>% substr(., 1, 7)
  file.list <- cbind(file.list, date)
  return(file.list)
})


##Combine all the lists into data frame.
total.data <- do.call(rbind,files.lists)
setDF(total.data)
rm(files.lists,files)
dim(total.data)
str(total.data)
names(total.data)
total.data <- total.data[,unique(names(total.data))]

## Top 10 most beloved jobs
total.data$�Ʊ�u�@�ʽ� %>% table
total.data <- total.data %>% filter(., �Ʊ�u�@�ʽ�=="��¾" | �Ʊ�u�@�ʽ�=="������")

## Working area transfer
total.data$area.work <- NA
"�_���a��"       -> total.data[which(substr(total.data[,"�Ʊ�W�Z�a�ϦW��"],1,3) %in% c("�x�_��","�s�_��","�򶩥�","��饫","��鿤","�s�˥�","�s�˿�")),"area.work"]
"�����a��"       -> total.data[which(substr(total.data[,"�Ʊ�W�Z�a�ϦW��"],1,3) %in% c("�]�߿�","�x����","���ƿ�","�n�뿤","���L��")),"area.work"]
"�n���a��"       -> total.data[which(substr(total.data[,"�Ʊ�W�Z�a�ϦW��"],1,3) %in% c("�Ÿq��","�Ÿq��","�x�n��","������","�̪F��")),"area.work"]
"�F���P���q�a��" -> total.data[which(substr(total.data[,"�Ʊ�W�Z�a�ϦW��"],1,3) %in% c("�y����","�Ὤ��","�x�F��","���","������","�s����")),"area.work"]
"�D�x�W�a��"     -> total.data[which(substr(total.data[,"�Ʊ�W�Z�a�ϦW��"],1,3) %in% c("�x�_��","�s�_��","�򶩥�","��饫","��鿤","�s�˥�","�s�˿�",
                                                                       "�]�߿�","�x����","���ƿ�","�n�뿤","���L��", 
                                                                       "�Ÿq��","�Ÿq��","�x�n��","������","�̪F��", 
                                                                       "�y����","�Ὤ��","�x�F��","���","������","�s����")==FALSE),"area.work"]
## Check areas which are outside Taiwan
total.data[which(substr(total.data[,"�Ʊ�W�Z�a�ϦW��"],1,3) %in% c("�x�_��","�s�_��","�򶩥�","��饫","��鿤","�s�˥�","�s�˿�",
                                                        "�]�߿�","�x����","���ƿ�","�n�뿤","���L��", 
                                                        "�Ÿq��","�Ÿq��","�x�n��","������","�̪F��", 
                                                        "�y����","�Ὤ��","�x�F��","���","������","�s����")==FALSE),"�Ʊ�W�Z�a�ϦW��"] %>% table

## Top 10 most beloved jobs
## Top 25 Demanded Jobs
total.data$date %>% unique
total.data$date <- total.data$date %>% substr(., 1, 5)
total.data$date <- as.integer(total.data$date)
total.data$date <- total.data$date - 1

top10beloved.job <- total.data %>% filter(., �Ʊ�¾�Ȥp���W��!="�uŪ��") %>% group_by(date, area.work, �Ʊ�¾�Ȥp���W��) %>% 
  summarize(.,Freq=n()) %>% arrange(.,date, area.work, -Freq) 
top10beloved.job <- top10beloved.job %>% group_by(., date, area.work) %>% mutate(., percentage=Freq/sum(Freq))
unique(top10beloved.job$area.work)

##change freq to a new standard
standard.top10beloved.job <- top10beloved.job %>% filter(., date==top10beloved.job$date[1])
top10beloved.job <- top10beloved.job %>% group_by(date,area.work) %>% top_n(n = 10)
top10beloved.job$Freq <- sapply(1:nrow(top10beloved.job), function(x){
  top10beloved.job$Freq[x] - standard.top10beloved.job$Freq[which(standard.top10beloved.job$�Ʊ�¾�Ȥp���W��==top10beloved.job$�Ʊ�¾�Ȥp���W��[x] & standard.top10beloved.job$area.work==top10beloved.job$area.work[x])]
})

##Set ranking
top10beloved.job$rank <-  NA
countdown <- 0
for(i in 1:nrow(top10beloved.job)){
  if(i==1){
    top10beloved.job$rank[i] <- 1
  }else{
    if(top10beloved.job$area.work[i]==top10beloved.job$area.work[i-1]){
      if(top10beloved.job$percentage[i]==top10beloved.job$percentage[i-1]){
        top10beloved.job$rank[i] <- top10beloved.job$rank[i-1]
        countdown <- countdown + 1
      }else{
        top10beloved.job$rank[i] <- top10beloved.job$rank[i-1] + 1 + countdown
        countdown <- 0
      }      
    }else{
      top10beloved.job$rank[i] <- 1
      countdown <- 0
    }
  } 
}

write.csv(top10beloved.job, paste0("output\\per.month\\",gsub("[:punct:]","_", Sys.time()),"_top10beloved.job.csv"), row.names=F)

###################
##department vs job
###################
dpt.match <- read.csv("1111�Ǹs�Ǫ�����-20160617-1.csv", stringsAsFactors=F)
for(i in 1:ncol(dpt.match)){
  dpt.match[,i] <- gsub("[0-9+_]", "", dpt.match[,i])
}
total.data$dpt <- ""
for(i in 1:nrow(dpt.match)){
  total.data$dpt[which(total.data$�̰��Ǿ�_��t�p���W��==dpt.match[i,3])] <- dpt.match[i,2]
}

dpt.top10beloved.job <- total.data %>% filter(., �Ʊ�¾�Ȥp���W��!="�uŪ��") %>% group_by(date, dpt, �Ʊ�¾�Ȥp���W��) %>% 
  summarize(.,Freq=n()) %>% arrange(.,date, -Freq) 
dpt.top10beloved.job <- dpt.top10beloved.job %>% filter(., dpt!="")
dpt.top10beloved.job <- dpt.top10beloved.job %>% group_by(., date, dpt) %>% mutate(., percentage=Freq/sum(Freq))
unique(dpt.top10beloved.job$dpt)

##change freq to a new standard
standard.dpt.top10beloved.job <- dpt.top10beloved.job %>% filter(., date==dpt.top10beloved.job$date[1])
dpt.top10beloved.job <- dpt.top10beloved.job %>% group_by(date,dpt) %>% top_n(n = 10)
dpt.top10beloved.job$Freq <- sapply(1:nrow(dpt.top10beloved.job), function(x){
  if(standard.dpt.top10beloved.job$Freq[which(standard.dpt.top10beloved.job$�Ʊ�¾�Ȥp���W��==dpt.top10beloved.job$�Ʊ�¾�Ȥp���W��[x] & standard.dpt.top10beloved.job$dpt==dpt.top10beloved.job$dpt[x])] %>% toString !="")
    return(dpt.top10beloved.job$Freq[x] - standard.dpt.top10beloved.job$Freq[which(standard.dpt.top10beloved.job$�Ʊ�¾�Ȥp���W��==dpt.top10beloved.job$�Ʊ�¾�Ȥp���W��[x] & standard.dpt.top10beloved.job$dpt==dpt.top10beloved.job$dpt[x])])
  return(dpt.top10beloved.job$Freq[x])
    
})

##Set ranking
dpt.top10beloved.job$rank <-  NA
countdown <- 0
for(i in 1:nrow(dpt.top10beloved.job)){
  if(i==1){
    dpt.top10beloved.job$rank[i] <- 1
  }else{
    if(dpt.top10beloved.job$dpt[i]==dpt.top10beloved.job$dpt[i-1]){
      if(dpt.top10beloved.job$percentage[i]==dpt.top10beloved.job$percentage[i-1]){
        dpt.top10beloved.job$rank[i] <- dpt.top10beloved.job$rank[i-1]
        countdown <- countdown + 1
      }else{
        dpt.top10beloved.job$rank[i] <- dpt.top10beloved.job$rank[i-1] + 1 + countdown
        countdown <- 0
      }      
    }else{
      dpt.top10beloved.job$rank[i] <- 1
      countdown <- 0
    }
  } 
}

write.csv(dpt.top10beloved.job, paste0("output\\per.month\\",gsub("[:punct:]","_", Sys.time()),"_dpt.top10beloved.job.csv"), row.names=F)




##
##�a�ϬO�_�n�A���B�z
top10beloved.area <- total.data %>% filter(., �Ʊ�¾�Ȥp���W��!="�uŪ��") %>% mutate(., �Ʊ�W�Z�a�ϦW��=substr(�Ʊ�W�Z�a�ϦW��, 1, 3)) %>% group_by(date, �Ʊ�W�Z�a�ϦW��) %>% 
  summarize(.,Freq=n()) %>% arrange(.,date, -Freq) 
top10beloved.area <- top10beloved.area %>% group_by(., date) %>% mutate(., percentage=Freq/sum(Freq))


##change freq to a new standard
standard.top10beloved.area <- top10beloved.area %>% filter(., date==top10beloved.area$date[1])
top10beloved.area <- top10beloved.area %>% group_by(date) %>% top_n(n = 10)
top10beloved.area$Freq <- sapply(1:nrow(top10beloved.area), function(x){
  top10beloved.area$Freq[x] - standard.top10beloved.area$Freq[which(standard.top10beloved.area$�Ʊ�W�Z�a�ϦW��==top10beloved.area$�Ʊ�W�Z�a�ϦW��[x])]
})

##Set ranking
top10beloved.area$rank <-  NA
countdown <- 0
for(i in 1:nrow(top10beloved.area)){
  if(i==1){
    top10beloved.area$rank[i] <- 1
  }else{
    if(top10beloved.area$date[i]==top10beloved.area$date[i-1]){
      if(top10beloved.area$percentage[i]==top10beloved.area$percentage[i-1]){
        top10beloved.area$rank[i] <- top10beloved.area$rank[i-1]
        countdown <- countdown + 1
      }else{
        top10beloved.area$rank[i] <- top10beloved.area$rank[i-1] + 1 + countdown
        countdown <- 0
      }      
    }else{
      top10beloved.area$rank[i] <- 1
      countdown <- 0
    }
  } 
}

write.csv(top10beloved.area, paste0("output\\per.month\\",gsub("[:punct:]","_", Sys.time()),"_top10beloved.area.csv"), row.names=F)


##dpt.top10beloved.area
##�a�ϬO�_�n�A���B�z
dpt.top10beloved.area <- total.data %>% filter(., �Ʊ�¾�Ȥp���W��!="�uŪ��") %>% mutate(., �Ʊ�W�Z�a�ϦW��=substr(�Ʊ�W�Z�a�ϦW��, 1, 3)) %>% group_by(date, dpt, �Ʊ�W�Z�a�ϦW��) %>% 
  summarize(.,Freq=n()) %>% arrange(.,date, -Freq) 
dpt.top10beloved.area <- dpt.top10beloved.area %>% filter(., dpt!="")
dpt.top10beloved.area <- dpt.top10beloved.area %>% group_by(., date, dpt) %>% mutate(., percentage=Freq/sum(Freq))
unique(dpt.top10beloved.area$dpt)

##change freq to a new standard
standard.dpt.top10beloved.area <- dpt.top10beloved.area %>% filter(., date==dpt.top10beloved.area$date[1])
dpt.top10beloved.area <- dpt.top10beloved.area %>% group_by(date, dpt) %>% top_n(n = 10)
dpt.top10beloved.area$Freq <- sapply(1:nrow(dpt.top10beloved.area), function(x){
  if(standard.dpt.top10beloved.area$Freq[which(standard.dpt.top10beloved.area$�Ʊ�W�Z�a�ϦW��==dpt.top10beloved.area$�Ʊ�W�Z�a�ϦW��[x] & standard.dpt.top10beloved.area$dpt==dpt.top10beloved.area$dpt[x])] %>% toString !="")
    return(dpt.top10beloved.area$Freq[x] - standard.dpt.top10beloved.area$Freq[which(standard.dpt.top10beloved.area$�Ʊ�W�Z�a�ϦW��==dpt.top10beloved.area$�Ʊ�W�Z�a�ϦW��[x] & standard.dpt.top10beloved.area$dpt==dpt.top10beloved.area$dpt[x])])
  return(dpt.top10beloved.area$Freq[x])
})

##Set ranking
dpt.top10beloved.area$rank <-  NA
countdown <- 0
for(i in 1:nrow(dpt.top10beloved.area)){
  if(i==1){
    dpt.top10beloved.area$rank[i] <- 1
  }else{
    if(dpt.top10beloved.area$dpt[i]==dpt.top10beloved.area$dpt[i-1]){
      if(dpt.top10beloved.area$percentage[i]==dpt.top10beloved.area$percentage[i-1]){
        dpt.top10beloved.area$rank[i] <- dpt.top10beloved.area$rank[i-1]
        countdown <- countdown + 1
      }else{
        dpt.top10beloved.area$rank[i] <- dpt.top10beloved.area$rank[i-1] + 1 + countdown
        countdown <- 0
      }      
    }else{
      dpt.top10beloved.area$rank[i] <- 1
      countdown <- 0
    }
  } 
}

write.csv(dpt.top10beloved.area, paste0("output\\per.month\\",gsub("[:punct:]","_", Sys.time()),"_dpt.top10beloved.area.csv"), row.names=F)


#################
#################
##quan mo
#################
#################

# Demand
##Get all files' names.
files <- list.files(file.path('per.month','�D�~'),full.names = TRUE)
files <- files[grepl("csv", files)]
##Import files
file.list <- fread(files[1])
tmp_names <- names(file.list)
files.lists <- pblapply(files,function(file.name){
  file.list <- fread(file.name)
  #date <- unlist(strsplit(file.name, "/"))[length(unlist(strsplit(file.name, "/")))] %>% gsub("[A-z.]", "", .) ##%>% substr(., 1, 7)
  #file.list <- cbind(file.list, date)
  names(file.list) <- tmp_names
  return(file.list)
})

for(i in 1:length(files.lists)){
  print(ncol(files.lists[[i]]))
}

##Combine all the lists into data frame.
total.data <- do.call(rbind.fill,files.lists)
setDF(total.data)
rm(files.lists,files)
dim(total.data)
str(total.data)
names(total.data)
total.data <- total.data[,unique(names(total.data))]
##
##��Ʈɶ� �a�z�ϰ�  �s_1111��~�����W��
## Top 10 most beloved jobs
demand_job_data <- total.data %>% select(��Ʈɶ�, ID1111¾�Ȥp���W��, �a�z�ϰ�, �s_1111��~�����W��)

## Working area transfer
demand_job_data$area.work <- NA
"�_���a��"       -> demand_job_data[which(substr(demand_job_data[,"�a�z�ϰ�"],1,3) %in% c("�x�_��","�s�_��","�򶩥�","��饫","��鿤","�s�˥�","�s�˿�")),"area.work"]
"�����a��"       -> demand_job_data[which(substr(demand_job_data[,"�a�z�ϰ�"],1,3) %in% c("�]�߿�","�x����","���ƿ�","�n�뿤","���L��")),"area.work"]
"�n���a��"       -> demand_job_data[which(substr(demand_job_data[,"�a�z�ϰ�"],1,3) %in% c("�Ÿq��","�Ÿq��","�x�n��","������","�̪F��")),"area.work"]
"�F���P���q�a��" -> demand_job_data[which(substr(demand_job_data[,"�a�z�ϰ�"],1,3) %in% c("�y����","�Ὤ��","�x�F��","���","������","�s����")),"area.work"]
"�D�x�W�a��"     -> demand_job_data[which(substr(demand_job_data[,"�a�z�ϰ�"],1,3) %in% c("�x�_��","�s�_��","�򶩥�","��饫","��鿤","�s�˥�","�s�˿�",
                                                                           "�]�߿�","�x����","���ƿ�","�n�뿤","���L��", 
                                                                           "�Ÿq��","�Ÿq��","�x�n��","������","�̪F��", 
                                                                           "�y����","�Ὤ��","�x�F��","���","������","�s����")==FALSE),"area.work"]
## Check areas which are outside Taiwan
demand_job_data[which(substr(demand_job_data[,"�a�z�ϰ�"],1,3) %in% c("�x�_��","�s�_��","�򶩥�","��饫","��鿤","�s�˥�","�s�˿�",
                                                            "�]�߿�","�x����","���ƿ�","�n�뿤","���L��", 
                                                            "�Ÿq��","�Ÿq��","�x�n��","������","�̪F��", 
                                                            "�y����","�Ὤ��","�x�F��","���","������","�s����")==FALSE),"�a�z�ϰ�"] %>% table

## Top 25 Demanded Jobs
demand_job_data <- demand_job_data[,c(1, 2, 4, 5)]
names(demand_job_data) <- c("date", "job", "mid_area", "area.work")

area_top10beloved.job <- demand_job_data %>% select(date, area.work, job) %>% 
  filter(., job!="�uŪ��") %>% group_by(date, area.work, job) %>%
  dplyr::summarize(.,Freq=n()) %>% arrange(.,date, area.work, -Freq) 
area_top10beloved.job <- area_top10beloved.job %>% group_by(., date, area.work) %>% mutate(., percentage=Freq/sum(Freq))
unique(area_top10beloved.job$area.work)

##change freq to a new standard
standard.area_top10beloved.job <- area_top10beloved.job %>% filter(., date==area_top10beloved.job$date[1])
area_top10beloved.job$Freq     <- sapply(1:nrow(area_top10beloved.job), function(x){
  standard.Freq <- standard.area_top10beloved.job$Freq[which(standard.area_top10beloved.job$job==area_top10beloved.job$job[x] & standard.area_top10beloved.job$area.work==area_top10beloved.job$area.work[x])]
  if(toString(standard.Freq)==""){
    return(0)
  }else{
    return(area_top10beloved.job$Freq[x] - standard.Freq)
  }
})
total_area_top10beloved.job    <- area_top10beloved.job
area_top10beloved.job          <- area_top10beloved.job %>% group_by(date,area.work) %>% top_n(n = 25)


##Set ranking
area_top10beloved.job$rank <-  NA
countdown <- 0
for(i in 1:nrow(area_top10beloved.job)){
  if(i==1){
    area_top10beloved.job$rank[i] <- 1
  }else{
    if(area_top10beloved.job$area.work[i]==area_top10beloved.job$area.work[i-1]){
      if(area_top10beloved.job$percentage[i]==area_top10beloved.job$percentage[i-1]){
        area_top10beloved.job$rank[i] <- area_top10beloved.job$rank[i-1]
        countdown <- countdown + 1
      }else{
        area_top10beloved.job$rank[i] <- area_top10beloved.job$rank[i-1] + 1 + countdown
        countdown <- 0
      }      
    }else{
      area_top10beloved.job$rank[i] <- 1
      countdown <- 0
    }
  } 
}

write.csv(area_top10beloved.job, paste0("output\\per.month\\",gsub("[:punct:]","_", Sys.time()),"_area_top10beloved.job.csv"), row.names=F)



#Line chart format
source('.\\rscript\\function\\linechart_format.R', print.eval  = TRUE)

sd.area  <- "�_���a��"
sd.job   <- "��F�H��"##"�M�d�������H��"
x.axis   <- "date"
y.axis   <- "Freq"
filename <- "output\\per.month\\���լݬ�"
df       <- area_top10beloved.job %>% filter(area.work==sd.area, job==sd.job)# %>% select(date, Freq)
line_graf(graf, x.axis, y.axis, filename)
















##live.area vs work.area
##
newdata <- fread("newdata.csv")
names(newdata)
setDF(newdata)
newdata$area.work <- NA
"�_���a��"       -> newdata[which(substr(newdata[,"�u�@�a�I"],1,3) %in% c("�x�_��","�s�_��","�򶩥�","��饫","��鿤","�s�˥�","�s�˿�")),"area.work"]
"�����a��"       -> newdata[which(substr(newdata[,"�u�@�a�I"],1,3) %in% c("�]�߿�","�x����","���ƿ�","�n�뿤","���L��")),"area.work"]
"�n���a��"       -> newdata[which(substr(newdata[,"�u�@�a�I"],1,3) %in% c("�Ÿq��","�Ÿq��","�x�n��","������","�̪F��")),"area.work"]
"�F���P���q�a��" -> newdata[which(substr(newdata[,"�u�@�a�I"],1,3) %in% c("�y����","�Ὤ��","�x�F��","���","������","�s����")),"area.work"]
"�D�x�W�a��"     -> newdata[which(substr(newdata[,"�u�@�a�I"],1,3) %in% c("�x�_��","�s�_��","�򶩥�","��饫","��鿤","�s�˥�","�s�˿�",
                                                                                 "�]�߿�","�x����","���ƿ�","�n�뿤","���L��", 
                                                                                 "�Ÿq��","�Ÿq��","�x�n��","������","�̪F��", 
                                                                                 "�y����","�Ὤ��","�x�F��","���","������","�s����")==FALSE),"area.work"]
newdata$area.live <- NA
"�_���a��"       -> newdata[which(substr(newdata[,"�~���a�I"],1,3) %in% c("�x�_��","�s�_��","�򶩥�","��饫","��鿤","�s�˥�","�s�˿�")),"area.live"]
"�����a��"       -> newdata[which(substr(newdata[,"�~���a�I"],1,3) %in% c("�]�߿�","�x����","���ƿ�","�n�뿤","���L��")),"area.live"]
"�n���a��"       -> newdata[which(substr(newdata[,"�~���a�I"],1,3) %in% c("�Ÿq��","�Ÿq��","�x�n��","������","�̪F��")),"area.live"]
"�F���P���q�a��" -> newdata[which(substr(newdata[,"�~���a�I"],1,3) %in% c("�y����","�Ὤ��","�x�F��","���","������","�s����")),"area.live"]
"�D�x�W�a��"     -> newdata[which(substr(newdata[,"�~���a�I"],1,3) %in% c("�x�_��","�s�_��","�򶩥�","��饫","��鿤","�s�˥�","�s�˿�",
                                                                                 "�]�߿�","�x����","���ƿ�","�n�뿤","���L��", 
                                                                                 "�Ÿq��","�Ÿq��","�x�n��","������","�̪F��", 
                                                                                 "�y����","�Ὤ��","�x�F��","���","������","�s����")==FALSE),"area.live"]
newdata[,"�~���a�I"] <- substr(newdata[,"�~���a�I"],1,3)
newdata[,"�u�@�a�I"] <- substr(newdata[,"�u�@�a�I"],1,3)
##
live2work <- newdata %>% filter(., ¾�Ȥp���W��!="�uŪ��") %>% 
  select(�~���a�I, �u�@�a�I) %>% group_by(live = �~���a�I, work = �u�@�a�I) %>%
  dplyr::summarize(.,Freq=n()) %>% arrange(.,live, -Freq)
live2work <- live2work %>% filter(live!="" & work!="")

##����o: ���O: �������
live2work <- live2work %>% group_by(., date, area.work) %>% mutate(., percentage=Freq/sum(Freq))
unique(live2work$area.work)

##change freq to a new standard
standard.live2work <- live2work %>% filter(., date==live2work$date[1])
live2work$Freq     <- sapply(1:nrow(live2work), function(x){
  standard.Freq <- standard.live2work$Freq[which(standard.live2work$job==live2work$job[x] & standard.live2work$area.work==live2work$area.work[x])]
  if(toString(standard.Freq)==""){
    return(0)
  }else{
    return(live2work$Freq[x] - standard.Freq)
  }
})
total_live2work    <- live2work
live2work          <- live2work %>% group_by(date,area.work) %>% top_n(n = 10)


##Set ranking
live2work$rank <-  NA
countdown <- 0
for(i in 1:nrow(live2work)){
  if(i==1){
    live2work$rank[i] <- 1
  }else{
    if(live2work$area.work[i]==live2work$area.work[i-1]){
      if(live2work$percentage[i]==live2work$percentage[i-1]){
        live2work$rank[i] <- live2work$rank[i-1]
        countdown <- countdown + 1
      }else{
        live2work$rank[i] <- live2work$rank[i-1] + 1 + countdown
        countdown <- 0
      }      
    }else{
      live2work$rank[i] <- 1
      countdown <- 0
    }
  } 
}

write.csv(live2work, paste0("output\\per.month\\",gsub("[:punct:]","_", Sys.time()),"_live2work.csv"), row.names=F)