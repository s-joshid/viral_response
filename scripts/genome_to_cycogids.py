#!/usr/bin/env python3
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
import argparse
import os

def main():
    #loading in file w/ cycodids
    cycog_ortholog_df = pd.read_csv('${CYCOG}',
                                    engine = 'python',
                                    header = 0)
    
    #reformatting from int to str so there is not a trailing .0
    #in final mapping file
    cycog_ortholog_df['cycogid'] = cycog_ortholog_df['cycogid'].astype(str)
   
    #load in genome specific tsv, created in bash script
    genome_df = pd.read_csv('${WORKDIR}/${GENOMENAME}_cycog6_table.tsv',
                            engine = 'python',
                            sep = '\t',
                            names = ["genomename", "geneid"]
                            )
    #creating final mapping file
    final_df = genome_df.merge(cycog_ortholog_df[['cycogid', 'geneid']], on='geneid', how='left')

    #exporting to data_directory
    final_df.to_csv('${WORKDIR}/${GENOMENAME}_to_cycogid.csv')

if __name__ == "__main__":
    main()
