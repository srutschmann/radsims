#!/bin/bash
#$ -cwd
#$ -N raxml-ng

# script to generate raxml-ng job files
# call script: prep_raxml_fullseq_sge.sh <folder> 2>&1 | tee <folder>.raxml_fullseq.log

BINDIR=/home/sereina/simulation/radsims_60/scripts

date
cd $1

echo "preparing raxml job files..."
for folder in $(seq -f "%03g" 001 002); do # to process some replicates i.e., 001-002
  echo "  $folder"
  cd $folder
  for file in *_concat*.phy; do
    pfx=${file%.phy} # use this prefix to generate output filenames
  # generate SGE job file
    cat > ${pfx}.raxml_fullseq.sge.sh <<EOL
#!/bin/bash
#$ -cwd
#$ -N raxml_fullseq.${pfx}

date
module load bio/raxml-ng/0.5.1b

echo "running raxml-ng..."
raxml-ng --search --msa $file --model GTR+G --threads 1 --prefix "${pfx}"

date
EOL
  done
  cd ..
done

date