#!/bin/bash
#SBATCH --job-name=LDSC
#SBATCH --output=logs/LDSC.%j.log
#SBATCH --partition=intelsr_medium
#SBATCH --time=12:00:00
#SBATCH --cpus-per-task=8
#SBATCH --mem=128G


#load ldsc environment - this might differ by HPC
module load Miniforge3
source ~/.bashrc
conda deactivate 2>/dev/null || true

#activate conda environment - this might differ by HPC 
conda activate /home/user/.conda/envs/snakemake_env 

#phenotypes prefixes; process your GWAS with GWAS Standardisation pipeline
phenotypes=(
	ADHD2022
	ASD2019
	BIP2019
	) 

#annotations to use (baseline annotations will always be included); 
#you can generate annotations based on gene locations, or directly use peaks from e.g. ATAC-seq
#annotations need to be sorted by chromosome/bp - provide name of annotation file without the .sorted.bed 

annotations=(
	neun_resected_pm_hg19_all.breaking_peaks.v2
	rfx4_resected_pm_hg19_all.breaking_peaks.v2
	olig2_resected_pm_hg19_all.breaking_peaks.v2
	pu1_resected_pm_hg19_all.breaking_peaks.v2
	)

#specify paths
ldsc_dir="ldsc39/ldsc" #dir which contains LDSC scripts
gwas_in_dir="gwas_directory_path" #input directory for formatted gwas (GWAS-standardised)
gwas_out_dir="gwas_directory_path/s-ldsc" #where munge_sumstats.py should output the formatted GWAS
out_dir="results_directory" #where to output ldsc results
annotation_dir="annotations_dir" #where your bed files are
required_files="${ldsc_dir}/required_files" #directory containing supplementary files for LDSC (see README)


#########################################################
#leave the rest as it is
#########################################################


SNAKEFILE="${SNAKEFILE:-workflow/Snakefile_ldsc.smk}"

snakemake \
  -s "$SNAKEFILE" \
  --config \
  	out_dir="$out_dir" \
  	gwas_in_dir="$gwas_in_dir" \
  	gwas_out_dir="$gwas_out_dir" \
  	annotation_dir="$annotation_dir" \
  	required_files="$required_files" \
  	ldsc_dir="$ldsc_dir" \
  	phenotypes="${phenotypes[*]}" \
  	annotations="${annotations[*]}" \
  --use-conda \
  --conda-frontend conda \
  --cores "$SLURM_CPUS_PER_TASK" \
  --printshellcmds

