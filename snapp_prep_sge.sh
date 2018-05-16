#!/bin/bash
#$ -cwd
#$ -N snapp

# script to generate input and job files for SNAPP
# call script: snapp_prep.sh <folder>

# settings
cores=8

date
cd $1

echo "preparing SNAPP input files and job scripts..."
for folder in $(ls -d */); do
  echo "  ${folder}"
  cd $folder
  for file in *snps_reduced.nex; do
    pfx=${file%.nex}
  cat > ${pfx}.snapp.sge.sh <<EOL
#!/bin/bash
#$ -cwd
#$ -N snap.${pfx}
#$ -j y
#$ -S /bin/bash
#$ -q "compute-0-x.q,compute-1-x.q,compute-2-x.q"
#$ -pe pe_8p 8

# load required modules
module load java/jdk/1.8.0_31
module load cuda/6.5.14
module load opencl/amd/sdk/2.9.1
module load bio/beagle/opencl/2.1.2
module unload opencl/amd/sdk/2.9.1
module load bio/beast/2.4.7

# if state file present: resume job
resume=""
if [[ -f ${pfx}.snapp.xml.state ]]; then
  resume="-resume -overwrite"
fi

hostname
date

echo "running SNAPP..."
echo "  beast \${resume} -threads ${cores} -beagle -beagle_CPU ${pfx}.snapp.xml"

beast \${resume} -threads ${cores} -beagle -beagle_CPU ${pfx}.snapp.xml

date
EOL

  #bash ${pfx}.snapp.sh # CAUTION: uncomment this line to run job in background
  #qsub ${pfx}.snapp.sh # CAUTION: uncomment this line to submit jobs to cluster queue, check number of jobs that can be submitted
  done
  cd ..
done

date

