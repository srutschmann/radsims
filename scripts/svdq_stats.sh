#!/bin/bash

# script to extract details about SVDQuartet runs
BINDIR="$HOME/simulation/radsims_60/scripts"

# check command line args
if [[ $# < 1 ]]; then
  (>&2 echo)
  (>&2 echo "Usage: $9 /path/to/radsims/run > svdq_stats.csv")
  (>&2 echo)
  exit 1
fi

# make sure run directory exists
rundir=$1
if [[ ! -d "$rundir" ]]; then
  (>&2 echo "[ERROR] Directory does not exist: $rundir")
  exit 1
fi

cd $rundir
rundir=$(basename $rundir)
id_run="${rundir#radsims_}"
# list all replicate folders in run
find -maxdepth 1 -type d -name "???" | while read -r repdir; do
  id_rep=$(basename $repdir)
  cd $repdir

  stats_concat="NULL,NULL,NULL,NULL"
  stats_ado="NULL,NULL,NULL" 
  stats_ado_snps="NULL,NULL,NULL,NULL"
  stats_ado_snps_red="NULL,NULL,NULL,NULL"
  stats_snps="NULL,NULL,NULL,NULL"
  stats_snps_red="NULL,NULL,NULL,NULL"

  # extract stats for concatenated alignments
  if [[ -f "${repdir}_concat.svdq.log" ]]; then
    fn=$(ls ???_concat.svdq.log)
    stats_concat=$(bash $BINDIR/svdq_stats.parse_log.sh $fn)
    stats_concat=${stats_concat:-"NULL,NULL,NULL,NULL"}
  fi
  
  # extract stats for concatenated alignments + ADO
  if [[ -f "${repdir}_concat_ado.svdq.log" ]]; then
    fn=$(ls ???_concat_ado.svdq.log)
    stats_ado=$(bash $BINDIR/svdq_stats.parse_log.sh $fn)
    stats_ado=${stats_ado:-"NULL,NULL,NULL,NULL"}
  fi

  # extract stats for ADO + SNPs
  if [[ -f "${repdir}_concat_ado_snps.svdq.log" ]]; then
    fn=$(ls ???_concat_ado_snps.svdq.log)
    stats_ado_snps=$(bash $BINDIR/svdq_stats.parse_log.sh $fn)
    stats_ado_snps=${stats_ado_snps:-"NULL,NULL,NULL,NULL"}    
  fi

  # extract stats for ADO + SNPs + reduced
  if [[ -f "${repdir}_concat_ado_snps_reduced.svdq.log" ]]; then
    fn=$(ls ???_concat_ado_snps_reduced.svdq.log)
    stats_ado_snps_red=$(bash $BINDIR/svdq_stats.parse_log.sh $fn)
    stats_ado_snps_red=${stats_ado_snps_red:-"NULL,NULL,NULL,NULL"}    
  fi

  # extract stats for SNPs
  if [[ -f "${repdir}_concat_snps.svdq.log" ]]; then
    fn=$(ls ???_concat_snps.svdq.log)
    stats_snps=$(bash $BINDIR/svdq_stats.parse_log.sh $fn)
    stats_snps=${stats_snps:-"NULL,NULL,NULL,NULL"}    
  fi

 # extract stats for SNPs + reduced
  if [[ -f "${repdir}_concat_snps_reduced.svdq.log" ]]; then
    fn=$(ls ???_concat_snps_reduced.svdq.log)
    stats_snps_red=$(bash $BINDIR/svdq_stats.parse_log.sh $fn)
    stats_snps_red=${stats_snps_red:-"NULL,NULL,NULL,NULL"}    
  fi

  printf "%s,%s,%s,%s,%s,%s,%s,%s\n" $id_run $id_rep "$stats_concat" "$stats_ado" "$stats_ado_snps" "$stats_ado_snps_red" "$stats_snps" "$stats_snps_red"
  cd ..
done
