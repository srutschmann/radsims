from ctypes import *
import re

class Dirent(Structure):
    _fields_ = [("d_ino", c_voidp),
                ("off_t", c_int64),
                ("d_reclen", c_ushort),
                ("d_type", c_ubyte),
                ("d_name", c_char * 2048)
            ]

def get_datafile(dirname, prefix):
	libc = cdll.LoadLibrary("libc.so.6")
	dir_ = c_voidp(libc.opendir(dirname))

	datafile = ''
	while True:
		p  = libc.readdir64(dir_)
		if not p:
			break
		
		entry = Dirent.from_address(p)
		if (entry.d_name.startswith(bytes(prefix))):
			datafile = entry.d_name
			break
	
	return datafile

def get_filename_digits(dirname, prefix):
	filename = get_datafile(dirname, prefix)
	digits = len(re.findall('%s(\d+).*\.\w+' % prefix, filename)[0])
	return digits

def write_phylip_non_interleaved(alignment, outfilename):
	num_taxa = len(alignment)
	len_aln  = alignment.get_alignment_length()
	with open(outfilename, 'wt') as f_out:
		# write header
		f_out.write("%d %d\n" % (num_taxa, len_aln))
		# write each taxon sequence as single line
		for rec in alignment:
			id_padded = rec.id.ljust(10)
			f_out.write("%s%s\n" % (id_padded, rec.seq))

# convert text to integer (if possible, otherwise return text)
def atoi(text):
	return int(text) if text.isdigit() else text

# for a record with SimPhy-formatted taxon identifier, return id components as numbers
# (e.g. SequenceRecord(id="1_2_3", seq="..."): returns [1, 2, 3])
def split_tax_id(rec):
	return [atoi(x) for x in rec.id.split('_')]

# sorts an alignment by species,
# expects numerical species IDs as first part of taxon IDs
def sort_aln_by_spec_num(aln):
	aln.sort(key=split_tax_id)
