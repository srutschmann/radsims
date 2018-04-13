#!/usr/bin/env python

"""

Name: nex2snapp.py 

Author: Harald Detering
Date:   2017-01-28

Based on original code by: Michael G. Harvey (12 May 2013)
https://github.com/mgharvey/misc_python/blob/master/bin/snapp_from_nex.py

Description: Convert a nexus alignment of concatenated SNPs to the input file format for 
SNAPP (Bryant et al. 2012).

Usage: 	python snapp_from_nex.py input_file output_directory [number_of_populations \
			[haplotypes_in_pop_1 haplotypes_in_pop_2 ... haplotypes_in_pop_n]]

Note: If population arguments are specified, haplotypes must occur in the alignment in the order 
that you input the number of haplotypes per population in the above command. 
For example, if there are 4 haplotypes (2 diploid individuals) in population 1, those should be 
the top 4 haplotypes in the alignment.

Note 2: The code will prompt you about whether or not you want to include sites with missing data. 
The original version of SNAPP could not handle missing data. In order to use missing data, you need 
a SNAPP add-on. To get it, start BEAUti, click menu File/Manage Add-ons, select SNAPP from the list, 
and click the install button. You may need to restart BEAUti. 

"""

from __future__ import division, print_function
import os
import sys
import argparse
import re
from Bio import AlignIO


def get_args():
	parser = argparse.ArgumentParser(
			description="""Program description""")
	parser.add_argument(
			"in_file",
			type=str,
			help="""Input NEXUS file"""
		)
	parser.add_argument(
			"out_file",
			type=str,
			help="""Output XML file"""
		)
	parser.add_argument(
			"template",
			type=str,
			help="""Output XML template file"""
		)
	parser.add_argument(
			"populations",
			type=int,
			nargs='?',
			help="""Number of populations"""
		)
	parser.add_argument(
			"pop_sizes",
			type=int,
			nargs='*',
			help="""Number of samples in each population"""
		)
	args = parser.parse_args()

	# make sure required files exist
	if not os.path.exists(args.in_file):
		print("[ERROR] Input file does not exist: {0}".format(args.in_file), file=sys.stderr)
		sys.exit(1)
	if not os.path.exists(args.template):
		print("[ERROR] Template file does not exist: {0}".format(args.template), file=sys.stderr)
		sys.exit(1)

	return args

def query_yes_no(question, default="yes"):
    valid = {"yes":True,   "y":True,  "ye":True,
             "no":False,     "n":False}
    if default == None:
        prompt = " [y/n] "
    elif default == "yes":
        prompt = " [Y/n] "
    elif default == "no":
        prompt = " [y/N] "
    else:
        raise ValueError("invalid default answer: '%s'" % default)
    while True:
        sys.stdout.write(question + prompt)
        choice = raw_input().lower()
        if default is not None and choice == '':
            return valid[default]
        elif choice in valid:
            return valid[choice]
        else:
            sys.stdout.write("Please respond with 'yes' or 'no' "\
                             "(or 'y' or 'n').\n")


