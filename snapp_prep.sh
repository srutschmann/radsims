#!/bin/bash
#SBATCH -N 1 # 1 node
#SBATCH -n 1 # 1 job
#SBATCH -c 1 # 1 core
#SBATCH --mem 20480
#SBATCH -t 24:00:00

# script to generate input and job files for SNAPP
# call script: snapp_prep.sh <folder>

# settings
SCRIPTS=/mnt/lustre/scratch/home/uvi/be/sru/simulation/scripts
CONF=/mnt/lustre/scratch/home/uvi/be/sru/simulation/conf_files
cores=20
mem=24000
runtime="100:00:00"
queue="shared"
qos="shared"

date
cd $1

module load biopython

echo "preparing SNAPP input files and job scripts..."
for folder in $(ls -d */); do
# for folder in $(seq -f "%03g" 6 10); do # # to process some replicates i.e., 6-10
  echo "  ${folder}"
  cd $folder
  for file in *snps_reduced.nex; do
    #ntax=$(perl -ne '/ntax=(\d+)/&&print $1' $file) # get number of taxa from NEXUS file
    pfx=${file%.nex} # remove ".nex" suffix from file names, use this prefix to generate output filenames

  # generate SNAPP XML file ($pfx.snapp.xml)
  # echo "    ${SCRIPTS}/nex2snapp.py ${file} ${pfx}.snapp.xml ${CONF}/snapp.xml.template.txt 1>/dev/null"
  ${SCRIPTS}/nex2snapp.py ${file} ${pfx}.snapp.xml ${CONF}/snapp.xml.template.txt 1>/dev/null

  # generate SGE job file
  cat > ${pfx}.snapp.sh <<EOL
#!/bin/bash
#SBATCH -J snap.${pfx}
#SBATCH -N 1
#SBATCH -n 1
#SBATCH -c ${cores}
#SBATCH --mem ${mem}
#SBATCH -t ${runtime}
#SBATCH -p ${queue}
#SBATCH --qos ${qos}


# load required modules
module load beast2/2.4.7
module load gcc/5.3.0
module load beagle-lib
#addonmanager -add SNAPP

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
  #sbatch ${pfx}.snapp.sh # CAUTION: uncomment this line to submit jobs to cluster queue, check number of jobs that can be submitted
  done
  cd ..
done

date

