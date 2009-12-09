#!/usr/bin/perl
use strict;
use PerlIO::gzip;
use Getopt::Long;
use Pod::Usage;

my ($man,$help);
my $useamos = 0; #slower, will return lower read usage relative to using UnusedReads.fa

GetOptions('useamos'=>\$useamos,'help|?' => \$help,'man' => \$man) or pod2usage(2);
pod2usage(1) if ($help || (@ARGV==0));
pod2usage(-exitstatus => 0, -verbose => 2) if $man;

my $rootDir = shift @ARGV;
die("$rootDir is not a directory") unless (-d $rootDir);

opendir( DIR, $rootDir );
my @allfiles   = readdir(DIR);
my @blatfiles  = grep( /\.psl$/, @allfiles );
my @blastfiles = grep( /m8$/, @allfiles );
my @readsfiles = grep( /^reads.stat/, @allfiles );
closedir(DIR);

my ( %winners,  %lengths );                  #from blat or blast
my ( $alignLen, $alignWin, $uniqueHits );    #from blat or blast
my ( $kmer,     $cvCut, $expCov );           #from log file
my ( $totBP,    $goodContigs );              #from contigs file

my ( $reads, $tiles );    #from either Reads/UnusedReads or velvet_asm.afg AMOS file

if ( scalar(@blatfiles) ) {
    parseBlat( $blatfiles[0], \%winners, \%lengths );
}
elsif ( scalar(@blastfiles) ) {
    parseBlast( $blastfiles[0], \%winners, \%lengths );
}
if ( scalar(@blatfiles) || scalar(@blastfiles) ) {
    postAlign( \%winners, \%lengths );
}

countContigs();

if ( $useamos == 1 ) {
    getTilesUsingAMOS();
}
else {
    getTilesUsingReads();
}

parseLogFile();

print join "\t", qw /totBP reads tiles goodContigs kmer cvCut expCov/;
print "\tblatHit\tbpAligned\tuniqueHits"
  if ( scalar(@blatfiles) || scalar(@blastfiles) );
print "\n";
print "$totBP\t$reads\t$tiles\t$goodContigs\t$kmer\t$cvCut\t$expCov";
print "\t$alignWin\t$alignLen\t$uniqueHits"
  if ( scalar(@blatfiles) || scalar(@blastfiles) );
print "\n";

sub parseBlat {
    my ( $blatFile, $winnersref, $lengthsref ) = @_;
    open( BLAT, "<$rootDir/$blatFile" ) or die("can't find blat file");

    while (<BLAT>) {

#match   mis-    rep.    N's     Q gap   Q gap   T gap   T gap   strand  Q               Q       Q       Q       T               T       T       T       block   blockSizes      qStarts  tStarts
#        match   match           count   bases   count   bases           name            size    start   end     name            size    start   end     count
#---------------------------------------------------------------------------------------------------------------------------------------------------------------
#45      0       0       0       0       0       0       0       -       NODE_1_length_31_cov_17.741936  45      0       45      AC207475.3      175195  14643   14688   1       45,     0,      14643,

        if ( my ( $match, $query, $qSize ) =
            $_ =~
            /^(\d+)\t\d+\t\d+\t\d+\t\d+\t\d+\t\d+\t\d+\t[-+]\t(\S+)\t(\d+)/ )
        {
            if ( $match / $qSize >= 0.90 ) {
                $winnersref->{$query}++;
                $lengthsref->{$query} = $match;
            }
        }
    }
    close(BLAT);
}

sub parseBlast {
    my ( $blastFile, $winnersref, $lengthsref ) = @_;
    open( BLAST, "<$rootDir/$blastFile" ) or die("can't find blast file");
    my ( $oq, $ob );
    while (<BLAST>) {
        my ( $query, $lgth, $bit ) =
          $_ =~ /^(\S+)\t\S+\t\S+\t(\d+).+\t\s?([0-9.]+)$/;
        if ( $query ne $oq ) {
            $winnersref->{$query} = $bit;
            $lengthsref->{$query} = $lgth;
            $ob                   = $bit;
            $oq                   = $query;
        }
        elsif ( $winnersref->{$query} > 0 && $bit > 0.95 * $ob ) {
            $winnersref->{$query} = 0;
        }
    }
    close(BLAST);
}

