#!/usr/bin/env python3

# this is a script to get the counts of invariable sites
# call script: invariant_sites.py <file>

import os, sys
from Bio import AlignIO

# file format that input is expected to have
msa_format = 'nexus'
# nucleotides that are accepted (read: counted)
valid_nucs = set(['A','C','G','T'])

# make sure command line args were provided
if len(sys.argv) < 2:
  print('usage: {} msa.fasta'.format(sys.argv[0]), file=sys.stderr)
  sys.exit(1)

# check input alignment file
fn_msa = sys.argv[1]
if not os.path.isfile(fn_msa):
  printf('[ERROR] file does not exist: {}'.format(fn_msa), file=sys.stderr)
  sys.exit(1)

# read alignment from file
msa = AlignIO.read(fn_msa, msa_format)
num_sites = msa.get_alignment_length()
inv_sites = {nuc: 0 for nuc in valid_nucs}

# loop over sites
for i in range(num_sites):
  # get unique nucleotides in alignment column
  nucs = set(msa[:,i].upper()) & valid_nucs
  # check if site invariable
  if len(nucs) == 1:
    # since sets are not accessible by index, "loop" over the single element
    for n in nucs:
      inv_sites[n] += 1

# print output to STDOUT
print('/'.join([str(inv_sites[n]) for n in valid_nucs]), end='')