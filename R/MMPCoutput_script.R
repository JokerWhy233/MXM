#class object for MMPC output

#Class MMPCoutput

#MMPCoutput object
# Function1: summary (generic for summary)
# Function2: plot (generic for plot)

#defining the class

setOldClass('proc_time')

setClass(Class='MMPCoutput', 
         slots=list(selectedVars='numeric', selectedVarsOrder='numeric', hashObject='list', pvalues='numeric', stats='numeric', univ='list', max_k='numeric', threshold='numeric', n.tests ='numeric', runtime='proc_time', test='character', rob='logical'), 
         prototype=list(selectedVars=NULL, selectedVarsOrder=NULL, hashObject=NULL, pvalues=NULL, stats=NULL, univ=NULL, max_k=NULL, threshold=NULL,n.tests=NULL, runtime=NULL, test=NULL, rob=NULL));

setMethod("summary", signature(object="MMPCoutput"), 
          function(object){
            x = object;
            #cat("General summary of the MMPCoutput object:\n")
            #summary(x);
            if ( length(x@selectedVars) == 0 ) {
              cat("\nSelected Variables: ")
              print(x@selectedVars);
              cat("\nSelected Variables ordered by pvalue: ")
              print(x@selectedVarsOrder);
              cat("\nhashObject summary:\n")
              print(base::summary(x@hashObject));
              cat("\nSummary of the generated pvalues matrix:\n")
              print(base::summary(x@pvalues));
              cat("\nSummary of the generated stats matrix:\n")
              print(base::summary(x@stats));
              cat("\nUnivariate associations:\n")
              print(x@univ)
              cat("\nmax_k option: ")
              cat(x@max_k);
              cat("\nthreshold option: ")
              cat(x@threshold);
              cat("\nTest: ")
              cat(x@test);
              cat("\nNumber of tests: ")
              cat(x@n.tests);
              cat("\nTotal Runtime:\n")
              print(x@runtime)
              #cat("    user system elapsed\n")
              #print(x@runtime[1:3]);
              cat("\nRobust:\n")
              print(x@rob)
            } else {
              cat("\nSelected Variables: ")
              print(x@selectedVars);
              cat("\nSelected Variables ordered by pvalue: ")
              print(x@selectedVarsOrder);
              cat("\nhashObject summary:\n")
              print(base::summary(x@hashObject));
              cat("\nSummary of the generated pvalues matrix:\n")
              print(base::summary(x@pvalues));
              cat("\nSummary of the generated stats matrix:\n")
              print(base::summary(x@stats));
              cat("\nUnivariate associations:\n")
              print(x@univ)
              cat("\nmax_k option: ")
              print(x@max_k);
              cat("\nthreshold option: ")
              print(x@threshold);
              cat("\nTest: ")
              cat(x@test);
              cat("\nNumber of tests: ")
              cat(x@n.tests);
              cat("\nTotal Runtime:\n")
              print(x@runtime)
              #cat("    user system elapsed\n")
              #print(x@runtime[1:3]);
              cat("\nRobust:\n")
              print(x@rob)
            }
          }
);
setMethod("plot", signature(x="MMPCoutput"), 
          function(x,mode="all", ...){
            
            if ( length(x@pvalues) <= 1000 ) {
              mode="all";
            }
            
            if (mode=="partial") {
              barplot(x@pvalues[1:500]);
              grid(nx = NA, ny = NULL, col = "black")
              b = barplot(add = TRUE,x@pvalues[1:500], main="Variables' Pvalues for null hypothesis: Ind(var, target)",xlab="Variable ID",ylab = "p-value" , beside=TRUE , border = FALSE)
              threshold_line = rep(x@threshold, 3*length(x@pvalues))
              lines(threshold_line , col="red" , lwd= 2.5)
              legend('topleft' ,  paste('threshold:',x@threshold, sep=" ") , lwd= 2.5,col="red" , bty = "n")
              labels = c(1,x@selectedVars,length(x@pvalues))
              axis(1, at=b[c(1,x@selectedVars,length(x@pvalues))],labels=labels)
            } else {
              barplot(x@pvalues);
              grid(nx = NA, ny = NULL, col = "black")
              b = barplot(add = TRUE,x@pvalues, main="Variables' Pvalues for null hypothesis: Ind(var, target)",xlab="Variable ID",ylab = "p-value" , beside=TRUE , border = FALSE)
              threshold_line = rep(x@threshold, 3*length(x@pvalues))
              lines(threshold_line , col="red" , lwd= 2.5)
              legend('topleft' ,  paste('threshold:',x@threshold, sep=" ") , lwd= 3,col="red" , bty = "n")
              labels = c(1,x@selectedVars,length(x@pvalues))
              axis(1, at=b[c(1,x@selectedVars,length(x@pvalues))],labels=labels)
            }
          }
);

