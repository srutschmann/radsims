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
  # files from all
  rm *.sh
  # files from svdq
  rm slurm-*
  rm *.master.nex
  rm svdq.*.o*
  rm svdq.*.e*
  # files from snapp
  rm *.xml
  rm *.xml.state
  # files from raxml
  rm *.raxml.bestModel
  rm *.raxml.startTree
  cd ..
done
echo "done."

date