sub postAlign {

    #length of all decent blatted queries

    foreach my $q ( keys %lengths ) { $alignLen += $lengths{$q} }

    #any queries that blatted well
    $alignWin = scalar( keys(%winners) );

    #find distinctive hits
    foreach my $h ( keys(%winners) ) {
        if ( $winners{$h} == 1 ) { $uniqueHits++ }
    }
}

sub getTilesUsingReads {
    my $readType;
    if ( -e "$rootDir/reads.stat" ){
	open( READS, "<$rootDir/reads.stat" );
    }else{
	die("can't find reads.stat file");
    }
    while(<READS>)
    {
	if(/^(\d+)\t(\d+)$/){
	    $reads=$1;
	}
    }

    if ( -e "$rootDir/UnusedReads.fa" ) {
        open( UNUSED, "<$rootDir/UnusedReads.fa" );
    }
    elsif ( -e "$rootDir/UnusedReads.fa.gz" ) {
        open( UNUSED, "<:gzip", "$rootDir/UnusedReads.fa.gz" );
    }
    else {
        die("can't find a suitable UnusedReads file");
    }
    my ($unusedReads);
    while (<UNUSED>) {
        if (/>/) { $unusedReads++; }
    }
    close(UNUSED);
    $tiles = $reads - $unusedReads;
}

sub getTilesUsingAMOS {

#warning: using the velvet_asm.afg file will deflate your read usage compared to the Log as redundant reads are not credited in the file
#AMOS file does not distinguish src as reads in a node from nodes in a contig
    my $inTile;

    my %readSrc;

    if ( -e "$rootDir/velvet_asm.afg" ) {
        open( ASM, "<$rootDir/velvet_asm.afg" );
    }
    elsif ( -e "$rootDir/velvet_asm.afg.gz" ) {
        open( ASM, "<:gzip", "$rootDir/velvet_asm.afg.gz" );
    }
    else {
        die("can't find a suitable .afg file");
    }

    while (<ASM>) {
        if (/\{RED/) { $reads++ }
        elsif (/\{TLE/) { $inTile = 1; }
        elsif (/src/) {
            if ($inTile) { $readSrc{$_} = 1; $inTile = 0; }
        }
    }
    close(ASM);
    $tiles = scalar keys %readSrc;
}

sub countContigs {
    if ( -e "$rootDir/contigs.fa" ) {
        open( CONTIGS, "<$rootDir/contigs.fa" );
    }
    elsif ( -e "$rootDir/contigs.fa.gz" ) {
        open( CONTIGS, "<:gzip", "$rootDir/contigs.fa.gz" );
    }
    else {
        die("can't find a suitable contigs file");
    }

    while (<CONTIGS>) {
        chomp();
        if   (/>/) { $goodContigs++; }
        else       { $totBP += length($_); }
    }
    close(CONTIGS);
}

sub parseLogFile {
    open( LOG, "<$rootDir/Log" ) or die("can't find log file");
    while ( my $line = <LOG> ) {
        print STDERR $line . "\n";

        if ( $line =~ /velveth/ ) {
            ($kmer) = $line =~ / (\d+) /;    #kmer usually an isolated entry
        }
        if ( $line =~ /velvetg/ ) {
            ($cvCut)  = $line =~ /-cov_cutoff ([0-9.]+)/;
            ($expCov) = $line =~ /-exp_cov ([0-9.]+)/;
        }
    }
    close(LOG);
}

 __END__
 
=head1 Generate Assembly Stats
 
=head1 SYNOPSIS

generateAssemblyStats.pl -useamos ./out_ecoli_31_38_76_dir

Options:
  -help
  -useamos use velvet_asm.afg instead of UnusedReads.fa to compute read usage

=head1 OPTIONS

=over 8
 
=item B<-help>
 
This help message

=back

=over 8
 
=item B<-useamos>

Use velvet_asm.afg instead of UnusedReads.fa to compute read usage. This will make your reports comparable to older versions of SVAR, but it is slower and will return lower read usage relative to using UnusedReads.fa

=back

=head1 DESCRIPTION

Produce a tab-delimited metadata file for Standard Velvet Assembly reports

=cut

