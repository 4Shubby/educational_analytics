#this run with success = 0 data only

rm(list=ls(all=TRUE))

library(data.table)
library(dplyr)
library(knitr)
library(ggplot2)
library(caret)
require(xgboost)
library(readr)
library(stringr)
library(car)
#require(corrplot)
library(Matrix)


setwd("S:/Reports/common/Data Request/Programs/William/Missing students/all degree seekers")
demo<-read.table('sp15_deg_demo_suc_3_gpa_missing.csv', header=TRUE, sep=',')
head(demo)
dim(demo) #10216

#### selecting enc data
deg_dat<-subset(demo, select = c(Student_ID, hs_gpa, Student_Gender_Code, 
        Financial_Aid_Student_Flag, Father_Highest_Grade_Level_Compl,Dependency_Status, Enrollment_Code_Description, Student_Age_At_Beginning_Of_Term, 
        FTIC_First_Time_in_College_Flag, Student_Credit_Hours_For_Term, GPA_All_College, Earned_Hours_All_College, Student_Income_Earned_From_Work, 
      Parent_Adjusted_Gross_Income_Fro, Children_yes_no, RPER, MPER, WPER, Mother_Highest_Grade_Level_Compl, Student_Race_Code,
      RSAT, WSAT, MSAT, Percentile, Missing, Country_Name, County_Code, Student_Permanent_Zip_Code ))


#head(deg_dat, n=20)
#colSums(is.na(deg_dat))
#summary(deg_dat)

dim(deg_dat) #10216

deg_dat$id <- as.numeric(as.factor(deg_dat$Student_ID))

####################   xg boost formatting ######################

#sapply(deg_dat,class)

#trasnform all integer and factor types
char.cols <- c('Student_Gender_Code', 'Student_Age_At_Beginning_Of_Term', 'Student_Income_Earned_From_Work', 'Parent_Adjusted_Gross_Income_Fro', 'RPER', 'MPER', 'WPER', 
               'RSAT', 'WSAT', 'MSAT', 'Dependency_Status', 'Enrollment_Code_Description', 'FTIC_First_Time_in_College_Flag',
               'Financial_Aid_Student_Flag', 'Father_Highest_Grade_Level_Compl', 'Mother_Highest_Grade_Level_Compl', 'Student_Age_At_Beginning_Of_Term',
               'Student_Income_Earned_From_Work', 'Parent_Adjusted_Gross_Income_Fro', 'Children_yes_no', 'Student_Race_Code', 'Percentile', 'Missing', 'Country_Name', 'County_Code', 'Student_Permanent_Zip_Code')
               
for (f in char.cols) {
  
    deg_dat[[f]] <- as.numeric(deg_dat[[f]])
}


Y <-deg_dat$Missing

#head(Y)

deg_dat$Missing <- NULL

deg_dat2 <- cbind(deg_dat$gpa, deg_dat$Student_Gender_Code, deg_dat$Student_Age_At_Beginning_Of_Term, deg_dat$Student_Credit_Hours_For_Term, 
                deg_dat$Earned_Hours_All_College, deg_dat$GPA_All_College, deg_dat$Parent_Adjusted_Gross_Income_Fro,  deg_dat$MPER, deg_dat$WPER, deg_dat$RPER, deg_dat$RSAT, deg_dat$WSAT, 
                deg_dat$MSAT, deg_dat$FTIC_First_Time_in_College_Flag, deg_dat$Enrollment_Code_Description , deg_dat$Financial_Aid_Student_Flag, deg_dat$Dependency_Status,
                deg_dat$hs_gpa, deg_dat$Father_Highest_Grade_Level_Compl, deg_dat$Mother_Highest_Grade_Level_Compl,
                deg_dat$Children_yes_no, deg_dat$Student_Income_Earned_From_Work, deg_dat$Student_Race_Code, deg_dat$Percentile, deg_dat$Country_Name, deg_dat$County_Code, deg_dat$Student_Permanent_Zip_Code
                )  
#head(deg_dat2)
dim(deg_dat2)
dtrain <- xgb.DMatrix(deg_dat2, missing=NA, label =Y)

#### split into train and test data set

#389 observations 70% is 272

train<-sample(1:10216, 7151)

#deg_dat2[train,]

dmodel<- xgb.DMatrix(deg_dat2[train,], missing=NA, label = Y[train])

dvalid<- xgb.DMatrix(deg_dat2[-train,], missing = NA, label = Y[-train])

param <- list(objective = "binary:logistic",  #or use reg:linear
              eval_metric = "auc",
              booster = "gbtree",  #or use gbtree, with gblinear can use parameters lambda default 0, alpha default 0, lambda_bias default 0
              eta = 0.02,
              subsample = 0.7,
              colsample_bytree = 1,  #(0,1] default 1
              min_child_weight = 0,
              max_depth = 15,   #can use [0, infinity] default 6
              gamma = 5,          #can use [0, infinity) default 0
              max_delta_step = 5)  #can use [0, infinity) default 0

