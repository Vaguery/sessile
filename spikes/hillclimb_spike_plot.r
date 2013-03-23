# R script for plotting a simple trace of sampled Snip scripts, mutation rate, and best score so far from data

climb = read.csv("~/programming/dartmouth/ces_like/spikes/hillclimb_spike-0.out", header=TRUE)
plot(climb$mutant_score,ylim=c(0.0,1.0),cex=0.3,pch=4,col=rgb(0.2,0.3,0.6,0.5),main="periodic annealing of Snip scripts",xlab="variant",ylab="Balanced Accuracy score")
points(climb$current_score,cex=0.3,pch=3,col=rgb(0.9,0.05,0.1,0.01))
points(climb$mutation_rate,cex=0.3,pch=3,col=rgb(0.1,0.6,0.1,0.01))