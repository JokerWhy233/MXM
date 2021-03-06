permCR = function(target, dataset, xIndex, csIndex, wei = NULL, dataInfo=NULL, univariateModels=NULL, hash = FALSE, stat_hash=NULL, pvalue_hash=NULL,
                  robust=FALSE, threshold = 0.05, R = 999){
  # Conditional independence test based on the Log Likelihood ratio test
  if (!survival::is.Surv(target) )  stop('The survival test can not be performed without a Surv object target');
  csIndex[ which( is.na(csIndex) ) ] = 0;
  thres <- threshold * R + 1
  
  if ( hash ) {
    csIndex2 = csIndex[which(csIndex!=0)]
    csIndex2 = sort(csIndex2)
    xcs = c(xIndex,csIndex2)
    key = paste(as.character(xcs) , collapse=" ");
    if ( is.null(stat_hash[[key]]) == FALSE ) {
      stat = stat_hash[[key]];
      pvalue = pvalue_hash[[key]];
      flag = 1;
      
      results <- list(pvalue = pvalue, stat = stat, flag = flag, stat_hash=stat_hash, pvalue_hash=pvalue_hash);
      return(results);
    }
  }
  #initialization: these values will be returned whether the test cannot be carried out
  pvalue = 1;
  stat = 0;
  flag = 0;
  results <- list(pvalue = pvalue, stat = stat, flag = flag, stat_hash=stat_hash, pvalue_hash=pvalue_hash);
  cox_results = NULL;
  cox_results_full = NULL;
  #timeIndex = dim(dataset)[2];
  event = target[,2]
  x = dataset[, xIndex];
  #if the censored indicator is empty, a dummy variable is created
  numCases = dim(dataset)[1];
  if (length(event)==0)  event = vector('numeric',numCases) + 1;
      if (is.na(csIndex) || length(csIndex) == 0 || csIndex == 0) {
        cox_results <- survival::coxph(target ~ x, weights = wei )
        stat <- anova(cox_results)[2, 2]
		    if (stat > 0) {
          step <- 0
          j <- 1		
          n <- length(x)
          while (j <= R & step < thres ) {
            xb <- sample(x, n)  
            bit2 = survival::coxph( target ~ xb, weights = wei )
            step <- step + ( anova(bit2)[2, 2] > stat )
            j <- j + 1
          }
          pvalue <- (step + 1) / (R + 1) 
		}  
      } else {
	      options(warn = -1)
        cox_results_full <- survival::coxph(target ~ ., data = as.data.frame(  dataset[ , c(csIndex, xIndex)] ), weights = wei) 
        res = anova(cox_results_full)
        pr = nrow(res)
        stat = res[pr, 2]
		    if (stat > 0) {
          j <- 1		
          step <- 0
          n <- length(x)
          while (j <= R & step < thres ) {
            xb <- sample(x, n)  
            bit2 = survival::coxph( target ~ ., data = as.data.frame( cbind( dataset[, csIndex], xb ) ), weights = wei )
            step <- step + ( anova(bit2)[pr, 2] > stat )
            j <- j + 1
          }
          pvalue <- (step + 1) / (R + 1) 
		}  
      }  
      flag = 1;
      if ( is.na(pvalue) || is.na(stat) ) {
        pvalue = 1;
        stat = 0;
        flag = 0;
      } else {
        #update hash objects
        if( hash )  {
          stat_hash[[key]] <- stat;      #.set(stat_hash , key , stat)
          pvalue_hash[[key]] <- pvalue;     #.set(pvalue_hash , key , pvalue)
        }
      }
      results <- list(pvalue = pvalue, stat = stat, flag = flag , stat_hash=stat_hash, pvalue_hash=pvalue_hash);
      return(results);
}