#!/bin/bash
#
# Submits SVDquartet jobs in given run folder.
# Will not run jobs that have already run (checks presence of *.tre file).
# Additional parameters:
#  - queue_name (only jobs configured for this queue will be submitted)
#  - min_replicate (minimum of replicate range to consider, default: 1)
#  - max_replicate (maximum of replicate range to consider, default: 200)
dryrun=false

usage() {
  echo "Usage: $0 [-d] [-q queue_name] [-l min_repl] [-u max_repl] run_dir" 1>&2; 
  echo "       use option '-d' for a dry run (just report, do not actually start jobs)"
  exit 1;
}

# default values for command line opts
QUEUE="thin\-shared|shared|fatnode"
MINREP=1
MAXREP=200

# get command line opts
options='dhl:q:u:'
while getopts $options option
do
    case $option in
        d  ) dryrun=true;;
        q  ) QUEUE=${OPTARG};;
        l  ) MINREP=${OPTARG};;
        u  ) MAXREP=${OPTARG};;
        h  ) usage; exit;;
        \? ) echo "Unknown option: -$OPTARG" >&2; exit 1;;
        :  ) echo "Missing option argument for -$OPTARG" >&2; exit 1;;
        *  ) echo "Unimplemented option: -$OPTARG" >&2; exit 1;;
    esac
done

# get positional arguments
RUNDIR=${@:$OPTIND:1}

if ! [[ -d $RUNDIR ]]; then
  echo "directory does not exist: $RUNDIR" >&2
  exit 1
fi

printf "Looking for submittable jobs\n"
printf "\tdirectory:\t%s\n" ${RUNDIR}
printf "\tsubmit queue:\t%s\n" ${QUEUE}
printf "\treplicates:\t%d-%d\n" ${MINREP} ${MAXREP}
printf "\n"

cd ${RUNDIR}
for r in $(seq -f "%03g" ${MINREP} ${MAXREP}); do
  cd $r

  # check if output tree is present
  if [[ ! -f ${r}_concat_ado_snps_reduced.svdq.tre ]]; then
    #echo "$r: ADO tree missing"
    if grep -Pq "SBATCH -p ${QUEUE}$" ${r}_concat_ado_snps_reduced.svdq.sh; then
      q=$(perl -ne '/SBATCH -p (\S+)/ && print "$1"' ${r}_concat_ado_snps_reduced.svdq.sh)
      echo "submit: ${r}_concat_ado_snps_reduced.svdq.sh to '$q'"
      if ! $dryrun; then
        sbatch ${r}_concat_ado_snps_reduced.svdq.sh
      fi
    fi
  fi

  # check if output tree is present
  if [[ ! -f ${r}_concat_snps_reduced.svdq.tre ]]; then
    #echo "$r: ADO tree missing"
    if grep -Pq "SBATCH -p ${QUEUE}$" ${r}_concat_snps_reduced.svdq.sh; then
      q=$(perl -ne '/SBATCH -p (\S+)/ && print "$1"' ${r}_concat_snps_reduced.svdq.sh)
      echo "submit: ${r}_concat_snps_reduced.svdq.sh to '$q'"
      if ! $dryrun; then
        sbatch ${r}_concat_snps_reduced.svdq.sh
      fi
    fi
  fi

  cd ..
done
