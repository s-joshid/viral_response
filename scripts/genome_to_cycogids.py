#!/usr/bin/env python3
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
import argparse
import os
#notes for cleanup 
#simplify argument names 
#get more specific with help strings and say what sort of file is going into it
#what are the fields? 
#handle arguments method will handle user input for input/output paths
def handle_arguments():
    description = '''This script joins the cyanobacteria specific IDS
    to the genome specific IDS obtained from the blastx.sh script
    Example Usage:
    ./scripts/genome_to_cycogs.py ./path/to/ortholog-metadata.csv ./path/to/GENOMENAME_cycog6_table.tsv GENOMENAME'''
    #parser outputs description
    parser = argparse.ArgumentParser(description = description)
    parser.add_argument('Cyano_orthologs' , type = str, 
                        help = 'Input path to cyanobacteria specific ortholog metadata file, obtained from Stephen' )
    parser.add_argument('genome_geneIDs' , type = str, 
                        help = 'Genome specific file of gene ids, obtained as the output of the blastx.sh script' )
    parser.add_argument('GenomeName', type = str, 
                        help = 'Insert genome name')
    return parser

def main():
    parser = handle_arguments()
    args = parser.parse_args()
    print("reading ortholog metadata csv")
    cycog_ortholog_df = pd.read_csv(args.Cyano_orthologs)
    print(cycog_ortholog_df.head(n=5))
    #reformatting from int to str so there is not a trailing .0
    #in final mapping file
    cycog_ortholog_df['cycogid'] = cycog_ortholog_df['cycogid'].astype(str)
    #load in genome specific tsv, created in bash script
    genome_df = pd.read_csv(args.genome_geneIDs,
                            sep = '\s+',
                            names = ["genomename", "geneid"]
                            )
    print(genome_df.columns)
    #creating final mapping file
    final_df = genome_df.merge(cycog_ortholog_df[['cycogid', 'geneid']], 
                               on='geneid', how='left')
    print(final_df.head(n=5))
    #exporting to data_directory
    Genome_str = args.GenomeName
    final_path = "./data/" + Genome_str + "_to_cycogid.csv"
    final_df.to_csv(final_path, index=False)
    print("output saved to " + final_path)

if __name__ == "__main__":
    main()
