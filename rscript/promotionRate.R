##�~�걡��
rm(list = ls()) #�h���u�@�Ŷ����Ҧ�����
gc() #�O��������
path<-choose.dir()
setwd(path)
start.time<-Sys.time()

people = read.csv('newdata.csv',stringsAsFactors=F)
people = people[which(people$�u�@�ʽ�!='�uŪ' & people$�u�@�ʽ�!='��¾' & people$�u�@�ʽ�!=''),]
people$¾�Ȥp���W��[which(people$¾�Ȥp���W��=='�`�������ݡ��d�x�H��')] = '�`�������ݡ��d�i�H��'
people$¾�Ȥp���W��[which(people$¾�Ȥp���W��=='�M�d�������H��')] = '�������������M�d�H��'

job_now_list <- read.csv('..\\1111¾�����O��-20160613-1.csv',stringsAsFactors=F)
##setdiff(job_now_list[,6],unique(people[(people$¾�Ȥp���W�� %in% job_now_list[,6]),'¾�Ȥp���W��']))
#nrow(people[(people$¾�Ȥp���W�� %in% job_now_list[,6]),])
#length(job_now_list[,6])
people <- people[which(people$¾�Ȥp���W�� %in% job_now_list[,6]),]

##���󤣥�for�|�ONA?
#for(i in 1:nrow(people)){
#  people$¾�ȸg���ഫ[i] = as.numeric(substr(people$¾�ȸg��[i],1,unlist(gregexpr(pattern ='�~',people$¾�ȸg��[i]))-1))*12+as.numeric(substr(people$¾�ȸg��[i],unlist(gregexpr(pattern ='�~',people$¾�ȸg��[i]))+1,nchar(toString(people$¾�ȸg��[i]))-1))
#  print(people$¾�ȸg���ഫ[i])
#  print(paste0('¾�ȸg���ഫ',i/nrow(people)*100,'%'))
#}

all_job_list = unique(people$¾�Ȥp���W��)
output_df = data.frame('¾�ȦW��'=character(),'��¾���~�ꦨ��'=character(),'��¾�e�����~��'=character(),'��¾�~��˥���'=character(),'��¾��ʤɾ��v_��L�޲z'=character(),'��¾��ʤɫe�~��'=character(),'��L�޲z_�˥���'=character(),stringsAsFactors=F)