def reformat_alignment(infile, missing):
        new_alignment = list()
	alignment = AlignIO.read("{0}".format(infile), "nexus")
	for w in xrange(alignment.get_alignment_length()):
		bases = alignment[:, w]	
		uniqs = list()
		uniqs = list(set(bases))
		if missing == "True": 
			nuniqs = filter(lambda a: a != "N", uniqs) # Filter out N's to check for biallelic-ness
			if len(nuniqs) != 2: # Check for biallelic-ness
				print("Skipping site {0} - not a biallelic SNP".format(w))
			else:
				allele1 = nuniqs[0]
				allele2 = nuniqs[1]
				new_snp = [0]*(len(bases))
				for x in range(len(bases)):
					if bases[x] == allele1:
						new_snp[x] = 0
					elif bases[x] == allele2:
						new_snp[x] = 1
					elif bases[x] == "N":
						new_snp[x] = "?"
				new_alignment.append(new_snp)
		elif missing == "False":
			if "N" in uniqs:
				print("Skipping site {0} - contains missing data".format(w))	 
			else:
				nuniqs = filter(lambda a: a != "N", uniqs) # Filter out N's to check for biallelic-ness
				if len(nuniqs) != 2: # Check for biallelic-ness
					print("Skipping site {0} - not a biallelic SNP".format(w))	
				else:
					allele1 = nuniqs[0]
					allele2 = nuniqs[1]
					new_snp = [0]*(len(bases))				
					for x in range(len(bases)-1):
						if bases[x] == allele1:
							new_snp[x] = 0
						elif bases[x] == allele2:
							new_snp[x] = 1
						elif bases[x] == "N":
							new_snp[x] = "?"
					new_alignment.append(new_snp)
	return new_alignment


def make_names(populations, pop_sizes):
  names = list()
  i = 0
  j = 0
  for y in range(populations): # For each pop
    for z in range(pop_sizes[i]): # For each individual in that pop
      names.append("{0}_{1}".format(i+1,j+1)) # Write name
      j += 1 # Plus one individual
      i += 1 # Plus one pop
  return names


def write_xml(infile, out_file, template, new_alignment):
  id_run = re.sub('\.svdq\.nex', '', infile)
  seqs = ''
  spec2tax = {}
  aln = AlignIO.read(infile, 'nexus')

  # construct sequences block
  for i in xrange(len(aln)):
    # assumption: sequence ids are '_'-delimited and start with species id
    id_seq  = aln[i].id
    id_spec = id_seq.split('_')[0]
    if id_spec not in spec2tax:
      spec2tax[id_spec] = []
    spec2tax[id_spec].append(id_seq)
    seqs += """    <sequence id="seq_{seqid}" taxon="{seqid}" totalcount="2" value="{seq}"/> 
""".format(seqid=id_seq, spec=id_spec, seq=''.join([str(x[i]) for x in new_alignment]))

  # construct taxonset block
  taxsets = ''
  for species in spec2tax:
    taxsets += """                <taxonset id="{id_spec}" spec="TaxonSet">
""".format(id_spec=species)
    for taxon in spec2tax[species]:
      taxsets += """                    <taxon id="{id_tax}" spec="Taxon"/>
""".format(id_tax=taxon)
    taxsets += "                </taxonset>\n"

  xml_fmt = open(template).read()
  params = {'id': id_run, 'seqs': seqs, 'taxsets': taxsets}
  with open(out_file, 'wt') as f_out:
    f_out.write(xml_fmt.format(**params))

def write_outfile(infile, outdir, new_alignment, names):
	has_names = not names is None
	alignment = AlignIO.read("{0}".format(infile), "nexus")
	out = open("{0}snapp_input.nex".format(outdir), 'wb')
	out.write("#NEXUS\n\n")
	out.write("Begin data;\n")
	out.write("\tDimensions ntax={0} nchar={1};\n".format(len(alignment[:,1]), len(new_alignment)))
	out.write("\tFormat datatype=binary symbols=\"01\" gap=- missing=?;\n")
	out.write("\tMatrix\n")
	for x in range(len(alignment[:,1])): # Loop through individuals
		out.write("{0}\t".format(names[x] if has_names else alignment[x].id))
		for y in range(len(new_alignment)): # Loop over alignment columns
			out.write("{0}".format(new_alignment[y][x])) # Write nucleotides
			out.flush()
		out.write("\n")	
		out.flush()
	out.write("\t;\n")
	out.write("End;")
	out.close()
	
	
def main():
  args = get_args()
  has_pops = len(args.pop_sizes) > 0
  missing = "True"
  new_align = reformat_alignment(args.in_file, missing)
  write_xml(args.in_file, args.out_file, args.template, new_align)


if __name__ == '__main__':
    main()
