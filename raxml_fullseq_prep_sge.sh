#!/bin/bash
#$ -cwd
#$ -N raxml-ng

# script to generate raxml-ng job files
# call script: raxml_fullseq_prep_sge.sh <folder> 2>&1 | tee <folder>.raxml_fullseq.log

BINDIR=/home/sereina/simulation/radsims_60/scripts

date
cd $1

echo "preparing raxml job files..."
for folder in $(ls -d */); do
  echo "  $folder"
  cd $folder
  for file in *_concat*.phy; do
    pfx=${file%.phy}
    cat > ${pfx}.raxml_fullseq.sge.sh <<EOL
#!/bin/bash
#$ -cwd
#$ -N raxml_fullseq.${pfx}

date
module load bio/raxml-ng/0.5.1b

echo "running raxml-ng..."
raxml-ng --all --msa $file --model GTR+G --tree rand{10} --threads 1 --prefix "${pfx}"

date
EOL
  done
  cd ..
done

date