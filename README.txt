Requirements:
-velvet (velveth velvetg should be in your PATH)
-R (with Sweave)
-pdflatex (usually part of TeTeX)
-ggplot2 (from R prompt type install.packages("ggplot2","proto","xtable"))
-Perl
-BLAT (to generate alignments against a reference genome, add faToTwoBit,gfClient,gfServer to your PATH)

Edit permute.sh to your liking, paying particular attention to the kmer, cvCut, expCov, and other flags

To Run:
1. perl fastaAllSize mysequences.fa > mysequences.stat
2. ./permute.sh mysequences (leave out the .fa)
3. faToTwoBit myrefgenome.fa myrefgenome.2bit
4. gfServer start localhost 9999 myrefgenome.2bit
5. for f in out*dir; do if [ ! -e $f/contigsVsRef.psl ]; then echo $f; gfClient localhost 9999 ./ $f/contigs.fa $f/contigsVsRef.psl; fi; done
6. for f in out*dir; do if [ ! -e $f/metadata.txt ]; then perl generateAssemblyStatsBlat.pl $f contigsVsRef.psl > $f/metadata.txt; fi; done
7. for f in out*dir; do echo "groupDir<-\"$f\";statFile<-\"mysequences\";statTab<-\"$f/stats.txt\";metaTab<-\"$f/metadata.txt\";source(\"calculateStats.R\")" | R --no-save --quiet; done
8. echo "refName<-\"My reference genome\";assmName<-\"mysequences\";statFile<-\"mysequences\"; Sweave(\"report.Rnw\",output=\"mysequences.tex\");" | R --no-save --quiet
9. pdflatex mysequences.tex
10. View the pdf report mysequences.pdf