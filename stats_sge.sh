#!/bin/bash
#$ -cwd
#$ -N stats

# script to extract statistics
# call script: stats.sh

BINDIR="/home/sereina/simulation/radsims_60/scripts"

module load sqlite/3.8.8.2
module load gcc
module load R/3.2.2_1

date

echo "calculating missing stats..."
for run_folder in radsims_??; do
  cd $run_folder
  ${BINDIR}/missing_stats.sh $run_folder > missing_stats.csv;
  cd ..
done
echo "done".

echo "calculating weighted rf distances..."
for run_folder in $(ls -d radsims_??/???/); do
  cd $run_folder
  Rscript --vanilla ${BINDIR}/rf_stats.R >> ../rf_stats.csv
  cd -
done
echo "done."

echo "extracting svdq stats for..."
for run_folder in radsims_??; do
  ${BINDIR}/svdq_stats.sh $run_folder;
done > svdq_stats.db.csv
echo "done."

date
