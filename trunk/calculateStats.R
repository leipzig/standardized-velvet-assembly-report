myTable<-read.table(statTab,header=TRUE)
myMeta<-read.table(metaTab,header=TRUE)
library(proto)

myArray<-as.vector(myMeta)
myArray["groupDir"]<-groupDir
#bottom filter on contig length is set by default
#myTable<-myTable[myTable$lgth>(myMeta$kmer-1),]

myArray["ctgs"]<-nrow(myTable)
myArray["meanLgth"]<-mean(myTable$lgth+myMeta$kmer-1)
myArray["medianLgth"]<-median(myTable$lgth+myMeta$kmer-1)
myArray["totalCoverage"]<-sum(myTable$lgth+myMeta$kmer-1)

#https://stat.ethz.ch/pipermail/r-help/2008-November/180966.html
x<-rev(sort(myTable$lgth+myMeta$kmer-1))
myArray["N50"]<-x[cumsum(x) > sum(x)/2][1]

statFileName<-paste(statFile,".frame.RData",sep="")
if(length(dir(pattern=statFileName))>0){
	load(statFileName)
	myDataFrame<-rbind(myDataFrame,as.data.frame(myArray,row.names<-NULL))
}else{
	myDataFrame<-as.data.frame(myArray,row.names<-NULL)
}

save(myDataFrame,file=statFileName,compress=TRUE)
