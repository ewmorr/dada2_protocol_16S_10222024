#!/bin/bash
#SBATCH --ntasks=1
#SBATCH --job-name="dada2"
#SBATCH --output=dada2_workflow.primer_qual_check.out
#SBATCH --partition=shared

module purge
module load anaconda/colsa
conda activate r-dada2_new

workDir=$HOME/$1
locus=$2

cd $workDir

#Run first R scripts
Rscript ~/repo/dada2_protocol_16S_10222024/sequence_processing_and_dada2/1_dada2_primer_check.r $workDir $locus

mkdir $workDir/cutadapt

if [[ $locus == "16S" ]]; then
    #primers for bacterial 16S V4-V5 region
    #fwd primer (515F)
    fwd=GTGYCAGCMGCCGCGGTAA
    #fwd.rc
    fwdRC=TTACCGCGGCKGCTGRCAC
    #rev (926R)
    rev=CCGYCAATTYMTTTRAGTTT
    #rev.rc
    revRC=AAACTYAAAKRAATTGRCGG
    
    if [[ -n $3 -a -n $4 ]]; then
        fwdTrunc=$3
        revTrunc=$4
    else
        fwdTrunc=220
        revTrunc=220
    fi
    
elif [[ $locus == "18S" ]]; then
    #primers for euk 18S V9 region. Note that we changed the fwd and rev because it appears they were sequenced backwards (Jeff H contructs)
    #fwd primer 18s-Euk_1391f
    rev=GTACACACCGCCCGTC
    #fwd.rc
    revRC=GACGGGCGGTGTGTAC
    #rev 18s-Euk_r (earth microbiome project)
    fwd=TGATCCTTCTGCAGGTTCACCTAC
    #rev.rc
    fwdRC=GTAGGTGAACCTGCAGAAGGATCA
    
    if [[ -n $3 -a -n $4 ]]; then
        fwdTrunc=$3
        revTrunc=$4
    else
        fwdTrunc=200
        revTrunc=200
    fi

else
    echo "Unrecognized locus. Please input either 16S or 18S as the second argument"
    exit 1
fi

echo "Locus is set to $locus. FWD read truncation length is $fwdTrunc. REV read truncation length is $revTrunc."

# It is not strictly necessary to trim based on RC of primer bc we perform a hard length truncation.
# However, there does not seem to be a downside (except possibly run time).
# Sometimes primer artifacts occur during the second PCR step. Therefore we still include the RC trim step.
for i in filtN/*R1*
do(

    dir=${i%/*}
    r1File=${i##*/}
    pre=${r1File%R1*}
    post=${r1File##*R1}
    r2File=${pre}R2${post}

    cutadapt -g $fwd -a $revRC \
        -G $rev -A $fwdRC \
        -m 50 -n 2 \
        -o cutadapt/$r1File -p cutadapt/$r2File \
        $dir/$r1File $dir/$r2File
)
done

Rscript ~/repo/dada2_protocol_16S_10222024/sequence_processing_and_dada2/2_post_cutadapt_primer_check_qual_filter.r $workDir $locus $fwdTrunc $revTrunc
#this is a good place to stop to check primer orientation and quality profiles

