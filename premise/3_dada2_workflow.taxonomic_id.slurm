#!/bin/bash
#SBATCH --ntasks=1
#SBATCH --job-name="dada2"
#SBATCH --output=dada2_workflow.taxonomic_id.out
#SBATCH --partition=shared

module purge
module load anaconda/colsa
conda activate r-dada2_new

workDir=$HOME/$1
locus=$2

if [[ $locus == "16S" ]]; then
    db="/mnt/home/garnas/ewj4/blast_dbs/silva_nr99_v138.1_train_set.fa"
#elif [[ $locus == "18S" ]]; then
#    db="/mnt/home/garnas/ewj4/blast_dbs/eukaryome_General_EUK_SSU_v1.9.fasta"
elif [[ $locus == "18S" ]]; then
    db="/mnt/home/garnas/ewj4/blast_dbs/pr2_version_5.0.0_SSU_dada2.fasta"
#elif [[ $locus == "all" ]]; then
#    db="/mnt/home/garnas/ewj4/blast_dbs/combined_silva_v138-eukaryome_ssu_v1.9.fasta";
elif [[ $locus == "18S-unite" ]]; then
    db="/mnt/home/garnas/ewj4/blast_dbs/unite_07252023/sh_general_release_dynamic_singletons_allEuk_25.07.2023.fasta";
else
    echo "Unrecognized locus. Please input 16S, 18S, or all as the second argument"
    exit 1
fi

cd $workDir
Rscript ~/repo/dada2_protocol_16S_10222024/sequence_processing_and_dada2/4_taxonomic_classification.r $workDir/dada2_core/dada2_seq_table_no_chim.rds $workDir/dada2_core $db


