## Where can I find more information on N50 length? ##
This, my most popular blog entry ever, discusses N50 in detail:

http://jermdemo.blogspot.com/2008/11/calculating-n50-from-velvet-output.html

## Why is the N50 reported in your report different from the one I see in the Log file produced by Velvet ##

The N50 in the Log file is in kmer units. The N50 in the report is in bp.

## I added kmer-1 to the N50 in the Log file and did not arrive at the number in your report. What is going on here? ##

You can't add kmer-1 to the kmer-N50 to arrive at the bp-N50. The math doesn't work like that. You need to convert all the contig lengths to bp and then calculate N50.

## I calculated the N50 from my contigs.fa file and got a different answer from kmer-N50 or your bp-N50. What the hell is wrong with this? ##

The contigs.fa contains by default only those contigs longer than 2kmers. Contigs shorter than that are considered spurious. So the N50 of sequences in your contigs.fa file will be considerably higher than that calculated from using the stats.txt file.

## Why do I get different read usage numbers when I specify -useamos in generateAssemblyStats.pl? ##

I think this is usually a side effect of allowing N's in your input sequences. Velvet will convert these to A's. If there is another read with a real A at that position Velvet will consider the N-posing-as-A read as used and the honest-A read as unused. The point being you should just leave out or trim sequences with Ns.

## I don't understand what should I use as input - contigs or reads? ##

Use quality trimmed reads as input.

## What should I use to quality trim my reads? ##
Nikhil Joshi's Trim will handle soft trimming with pair mate widows

http://wiki.bioinformatics.ucdavis.edu/index.php/Trim.pl

Joseph Fass's TrimBWAStyle is a slightly different algorithm

http://wiki.bioinformatics.ucdavis.edu/index.php/TrimBWAstyle.pl

## How should I use your report? ##

This report simply provides a way of visualizing the effect of kmer and cvCut on your assemblies.

If you find that your assemblies "converge" or arrive at roughly the same results, then you can choose one arbitrarily and move on. If you find that your assemblies are scattered across the landscape of size, contig count, read usage, and N50, then you will need to consider what levels of stringency and sensitivity you are willing to accept.

Any assembly will be composed of:

  * correct contigs
  * fragmented contigs
  * chimeric contigs
  * spurious contigs

and may suffer from:

  * missing contigs


I would consider chimeras and spurious contigs to be distinguished by length - spurious contigs are an artifact of the debruijn method and are very short. I don't think chimeras are very common in Velvet compared to other assemblers - any ambiguity normally results in fragments.

Velvet assemblies performed under high stringency (high kmer, high cvCut) conditions will minimize chimeric, fragmented and spurious contigs at the expense of more missing contigs.

To validate a de-novo short read assembly, especially a transcriptome which by its very nature will never form long contigs, you need to decide whether you are willing to accept some bad with the good or insist on just the good and get less of it. This is a classic signal-to-noise problem.