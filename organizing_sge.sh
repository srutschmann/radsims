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
  # remove files from raxml
  rm *.raxml.bestModel
  rm *.raxml.startTree
  cd ..
done
echo "done."

date