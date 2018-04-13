#!/bin/bash
#SBATCH -N 1
#SBATCH -n 1
#SBATCH -t 01:00:00

# script to generate chunks of SimPhy output to precess with INdelible and postprocessing
# call script: ./indelible_chunk.sh <folder>

date
echo "generating chunks..."

# create chunk subsets
m=20 # chunk size for the indelible runs with current time limit on cesga
n=$(ls SimPhy_radsims/ | grep -P '^\d+$' | wc -l) # number of replicate folders
for i in $(seq 1 $m $n); do
    mkdir chunk_$i-$((i+m-1))
    for d in $(ls SimPhy_radsims/ | grep -P '^\d+$' | tail -n+$i | head -$m); do
        ln -s ../SimPhy_radsims/$d chunk_$i-$((i+m-1))/
    done
done

date
