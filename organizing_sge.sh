#!/bin/bash
#$ -cwd
#$ -N org

# script to delete/modify files
# call script: organizing.sh <folder>

# move into radsims_* dir
cd $1

date

echo "removing files..."

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
  # files from raxml-ng
  rm *.raxml.bestModel
  rm *.raxml.mlTrees
  rm *.raxml.startTree
  rm *snps.e*
  rm *snps.o*
  rm *concat_ado.e*
  rm *concat_ado.o*
  rm *concat.e*
  rm *concat.o*
  cd ..
done
echo "done."

date