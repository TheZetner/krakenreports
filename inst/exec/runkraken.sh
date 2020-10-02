#!/usr/bin/env bash
eval "$(conda shell.bash hook)"

# Usage:
# Loop through a series of NGS datasets run kraken2 against combined human/covid database on each of the run fastqs
# bash runkraken.sh <fastq directory>
# To be run on a directory of fastq files.

# Run directory must have trailing slash
DIR=$1
DBNAME=/Drives/P/Galaxies/main_nml/galaxy-common/database/kraken2_database/kraken2_genexa_covid19_human/

for i in `ls $DIR/*.fastq`; do file=${i##*/}; sbatch -p NMLResearch -c 2 --mem 1G --wrap="kraken2 --confidence 0.1 --db $DBNAME --report ${file%%.*}-REPORT.tsv --threads 2 $i --output ${file%%.*}-kraken.tsv"; done