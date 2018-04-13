#!/bin/bash
#SBATCH -N 1
#SBATCH -n 1
#SBATCH -t 01:00:00

date

module load gcc/5.3.0
module load simphy/1.0.2

# modified parameters
GP="L:1.4,1"  # Gene-by-lineage-specific rate heterogeneity modifier (HYPER PARAM)
HG="F:GP" # Gene-by-lineage-specific rate heterogeneity modifier

echo "running simphy..."
cp /mnt/lustre/scratch/home/uvi/be/sru/simulation/conf_files/201710_SimPhy_radsims.conf ./SimPhy.conf
sed -i "s/-cs 22/-cs $RANDOM/g" SimPhy.conf
# simphy -i ./SimPhy.conf 
simphy -i ./SimPhy.conf -gp $GP -hg $HG

date
