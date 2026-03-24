
#####################################################
#Specify config parameters for snakemake
####################################################
out_dir = config["out_dir"]
gwas_in_dir = config["gwas_in_dir"]
gwas_out_dir = config["gwas_out_dir"]
annotation_dir = config["annotation_dir"]
required_files = config["required_files"]
ldsc_dir = config["ldsc_dir"]

PHENOTYPES = config["phenotypes"].split()
ANNOTATIONS = config["annotations"].split()

CHRS = [str(i) for i in range(1, 23)]


#####################################################
#process the GWAS
####################################################


rule all:
    input:
        expand(
            f"{out_dir}/heritability_results/{{phenotype}}-{{annotation}}_s_model.results",
            phenotype=PHENOTYPES,
            annotation=ANNOTATIONS
        )


rule format_GWAS:
	input:
		snps=f"{required_files}/hg19_w_hm3.snplist",
		sumstats=lambda wc: f"{gwas_in_dir}/{wc.phenotype}.GRCh37.munged.LDSC.tsv.gz"
	output:
		sumstats=f"{gwas_out_dir}/{{phenotype}}.ldsc.sumstats.gz"
	params:
		ldsc_mungesumstats=f"{ldsc_dir}/munge_sumstats.py",
		output_prefix=lambda wc: f"{gwas_out_dir}/{wc.phenotype}.ldsc",
		sumstats_temp=lambda wc: f"{gwas_in_dir}/{wc.phenotype}.GRCh37.munged.LDSC.tsv"
	conda:
		"envs/ldsc39_environment.yml"
	shell:
		r"""
		set -euo pipefail

		zcat {input.sumstats} \
		> {params.sumstats_temp}

		echo "formatting summary statistics for {input.sumstats}"

		python {params.ldsc_mungesumstats} \
			--sumstats {params.sumstats_temp} \
			--merge-alleles {input.snps} \
			--chunksize 500000 \
			--signed-sumstats BETA,0 \
			--out {params.output_prefix}

		echo "{output.sumstats} written. removing tmp sumstats file {params.sumstats_temp}"

		rm {params.sumstats_temp}

		"""


rule generate_annotations:
	input:
		annotation=lambda wc: f"{annotation_dir}/{wc.annotation}.sorted.bed",
		bim=lambda wc:f"{required_files}/1000G_EUR_Phase3_plink/1000G.EUR.QC.{wc.chr}.bim"
	output:
		annot=f"{out_dir}/{{annotation}}.{{chr}}.annot.gz"
	params:
		makeannot=f"{ldsc_dir}/make_annot.py",
		annot_file=lambda wc: f"{out_dir}/{wc.annotation}.{wc.chr}.annot.gz"
	conda:
		"envs/ldsc39_environment.yml"
	shell:
		r"""
		set -euo pipefail
		
		echo "Generating annotations for {input.annotation}"

		python {params.makeannot} \
			--bed-file {input.annotation} \
			--bimfile {input.bim} \
			--annot-file {params.annot_file}
		"""


rule generate_ld_scores:
	input:
		annot_file=lambda wc: f"{out_dir}/{wc.annotation}.{wc.chr}.annot.gz",
		snps = f"{required_files}/hg19_w_hm3_snpids.txt"
	output:
		scores=f"{out_dir}/{{annotation}}.{{chr}}.l2.ldscore.gz",
		M=f"{out_dir}/{{annotation}}.{{chr}}.l2.M",
		M_5_50=f"{out_dir}/{{annotation}}.{{chr}}.l2.M_5_50"
	params:
		bfile=lambda wc: f"{required_files}/1000G_EUR_Phase3_plink/1000G.EUR.QC.{wc.chr}",
		ldsc=f"{ldsc_dir}/ldsc.py",
		out=lambda wc: f"{out_dir}/{wc.annotation}.{wc.chr}"
	conda:
		"envs/ldsc39_environment.yml"
	shell:
		r"""
		set -euo pipefail
		
		echo "Calculating ld_scores for {input.annot_file}"

		python {params.ldsc} \
			--l2 \
			--bfile {params.bfile} \
			--ld-wind-cm 1 \
			--annot {input.annot_file} \
			--thin-annot \
			--out {params.out} \
			--print-snps {input.snps}

		"""

rule single_annotation_score_regression:
	input:
		scores=lambda wc:expand(
			f"{out_dir}/{wc.annotation}.{{chr}}.l2.ldscore.gz",
			chr=CHRS),
		M=lambda wc:expand(
			f"{out_dir}/{wc.annotation}.{{chr}}.l2.M",
			chr=CHRS),
		M_5_50=lambda wc:expand(
			f"{out_dir}/{wc.annotation}.{{chr}}.l2.M_5_50",
			chr=CHRS),
		annot=lambda wc:expand(
			f"{out_dir}/{wc.annotation}.{{chr}}.annot.gz",
			chr=CHRS),
		sumstats= lambda wc: f"{gwas_out_dir}/{wc.phenotype}.ldsc.sumstats.gz",
	output:
		ldsc=f"{out_dir}/heritability_results/{{phenotype}}-{{annotation}}_s_model.results"
	params:
		annot=lambda wc: f"{out_dir}/{wc.annotation}.",
		weights=f"{required_files}/1000G_Phase3_weights_hm3_no_MHC/weights.hm3_noMHC.",
		frq=f"{required_files}/1000G_Phase3_frq/1000G.EUR.QC.",
		baseline_annot=f"{required_files}/1000G_Phase3_baselineLD_v2.2_ldscores/baselineLD.",
		output_prefix=lambda wc:f"{out_dir}/heritability_results/{wc.phenotype}-{wc.annotation}_s_model",
		ldsc=f"{ldsc_dir}/ldsc.py"
	conda:
		"envs/ldsc39_environment.yml"
	shell:
		r"""
		set -euo pipefail

		mkdir -p {out_dir}/heritability_results

		echo "Running single annotation model s-LDSC {params.annot} for {input.sumstats} accounting for {params.baseline_annot}"

		python {params.ldsc} \
			--h2 {input.sumstats} \
			--ref-ld-chr {params.baseline_annot},{params.annot} \
			--out {params.output_prefix} \
			--overlap-annot \
			--frqfile-chr {params.frq} \
			--w-ld-chr {params.weights} \
			--print-coefficients

		echo "LDSC analysis finished for {params.annot} and {input.sumstats}"
		"""
