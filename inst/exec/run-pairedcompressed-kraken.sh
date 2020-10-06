#!/usr/bin/env bash

# Usage:
# Loop through a series of NGS datasets run kraken2 against combined human/covid database on each of the run fastqs
# This to be run on compressed paired fastq files with designators pair1/pair2
# bash runkraken.sh <fastq directory>
# To be run on a directory of fastq files.

# Run directory must have trailing slash
DIR=$1
DBNAME=/Drives/P/Galaxies/main_nml/galaxy-common/database/kraken2_database/kraken2_genexa_covid19_human/

for i in `ls $DIR/*pair1.fastq.gz`; do pair2=`echo $i | sed 's/pair1.fastq.gz/pair2.fastq.gz/g'`;file=${i##*/}; sbatch -p NMLResearch -c 48 --mem 96G --wrap="kraken2 --paired --gzip-compressed --confidence 0.1 --db $DBNAME --report ${file%%.*}-REPORT.tsv --threads 48 $i $pair2 --output ${file%%.*}-kraken.tsv"; done
