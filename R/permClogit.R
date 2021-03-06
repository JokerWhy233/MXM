permClogit = function(target, dataset, xIndex, csIndex, wei = NULL, dataInfo=NULL, univariateModels=NULL, hash = FALSE, stat_hash=NULL, pvalue_hash=NULL,
                         robust=FALSE, threshold = 0.05, R = 999) {

  csIndex[which(is.na(csIndex))] = 0;
  thres <- threshold * R + 1
  
  if( hash )  {
    csIndex2 = csIndex[which(csIndex!=0)]
    csIndex2 = sort(csIndex2)
    xcs = c(xIndex,csIndex2)
    key = paste(as.character(xcs) , collapse=" ");
    if ( !is.null(stat_hash[[key]]) )  {
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
  clogit_results = NULL;
  clogit_results_full = NULL;
  id = target[, 2] #the patient id
  x = dataset[ , xIndex];
  cs = dataset[, csIndex];
  case = as.logical(target[, 1]);  ## case control, 0 is the control
  #if the conditioningset (cs) is empty, lets take it easy.
  res <- tryCatch(
    {
    if (is.na(csIndex) || length(csIndex) == 0 || csIndex == 0) {
    #perform the test. If the clogit function launches a warning, the
    #function returns "flag=0", that means "the test cannot be performed"
    #fitting the model
      clogit_results <- survival::clogit(case ~ x + strata(id) )
      #retrieve the p value and stat.
      dof = length( coef(clogit_results) ) 
      stat = abs( diff(clogit_results$loglik) )
      step <- 0
      j <- 1		
      n <- length(target)
      while (j <= R & step < thres ) {
        xb <- sample(x, n)  
        bit2 <- survival::clogit( case ~ xb + strata(id) ) 
        step <- step + ( abs( diff(bit2$loglik) ) > stat )
        j <- j + 1
      }
	    stat <- 2 * stat
      pvalue <-  (step + 1) / (R + 1)

      if ( hash )  {   #update hash objects
        stat_hash[[key]] <- stat;   #.set(stat_hash , key , stat)
        pvalue_hash[[key]] <- pvalue;   #.set(pvalue_hash , key , pvalue)
      }
      flag = 1;
    
    } else {
      clogit_results <- survival::clogit(case ~ . + strata(id), data = as.data.frame( dataset[ , c(csIndex)] ) ) 
      #fitting the full model
      clogit_results_full <- survival::clogit(case ~ . + strata(id), data = as.data.frame(  dataset[ , c(csIndex, xIndex)] ) )
      #retrieving the p value
      stat = anova(clogit_results_full, clogit_results)[2, 2]
      step <- 0
      j <- 1		
      n <- length(x)
      while (j <= R & step < thres ) {
        xb <- sample(x, n)  
        bit2 <- survival::clogit( case ~ cbind(cs, xb) + strata(id) ) 
        step <- step + ( anova(bit2, clogit_results)[2, 2] > stat )
        j <- j + 1
      }
      pvalue <- (step + 1) / (R + 1) 
      if( hash )  {                #update hash objects
        stat_hash[[key]] <- stat;             #.set(stat_hash , key , stat)
        pvalue_hash[[key]] <- pvalue;         #.set(pvalue_hash , key , pvalue)
      }
      flag = 1;
    }
    results = list(pvalue = pvalue, stat = stat, flag = flag, stat_hash=stat_hash, pvalue_hash=pvalue_hash);
    return(results);
  },
  error=function(cond) {
    #   message(paste("error in try catch of the testIndZIP test"))
    #   message("Here's the original error message:")
    #   message(cond)
    #   #        #for debug
    #   #        print("\nxIndex = \n");
    #   #        print(xIndex);
    #   #        print("\ncsindex = \n");
    #   #        print(csIndex);
    #   stop();
    #error case
    pvalue = log(1);
    stat = 0;
    flag = 0;
    results <- list(pvalue = pvalue, stat = stat, flag = flag , stat_hash=stat_hash, pvalue_hash=pvalue_hash);
    return(results);
  },  
    finally={}
  )
  return(res);
}