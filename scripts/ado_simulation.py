#! /usr/bin/env python

# this is a script to simulate ado, extract SNPs, and concatenate alignments
# call script: ado_simulation.py <folder> 

import sys, os, random, util
from Bio import AlignIO, SeqIO

# check sys.args
if len(sys.argv) != 2:
  print("usage: %s output_prefix" % sys.argv[0])
  sys.exit(1)

# global settings (fixed for speed)
r_site_len = 10  # length of restriction site
seq_len = 110    # sequence length in alignments
missing_seq = 'N'*seq_len # dummy sequence
locus_pfx  = "data_%s"
filename_digits = util.get_filename_digits('.', 'data_')

concat_filename = sys.argv[1] + "_concat.phy"
ado_filename    = sys.argv[1] + "_concat_ado.phy"
ado_filepattern = "data_%s.ado.phy"
output_ado_alignments = True # export ADO alignments into separate files


## concatenate alignments ##

# concatenate whole alignment (gene alignment)
print("concatenating alignments...")
gene_id = 1
aln_fn = (locus_pfx % str(gene_id).zfill(filename_digits)) + '_TRUE.phy'
aln = AlignIO.read(aln_fn, 'phylip-relaxed')
util.sort_aln_by_spec_num(aln)
concat_aln = aln[:, 0:0] # create "empty" alignment with taxa IDs only

while os.path.isfile(aln_fn):
  aln = AlignIO.read(aln_fn, 'phylip-relaxed')
  util.sort_aln_by_spec_num(aln)
  concat_aln += aln
  gene_id += 1
  aln_fn = (locus_pfx % str(gene_id).zfill(filename_digits)) + '_TRUE.phy' # next aln

# AlignIO.write(concat_aln, concat_filename, 'phylip-relaxed')
# we want non-interleaved PHYLIP output, which Biopython cannot do at the moment...
util.write_phylip_non_interleaved(concat_aln, concat_filename)


## simulate allelic dropout (ado) ##
print("simulating allelic dropout...")

# import ancestral sequences
anc_recs = SeqIO.parse('ancestral.fasta', 'fasta')

# import alignment
# concat_aln = AlignIO.read(concat_filename, 'phylip-relaxed')
# make sequences changeable (to introduce missing sequence parts)
for rec in concat_aln:
  rec.seq = rec.seq.tomutable()

gene_id = 1
aln_len = concat_aln.get_alignment_length()
anc_match = True # tells if ancestral seq ids are in sync with alignments
# iterate concatenated alignment gene by gene
for start_idx in range(0, aln_len, seq_len):
  # get ancestral restriction site
  if anc_match:
    anc = anc_recs.next()
  anc_match = (anc.id.startswith("data_%s_ANCESTRAL" % format(gene_id, "0%d" % filename_digits)))
  if not anc_match:
    print("simulate_ado: [WARNING] ancestral seq '%s' does not match gene '%d'." % (anc.id, gene_id))
    print("                ADO sim will not be done for this gene - proceeding to next one.")
  r_site = str(anc.seq[:r_site_len])

  # identify sequences with snp in the first X bp
  #print("%05d: '%s'" %(gene_id, r_site))
  for rec in concat_aln:
    #print("'%s' == '%s'? %s" % (rec.seq[start_idx:start_idx+r_site_len], r_site, str(rec.seq[start_idx:start_idx+r_site_len]) == r_site))
    if anc_match and not str(rec.seq[start_idx:start_idx+r_site_len]) == r_site:
      # replace sequences with snp in the first X bp with N's
      rec.seq[start_idx:start_idx+seq_len] = missing_seq
  
  if output_ado_alignments:
    outfile = ado_filepattern % str(gene_id).zfill(filename_digits)
    AlignIO.write(concat_aln[:, start_idx:start_idx+seq_len], outfile, 'phylip-relaxed')
  gene_id += 1

# write modified alignment to file
# AlignIO.write(concat_aln, ado_filename, 'phylip-relaxed')
# we want non-interleaved PHYLIP output, which Biopython cannot do at the moment...
util.write_phylip_non_interleaved(concat_aln, ado_filename)

# print("concatenating SNPs...")
# 
# aln_len = concat_aln.get_alignment_length()
# concat_snps = concat_aln[:, 0:0]
# concat_snps_reduced = concat_aln[:, 0:0]
# for start_idx in range(0, aln_len, seq_len):
#   snp_pos = []
#   # extract all snps and concatenate (snp alignment)
#   for i in range(start_idx, start_idx+seq_len):
#     uniq_alleles = set(concat_aln[:, i]) - set('N')
#     if len(uniq_alleles) > 1: # check if alignment column has more than one allele
#       snp_pos.append(i)
#       concat_snps += concat_aln[:, i:i+1]
#   
#   # extract one snp and concatenate (reduced snp alignment)
#   if len(snp_pos) > 0:
#     snp_idx = random.randrange(len(snp_pos))
#     snp_col = snp_pos[snp_idx]
#     concat_snps_reduced += concat_aln[:, snp_col:snp_col+1]
# 
# # write concatenated SNPs to file
# AlignIO.write(concat_snps, 'concat_snps.fasta', 'fasta')
# AlignIO.write(concat_snps_reduced, 'concat_snps_reduced.fasta', 'fasta')
