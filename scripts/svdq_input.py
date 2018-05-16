#!/usr/bin/env python

'''
script to create input files for svdq

input file: file.phy or file.fasta
output file: file.svdq.nex
call script: ./svdq_input.py <input file>

last updated: 10/2017
'''

from __future__ import print_function
import os, sys
from Bio import SeqIO
from Bio import AlignIO
from Bio.Alphabet import IUPAC
from Bio.Nexus import Nexus

# As long as Biopython does not support non-interleaved NEXUS output, we need to do it ourselves...
# (but watch this: https://github.com/biopython/biopython/pull/362)
def write_nexus_non_interleaved(alignment, fh_out):
  ntax = len(alignment)
  nchar = alignment.get_alignment_length()
  minimal_record = "#NEXUS\nbegin data; dimensions ntax=0 nchar=0; " \
                   + "format datatype=dna missing=N; end;"
  n = Nexus.Nexus(minimal_record)
  n.alphabet = alignment._alphabet
  for record in alignment:
    n.add_sequence(record.id, str(record.seq))
  n.write_nexus_data(fh_out, interleave=False)

def write_taxon_set(alignment, fh_out):
  # create taxonset
  tax2spec = []
  line = 0
  spec = ''
  for rec in alignment:
    line += 1
    rec_spec = rec.id.split('_')[0]
    if spec != rec_spec:
      tax2spec.append([rec_spec, line, line])
      spec = rec_spec
    else:
      tax2spec[-1][2] += 1
  
  fh_out.write("\n\nbegin sets;\n\ttaxpartition species =")
  first = True
  delim = ''
  for spec, start, end in tax2spec:
    if start == end:
      fh_out.write("%s\n\t\t%s: %d" % (delim, spec, start))
    else:
      fh_out.write("%s\n\t\t%s: %d-%d" % (delim, spec, start, end))
    if first:
      delim = ','
      first = False
  fh_out.write(";\nend;\n")

# write partitioning information (assuming fixed locus length l)
def write_char_set(alignment, fh_out, l=110):
  len_aln = alignment.get_alignment_length()
  n = 0
  fh_out.write("\n\nbegin assumptions;")
  for start in range(1, len_aln, l):
    n += 1
    fh_out.write("\nCHARSET gtree_%d = %d-%d;" % (n, start, start+l-1))
  fh_out.write("\nend;\n")

def svdq_nex(filename, format, alphabet=IUPAC.unambiguous_dna):
  fn_parts = filename.rsplit('.', 1)
  fn_out = fn_parts[0] + '.nex' # this was modified from svdq.nex

  # read input alignment
  aln = AlignIO.read(filename, format, alphabet=alphabet)
  
  # write output file
  with open(fn_out, 'wt') as outfile:
    # outfile.write(aln.format('nexus'))
    write_nexus_non_interleaved(aln, outfile)
    write_taxon_set(aln, outfile)
    write_char_set(aln, outfile)

if __name__ == '__main__':
  if len(sys.argv) < 2:
    print("usage: %s alignment.phy" % sys.argv[0], file=sys.stderr)
    sys.exit(1)

  fn_input = sys.argv[1]
  if not os.path.exists(fn_input):
    print("[ERROR] file '%s' does not exist." % fn_input, file=sys.stderr)
    sys.exit(1)

  if fn_input.endswith('phy'):
    svdq_nex(fn_input, 'phylip')
  else:
    svdq_nex(fn_input, 'fasta')
