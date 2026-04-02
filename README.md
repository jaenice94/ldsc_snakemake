# ldsc_snakemake
snakemake workflow for ld score regression analysis

Clone this repository as well as the github directory for python 3.9 compatible ldsc scripts: https://github.com/CBIIT/ldsc. This pipeline is based on https://github.com/bulik/LDSC.
```bash
git clone https://github.com/jaenice94/ldsc_snakemake.git
cd ldsc_snakemake
git clone -b ldsc39 https://github.com/CBIIT/ldsc.git
cd ldsc39/ldsc

mkdir -p required_files
cd required_files
```
Obtain required files, you will need: #can be found https://zenodo.org/records/10515792
- 1000G_EUR_Phase3_plink
- 1000G_Phase3_baselineLD_v2.2_ldscores
- 1000G_Phase3_frq
- 1000G_Phase3_weights_hm3_no_MHC
- hg19_w_hm3.snplist
- hg19_w_hm3_snpids.txt (a list of rsids generated from hg19_w_hm3.snplist)

You will also need GWAS summary statistics. I processed them with https://github.com/jaenice94/prscs/tree/main/GWAS_standardisation prior to feeding them into the snakemake workflow. You will need to ensure the effect/non-effect alleles are assigned correctly. The files listed here are in hg19, so your GWAS will also need to be in hg19 or lifted to hg19. Analyses in hg38 will require different files. 

You can either test your own annotations, these should be in .bed format in hg19, or use example bedfiles (e.g. obtained from https://github.com/nottalexi/VascEpigenDementia/tree/main/peaks/Consensus_peaks/H3K27Ac) 

To run snakemake you will need a environment with snakemake installed
```bash
conda env create -f workflow/envs/snakemake_env.yaml
conda activate snakemake_env
```

To test out if snakemake pipeline works, you can do a dry run:
```bash
snakemake -np #update to match configs in script
```

You can add the annotations you want to test and GWAS phenotypes you want to include similar to the provided example submission script. 
Specify all the paths in this script as well. Then submit the script. With the settings in the workflow, each annotation is tested for risk variant enrichment, while accounting for the baseline annotations (see https://github.com/bulik/ldsc/wiki for further information). 

```bash
sbatch submission_ldsc.sh
```

A simple script for visualisation in form of a heatmap is provided under visualisation/heatmap.Rmd

NOTE: I ran into one issue with ldsc.py - see here on how to fix it: https://github.com/bulik/ldsc/issues/435 

