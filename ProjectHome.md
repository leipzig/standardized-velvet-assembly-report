# Screenshots: #
| ![http://lh3.ggpht.com/_AWkLjPyyn0g/SpMal_Ykm6I/AAAAAAAAATw/hiHn39DcuNc/s200/example.png](http://lh3.ggpht.com/_AWkLjPyyn0g/SpMal_Ykm6I/AAAAAAAAATw/hiHn39DcuNc/s200/example.png) | ![http://lh6.ggpht.com/_AWkLjPyyn0g/SszoyTlMp0I/AAAAAAAAAVw/HUeyJSKOz0M/s200/readUsage.png](http://lh6.ggpht.com/_AWkLjPyyn0g/SszoyTlMp0I/AAAAAAAAAVw/HUeyJSKOz0M/s200/readUsage.png) |
|:----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|:--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|

# Requirements: #
  * velvet (velveth,velvetg should be in your PATH)
  * R (with Sweave, usually included)
  * R libraries (from R prompt type install.packages("ggplot2","proto","xtable"))
  * pdflatex (usually part of TeTeX)
  * Perl (with PerlIO::gzip)

# Optional: #
  * To generate alignments against a reference genome, use either
    * BLAT (add to your PATH)
    * BLAST (add to your PATH)

# To Download: #
  * Get Subversion
  * `svn checkout http://standardized-velvet-assembly-report.googlecode.com/svn/trunk/ standardized-velvet-assembly-report-read-only`

# To Run: #
  * Edit permute.sh to your liking, paying particular attention to the kmer, cvCut, expCov, and other crucial flags like shortPaired
  * `perl fastaAllSize mysequences.fa > mysequences.stat`
  * `./permute.sh mysequences (leave out the .fa)`

  * If NOT using a reference genome skip this section
    * If using Blat:
      * `faToTwoBit myrefgenome.fa myrefgenome.2bit`
      * `gfServer start localhost 9999 myrefgenome.2bit`
      * `for f in out*dir; do if [ ! -e $f/contigsVsRef.psl ]; then echo $f; gfClient localhost 9999 ./ $f/contigs.fa $f/contigsVsRef.psl; fi; done`
    * If using BLAST:
      * `formatdb -i myrefgenome -p F`
      * `for f in out*dir; do if [ ! -e $f/contigsVsRef.m8 ]; then echo $f; blastall -i $f/contigs.fa -p blastn -d myrefgenome -m 8 -o $f/contigsVsRef.m8; fi; done`


  * `for f in out*dir; do if [ ! -e $f/metadata.txt ]; then perl generateAssemblyStats.pl $f > $f/metadata.txt; fi; done`
  * `for f in out*dir; do echo "groupDir<-\"$f\";statFile<-\"mysequences\";statTab<-\"$f/stats.txt\";metaTab<-\"$f/metadata.txt\";source(\"calculateStats.R\")" | R --no-save --quiet; done`

  * Choose one of three report formats
    * If you wish to skip the individual contig length histograms (much quicker)
> > > `echo "assmName<-\"mysequences\";statFile<-\"mysequences\"; Sweave(\"shortReport.Rnw\",output=\"mysequences.tex\");" | R --no-save --quiet`
    * If using no reference genome:
> > > `echo "assmName<-\"mysequences\";statFile<-\"mysequences\"; Sweave(\"report.Rnw\",output=\"mysequences.tex\");" | R --no-save --quiet`
    * If using the reference genome alignments:
> > > `echo "refName<-\"My reference genome\";assmName<-\"mysequences\";statFile<-\"mysequences\"; Sweave(\"refReport.Rnw\",output=\"mysequences.tex\");" | R --no-save --quiet`



  * `pdflatex mysequences.tex`
  * View the pdf report mysequences.pdf