# control for complexity: max_depth, min_child_weight, gamma
# control for robust to noise:  subsample, colsample_by_tree


###model and validate

m1 <- xgb.train(data = dmodel, param, nrounds = 500, watchlist = list(valid = dvalid, model = dmodel), early.stop.round = 20,
                nthread=11, print_every_n = 10) #iter 63, .725


#### train full model
set.seed(7777)
m2 <- xgb.train(data = dtrain, 
                param, nrounds = 63,
                watchlist = list(train = dtrain),
                print_every_n = 10)
#train auc of 87.5

#### read in and transfrom prediction data set

########left off here
sp16_deg_demo<-read.table('sp16_deg_demo_suc_3_gpa_missing.csv', header=TRUE, sep=',')
#head(sp16_enc_demo_success)
dim(sp16_deg_demo)#10580



p_dat<-subset(sp16_deg_demo, select = 
                c(Student_ID, hs_gpa, Student_Gender_Code, Financial_Aid_Student_Flag, Father_Highest_Grade_Level_Compl,
                  Dependency_Status, Enrollment_Code_Description, Student_Age_At_Beginning_Of_Term, FTIC_First_Time_in_College_Flag, 
                  Student_Credit_Hours_For_Term, GPA_All_College, Earned_Hours_All_College, Student_Income_Earned_From_Work, 
                  Parent_Adjusted_Gross_Income_Fro, Children_yes_no, RPER, MPER, WPER, Mother_Highest_Grade_Level_Compl, Student_Race_Code,
                  RSAT, WSAT, MSAT, Percentile, Country_Name, County_Code, Student_Permanent_Zip_Code))
#head(p_dat, n=20)

dim(p_dat)#334
#colSums(is.na(p_dat))

sid <- subset(p_dat, select = c(Student_ID))

#sapply(p_dat,class)

#char.cols2 <- c('Student_Gender_Code', 'Student_Age_At_Beginning_Of_Term', 'Student_Income_Earned_From_Work', 'Parent_Adjusted_Gross_Income_Fro', 'RPER', 'MPER', 'WPER', 
#               'RSAT', 'WSAT', 'MSAT', 'Successful',  'Dependency_Status', 'Enrollment_Code_Description', 'FTIC_First_Time_in_College_Flag',
#               'Financial_Aid_Student_Flag', 'Father_Highest_Grade_Level_Compl', 'Mother_Highest_Grade_Level_Compl')

char.cols2 <- c('Student_Gender_Code', 'Student_Age_At_Beginning_Of_Term', 'Student_Income_Earned_From_Work', 'Parent_Adjusted_Gross_Income_Fro', 'RPER', 'MPER', 'WPER', 
               'RSAT', 'WSAT', 'MSAT',  'Dependency_Status', 'Enrollment_Code_Description', 'FTIC_First_Time_in_College_Flag',
               'Financial_Aid_Student_Flag', 'Father_Highest_Grade_Level_Compl', 'Mother_Highest_Grade_Level_Compl', 'Student_Age_At_Beginning_Of_Term',
               'Student_Income_Earned_From_Work', 'Parent_Adjusted_Gross_Income_Fro', 'Children_yes_no', 'Student_Race_Code', 'Percentile', 'Country_Name', 'County_Code', 'Student_Permanent_Zip_Code')

for (f in char.cols2) {
  p_dat[[f]] <- as.numeric(p_dat[[f]])
}




p_dat2 <- cbind(p_dat$gpa, p_dat$Student_Gender_Code, p_dat$Student_Age_At_Beginning_Of_Term, p_dat$Student_Credit_Hours_For_Term, 
                p_dat$Earned_Hours_All_College, p_dat$GPA_All_College, p_dat$Parent_Adjusted_Gross_Income_Fro,  p_dat$MPER, p_dat$WPER, p_dat$RPER, p_dat$RSAT, p_dat$WSAT, 
                p_dat$MSAT, p_dat$FTIC_First_Time_in_College_Flag, p_dat$Enrollment_Code_Description , p_dat$Financial_Aid_Student_Flag, p_dat$Dependency_Status,
                p_dat$hs_gpa, p_dat$Father_Highest_Grade_Level_Compl, p_dat$Mother_Highest_Grade_Level_Compl,
                p_dat$Children_yes_no, p_dat$Student_Income_Earned_From_Work, p_dat$Student_Race_Code, p_dat$Percentile, p_dat$Country_Name, p_dat$County_Code, p_dat$Student_Permanent_Zip_Code
                ) 

dtest <- xgb.DMatrix(p_dat2, missing=NA)

####predicitons
out <- predict(m2, missing=NA, dtest)

sp16_pred <- data.frame(activity_id = sid, outcome = out)

#head(sp16_pred, n=50)

write.csv(sp16_pred, file = "sp16_pred_full_blind_deg_zip_v3.csv", row.names = F)
