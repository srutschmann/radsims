#!/usr/bin/perl -w

# original script provided by SimPhy adjusted to work for radsims simulation see SR/HD comments (delete tree files, call diversity, perform ado, concatenate alignments, extract snps)

# Quick and dirty perl script to simulate sequence evolution using INDELible along gene trees simulated by SimPhy.
# It doesn't support input indelible [BRANCHES] [TREE] 
# ?? [EVOLVE]
# Diego Mallo 2015

use strict;
#GSL
use Math::GSL::RNG qw/:all/;
use Math::GSL::Randist qw/:all/;
use Math::GSL::CDF qw/:all/;

#Config
my $w_dir;
my $input_file;
my $my_length;
my $length_command;
my $seed;
my $n_threads=0; #Maximum by default

# RADSIMS-specific settings
my $diversity="/mnt/lustre/scratch/home/uvi/be/sru/simulation/scripts/diversity/diversity"; # SR: path to diversity program (calculates alignment stats)
my $ado_sim="/mnt/lustre/scratch/home/uvi/be/sru/simulation/scripts/ado_simulation.py"; # SR: path to ado_sim program (simulation of allelic dropout in alignments)
my $extract_snps="/mnt/lustre/scratch/home/uvi/be/sru/simulation/scripts/extract_snps/extract_snps"; # SR: path to extract_snps program (generates SNP alignments)
my $has_ancestral_state=1; # SR: set to '1' if INDELible generates 'data_*_ANCESTRAL.phy' files (else '0')

my @files;
my $curr_sp=-1;
my $sp_counter=0;
my $sequence_counter=1;
my $filehandwrite;
my $filehandread;
my $filehandcontrol;
my $partitions;
my $evolves;
my $out_models;
my $out_partitions;
my $out_settings;
my $temp_model;
my $model_id;
my $backup=$/;
my $locus;
my $id;
my $n_digits=0;
my $trees;
my $itree;
my $rng;

sub parse_sampling
{
	my $sampling_string="";
	my $distribution_code="";
	my $is_integer="";
	my @ret_value=0;
	my $out='';
	
	($sampling_string)=@_;
	$sampling_string=~m/^(.*?):/ or die "The parameter $sampling_string does not follow the required sampling notation format";
	$distribution_code=uc($1);
	if ($sampling_string=~/:i$/i)
	{
		$is_integer=1;
	}
	else
	{
		$is_integer=0;
	}
	my @params=();
	while ($sampling_string=~m/([+-]?((\d+(\.\d*)?)|(\.\d+)))/g)
	{
		push(@params,$1);
	}
	if ($distribution_code eq "F")
	{
		scalar @params == 1 or die "Incorrect number of parameters for a fixed value. Sampling command \"$sampling_string\"";
		@ret_value=($params[0]);
	}
	elsif ($distribution_code eq "N")
	{
		scalar @params == 2 or die "Incorrect number of parameters sampling a normal distribution. Sampling command \"$sampling_string\"";
		@ret_value=(gsl_ran_gaussian_ziggurat($rng->raw(),$params[1])+$params[0]);
	}
	elsif ($distribution_code eq "L")
	{
		scalar @params == 2 or die "Incorrect number of parameters sampling a lognormal distribution. Sampling command \"$sampling_string\"";
		@ret_value=(gsl_ran_lognormal($rng->raw(),@params));
	}
	elsif ($distribution_code eq "U")
	{
		scalar @params == 2 or die "Incorrect number of parameters sampling an uniform distribution. Sampling command \"$sampling_string\"";
		@ret_value=(gsl_ran_flat($rng->raw(),@params));
	}
	elsif ($distribution_code eq "E")
	{
		scalar @params == 1 or die "Incorrect number of parameters sampling an exponential distribution. Sampling command \"$sampling_string\"";
		@ret_value=(gsl_ran_exponential($rng->raw(),@params));
	}
	elsif ($distribution_code eq "G")
	{
		scalar @params == 2 or die "Incorrect number of parameters sampling a gamma distribution. Sampling command \"$sampling_string\"";
		@ret_value=(gsl_ran_gamma($rng->raw(),@params));
	}
	elsif ($distribution_code eq "SL")
	{
		scalar @params == 3 or die "Incorrect number of parameters sampling a lognormal distribution multiplied by a constant. Sampling command \"$sampling_string\"";
		@ret_value=(gsl_ran_lognormal($rng->raw(),$params[0],$params[1])*$params[2]);
	}
	elsif ($distribution_code eq "D")
	{
		my $dimensions= scalar @params;
		my $sum=0;
		for (my $dim=0; $dim<$dimensions; $dim++)
		{
			$ret_value[$dim]=gsl_ran_gamma($rng->raw(),$params[$dim],1);
			$sum+=$ret_value[$dim];
		}
		for (my $dim=0; $dim<$dimensions; $dim++)
		{
			$ret_value[$dim]/=$sum;
		}
	}
	elsif ($distribution_code eq "RD")
	{
		my $dimensions= scalar @params;
		my $sum=0;
		for (my $dim=0; $dim<$dimensions; $dim++)
		{
			$ret_value[$dim]=gsl_ran_gamma($rng->raw(),$params[$dim],1);
			$sum+=$ret_value[$dim];
		}
		my $last=$ret_value[$dimensions-1]/$sum;
		for (my $dim=0; $dim<$dimensions-1; $dim++)
		{
			$ret_value[$dim]/=($sum/$last);
		}
		pop @ret_value;
	}

	else
	{
		die "Unknown distribution code \"$distribution_code\" present in the sampling command \"$sampling_string\"";
	}
	
	if ($is_integer==1)
	{
		for (my $element=0;$element<scalar @ret_value;$element++)
		{
			$ret_value[$element]=int $ret_value[$element];
		}
		return join (' ',@ret_value);
	}
	else
	{
		for (my $element=0;$element<scalar @ret_value;$element++)
		{
			$ret_value[$element]=sprintf("%f",$ret_value[$element]);
		}

		return join (' ',@ret_value);
	}
}

