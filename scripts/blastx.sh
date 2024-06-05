#!/bin/bash
#working with Doron et al. 2016 paper 
#genomes: syn- WH7803, WH8102 and WH8109 pro - NATL2A
#WH8109 ncbi accession no. CP006882


#working with only WH8109
WORKDIR=$(echo '../data') #will be scripts dir
CYCOGBLASTDIR=$(echo '../data/cycog6')
GENOMENAME=$(echo 'WH8109')

cd ${WORKDIR}/blastoutput

#making FASTA file of WH1809 coding sequece

cat ${WORKDIR}/WH8109sequence.txt | sed -r 's/^>.+locus_tag=/>/' | sed 's/[]] .+$//' > ${WORKDIR}/${GENOMENAME}.cds.fna  

#making sure blastx biocontainer is installed
if [! '../containers/blastx.sif'];
    then
    cd ../containers
    singularity build blastx.sif docker://quay.io/biocontainers/blast:2.14.1--pl5321h6f7f691_0
    cd ../scripts

#Find cycog6 matches for each WH8109
singularity exec --no-home --bind ../:Viral_response ../containers/blastx.sif \
    blastx -db ${CYCOGBLASTDIR} -query ${WORKDIR}/${GENOMENAME}.cds.fna  \
    -out ${WORKDIR}/${GENOMENAME}_blastx_cycog6.out
    -evalue 0.001 \
    -num_threads 20 \
    -outfmt "6 qseqid sseqid evalue bitscore pident qcovs qcovhsp"
#retaining best hits
cat ${WORKDIR}/${GENOMENAME}_blastx_cycog6.out | awk - F "\t" '!seen[$1]++' > ${WORKDIR}/${GENOMENAME}_blastx_cycog6_tophit.out 

#table of legacy genome tags and best Cycog ID match
cat ${WORKDIR}/${GENOMENAME}_blastx_cycog6_tophit.out | awk 'BEGIN {FS="\t"} ; {OFS="\t"} ; {print $1,$2}' > ${WORKDIR}/${GENOMENAME}_cycog6_table.tsv 
sed -i -r 's/\|/\t/' ${WORKDIR}/${GENOMENAME}_cycog6_table.tsv








