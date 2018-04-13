#!/bin/bash
#SBATCH -N 1
#SBATCH -n 1
#SBATCH -t 01:00:00

date
echo "running indelible, diversity and extract_snps..."

# generate indelible input files, run indelible, run diversity
for d in $(ls -d chunk*/); do
    # generate SGE job file
    cat > ${d%/}.indelible.sh <<EOL
#!/bin/bash
#SBATCH -N 1
#SBATCH -n 1
#SBATCH -t 00:10:00

date
module load gcc/5.3.0
module load gsl/1.16
module load indelible

echo "running indelible..."
perl /mnt/lustre/scratch/home/uvi/be/sru/simulation/scripts/indelible_process.pl $d /mnt/lustre/scratch/home/uvi/be/sru/simulation/conf_files/INDELible_radsims.txt 22 2

EOL
bash ${d%/}.indelible.sh & # CAUTION: uncomment this line to run job in background
#qsub ${d%/}.indelible.sh # CAUTION: uncomment this line to submit jobs to cluster queue
done

wait # make sure all background process are finished

date