if (scalar @ARGV != 4)
{
	die "Incorrect number of parameters, Usage: $0 directory input_config seed numberofcores\n";
}

($w_dir,$input_file,$seed,$n_threads)=@ARGV;

#Working on the input file to be replicated
$/=undef;
open($filehandcontrol,$input_file) or die "Error opening the input config file $input_file";
my $content=<$filehandcontrol>;
close($filehandcontrol);
$/=$backup;

chdir($w_dir) or die "Error changing the working dir to $w_dir\n";
$w_dir=~m/([^\/]*).?$/ or die "Error parsing the working directory";
$w_dir=$1;
opendir (my $dirs_handler, ".");

my @dirs = grep {-d "./$_" && ! /^\.{1,2}$/} readdir($dirs_handler);

if ($seed)
	{$rng = Math::GSL::RNG->new("",$seed);}
else
	{$rng = Math::GSL::RNG->new();}

#Delete commented out text
$content=~s/\/\/.*?(?=\n)//g;
$content=~s/\/\*.*?\*\///sg;
$content=~s/\n+/\n/sg;

#TYPE Parsing
$content=~m/(\[TYPE\].*?)((?=\[[A-Z])|$)/s or die "Error parsing the configuration file: There was no [TYPE] section";
my $type=$1;


#SIMPHY-UNLINKED-MODEL
my %unlinked_models=();
my $parser;
my $name;
while ($content=~m/(\[SIMPHY-UNLINKED-MODEL\].*?)((?=\[[A-Z])|$)/sg)
{
	$parser=$1;
	$parser=~m/\[SIMPHY-UNLINKED-MODEL\]\s*(.*?)\s*\n/ or die "[SIMPHY-UNLINKED-MODEL] $parser has not been parsed properly \n";
	$name=$1;
	$unlinked_models{$name}=$parser;
}
#SETTINGS Parsin
my @settings;
while ($content=~m/(\[SETTINGS\].*?)((?=\[[A-Z])|$)/sg)
{
	push(@settings,$1);
}
scalar @settings > 1 and die "Unsuported number of [SETTINGS] sections have been found in the input file";


#MODEL Parsing
my %models=();
while ($content=~m/(\[MODEL\].*?)((?=\[[A-Z])|$)/sg)
{
	$parser=$1;
	$parser=~m/\[MODEL\]\s*(.*?)\s*\n/ or die "[MODEL] $parser has not been parsed properly \n";
	$name=$1;
	$models{$name}=$parser;
}
scalar keys %models < 1 and scalar keys %unlinked_models < 1 and die "Neither [MODEL] nor [UNLINKED-MODEL] sections have been found in the input file";

#PARTITIONS Parsing
my @partitions;
while ($content=~m/(\[PARTITIONS\].*?)((?=\[[A-Z])|$)/sg)
{
	push(@partitions,$1);
}
scalar @partitions > 0 and die "Unsupported [PARTITIONS] in the input file. This script is only compatible with [SIMPHY-PARTITIONS], which have different format that the original INDELible's [PARTITIONS] sections.";

#SIMPHY-PARTITIONS
my @simphy_partitions;
my @part_names;
my @p_trees;
my @part_model;
my @length;
my $total_percentage=0;

while ($content=~m/(\[SIMPHY-PARTITIONS\].*?)((?=\[[A-Z])|$)/sg)
{
	$parser=$1;
	push(@simphy_partitions,$parser);
	$parser=~m/\[SIMPHY-PARTITIONS\]\s*(.*?)\s*\[(.*)?\s+(.*)?\s+(.*)\]/ or die "[SIMPHY-PARTITION] $content has not been parsed correctly. Please, check the sintax.\n";
	push(@part_names,$1);
	push(@p_trees,$2);
	$total_percentage+=$2;
	push(@part_model,$3);
	push(@length,$4);
#	$length[-1]=~m/\$\((.*)\)/ and $length[-1]=parse_sampling($1);
	
} 
$total_percentage != 1 and die "[SIMPHY-PARTITIONS] Tree relative quantity does not add up to one. Please, check your input config file.\n"; 

#EVOLVES Parsing
my @evolves;
while ($content=~m/(\[EVOLVE\].*?)((?=\[[A-Z])|$)/sg)
{
	push(@evolves,$1);
}
scalar @evolves > 0 and die "Unsupported [EVOLVE] in the input file";

#SIMPHY_EVOLVE parsing
my @simphy_evolves;
my $n_rep=1;
my $output_prefix="";
while ($content=~m/(\[SIMPHY-EVOLVE\].*?)((?=\[[A-Z])|$)/sg)
{
	push(@simphy_evolves,$1);
}
scalar @simphy_evolves > 1 and die "Unsupported number of [SIMPHY-EVOLVE] in the input file, only one supported\n";
if (scalar @simphy_evolves >0)
{
	$simphy_evolves[0]=~m/\[SIMPHY-EVOLVE\]\s*(.*?)\s+(.*?)\s+\n*/ or die "[SIMPHY-EVOLVE] cannot be parsed properly\n";
	$n_rep=int($1);
	$output_prefix=$2;
}

#BRANCHES Parsing
my @branches;
while ($content=~m/(\[BRANCHES\].*?)((?=\[[A-Z])|$)/sg)
{
	push(@branches,$1);
}
scalar @branches > 0 and die "Unsupported [BRANCHES] in the input file";


#MAIN LOOP
foreach my  $dir (@dirs)
{
	$sp_counter=int($dir);
	print "\n\n\nTreating gene trees from the replicate $sp_counter\n";
	
	#Inside newdir
	chdir($dir) or die "Error changing the working dir\n";
	
	#Gene tree copy and modification 

	#INDELIBLE
	print "\t\nGenerating the INDELIBLE control.txt file\n";
	open($filehandwrite,">"."control.txt") or die "Error opening the file\n";
	
	@files=<g_trees*.trees>;
	$id='';
	$out_models='';
	$trees='';
	$out_partitions='';
	$evolves='[EVOLVE] ';
	$out_settings='';
	
	if (scalar @settings >0)
	{
		$out_settings=$settings[0];
		$out_settings=~s/\$\((.*?)\)/parse_sampling($1)/ge;
	}

	foreach my $file (@files)
	{
		open($filehandread,$file) or die "Error opening the file $file\n";
		$file=~m/g_trees(\d*)\.trees/ or die "Error parsing gene tree filenames";
		$n_digits=length($1);
		$locus=int($1);
		$/="";
		$itree=<$filehandread>;
		chomp($itree);
		close($filehandread);
		#unlink($file); # SR: delete tree files to save disk space

		$trees.=sprintf("\[TREE\] T%.*d %s\n",$n_digits,$locus,$itree);		
		$sequence_counter+=1;
	}
	my $n_trees=scalar @files;	
	my $partition_id=0;
	my $prev_ptrees=0;
	my $temp_length="";
	for (my $tree_id=1; $tree_id<= scalar @files; $tree_id++)
	{
		if ($tree_id/$n_trees>$p_trees[$partition_id]+$prev_ptrees) #Next partition
		{
			$prev_ptrees=$p_trees[$partition_id];
			$partition_id+=1;
		}
		$temp_length=$length[$partition_id];
		$temp_length=~s/\$\((.*?)\)/parse_sampling($1)/ge;
		if ($unlinked_models{$part_model[$partition_id]})
		{
			$temp_model=$unlinked_models{$part_model[$partition_id]};
			$temp_model=~s/(\[SIMPHY-UNLINKED-MODEL\])\s*(.*?)\s*\n/\[MODEL\] $2_$tree_id\n/ or die "Error parsing the configuration file: Malformed [UNLINKED-MODEL] section";
			$model_id="$2_$tree_id";
			$temp_model=~s/\$\((.*?)\)/parse_sampling($1)/ge;
			$out_partitions.=sprintf("\[PARTITIONS\] %s_%.*d \[T%.*d %s %d\]\n",$part_names[$partition_id],$n_digits,$tree_id,$n_digits,$tree_id,$model_id,int($temp_length));	
			$out_models.="$temp_model\n";
		}
		elsif ($models{$part_model[$partition_id]})
		{
			$out_partitions.=sprintf("\[PARTITIONS\] %s_%.*d \[T%.*d %s %d\]\n",$part_names[$partition_id],$n_digits,$tree_id,$n_digits,$tree_id,$part_model[$partition_id],int($temp_length));
		}
		else
		{
			die "The parsed model \"$part_model[$partition_id]\" of the current partition \"$part_names[$partition_id]\"does not correspond with any sampled model\n";
		}
		$evolves.=sprintf("%s_%.*d %d %s_%.*d\n",$part_names[$partition_id],$n_digits,$tree_id,$n_rep,$output_prefix,$n_digits,$tree_id);
		
	}

	my $temp_model="";
	foreach my $modelname (keys %models)
	{
		$temp_model=$models{$modelname};
		$temp_model=~s/\$\((.*?)\)/parse_sampling($1)/ge;
		$out_models.="$temp_model\n";
	}
	
		
#		$id=sprintf("%.*d",$n_digits,$locus);
#		$temp_model=$models[0];
#		$temp_model=~s/(\[MODEL\])\s*(.*?)\s*\n/$1 $2$id\n/ or die "Error parsing the configuration file: There was no [MODEL] section";
#		$model_id="$2$id";
#		$temp_model=~s/\$\((.*?)\)/parse_sampling($1)/ge;
#		$out_models.="$temp_model\n";
#
#		$my_length=parse_sampling($length_command);
#		$out_partitions.=sprintf("\[PARTITIONS\] T%.*d \[T%.*d %s %d\]\n",$n_digits,$locus,$n_digits,$locus,$model_id,int($my_length));
#		$evolves.=sprintf("T%.*d 1 %.*d\n",$n_digits,$locus,$n_digits,$locus);

	
	print $filehandwrite $type,"\n",$out_settings,"\n",$out_models,"\n",$trees,"\n",$out_partitions,"\n",$evolves;
	close($filehandwrite);
	
	print "\tFile created\n";
	
	chdir("..");
	
}
my $is_parallel=`command -v parallel`;
if ($is_parallel && $n_threads!=0)
{
	print "Parallel sequence simulation\n";
	system("ls -d [0-9][0-9][0-9] | parallel -P $n_threads 'cd {} && indelible'");
}
else
{
	print "Sequential sequence simulation\n";
	foreach my $dir (@dirs)
	{
		$sp_counter=int($dir);
		print "\nSimulating sequences for replicate $sp_counter\n";	
		#Inside newdir
		chdir($dir) or die "Error changing the working dir\n";
		system("indelible && touch indelible.done");

		# HD: delete gene tree files only if indelible run was successful
		my $indelible_ok = (-f "indelible.done");
		if ($indelible_ok) {
			unlink(<g_trees*.trees>);
		}

		# SR: consolidate ancestral ROOT sequences into single file and remove the rest
		if ($has_ancestral_state) {
			local $/ = "\n"; # set line separator
			open(my $anc_out, ">", "ancestral.fasta") or die "Could not open file 'ancestral.fasta' $!";
			my @anc_files=<*_ANCESTRAL.phy>;
			foreach my $ancfile (@anc_files) {
				open(my $fh, "<", $ancfile) or die "Could not open file '$ancfile' $!\n";
				while (my $line = <$fh>) {
					chomp $line;
					if ( $line =~ /^ROOT\t(.+)$/ ) {
						print $anc_out ">$ancfile\n$1\n";
					}
				}
			}
			close $anc_out;
			unlink(@anc_files);
		}

		unlink(<data_*.fas>); # .phy files contain sequences, so .fas are not needed

		# SR: calculate alignment stats from TRUE alignments,
		my @truephyfiles=<*_TRUE.phy>;
		foreach my $phyfile (@truephyfiles) {
			system("$diversity $phyfile -m >> concat_stats.csv 2>/dev/null");
		}
		# HD: run ADO simulation
		system("$ado_sim $dir && touch ado_sim.done");
		my $ado_sim_ok = (-f "ado_sim.done");
		# SR: calculate alignment stats from TRUE alignments,
		my @adophyfiles=<data_*.ado.phy>;
		foreach my $phyfile (@adophyfiles) {
			system("$diversity $phyfile -m >> concat_ado_stats.csv 2>/dev/null");
		}
		# HD: extract SNPs from concatenated alignments (both with/without ADO)
		system("$extract_snps ${dir}_concat.phy ${dir}_concat && touch extract_snps_concat.done");
		system("$extract_snps ${dir}_concat_ado.phy ${dir}_concat_ado && touch extract_snps_concat_ado.done");
		my $extract_snps_ok = (-f "extract_snps_concat.done") && (-f "extract_snps_concat_ado.done");
		# delete .phy files if previous steps were successful
		if ($ado_sim_ok && $extract_snps_ok) {
			unlink(@truephyfiles);
			unlink(@adophyfiles);
		}
		#unlink("LOG.txt");
		#unlink(<*.done>); # remove *.done files

		chdir("..")
	}
}
exit;


