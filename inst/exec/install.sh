#!/usr/bin/env bash

conda install -c bioconda kraken2
conda install -y -c r r-base
conda install -y -c conda-forge r-essentials
conda install -y -c conda-forge r-xml
Rscript --vanilla -e 'install.packages("remotes", repo="https://packagemanager.rstudio.com/all/latest"); remotes::install_github("TheZetner/krakenreports")'
cp $CONDA_PREFIX/lib/R/library/krakenreports/exec/krakenreports.R $CONDA_PREFIX/bin/
cp $CONDA_PREFIX/lib/R/library/krakenreports/exec/runkraken.sh $CONDA_PREFIX/bin/

