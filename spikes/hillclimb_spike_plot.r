# R script for plotting a simple trace of sampled Snip scripts, mutation rate, and best score so far from data

climb = read.csv("~/programming/dartmouth/ces_like/spikes/hillclimb_spike-0.out", header=TRUE); 
  plot(climb$mutant_score,ylim=c(0.0,1.0),cex=0.3,pch=4,col=rgb(0.2,0.3,0.6,0.5),main="multiscale hillclimbing of Snip scripts",xlab="variant",ylab="Balanced Accuracy score"); 
  points(x=climb$improvement_rate,cex=0.3,pch=2,col=rgb(0.9,0.1,0.1,0.3),type="l"); 
  points(climb$silent_rate,cex=0.3,pch=3,col=rgb(0.1,0.9,0.1,0.3),type="l"); 
  points(climb$change_rate,cex=0.3,pch=3,col=rgb(0.1,0.1,0.9,0.3),type="l");
  legend(100,1.0,c("improved","silent","expressed"),col=c(rgb(0.9,0.1,0.1,0.3),rgb(0.1,0.9,0.1,0.3),rgb(0.1,0.1,0.9,0.3)),lty=1)