use strict;
use warnings;
use Getopt::Long;
###################################################################
#This script is updated on 10.08.2020 by shuang to trim 5'end flank of RPF protected fragment, which reveals the codon on P site and used to calculate coverage

#It will also produce the 5' end prefernce of 4 nt, 2nt ahead of 5' end and 2 nt after the cleavage site, which will provide a statistics for end cleavage preference
####################################################################

# set the threshold for the size selection. 65 mean 65%.

my ($threshold, $species, $up, $down);

$threshold = 60;
$species = "";
$up = 40;
$down = 25;

GetOptions 
(
  't=s'=>\$threshold,	# file containing peak, must have its path.
  'sp=s'=>\$species,		# name of sample
  'up=s'=>\$up,	# path and file name of genome
  'down=s'=>\$down	   
 );

if ($species eq "") {
	die "Missing one or more input file name(s)!
	use of script:
	perl step4_trimbedv2.pl  -sp <species name>  ) \n"} # check parameters


mkdir 'cleavage_preference';

open (REF, "/disk/wzy/ribo_seq/human_ribo/$species/longest_cDNA.fa") or die $!;
my %si; my %gene; my $ge; 
while (<REF>) {
    $_=~ s/\s+$//;
    if (/^>/)       {
    $ge=$_;
    $ge=~ s/^>//;
    next;}
    $gene{$ge}.=$_; }


foreach my $j (keys %gene)  {
    $si{$j}=length($gene{$j}); 
    }
close REF;


open (fileName, "deadapter.txt") or die $!;
while (<fileName>)  {
	chomp;
	#$_ =~ s/.fastq$//;
	print "$_\n";
	trimbed($_);   }

close fileName;



sub trimbed                       {

  my ($sam)=@_; print "processing $sam\n";
  
  my $count=0; my %trim=(); my %count = ();  my %pref5; 

  open (hand0, "codon_stat/$sam.txt") or die $!;

  while (<hand0>)                  {

    next unless (/^\d\d\t\d+\t/);

    my @a = split /\t/; 

    if ($a[2] >= $threshold)  {$trim{$a[0]} = 15;}
    elsif ($a[3] >= $threshold)  {$trim{$a[0]} = 14;}
    elsif ($a[4] >= $threshold)  {$trim{$a[0]} = 16;}
                                    }
  close hand0;

  
  open (hand1, "$sam.sort.bed") or die $!;
 
  open (hand3, ">$sam\_A.bed");
  open (hand4, ">codon_stat/$sam\_trim.txt");
  open (hand5, ">cleavage_preference/$sam.5end.stat.txt");

  print hand4 "trimming status >= $threshold\nlength\tposition\n";

  while (<hand1>)                {

  $_=~ s/\s+$//;
  my @a1=split /\t/; 

  if ($a1[5] eq '-') {next;}

     my $size=$a1[2]-$a1[1];
     next if $size > $up or $size < $down; 

  if (exists $trim{$size})   {          
     $count{$size}++;
     my $pos=$a1[1]+$trim{$size}-3; 
     my $si=$pos+1;

     my $posA=$pos+3;
     my $siA=$posA+1;

     #print hand2 "$a1[0]\t$pos\t$si\t$a1[3]\t$a1[4]\t$a1[5]\n";
     print hand3 "$a1[0]\t$posA\t$siA\t$a1[3]\t$a1[4]\t$a1[5]\n";
     
     next if $pos < 100 or $pos+100 > $si{$a1[0]};
		
     my $junc5 = substr($gene{$a1[0]},$a1[1]-2,4);
	 my $stat = "in";
	 if ( ($pos-100)%3 == 1 )  {
			$stat = "s1";}
	 if ( ($pos-100)%3 == 2 )  {
			$stat = "s2";}
		$pref5{$junc5}{$stat} ++;

                             }     }

  close hand1;  close hand3; 
  
   
   foreach (sort keys %trim)  {
    print hand4 "$_\t$trim{$_}\t$count{$_}\n" if exists $count{$_} ;  }
  close hand4;  
  
  print hand5 "Junction_4nt\tInner\tinframe\tplus1\tminus1\n";
	foreach my $i (keys %pref5)   {
		my $inner_cleave = substr($i,1,2);
		print hand5 "$i\t$inner_cleave";
		my @frame = ("in", "s1", "s2");
		foreach my $j (@frame)  {
			if (exists $pref5{$i}{$j})  {
				print hand5 "\t$pref5{$i}{$j}";}
			else {
				print hand5 "\t0"; }   }
		print hand5 "\n";         }
			
	close hand5;     }




__END__

