ulimit -v 240000000
PATH=$PATH:./
if [ -z "$1" ]
then
    echo "I need a sequence name (without the extension) as an argument"
    exit
fi
#try to guess the correct extension from ls
ext=$(ls $1* | grep -oE -m1 '(.fa|.fq|.fasta|.fastq|.eland|.gerald)(.gz)?$')
if [ ! -e "$1""$ext" ]
then
    echo "Cannot find $1$ext"
    exit
fi
longExt="`echo $ext | sed -e 's/\.fa\(sta\)*/fasta/;s/\.fq/fastq/;s/^\.//;'`"

if [ ! -e $1".stat" ]
then
    if [ "${ext##*.}" = "gz" ]
    then
	echo "Cannot find $1.stat. Please run gunzip -c $1$ext | fast(a or q)AllSize > $1.stat on your sequences."
    else
        echo "Cannot find $1.stat. Please run fast(a or q)AllSize $1$ext > $1.stat on your sequences."
    fi
    exit
fi
for kmer in 31 27 23 21
do
    if [ -e "out_"$1"_"$kmer"/Roadmaps" ]
    then
	echo "roadmap ready"
    else
	echo "running velveth"
	velveth "out_"$1"_"$kmer $kmer -$longExt -shortPaired $1$ext
    fi
    for cvCut in 12 10 6 4 3 2
    do
    expCov=$((2*$cvCut))
                dirName="out_"$1"_"$kmer"_"$cvCut"_"$expCov"_dir"
		if [ -e $dirName"/contigs.fa" ] || [ -e $dirName"/contigs.fa.gz" ]
		then
		    echo "I see contigs in $dirName"
		else
		    mkdir $dirName
                    ln -s "../"$1$ext $dirName"/reads"$ext
		    ln -s "../"$1".stat" $dirName"/reads.stat"
		    ln -s "../out_"$1"_"$kmer/Sequences $dirName"/Sequences" 
                    ln -s "../out_"$1"_"$kmer/Roadmaps $dirName"/Roadmaps"
                    cp "out_"$1"_"$kmer/Log $dirName"/Log"
		    echo  $dirName

		    echo velvetg
		    #you will need to set -amos_file to yes if you are using the -useamos option in generateAssemblyStats.pl to count read usage instead of Unused reads
                    velvetg $dirName -exp_cov $expCov -cov_cutoff $cvCut -read_trkg yes -amos_file no -unused_reads yes
                    if [ $? != 0 ]
		    then
			echo "velvetg did not run normally"
                        exit
                    fi
		    gzip $dirName"/velvet_asm.afg" &
		    rm $dirName"/LastGraph"
		    rm $dirName"/Graph2"
		    rm $dirName"/PreGraph"
		    rm $dirName"/Sequences"
		    rm $dirName"/Roadmaps"
		fi
done
done