#!/bin/bash
#$ -cwd
#$ -N snapp

# script to generate input and job files for SNAPP (adjusted from SLURM file, only generates job file)
# call script: snapp_prep.sh <folder>

# settings
# SCRIPTS=/mnt/lustre/scratch/home/uvi/be/sru/simulation/scripts
# CONF=/mnt/lustre/scratch/home/uvi/be/sru/simulation/conf_files
cores=8
# mem=24000
# runtime="100:00:00"
# queue="shared"
# qos="shared"

date
cd $1

# module load biopython

echo "preparing SNAPP input files and job scripts..."
# for folder in $(ls -d */); do
for folder in $(seq -f "%03g" 1 2); do # # to process some replicates i.e., 6-10
  echo "  ${folder}"
  cd $folder
  for file in *snps_reduced.nex; do
    #ntax=$(perl -ne '/ntax=(\d+)/&&print $1' $file) # get number of taxa from NEXUS file
    pfx=${file%.nex} # remove ".nex" suffix from file names, use this prefix to generate output filenames

  # generate SNAPP XML file ($pfx.snapp.xml)
  # echo "    ${SCRIPTS}/nex2snapp.py ${file} ${pfx}.snapp.xml ${CONF}/snapp.xml.template.txt 1>/dev/null"
  # ${SCRIPTS}/nex2snapp.py ${file} ${pfx}.snapp.xml ${CONF}/snapp.xml.template.txt 1>/dev/null

  # generate SGE job file
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
  resume="-resume"
fi

hostname
date

echo "running SNAPP..."
echo "  beast ${resume} -threads ${cores} -beagle -beagle_CPU ${pfx}.snapp.xml"

beast ${resume} -threads ${cores} -beagle -beagle_CPU ${pfx}.snapp.xml

date
EOL

  #bash ${pfx}.snapp.sh # CAUTION: uncomment this line to run job in background
  #qsub ${pfx}.snapp.sh # CAUTION: uncomment this line to submit jobs to cluster queue, check number of jobs that can be submitted
  done
  cd ..
done

date

