#!/bin/bash
#$ -cwd
#$ -N raxml-ng

# script to generate raxml-ng job files
# call script: raxml_fullsnpsstam_prep_sge.sh <folder> 2>&1 | tee <folder>.raxml_fullsnpsstam.log

BINDIR=/home/sereina/simulation/radsims_60/scripts

python/3.6.3

date
cd $1

echo "preparing raxml job files..."
# for folder in $(ls -d */); do
for folder in $(seq -f "%03g" 001 002); do
  echo "  $folder"
  cd $folder
  for file in *_concat{_ado,}.nex; do
    pfx=${file%.nex}
    nuc=$(python3 $BINDIR/invariant_sites.py $file)
    echo "${nuc}" > ${pfx}_nuc_cnts.txt
    file=${pfx}_snps.fasta
    cat > ${pfx}.raxml_fullsnpsstam.sge.sh <<EOL
#!/bin/bash
#$ -cwd
#$ -N fullsnpsstam.${pfx}

date
module load bio/raxml-ng/0.5.1b

echo "running raxml-ng..."
raxml-ng --all --msa $file GTR+G+ASC_STAM{${nuc}} --tree rand{10} --threads 1 --prefix "${pfx}"

date
EOL
  done
cd ..
done

date
