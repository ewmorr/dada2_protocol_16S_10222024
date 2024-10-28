# Workflow for processing 16S or 18S reads to ASVs on the Premise server using dada2
### See https://benjjneb.github.io/dada2/tutorial.html for explanations of the ASV calling process and R code 
## software setup
If conda environments are not already installed on the user premise account install them as follows
```
module load anaconda/colsa

#dada2 env
conda create --name r-dada2_new --clone template
conda activate r-dada2_new
conda install bioconda::bioconductor-dada2
conda install r-dplyr
```

Then open R and check that dada2 is installed and loads. Open an R interpreter by typing a capital R on the command line
```
R
```
Once R is open you can run R commands as normal
```
library(dada2) #load dada2 
q(save="no") #exit R without saving
```
Once you have the environment set up you can run dada2 via slurm by setting up a slurm script to first activate the dada2 conda environment and then calling an R script using `Rscript` command. 

### Finally...
Also clone this git repo to your local directory
```
mkdir repo
cd repo
git clone https://github.com/ewmorr/dada2_protocol_16S_10222024
```

## Now we are ready to process sequences. 
You should set up a parent directory with some meaningful name to hold all of the work that will be done. Within this directory put the sequences in a subdirectory called 'reads' (you could call the reads dir whatever you want, but this part is hardcoded in the script so you would have to change that manually :) . For example: `test_run/reads`
```
mkdir test_run
cd test_run
mkdir reads
cp path_to/seqs/*fastq.gz ./reads
```
You can check the number of reads per sample.
```
for i in reads/*R1*fastq*
do(
    r1File=${i##*/}
    sample=${r1File%_S*} #you can change this to pick out a different part of the file
    numReads=$(echo $(zcat $i | wc -l) / 4 | bc)
    echo -e "$sample\t$numReads" >> reads_per_sample.txt
)
done
```

### Step 1. check primer/adapter orientation, remove adapters, and check quality
Run the first script. You pass the script to sbatch, and pass the name of your parent directory or "working directory" to the script as the first argument. The second argument should be one of `16S` or `18S`. The second argument determines whether the bacterial V4-V5 region primers (515f-926r) or the Earth Microbiome Project (Eukaryotic) 18S V9 primers are used in primer searches. 
```
sbatch ~/repo/dada2_protocol_16S_10222024/premise/1_dada2_workflow.primer_and_qual_checks.slurm test_run 16S
```
The script has written some initial quality checks to the `dada2_processing_tables_figs` directory. Download these and take a look. Note that we perform a hard length truncation in this step of both fwd and rev reads, at 220 bp for 16S and 125 bp for 18S (the 18S V9 region is shorter and we tend to see more quality tailing). You should inspect both the pre quality filtering and post quality filtering graphs to look for a drop in quality scores towards the end of the read. If the current length truncation does not seem adequate to trim the portion of the read with a length dependent drop in quality (if any) then the `truncLen` argument can be adjusted as necessary by adding the desired truncation length of the fwd and rev reads as the third and fourth arguments of the script, respectively. E.g., 
```
sbatch ~/repo/dada2_protocol_16S_10222024/premise/1_dada2_workflow.primer_and_qual_checks.slurm test_run 16S 210 200
```
See the examples [here](https://benjjneb.github.io/dada2/tutorial.html) for hints on setting the truncation length based on the quality profiles. Note that if a large number of reads are dropped at this step and there is significant quality tailing (as described above) it may be desirable to reduce truncLen in order to maintain more reads passing the maxEE filter (as mentioned in the dada2 tutorial).

### Step 2. Run the core dada2 algorithm

```
sbatch ~/repo/dada2_protocol_16S_10222024/premise/2_dada2_workflow.dada2.slurm test_run
```
Check `dada2_processing_tables_figs/read_processing_tracking.csv` for a breakdown of the number of reads remaining after each prcessing step. The primary outputs are in the folder `dada2_core`. The file `ASVs_counts.tsv` is the sample x ASV table, the file `ASVs.fa` contains the representative sequences of the ASVs, and the file `asv_lens.csv` contains the frequency distribution of lengths of the ASVs (may be useful as a sanity check).

### Step 3. Taxonomic classification. 
The first argument is again your working directory. The second argument should be one of `16S`, `18S-eukaryome` or `18S-PR2`. This argument determines whether the [SILVA v138 bacterial SSU database](https://benjjneb.github.io/dada2/training.html), [EUKARYOME SSU v1.9](https://eukaryome.org), or the [PR2 v5.0 SSU database](https://github.com/pr2database/pr2database/releases) is used as the reference for taxnomic ID. The EUKARYOME database is preferred for 18S data as the database is more comprehensive and the taxonomy is both more accurate and easier to interpret, but the PR2 database may be useful for comparison. There are other databases available that may be of interest, but these are a good start.
```
sbatch ~/repo/dada2_protocol_16S_10222024/premise/3_dada2_workflow.taxonomic_id.slurm test_run 16S
```
The file `ASVs_taxonomy.tsv` within the `dada2_core` folder contains the ASV taxonomic assignment and the file `ASVs_taxonomy_bootstrapVals.tsv` contains the bootstrap confidence scores of the taxonomic assignments.
