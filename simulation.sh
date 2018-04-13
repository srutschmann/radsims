#!/bin/bash
#SBATCH -N 1 # 1 node
#SBATCH -n 1 # 1 job
#SBATCH -c 10 # 10 cores
#SBATCH --mem 24GB # 20GB memory (default is 5333MB)
#SBATCH -t 100:00:00 # 100h (100h is maximum)

# script to run simulations, including
# 1) species and gene tree simulation with SimPhy
# 2) split SimPyh replicates into chunks for parallel processing of Indelible
# 3) run Indelible
# 4) process Indlible: calculate stats with diversity, extract snps with extract_snps
# call script: simulation.sh <id> 2>&1 | tee <id>.simulation.log 

date

hostname

echo "running simulation ..."

# define RUN_ID
# ./simulation.sh 01 # radsims_01
if [[ $# -eq 0 ]]; then
  echo "usage $0 RUN_ID [STEP]"
  exit 0
fi
RUN_ID=$1

# a step to resume from can be provided (optionally)
STEP=0
if [[ $# -gt 1 ]]; then
  STEP=$2
  echo "STEP=$STEP"
fi

# define working directory for scripts and output
WORK_DIR=/mnt/lustre/scratch/home/uvi/be/sru/simulation/tmp_${RUN_ID}

# create working directory
if [ ! -d $WORK_DIR ]; then
  echo "creating directory $WORK_DIR"
  mkdir -p $WORK_DIR
fi

if [ $STEP -lt 1 ]; then # step 0
echo "copy processing scripts to working directory $WORK_DIR"
cp ./scripts/simphy.sh $WORK_DIR
cp ./scripts/indelible_chunk.sh $WORK_DIR
cp ./scripts/indelible.sh $WORK_DIR
fi # step 0

# echo "changing to working directory $WORK_DIR"
cd $WORK_DIR

# run simphy with 200 replicates
if [ $STEP -lt 2 ]; then # step 1
echo "running simphy..."
./simphy.sh 1>simphy.out 2>simphy.err
touch simphy.done
date
fi # step 1

# split replicates into 20 chunks
if [ $STEP -lt 4 ]; then # step 2
echo "splitting simphy output into 20 chunks of 10 replicates each..."
./indelible_chunk.sh
touch indelible_chunk.done
date
fi # step 2

# run indelible on each chunk in parallel, prepare six alignments (concat, concat_snps, concat_snps_reduced), get stats ..."
if [ $STEP -lt 5 ]; then # step 3
echo "running indelible on each chunk in parallel and preparing aligns and align_stats..."
./indelible.sh
touch indelible.done
date
fi # step 3

# move files
echo "copying and renaming files..."
mv /mnt/lustre/scratch/home/uvi/be/sru/simulation/tmp_${RUN_ID}/SimPhy_radsims /mnt/lustre/scratch/home/uvi/be/sru/simulation/radsims_${RUN_ID}

echo "simulation run has finished"
echo "please check results in: /mnt/lustre/scratch/home/uvi/be/sru/simulation/radsims_${RUN_ID}"
echo "please remove tmp folder: /mnt/lustre/scratch/home/uvi/be/sru/simulation/tmp_${RUN_ID}"

date
