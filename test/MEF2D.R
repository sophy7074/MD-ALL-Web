
#library ----
library(dplyr)
library(stringr)
library(Rphenograph)
library(MDALL)

# For single sample
file_count="/software/tests/MEF2D/COH000353_D1.DUX4patched.HTSeq"
file_vcf="/software/tests/MEF2D/COH000353_D1.HaplotypeCaller.vcf"
file_fusioncatcher="/software/tests/MEF2D/COH000353_D1.fusioncatcher"
file_cicero="/software/tests/MEF2D/COH000353_D1.cicero"



df_out_testOne=run_one_sample(sample_id = "MEF2D",file_count = file_count,
                              file_vcf = file_vcf,
                              file_fusioncatcher = file_fusioncatcher,
                              file_cicero = file_cicero,
                              featureN_PG = c(100))

write.csv(df_out_testOne, file = "./test/MEF2D/result_output.csv", row.names = FALSE, na = "")

# # For multiple samples
# setwd("/home/zgu_labs/bin/R/shinyApp/MDALL")
# df_listing=read.table("/home/zgu_labs/bin/R/shinyApp/MDALL/test/file_list.tsv",sep  = "\t",header = T)
#
#
# out_testMul=run_multiple_samples(file_listing = "test/file_list.tsv",featureN_PG = c(100,1058))
#
# out_mul=out_testMul$df_sums



#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# df_out_testOne=run_one_sample(sample_id = "COH000333_D1.15M",file_count = file_count,
#                               file_vcf = file_vcf,
#                               file_fusioncatcher = file_fusioncatcher,
#                               file_cicero = file_cicero,
#                               featureN_PG = c(100))


# out_testMul=run_multiple_samples(file_listing = "test/file_list.tsv",featureN_PG = c(100))
# out_mul=out_testMul$df_sums
