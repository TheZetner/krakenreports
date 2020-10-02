#!/usr/bin/env bash

echo "Updating krakenreports in library $CONDA_PREFIX"
Rscript --vanilla -e 'remotes::install_github("TheZetner/krakenreports")'

echo "Copying executable scripts to $CONDA_PREFIX/bin"
cp $CONDA_PREFIX/lib/R/library/krakenreports/exec/krakenreports.R $CONDA_PREFIX/bin/
cp $CONDA_PREFIX/lib/R/library/krakenreports/exec/runkraken.sh $CONDA_PREFIX/bin/

echo "Use runkraken.sh to run kraken2 via sbatch on a folder of fastq files."
echo "Use krakenreports.R to create plots and reports of the results"
