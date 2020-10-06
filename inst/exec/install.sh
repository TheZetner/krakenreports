#!/usr/bin/env bash

echo Installing Kraken2
conda install -y -c bioconda kraken2

echo Installing R dependencies
conda install -y -c r r-base
conda install -y -c conda-forge r-essentials
conda install -y -c conda-forge r-xml

echo "Installing krakenreports to library in $CONDA_PREFIX"
Rscript --vanilla -e 'install.packages("remotes", repo="https://packagemanager.rstudio.com/all/latest"); remotes::install_github("TheZetner/krakenreports")'

echo "Copying executable scripts to $CONDA_PREFIX/bin"
cp $CONDA_PREFIX/lib/R/library/krakenreports/exec/krakenreports.R $CONDA_PREFIX/bin/
cp $CONDA_PREFIX/lib/R/library/krakenreports/exec/runkraken.sh $CONDA_PREFIX/bin/

echo "Use runkraken.sh to run kraken2 via sbatch on a folder of fastq files."
echo "Use krakenreports.R to create plots and reports of the results"
