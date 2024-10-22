#!/bin/bash
#SBATCH --ntasks=1
#SBATCH --job-name="dada2"
#SBATCH --output=dada2_workflow.taxonomic_id.out
#SBATCH --partition=shared

module purge
module load anaconda/colsa
conda activate r-dada2_new

workDir=$HOME/$1
cd $workDir

indir=$workdir/itsxpress_out
outdir=$workdir/dada2_core


Rscript ~/repo/dada2_protocol_16S_10222024/sequence_processing_and_dada2/4_SILVA_taxonomic_classification.r $workDir/dada2_core/dada2_seq_table_no_chim.rds $workDir/dada2_core /mnt/home/garnas/ewj4/blast_dbs/silva_nr99_v138.1_train_set.fa


