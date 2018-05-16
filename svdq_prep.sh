#!/bin/bash
#SBATCH -N 1 # 1 node
#SBATCH -n 1 # 1 job
#SBATCH -c 1 # 1 core
#SBATCH --mem 20480
#SBATCH -t 24:00:00

# script to generate svdq input and job files and optionally launch svdq in background or submit jobfiles to queue
# call script: svdq_prep.sh <folder> 2>&1 | tee <folder>.svdq_prep.log

BINDIR=/mnt/lustre/scratch/home/uvi/be/sru/simulation/scripts

# settings
MIN_THREADS=20
MED_THREADS=24
MAX_THREADS=64
MIN_MEM=10240
MED_MEM=10240
MAX_MEM=20480

date
cd $1

echo "generating svdq input files ..."
for folder in $(ls -d */); do
  echo "  $folder"
  cd $folder
  pfx=$(basename $folder)
  # create svdq input files with charset block
  $BINDIR/svdq_input.py ${pfx}_concat_ado.phy
  $BINDIR/svdq_input.py ${pfx}_concat.phy
  # create svdq input files without charset block
  $BINDIR/svdq_input_wchar.py ${pfx}_concat_ado_snps.fasta
  $BINDIR/svdq_input_wchar.py ${pfx}_concat_snps.fasta
  $BINDIR/svdq_input_wchar.py ${pfx}_concat_ado_snps_reduced.fasta
  $BINDIR/svdq_input_wchar.py ${pfx}_concat_snps_reduced.fasta
  cd ..
done

echo "preparing svdq master and job files..."
for folder in $(ls -d */); do
  echo "  $folder"
  cd $folder
  for file in *.nex; do
    ntax=$(perl -ne '/ntax=(\d+)/&&print $1' $file) # get number of taxa from NEXUS file
    pfx=${file%.nex}
  # check number of taxa, for file in *.nex if ntaxa>200 replace 'evalQuartets=all' with 'evalQuartets=random nquartets=48603900'
  # generate master file
  # check number of threads, add this to master files, make sure which are the best settings
  if [ $ntax -gt 160 ]; then
    threads=$MAX_THREADS
    mem=$MAX_MEM
    queue="fatnode"
    qos=""
  elif [ $ntax -gt 100 ]; then
    threads=$MED_THREADS
    mem=$MED_MEM
    queue="thin-shared"
    qos=""
  else
    threads=$MIN_THREADS
    mem=$MIN_MEM
    queue="shared"
    qos="#SBATCH --qos shared"
  fi 

  if [ $ntax -gt 200 ]; then
    cat > ${pfx}.svdq.master.nex <<EOL
#nexus

begin paup;
        log file= ${pfx}.svdq.log start append;
        execute ${pfx}.nex;
        svdq nthreads=${threads} evalQuartets=random nquartets=48603900 speciesTree=yes partition=species treeInf=QFM bootstrap=yes nreps=1000 treeFile=${pfx}.svdq.bs.tre treemodel=mscoalescent;
        savetrees file=${pfx}.svdq.tre format=newick supportValues=Both;
end;

EOL
  else # ntax > 200
    cat > ${pfx}.svdq.master.nex <<EOL
#nexus

begin paup;
        log file= ${pfx}.svdq.log start append;
        execute ${pfx}.nex;
        svdq nthreads=${threads} evalQuartets=all speciesTree=yes partition=species treeInf=QFM bootstrap=yes nreps=1000 treeFile=${pfx}.svdq.bs.tre treemodel=mscoalescent;
        savetrees file=${pfx}.svdq.tre format=newick supportValues=Both;
end;

EOL
  fi # ntax <= 200

  # generate SLURM job file
  cat > ${pfx}.svdq.sh <<EOL
#!/bin/bash
#SBATCH -J svdq.${pfx}  # job name
#SBATCH -N 1         # nodes
#SBATCH -n 1         # jobs
#SBATCH -c ${threads}         # cores
#SBATCH --mem ${mem}  # total memory (MB)
#SBATCH -t 100:00:00 # time (100h is maximum)
#SBATCH -p ${queue}
${qos}

date
module load paup/4a159

echo "running svdq..."
# run paup in interactive mode
paup -n ${pfx}.svdq.master.nex

date
EOL
  #bash ${pfx}.svdq.sh # CAUTION: uncomment this line to run job in background
  #sbatch ${pfx}.svdq.sh # CAUTION: uncomment this line to submit jobs to cluster queue, check number of jobs that can be submitted
  done
  cd ..
done

date


