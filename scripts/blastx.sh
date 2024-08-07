#!/bin/bash


#working with Doron et al. 2016 paper
#genomes: syn- WH7803, WH8102 and WH8109 pro - NATL2A
#WH8109 obtained through ncbi accession no. CP006882
#name resulting text file as GenomeIDsequence.txt eg WH8109sequence.txt
#working with only WH8109


#ALL PATHS DEPENDENT ON BEING IN HOME DIRECTORY
#run this script by the following command: ./scripts/blastx.sh

TO_MOUNT=$(realpath .)
WORKDIR=$(realpath "./data")
#CYCOGBLASTDIR obtained from unzipping the cycog6 tarball (Data_S8-img_data_cycog6.tar.gz) provided by stephen 
#preprocessing
#1. unzip initial tarbaall
#tar -xvzf Data_S8-img_data_cycog6.tar.gz
#2. navigate to resulting directory and unzip all tar.gz files there
#cd ./img_data_cycog6
#for f in ./*.gz; do tar -xvzf ```${f}```; done
#3. remove all the .tar.gz files from the img_data_cycog6 directory
#rm *.tar.gz
CYCOGBLASTDIR="${WORKDIR}/img_data_cycog6"
GENOMENAME="WH8109"


#verify file paths
echo "WORKDIR: ${WORKDIR}"
echo "GENOMENAME: ${GENOMENAME}"
echo "CYCOGBLASTDIR: ${CYCOGBLASTDIR}"
echo "TO_MOUNT: ${TO_MOUNT}"


#making FASTA file of WH1809 coding sequece
echo "making genome cds into a FASTA file"
cat "${WORKDIR}"/WH8109sequence.txt | sed -r 's/^>.+locus_tag=/>/' | sed -r 's/[]] .+$//' > ${WORKDIR}/${GENOMENAME}.cds.fna
echo "complete"


#making sure blastx biocontainer is installed
echo "ensuring proper singularity containers are downloaded"
if [ ! -e ./containers ]; then
	echo "making containers directory"
	mkdir ./containers
fi

if [ ! -e './containers/blastx.sif' ];
then
    echo "building container"
    cd ./containers
    singularity build blastx.sif docker://quay.io/biocontainers/blast:2.14.1--pl5321h6f7f691_0
    cd ..
    #should end in main directory
fi
echo "complete"

#ensuring we have the protein database properly created
#done by checking if one of the cycog_db.p* files is there 
echo "creating protein database, if missing"
if [ ! -e "${WORKDIR}"/cycog_db.pdb ]; then
    #creating txt file of all .faa file paths under CYCOGBLASTDIR
    echo "Creating paths to faa files"
    for directory in "${CYCOGBLASTDIR}"*/; do
        find ${directory}  -name "*.faa" >> "${CYCOGBLASTDIR}"/paths_to_faa_files.txt;
    done
    echo "cleaning each faa file"
    #cleaning up faa files so they are in a format blastx can recognize and work with
    while read -r path; do
        sed 's/\(>[^ ]*\).*/\1/' ${path} >> "${CYCOGBLASTDIR}"/cleaned_faa_files.faa;
    done < "${CYCOGBLASTDIR}"/paths_to_faa_files.txt
    #creating the protein database
    echo "creating protein db"
    singularity exec --no-home --bind "${TO_MOUNT}":"${TO_MOUNT}" \
    ./containers/blastx.sif makeblastdb -in "${CYCOGBLASTDIR}/cleaned_faa_files.faa" \
    -dbtype prot -parse_seqids -out "${WORKDIR}/cycog_db" -title "cycog db"

    #check if db was properly created, command should throw no errors
    echo "checking db was properly created"
    singularity exec --no-home --bind "${TO_MOUNT}":"${TO_MOUNT}" \
    ./containers/blastx.sif \
    blastdbcmd -db "${WORKDIR}/cycog_db" -info
fi
echo "complete"

#Find cycog6 matches for each WH8109
echo "finding genes in genome that matches to the protein database via blastx"
echo "this step may take a bit"
singularity exec --no-home --bind "${TO_MOUNT}":"${TO_MOUNT}" ./containers/blastx.sif \
    blastx -db "${WORKDIR}/cycog_db" \
    -query "${WORKDIR}/${GENOMENAME}.cds.fna"  \
    -out "${WORKDIR}/${GENOMENAME}_blastx_cycog6.out" \
    -evalue 0.001 \
    -num_threads 20 \
    -outfmt "6 qseqid sseqid evalue bitscore pident qcovs qcovhsp"
echo "complete"


#retaining best hits
echo "retainig best hits and reformatting results to cleaned up tsv file"
cat ${WORKDIR}/${GENOMENAME}_blastx_cycog6.out | awk -F "\t" '!seen[$1]++' > "${WORKDIR}/${GENOMENAME}_blastx_cycog6_tophit.out"

#table of legacy genome tags and best Cycog ID match
cat ${WORKDIR}/${GENOMENAME}_blastx_cycog6_tophit.out | awk 'BEGIN {FS="\t"} ; {OFS="\t"} ; {print $1,$2}' > ${WORKDIR}/${GENOMENAME}_cycog6_table.tsv sed -i -r 's/\|/\t/' ${WORKDIR}/${GENOMENAME}_cycog6_table.tsv
echo "complete"

#matching up genes to cycogids: done via genome_to_cycogids.py script
