ulimit -v 240000000
PATH=$PATH:./
if [ ! -e $1".fa" ]
then
    echo "cannot find $1.fa"
    exit
fi
for kmer in 31 29 27 25 23
do
    if [ -e "out_"$1"_"$kmer"/Roadmaps" ]
    then
	echo "roadmap ready"
    else
	echo "running velveth"
	velveth "out_"$1"_"$kmer $kmer -fasta -shortPaired $1.fa
    fi
    for cvCut in 10 6 4 3 2
    do
    expCov=$((2*$cvCut))
                dirName="out_"$1"_"$kmer"_"$cvCut"_"$expCov"_dir"
		if [ -e $dirName"/contigs.fa" ]
		then
		    echo "I see the contigs.fa file in $dirName"
		else
		    mkdir $dirName
		    ln -s "../out_"$1"_"$kmer/Sequences $dirName"/Sequences" 
                    ln -s "../out_"$1"_"$kmer/Roadmaps $dirName"/Roadmaps"
                    cp "out_"$1"_"$kmer/Log $dirName"/Log"
		    echo  $dirName

		    echo velvetg
                    velvetg $dirName -exp_cov $expCov -cov_cutoff $cvCut -read_trkg yes -amos_file yes -unused_reads yes
		    gzip $dirName"/velvet_asm.afg" &
		    rm $dirName"/LastGraph"
		    rm $dirName"/Graph2"
		    rm $dirName"/PreGraph"
		    rm $dirName"/Sequences"
		    rm $dirName"/Roadmaps"
		fi
done
done