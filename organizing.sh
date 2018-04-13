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
  cd $folder
  # rename files
  mv ado_stats.csv concat_ado_stats.csv
  mv align_stats.csv concat_stats.csv
  # remove files from all
  rm *.log # move this to log
  rm *.sh
  # remove files from svdq
  rm slurm-*
  rm *.bs.tre # this is needed
  rm *.master.nex
  rm *.tre # this is needed
  # remove files from snapp
  rm *.xml
  rm *.xml.state
  rm *.trees # this is needed
  rm *ado_snps_reduced.o* # move this to log?
  rm *ado_snps_reduced.po* # move this to log?
  rm *concat_snps_reduced.o* # move this to log?
  rm *concat_snps_reduced.po* # move this to log?
  cd ..
done
echo "done."

date
