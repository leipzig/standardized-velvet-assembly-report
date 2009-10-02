myTable<-read.table(statTab,header=TRUE)
myMeta<-read.table(metaTab,header=TRUE)
#http://www.mail-archive.com/r-help@stat.math.ethz.ch/msg74771.html
library(proto)

myArray<-as.vector(myMeta)
myArray["groupDir"]<-groupDir
myArray["ctgs"]<-nrow(myTable)
myArray["meanLgth"]<-mean(myTable$lgth+myMeta$kmer-1)
myArray["medianLgth"]<-median(myTable$lgth+myMeta$kmer-1)
myArray["totalCoverage"]<-sum(myTable$lgth+myMeta$kmer-1)
myArray["maxLgth"]<-max(myTable$lgth+myMeta$kmer-1)
myArray["over1k"]<-length(which(myTable$lgth+myMeta$kmer-1>=1000))

#https://stat.ethz.ch/pipermail/r-help/2008-November/180966.html
x<-rev(sort(myTable$lgth+myMeta$kmer-1))
myArray["N50"]<-x[cumsum(x) >= sum(x)/2][1]

statFileName<-paste(statFile,".frame.RData",sep="")
if(length(dir(pattern=statFileName))>0){
	load(statFileName)
	myDataFrame<-rbind(myDataFrame,as.data.frame(myArray,row.names<-NULL))
}else{
	myDataFrame<-as.data.frame(myArray,row.names<-NULL)
}

save(myDataFrame,file=statFileName,compress=TRUE)
