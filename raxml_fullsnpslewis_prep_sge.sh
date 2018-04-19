#!/bin/bash
#$ -cwd
#$ -N raxml-ng

# script to generate raxml-ng job files
# call script: raxml_fullsnpslewis_prep_sge.sh <folder> 2>&1 | tee <folder>.raxml_fullsnpslewis.log

BINDIR=/home/sereina/simulation/radsims_60/scripts

date
cd $1

echo "preparing raxml job files..."
for folder in $(ls -d */); do
# for folder in $(seq -f "%03g" 001 002); do
  echo "  $folder"
  cd $folder
  for file in *_snps.fasta; do
    pfx=${file%.fasta}
    cat > ${pfx}.raxml_fullsnpslewis.sge.sh <<EOL
#!/bin/bash
#$ -cwd
#$ -N fullsnpslewis.${pfx}

date
module load bio/raxml-ng/0.5.1b

echo "running raxml-ng..."
raxml-ng --all --msa $file --model GTR+G+ASC_LEWIS --tree rand{10},pars{10} --threads 1 --prefix "${pfx}"

date
EOL
  done
  cd ..
done

date