for(i_dpm in 1:length(all_job_list)){
  
  job_name = all_job_list[i_dpm]
  
  ##�c���~��L�C�� �B ¾�Ȥp���W�٬� job_name ��
  people_sep = people[which(people$¾�Ȥp���W��== job_name& people$¾�ȸg��!='0�~0��'& people$¾�ȸg��!='0�~1��'& people$¾�ȸg��!='0�~2��'& people$¾�ȸg��!='0�~3��'& people$¾�ȸg��!='0�~4��'& people$¾�ȸg��!='0�~5��'& people$¾�ȸg��!='0�~6��'),]
  ##���ͭ쥻�S�޲z�H�ƪ�df
  people_sep_no_manage = people_sep[which(people_sep$�޲z�H��=='0�H'),]
  #numofalltemp=0
  alltemp = {}
  allmonth = {}
  for(i in 1:nrow(people_sep)){
    ##��X����df���A�u�@�ݹJ>18000�� �B�u�@�� people_sep���U�@���u�@��
    
    if(people_sep$�u�@�ݹJ[i]>=20008){
      ##�p��U�@���~��P�o�@���~�ꪺ�����T��
      temp = people[which(people$�u�@�ݹJ>=20008 & people$�i���s��==people_sep$�i���s��[i] &people$�ĴX�u�@�g��==(people_sep[i,'�ĴX�u�@�g��']+1)),'�u�@�ݹJ'][1]/people_sep$�u�@�ݹJ[i]
      ##�p�G�o�T��>1�~�|�C�J�Ҽ{
      if(toString(temp)!="NA" & temp >=1){
        ##�C�J�~��T�׭p��
        alltemp = c(alltemp,temp)
        #numofalltemp = numofalltemp + 1 
        ##�C�J�~��p�� (�ഫ����)
        allmonth = c(allmonth ,as.numeric(substr(people_sep$¾�ȸg��[i],1,unlist(gregexpr(pattern ='�~',people_sep$¾�ȸg��[i]))-1))*12+as.numeric(substr(people_sep$¾�ȸg��[i],unlist(gregexpr(pattern ='�~',people_sep$¾�ȸg��[i]))+1,nchar(toString(people_sep$¾�ȸg��[i]))-1)))        
      }
    }   
    
    cat('\r',i,' ',job_name , ' �B�z�~��ʤɪ��A ' , format(round(i/nrow(people_sep)*100,2),nsmall=2),'%         ')
  }
  ##�����X�~�ꦨ���P�����~��, �����s��
  �~�ꦨ�� = paste0(round(mean(alltemp[!alltemp %in% boxplot.stats(alltemp)$out])*100,2),'%')
  �����~�� = paste0(round(mean(allmonth[!allmonth %in% boxplot.stats(allmonth)$out]),0),'�Ӥ�')
    
  n_of_up = 0
  allmonthup = 0
  numofallup={}
  
  cat('\n')
  ##���ۥH�S�޲z�g�笰��¦�����R
  for(i in 1:nrow(people_sep_no_manage)){
    temp = people[which(people$�i���s��==people_sep_no_manage[i,'�i���s��'] & people$�ĴX�u�@�g��==(people_sep_no_manage[i,'�ĴX�u�@�g��']+1) & people$�޲z�H��!='���w' & people$�޲z�H��!='0�H'),][1]
    #people_next = rbind(people_next,temp)
    if(!is.na(as.numeric(temp[1,1]))[1]){
      n_of_up = n_of_up + 1
      allmonthup = c(allmonthup , as.numeric(substr(people_sep_no_manage$¾�ȸg��[i],1,unlist(gregexpr(pattern ='�~',people_sep_no_manage$¾�ȸg��[i]))-1))*12+as.numeric(substr(people_sep_no_manage$¾�ȸg��[i],unlist(gregexpr(pattern ='�~',people_sep_no_manage$¾�ȸg��[i]))+1,nchar(toString(people_sep_no_manage$¾�ȸg��[i]))-1)))
      numofallup = numofallup +1
    }
    cat('\r',i,' ',job_name ,' �ʤɤ�һP�~��p�� ',format(round(i/nrow(people_sep_no_manage)*100,2),nsmall=2),'%       ')
  }
  ##�p��ʤɾ��v �P �c�����s�Ȫ��~��
  �ʤɾ��v = paste0(round(n_of_up/nrow(people_sep_no_manage)*100,2),'%')
  �ʤɦ~�� = paste0(round(mean(allmonthup[!allmonthup %in% boxplot.stats(allmonthup)$out]),0),'�Ӥ�')
  ##�ʤɳt�׬��h�֤�ʤ�
  
  temp = data.frame('¾�ȦW��'=character(),'��¾���~�ꦨ��'=character(),'��¾�e�����~��'=character(),'��¾�~��˥���'=character(),'��¾��ʤɾ��v_��L�޲z'=character(),'��¾��ʤɫe�~��'=character(),'��L�޲z_�˥���'=character(),stringsAsFactors=F)
  
  temp[1,1] = job_name
  temp[1,2] = �~�ꦨ��
  temp[1,3] = �����~��
  temp[1,4] = max(length(allmonth),length(alltemp))
  temp[1,5] = �ʤɾ��v
  temp[1,6] = �ʤɦ~��
  temp[1,7] = nrow(people_sep_no_manage)
  output_df = rbind(output_df,temp)
  
  cat('\n')
  cat('�ثe�B�z�F ',nrow(output_df),' ��¾��')
  cat('\n')
}

write.csv(output_df,paste0('output\\20160630_�����~�ꦨ���P�ʤɪ��p.csv'),row.names=F)

##
##�c���~��L�C�� �B ¾�Ȥp���W�٬� job_name ��
##��X����df���A�u�@�ݹJ>18000�� �B�u�@�� people_sep���U�@���u�@��
##�p��U�@���~��P�o�@���~�ꪺ�����T��
##�p�G�o�T��>1�~�|�C�J�Ҽ{
##�C�J�~��p�� (�ഫ����)
##�����X�~�ꦨ���P�����~��, �����s��

##���ۥH�S�޲z�g�笰��¦�����R
##�p��ʤɾ��v �P �c�����s�Ȫ��~��
##�ʤɳt�׬��h�֤�ʤ�

##�U�t�� �w�^�O
if(F){
  ##�ƾǡ��Ƥu�u�{�v
  department_job_match_list <- read.csv('����¾���u�դ��.csv',stringsAsFactors=F)
  
  #department_job_match_list <- read.csv(file.choose(),stringsAsFactors=F)
  
  for(i_dpm in 1:length(unique(department_job_match_list[,2]))){
    output_df = data.frame('¾�ȦW��'=character(),'��¾���~�ꦨ��'=character(),'��¾�e�����~��'=character(),'��¾�~��˥���'=character(),'��¾��ʤɾ��v'=character(),'��¾��ʤɫe�~��'=character(),'��¾�ʤɼ˥���'=character(),stringsAsFactors=F)
    
    �Ǩt = unique(department_job_match_list[,2])[i_dpm]
    job_list = department_job_match_list$X1111¾�Ȥp���W��[which(department_job_match_list[,2]==unique(department_job_match_list[,2])[i_dpm])]
    
    for(i in 1:length(job_list)){
      job_name = job_list[i]
      
      people_sep = people[which(people$¾�Ȥp���W��== job_name& people$¾�ȸg��!='0�~0��'& people$¾�ȸg��!='0�~1��'& people$¾�ȸg��!='0�~2��'& people$¾�ȸg��!='0�~3��'& people$¾�ȸg��!='0�~4��'& people$¾�ȸg��!='0�~5��'& people$¾�ȸg��!='0�~6��'),]
      people_sep_no_manage = people_sep[which(people_sep$�޲z�H��=='0�H'),]
      #numofalltemp=0
      alltemp = {}
      allmonth = {}
      for(i in 1:nrow(people_sep)){
        temp = people[which(people$�u�@�ݹJ>=18000 & people$�i���s��==people_sep$�i���s��[i] &people$�ĴX�u�@�g��==(people_sep[i,'�ĴX�u�@�g��']+1)),'�u�@�ݹJ'][1]/people[which(people$�u�@�ݹJ!=0 & people$�i���s��==people_sep$�i���s��[i] &people$�ĴX�u�@�g��==(people_sep[i,'�ĴX�u�@�g��'])),'�u�@�ݹJ'][1]
        if(toString(temp)!="NA" & temp >=1){
          alltemp = c(alltemp,temp)
          #numofalltemp = numofalltemp + 1 
          allmonth = c(allmonth ,as.numeric(substr(people_sep$¾�ȸg��[i],1,unlist(gregexpr(pattern ='�~',people_sep$¾�ȸg��[i]))-1))*12+as.numeric(substr(people_sep$¾�ȸg��[i],unlist(gregexpr(pattern ='�~',people_sep$¾�ȸg��[i]))+1,nchar(toString(people_sep$¾�ȸg��[i]))-1)))
          
          
        }
        
        
        
        print(paste0(i,' ',job_name , ' �B�z�~��ʤɪ��A ' , i/nrow(people_sep)*100,'%'))
        #print(temp)
        #print(alltemp)
      }
      �~�ꦨ�� = paste0(round(mean(alltemp[!alltemp %in% boxplot.stats(alltemp)$out])*100,2),'%')
      �����~�� = paste0(round(mean(allmonth[!allmonth %in% boxplot.stats(allmonth)$out]),0),'�Ӥ�')
      
      people_next = people_sep[1,]
      people_next = people_next[-1,]
      
      n_of_up = 0
      allmonthup = 0
      numofallup={}
      for(i in 1:nrow(people_sep_no_manage)){
        temp = people[which(people$�i���s��==people_sep_no_manage[i,'�i���s��'] & people$�ĴX�u�@�g��==(people_sep_no_manage[i,'�ĴX�u�@�g��']+1 & people$�޲z�H��!='���w' & people$�޲z�H��!='0�H')),][1]
        #people_next = rbind(people_next,temp)
        if(!is.na(as.numeric(temp[1,1]))[1]){
          n_of_up = n_of_up + 1
          allmonthup = c(allmonthup , as.numeric(substr(people_sep_no_manage$¾�ȸg��[i],1,unlist(gregexpr(pattern ='�~',people_sep_no_manage$¾�ȸg��[i]))-1))*12+as.numeric(substr(people_sep_no_manage$¾�ȸg��[i],unlist(gregexpr(pattern ='�~',people_sep_no_manage$¾�ȸg��[i]))+1,nchar(toString(people_sep_no_manage$¾�ȸg��[i]))-1)))
          numofallup = numofallup +1
        }
        print(paste0(i,' ',job_name ,' �ʤɤ�һP�~��p�� ',i/nrow(people_sep_no_manage)*100,'%'))
      }
      �ʤɾ��v = paste0(round(n_of_up/nrow(people_sep_no_manage)*100,2),'%')
      �ʤɦ~�� = paste0(round(mean(allmonthup[!allmonthup %in% boxplot.stats(allmonthup)$out]),0),'�Ӥ�')
      ##�ʤɳt�׬��h�֤�ʤ�
      
      temp = data.frame('¾�ȦW��'=character(),'��¾���~�ꦨ��'=character(),'��¾�e�����~��'=character(),'��¾�~��˥���'=character(),'��¾��ʤɾ��v'=character(),'��¾��ʤɫe�~��'=character(),'��¾�ʤɼ˥���'=character(),stringsAsFactors=F)
      
      temp[1,1] = job_name
      temp[1,2] = �~�ꦨ��
      temp[1,3] = �����~��
      temp[1,4] = max(length(allmonth),length(alltemp))
      temp[1,5] = �ʤɾ��v
      temp[1,6] = �ʤɦ~��
      temp[1,7] = nrow(people_sep_no_manage)
      output_df = rbind(output_df,temp)
      
      
    }
    write.csv(output_df,paste0('output\\',�Ǩt,'�~�ꦨ���P�ʤɪ��p1.csv'),row.names=F)
    
  }
  
  
  #�t�ήɶ�
  end.time <- Sys.time()
  #�O���@�q�{�ǵ�������ɶ�
  run.time <- end.time - start.time
  run.time
  
  
  
  ##��Ž��������
  if(FALSE){
    "   interquartile range (IQR) = Q3 ??? Q1
    
    ���l��ݩ����X�h����u�OQ1 ??? 1.5 x IQR �� Q3 + 1.5 x IQR
    
    �ܩ�outlier�O���b boxplot ���U�O��ܪ��I�A
    
    ���bQ1 ??? 1.5 x IQR �U�� �� ���� Q3 + 1.5 x IQR �W��
    "
  }
}