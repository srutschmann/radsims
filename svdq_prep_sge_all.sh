#!/bin/bash
#$ -cwd
#$ -N svdq

# script to generate svdq input and job files and optionally launch svdq in background or submit jobfiles to queue
# call script: svdq_prep.sh <folder> 2>&1 | tee <folder>.svdq_prep.log

BINDIR=/home/sereina/simulation/radsims_60/scripts

date
cd $1

# echo "generating svdq input files ..."
# for folder in $(seq -f "%03g" 183 200); do # to process some replicates i.e., 183-200
# for folder in $(ls -d */); do
  # echo "  $folder"
  # cd $folder
  # pfx=$(basename $folder)
  # create svdq input files with charset block
  # $BINDIR/svdq_input.py ${pfx}_concat_ado.phy
  # $BINDIR/svdq_input.py ${pfx}_concat.phy
  # create svdq input files without charset block
  # $BINDIR/svdq_input_wchar.py ${pfx}_concat_ado_snps.fasta
  # $BINDIR/svdq_input_wchar.py ${pfx}_concat_snps.fasta
  # $BINDIR/svdq_input_wchar.py ${pfx}_concat_ado_snps_reduced.fasta
  # $BINDIR/svdq_input_wchar.py ${pfx}_concat_snps_reduced.fasta
  # cd ..
# done

echo "preparing svdq master and job files..."
for folder in $(seq -f "%03g" 001 001); do # to process some replicates i.e., 183-200
# for folder in $(ls -d */); do
  echo "  $folder"
  cd $folder
  for file in *_concat_snps.nex *_concat_ado_snps.nex *_concat.nex *_concat_ado.nex; do # for unlinked SNPs (*_snps_reduced.nex), all SNPs, loci
    # ntax=$(perl -ne '/ntax=(\d+)/&&print $1' $file) # get number of taxa from NEXUS file
    pfx=${file%.nex} # remove ".nex" suffix from file names, use this prefix to generate output filenames
  # check number of taxa, for file in *.nex if ntaxa>200 replace 'evalQuartets=all' with 'evalQuartets=random nquartets=48603900'
  # generate master file
  # if [ $ntax -gt 200 ]; then
    # cat > ${pfx}.svdq.master.nex <<EOL
#nexus

# begin paup;
#         log file= ${pfx}.svdq.log start append;
#         execute ${pfx}.nex;
#         svdq nthreads=2 evalQuartets=random nquartets=48603900 speciesTree=yes partition=species treeInf=QFM bootstrap=yes nreps=1000 treeFile=${pfx}.svdq.bs.tre treemodel=mscoalescent;
#         savetrees file=${pfx}.svdq.tre format=newick supportValues=Both;
# end;

# EOL
#   else # ntax > 200
#     cat > ${pfx}.svdq.master.nex <<EOL
#nexus

# begin paup;
#         log file= ${pfx}.svdq.log start append;
#         execute ${pfx}.nex;
#         svdq nthreads=2 evalQuartets=all speciesTree=yes partition=species treeInf=QFM bootstrap=yes nreps=1000 treeFile=${pfx}.svdq.bs.tre treemodel=mscoalescent;
#         savetrees file=${pfx}.svdq.tre format=newick supportValues=Both;
# end;

# EOL
#   fi # ntax <= 200

  # generate SGE job file
  cat > ${pfx}.svdq.sge.sh <<EOL
#!/bin/bash
#$ -cwd
#$ -N svdq.${pfx}

date
module load bio/paup/4.0a159

echo "running svdq..."
paup4a159_centos64 -n ${pfx}.svdq.master.nex

date
EOL
  #bash ${pfx}.svdq.sge.sh # CAUTION: uncomment this line to run job in background
  #qsub ${pfx}.svdq.sge.sh # CAUTION: uncomment this line to submit jobs to cluster queue, check number of jobs that can be submitted
  done
  cd ..
done

date