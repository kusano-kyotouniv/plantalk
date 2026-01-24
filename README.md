# plantalk
A tiny gene ontology (GO) analysis tool

A tool to process transcriptome data into a list of GO term and the expression ratio average.

Usage: 

perl plantalk.pl 
  --geneseq [trinity output]
  --proteinseq [transdecoder output]
  --annotation [eggNOG output]
  --geneontology go-basic.obo
  --expression [salmon output]
  --experimentals [sample number and/or sample names]
  --controls [sample number and/or sample names]
  --output [output directory] (optional)
  -show_sample_names (optional)
  --max_genes [float] (optional: 0.03 default)
  --min_genes [int] (optional: 4 default)

Requires:

Any libraries are NOT required to run the plantalk.pl, may run in most of default environment of perl.

Required Input Files:

plantalk.pl assumes to work in a de novo transcriptiome analysis composed of trinity, transdecoder, salmon, eggNOG mapper.

1) nucleotide sequence data with contig name in Trinity output format (Trinity.fasta, representative)
2) protein sequence data in transdecoder output format (prefix.transdecoder.pep, representative)
3) annotation data, eggNOG mapper output (prefix.emapper.annotations, representative)
4) gene ontology file (go-basic.obo) provided by Gene Ontology Resource https://geneontology.org/
5) expression analysis data containing experimental and control samples, representatively salmon merge format
  containing experimental and control samples, in a pair at least.

Output:

GOlofFC_sorted.txt
  may contain a list of GO term and average expression ratio of genes with the GO term in log(foldchange).

effective_genes.fasta
  may contain a non-redundant nucleotide sequence data, to run plantalk.pl again with a new salmon result using this non-redundant inputs, for better result. In the de novo transcriptome analysis, this re-analysis is strongly recommened because the contig redundancy in a gene may affect the count of GO assignments without any biological meanings.

Installation:

Only download and put plantalk.pl in your working directory and run with required options.

Required Options:

--geneseq [trinity output]
  nucleotide sequence data in fasta format with trinity contig name format.
  example contig name is like: abcde12345_c0_g1_i2
  
--proteinseq [transdecoder output]
  amino acid sequence data in fasta format with transdecoder protein name format.
  example protein name is like: abcde12345_c1_g0_i4_p2

--annotation [eggNOG output]
  eggNOG mapper output.
  example file name is like: prefix.emapper.annotations

--geneontology go-basic.obo
  go-basic.obo is provided by Gene Ontology Resource (https://geneontology.org/).
  You can download go-basic.obo from the website.

--expression [salmon output]
  "salmon quantmerge --column TPM" output.
  The order and the name of samples provided in the "--quants" field of salmon quantmerge is acceptable in --experimentals and --controls fields.
  
--experimentals [sample number and/or sample names]
--controls [sample number and/or sample names]
  The order number and the name of samples provided in the "--quants" field of salmon quantmerge.
  example: --experimtnals 1 2 3 stimulated4 --controls 9 10 11 control5 placebo6 

Optional Options.

-show_sample_names (optional)
  to show sample numbers and/or names of samples applicable in --experimentals and --controls fields.
  The successfully selected samples are marked with asterisks.

--output [output directory]
  to set another directory name to output the result files.
  The default directory name is "plantalk_result".

--max_genes [float] (optional: 0.03 default)
  to exclude GO terms assigned to too many contigs (genes). 
  The default 0.03 means GOs assigned over 3% of total contigs (genes) are excluded.

--min_genes [int] (optional: 4 default)
  to exclude GO terms assigned to too few contigs (genes).
  The default 4 means GOs assigned less than 4 contigs (genes) are excluded.

