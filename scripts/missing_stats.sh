#!/bin/bash

# script to calculate the percentage of missing characters
# call script: ./missing_stats.sh <dir> > missing_stats.csv
#
# parameters:
#   1. run_dir: directory containing the replicates
# output: (csv to stdout)
#   <replicate>,<perc_concat>,<perc_snps>,<perc_snps_reduced>

if [ $# -lt 1 ]; then
  echo "usage: $0 run_dir"
  exit 1
fi

export LC_NUMERIC="en_US.UTF-8"

for rep in $(ls -d */); do
  rep_id=$(basename $rep)
  total_cat=$(head -1 ${rep_id}/${rep_id}_concat_ado.phy | tr ' ' '*' | bc -l)
  total_snps=$(grep -v ">" ${rep_id}/${rep_id}_concat_ado_snps.fasta | wc | awk '{print $3-$1}')
  total_snps_red=$(grep -v ">" ${rep_id}/${rep_id}_concat_ado_snps_reduced.fasta | wc | awk '{print $3-$1}')
  missing_cat=$(tr -cd N < ${rep_id}/${rep_id}_concat_ado.phy | wc -c)
  missing_snps=$(tr -cd N < ${rep_id}/${rep_id}_concat_ado_snps.fasta | wc -c)
  missing_snps_red=$(tr -cd N < ${rep_id}/${rep_id}_concat_ado_snps_reduced.fasta | wc -c)
  pct_cat=$(echo "$missing_cat/$total_cat" | bc -l) 
  pct_snps=$(echo "$missing_snps/$total_snps" | bc -l)
  pct_snps_red=$(echo "$missing_snps_red/$total_snps_red" | bc -l)
  printf "%s,%0.4f,%0.4f,%0.4f\n" $rep_id $pct_cat $pct_snps $pct_snps_red
done

# verification for radsims_01/001
  # head -1 001_concat_ado.phy | tr ' ' '*' | bc -l ## 219675390
  # grep -v ">" 001_concat_ado_snps.fasta | wc | awk '{print $3-$1}' ## 49672998
  # grep -v ">" 001_concat_ado_snps_reduced.fasta | wc | awk '{print $3-$1}' ## 1658424
