#library ----
library(dplyr)
library(stringr)
library(Rphenograph)
library(MDALL)

#Prepare the listing file of input files
df_listing=read.table("/test/file_list.tsv",sep  = "\t",header = T)
df_listing

#Analysis for multiple samples
out_testMul=run_multiple_samples(file_listing = "/test/file_list.tsv",featureN_PG = c(100,1058))

#check results
df_out_testMul=out_testMul$df_sums
df_out_testMul

#save results
write.csv(df_out_testMul, file = "/test/file_list.result.csv", row.names = FALSE, na = "")
