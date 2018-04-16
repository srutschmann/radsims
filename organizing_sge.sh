#!/bin/bash
#$ -cwd
#$ -N org

# script to delete/modify files
# call script: organizing.sh <folder>

# move into radsims_* dir
cd $1

date

echo "cleaning/re-organizing files..."

for folder in $(ls -d */); do
# for folder in $(seq -f "%03g" 001 002); do
  cd $folder
  # remove files from all
  rm *.sh
  # remove files from svdq
  rm slurm-*
  rm *.master.nex
  rm svdq.*.o*
  rm svdq.*.e*
  # remove files from snapp
  rm *.xml
  rm *.xml.state
  # maybe also delete or move to log files
  # rm *ado_snps_reduced.o*
  # rm *ado_snps_reduced.po*
  # rm *concat_snps_reduced.o*
  # rm *concat_snps_reduced.po*
  cd ..
done
echo "done."

date