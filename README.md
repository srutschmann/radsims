# radsims
Simulation study on the performance of species tree estimation

This repository contains all the scripts used for the simulation of RAD-seq data, species tree estimation, and post-analyses.

## RAD-seq simulation
1) Species and locus tree simulation
2) Sequence simulation and allelic dropout

## Species tree estimation
1) Concatenation-based maximum likelihood inference
2) Coalescent-based species tree estimation
3) Coalescent-based summary species tree estimation

## Post-analyses
1) Comparison of tree topologies

*Note that this respository is currently under construction. Please feel free to drop me a message if you encounter any question/issue.*

## Structure of project
Overview of scripts used to run the simulation, phylogenetic inferences, and post-analyses, including platform in brackets.

### simulate data (SLURM)
./simulation.sh <id>

### get stats and create job scripts for phylogenetic inferences (SLURM and SGE)
./raxml_fullseq_sge.sh <id>
./snapp_prep_sge.sh <id>
./snapp_prep.sh <id>
./svdq_prep_sge_all.sh <id>
./svdq_prep_sge.sh <id>
./svdq_prep.sh <id>
./svdq_start_jobs.extra-long.sh
./svdq_start_jobs.sh

### get stats (SGE)
./stats_sge.sh
./db_setup_sge.sh

### remove redundant files (SGE)
./organizing_sge.sh <id>

### plot stats (locally using radsims.db)
.Rmd scripts