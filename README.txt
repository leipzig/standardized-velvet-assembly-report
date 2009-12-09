Requirements:
-velvet (velveth velvetg should be in your PATH)
-R (with Sweave)
-pdflatex (usually part of TeTeX)
-ggplot2 (from R prompt type install.packages("ggplot2","proto","xtable"))
-Perl

Optional:
-BLAT or BLAST (to generate alignments against a reference genome). If using BLAT, add faToTwoBit,gfClient,gfServer to your PATH. If using BLAST, add blastall and formatdb.
 
Edit permute.sh to your liking, paying particular attention to the kmer, cvCut, expCov, and other flags

To Run:
1. perl fastaAllSize mysequences.fa > mysequences.stat or gunzip -c mysequences.fa.gz | fastaAllSize > mysequences.stat. Substitute fastqAllSize for fastq files.
2. ./permute.sh mysequences (leave out the .fa)

If NOT using a reference genome skip to 6
If using Blat:
3. faToTwoBit myrefgenome.fa myrefgenome.2bit
4. gfServer start localhost 9999 myrefgenome.2bit
5. for f in out*dir; do if [ ! -e $f/contigsVsRef.psl ]; then echo $f; gfClient localhost 9999 ./ $f/contigs.fa $f/contigsVsRef.psl; fi; done
If Using BLAST:
3. formatdb -i myrefgenome -p F
4. for f in out*dir; do if [ ! -e $f/contigsVsRef.m8 ]; then echo $f; blastall -i $f/contigs.fa -p blastn -d myrefgenome -m 8 -o $f/contigsVsRef.m8; fi; done


6. for f in out*dir; do if [ ! -e $f/metadata.txt ]; then perl generateAssemblyStats.pl $f > $f/metadata.txt; fi; done
7. for f in out*dir; do echo "groupDir<-\"$f\";statFile<-\"mysequences\";statTab<-\"$f/stats.txt\";metaTab<-\"$f/metadata.txt\";source(\"calculateStats.R\")" | R --no-save --quiet; done
8. If you wish to skip the individual contig length histograms (much quicker)
     echo "assmName<-\"mysequences\";statFile<-\"mysequences\"; Sweave(\"shortReport.Rnw\",output=\"mysequences.tex\");" | R --no-save --quiet
   If using no reference genome:
     echo "assmName<-\"mysequences\";statFile<-\"mysequences\"; Sweave(\"report.Rnw\",output=\"mysequences.tex\");" | R --no-save --quiet
   If using the reference genome alignments:
     echo "refName<-\"My reference genome\";assmName<-\"mysequences\";statFile<-\"mysequences\"; Sweave(\"refReport.Rnw\",output=\"mysequences.tex\");" | R --no-save --quiet
9. pdflatex mysequences.tex
10. View the pdf report mysequences.pdf