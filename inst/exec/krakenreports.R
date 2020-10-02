#!/usr/bin/env Rscript


# Kraken pseudo cigars

# Kraken information ####

# "C"/"U": one letter code indicating that the sequence was either classified or unclassified.
# The sequence ID, obtained from the FASTA/FASTQ header.
# The taxonomy ID Kraken used to label the sequence; this is 0 if the sequence is unclassified.
# The length of the sequence in bp.
# A space-delimited list indicating the LCA mapping of each k-mer in the sequence. For example, "562:13 561:4 A:31 0:1 562:3" would indicate that:
#   the first 13 k-mers mapped to taxonomy ID #562
# the next 4 k-mers mapped to taxonomy ID #561
# the next 31 k-mers contained an ambiguous nucleotide
# the next k-mer was not in the database
# the last 3 k-mers mapped to taxonomy ID #562

# Script ####

library(readr)
library(tidyr)
library(dplyr)
library(ggplot2)
library(optparse)
library(purrr)
library(krakenreports)


option_list <- list(
  make_option(c("-i", "--input"),
              action="store",
              default=system.file("extdata", "mapped.tsv", package = "krakenreports"),
              help="Kraken TSV - example included with package. Run without input to test."),
  make_option(c("-s", "--seqid"),
              action="store",
              default=NA,
              help="Sequence ID to display only one"),
  make_option(c("-o", "--output"),
              action="store",
              default=paste(Sys.Date(), "_krakenreports", sep = ""),
              help="Output prefix")
)

opt <- parse_args(OptionParser(option_list=option_list), positional_arguments = TRUE)

mapped <- readKmerData(x = opt$options$input)

x <-tidyKmerData(mapped)

fileprefix <- tools::file_path_sans_ext(opt$options$output)

# Write reports
x %>%
  count(taxeng) %>%
  arrange(SEQID, desc(n)) %>%
  select(Sequence = SEQID, TaxonomicName = taxeng, Count = n) %>%
  write_csv(paste0(fileprefix, "_perseq.csv"))

x %>%
  ungroup() %>%
  count(taxeng) %>%
  arrange(desc(n)) %>%
  select(TaxonomicName = taxeng, Count = n) %>%
  write_csv(paste0(fileprefix, "_allseqs.csv"))

# Write Plots
print(paste("Writing plots to", paste0(fileprefix, ".pdf")))
pdf(paste0(fileprefix, ".pdf"))
if(is.na(opt$options$seqid)){
  plotAllKmerCigars(x)
}else {
  opt$options$seqid <- x$SEQID[283]
  plotKmerCigar(x, opt$options$seqid)
}
dev.off()


