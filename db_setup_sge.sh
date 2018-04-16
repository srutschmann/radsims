#!/bin/bash
#$ -cwd
#$ -N db_setup

# call script: db_setup.sh

BINDIR="/home/sereina/simulation/radsims_60/scripts"
DB="/home/sereina/simulation/radsims_60/radsims.db"

module load sqlite/3.8.8.2

date
set -e

echo "creating DB... \"$DB\""
sqlite3 $DB < ${BINDIR}/create_schema.sql

# loop over runs
for run_folder in radsims_*; do
  id_run="${run_folder#radsims_}"

  echo "processing run '$run_folder...'"
  echo "exporting csv files from SimPhy db..."
  echo ".mode csv
.headers on
select * from Species_Trees;
" | sqlite3 $run_folder/SimPhy_radsims.db > $run_folder/s_trees.csv
  echo ".mode csv
.headers on
select * from Gene_Trees;
" | sqlite3 $run_folder/SimPhy_radsims.db > $run_folder/g_trees.csv

  # prepare csv files for DB import
  # remove column headers, add run-IDs
  tail -n+2 $run_folder/s_trees.csv | perl -sne 'print "$r,$_"' -- -r=$id_run > s_trees.db.csv
  tail -n+2 $run_folder/g_trees.csv | perl -sne 'print "$r,$_"' -- -r=$id_run > g_trees.db.csv
  cat $run_folder/missing_stats.csv | perl -sne 'print "$r,$_"' -- -r=$id_run >> missing_stats.db.csv
  if [[ -f $run_folder/rf_stats.csv ]]; then
    cat $run_folder/rf_stats.csv | perl -sne 'print "$r,$_"' -- -r=$id_run >> rf_stats.db.csv
  else
  touch rf_stats.db.csv
  fi
  # concatenate alignment stats
  > concat_stats.db.csv
  > concat_ado_stats.db.csv
  for species_folder in $(ls -d $run_folder/*/); do
    id_species=$(basename $species_folder)
    cat ${species_folder}/concat_stats.csv | perl -sne '/^data_(\d+)_TRUE.phy,(.+)$/ && print "$r_id,$s_id,$1,$2\n"' -- -r_id=$id_run -s_id=$id_species >> concat_stats.db.csv
    cat ${species_folder}/concat_ado_stats.csv | perl -sne '/^data_(\d+).ado.phy,(.+)$/ && print "$r_id,$s_id,$1,$2\n"' -- -r_id=$id_run -s_id=$id_species >> concat_ado_stats.db.csv
  done

  # aggregate alignment stats (mean, min, max)
  cat concat_stats.db.csv | awk -F, -v OFS=, -f scripts/concat_stats.mean.awk > concat_stats_agg.db.csv
  # aggregate alignment ado stats (mean, min, max)
  cat concat_ado_stats.db.csv | awk -F, -v OFS=, -f scripts/concat_ado_stats.mean.awk > concat_ado_stats_agg.db.csv
  # aggregate gene tree stats (mean, min, max)
  cat g_trees.db.csv | awk -F, -v OFS=, -f scripts/g_trees.mean.awk > g_trees_agg.db.csv # includes weird characters!

  echo "creating record for run $id_run..."
  sqlite3 $DB "INSERT INTO runs VALUES($id_run);"

  echo "importing csv files..."
  # species tree data
  sqlite3 $DB <<"EOF"
.mode csv
.import s_trees.db.csv species_trees
EOF

  # gene tree data
  sqlite3 $DB <<"EOF"
.mode csv
.import g_trees.db.csv gene_trees
EOF

  # gene tree aggregated data
  sqlite3 $DB <<"EOF"
.mode csv
.import g_trees_agg.db.csv gene_trees_agg
EOF

  # alignment data
  sqlite3 $DB <<"EOF"
.mode csv
.import concat_stats.db.csv concat_stats
EOF
  sqlite3 $DB <<"EOF"
.mode csv
.import concat_stats_agg.db.csv concat_stats_agg
EOF

  # alignment aggregated data
  sqlite3 $DB <<"EOF"
.mode csv
.import concat_ado_stats.db.csv concat_ado_stats
EOF
  sqlite3 $DB <<"EOF"
.mode csv
.import concat_ado_stats_agg.db.csv concat_ado_stats_agg
EOF

  # missing stats
  sqlite3 $DB <<"EOF"
.mode csv
.import missing_stats.db.csv missing_stats
EOF

  # rf stats 
  sqlite3 $DB <<"EOF"
.mode csv
.import rf_stats.db.csv rf_stats
EOF


done


  # svdq stats: PAUP version, runtime, (in)compatible quartets
  sqlite3 $DB <<"EOF"
.mode csv
.import svdq_stats.db.csv svdq_stats
EOF

echo "all data imported. cleaning up temporary files..."
rm concat_*.db.csv
rm g_trees*.csv
rm s_trees*.csv

date
