#!/usr/bin/perl

use PerlIO::gzip;

$rootDir=$ARGV[0];

opendir(DIR, $rootDir);
@blatfiles = grep(/\.psl$/,readdir(DIR));
@blastfiles = grep(/\.m8$/,readdir(DIR));
closedir(DIR);

if(scalar(@blatfiles)){
    $blatFile=$blatfiles[0];
    open(BLAT,"<$rootDir/$blatFile") or die("can't find blat file");
    %winners;
    %lengths;
    while(<BLAT>){
    #match   mis-    rep.    N's     Q gap   Q gap   T gap   T gap   strand  Q               Q       Q       Q       T               T       T       T       block   blockSizes      qStarts  tStarts
    #        match   match           count   bases   count   bases           name            size    start   end     name            size    start   end     count
    #---------------------------------------------------------------------------------------------------------------------------------------------------------------
    #45      0       0       0       0       0       0       0       -       NODE_1_length_31_cov_17.741936  45      0       45      AC207475.3      175195  14643   14688   1       45,     0,      14643,

    	if(
	   ($match,$query,$qSize)=$_=~/^(\d+)\t\d+\t\d+\t\d+\t\d+\t\d+\t\d+\t\d+\t[-+]\t(\S+)\t(\d+)/
	   ){
	   if($match/$qSize>=0.90){
	  $winners{$query}++;$lengths{$query}=$match
        }
       }
    }
    close(BLAT);
}else{
    if(scalar(@blastfiles)){
	$blastFile=$blastfiles[0];
open(BLAST,"<$rootDir/$blastFile") or die("can't find blast file");
while(<BLAST>){
        ($query,$lgth,$bit)=$_=~/^(\S+)\t\S+\t\S+\t(\d+).+\t\s?([0-9.]+)$/;
        if($query ne $oq){
            $winners{$query}=$bit;
            $lengths{$query}=$lgth;
            $ob=$bit;
            $oq=$query;
        }elsif($winners{$query}>0 && $bit>0.95*$ob){
            $winners{$query}=0;
        }
}
close(BLAST);
    }
}




if(scalar(@blatfiles) || scalar(@blastfiles)){
#length of all decent blatted queries
$alignLen=0;
foreach $q(keys %lengths)
{$alignLen+=$lengths{$q}}

#any queries that blatted well
$alignWin=scalar(keys(%winners));

#find distinctive hits
$uniqueHits=0;
foreach $h(keys(%winners)){
    if($winners{$h}==1){$uniqueHits++}
}
}#if blatfile or blastfile

open(CONTIGS,"<$rootDir/contigs.fa");
$totBP=0;$goodContigs=0;
while(<CONTIGS>)
{
    chomp();
    if(/>/){$goodContigs++;}
    else{$totBP+=length($_);}
}
close(CONTIGS);
open(LOG,"<$rootDir/Log") or die("can't find log file");
while($line=<LOG>){
  print STDERR $line."\n";

  if($line=~/velveth/){
      ($kmer)=$line=~/ (\d+) /; #kmer usually an isolated entry
  }
  if($line=~/velvetg/){
    ($cvCut) =$line=~/-cov_cutoff ([0-9.]+)/;
    ($expCov)=$line=~/-exp_cov ([0-9.]+)/;
  } 
}
close(LOG);


$reads=0;
$tiles=0;
$inTile=0;#AMOS file does not distinguish src as reads in a node from nodes in a contig
%readSrc;
open ASM,"<:gzip","$rootDir/velvet_asm.afg.gz" or open ASM,"<$rootDir/velvet_asm.afg" or die "can't find .afg file";
while(<ASM>){
    if(/\{RED/){$reads++}
    elsif(/\{TLE/){$inTile=1;}
    elsif(/src/){if($inTile){$readSrc{$_}=1;$inTile=0;}}
    #elsif(/\{CTG/){$contigs++}not reliable
}
close(ASM);
$tiles=scalar keys %readSrc;

print "totBP"."\t"."reads"."\t"."tiles"."\t"."goodContigs"."\t"."kmer"."\t"."cvCut"."\t"."expCov";
print "\t"."blatHit"."\t"."bpAligned"."\t"."uniqueHits" if (scalar(@blatfiles));
print "\n";
print "$totBP\t$reads\t$tiles\t$goodContigs\t$kmer\t$cvCut\t$expCov";
print "\t$alignWin\t$alignLen\t$uniqueHits" if (scalar(@blatfiles));
print "\n";
