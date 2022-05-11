""" Process CITE-Seq data """

""" 1 - preprocess will plot important QC metrics for data filtration """
""" 2 - integrate will find anchors and integrate all samples into an integrated seurat object """
""" 3 - cluster will cluster individual samples plus integrated object """
""" 4 - differential will test for DE genes in seurat objects """

import os
import sys
import time
import glob

configfile: "config/config.yaml"

SAMPLES = [ os.path.basename(i) for i in glob.glob("data/raw/*")]

def message(m):
	sys.stderr.write("|--- {} \n".format(m))

for i in SAMPLES:
	message("Samples to process: {}".format(i))

p = config["project_name"]

if not os.path.isdir("data/reports"):
	os.mkdir("data/reports")
if not os.path.isdir("data/rda"):
	os.mkdir("data/rda")

# snakemake -j 8 --use-conda --cluster-config cluster.yaml --profile slurm

rule all:
	input:
		# 1 - preprocess
		"data/reports/1-preprocess.html",
		"data/rda/preprocess.{project_name}.{date}.rds".format(project_name = p),
		# 2 - integrate
		# "data/reports/2-integrate.html",
		# "data/rda/integrate.{project_name}.{date}.rds".format(project_name = p),
		# 3 - cluster
		# "data/reports/3-cluster.html",
		# "data/rda/cluster.{project_name}.{date}.rds".format(project_name = p),
		# 4 - differential
		# "data/reports/4-differential.html"

rule preprocess:
	input:
		rmd = "scripts/1-preprocess.Rmd",
		samples = expand("data/raw/{sample}/outs/filtered_feature_bc_matrix", sample = SAMPLES)
	output:
		report = "data/reports/1-preprocess.html",
		rds = "data/rda/preprocess.{project_name}.rds".format(project_name = p)
	conda:
		"envs/seurat.yaml"
	log:
		"logs/1-preprocess.log"
	shell:
		"""
		Rscript -e 'rmarkdown::render( here::here("{input.rmd}"), output_file = here::here("{output.report}"), knit_root_dir = here::here(), envir = new.env(), params = list(input_samples = "{input.samples}", output_rds = "{output.rds}" ))' > {log} 2>&1
		"""

# knit rmarkdown report with multiple outputs workaround: https://github.com/snakemake/snakemake/issues/178
# how to use rmd params to specify input/output files:
# https://stackoverflow.com/questions/32479130/passing-parameters-to-r-markdown
# here::here() will turn a relative path absolute, and is required for rmarkdown I/O
