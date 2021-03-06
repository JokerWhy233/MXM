permMVreg = function(target, dataset, xIndex, csIndex, wei = NULL, dataInfo=NULL, univariateModels=NULL, hash = FALSE, stat_hash=NULL, 
 pvalue_hash=NULL, robust=FALSE, threshold = 0.05, R = 999) {
  # TESTINDMVREG Conditional Independence Test for multivariate continous class variables 
  # PVALUE = TESTINDMVREG(Y, DATA, XINDEX, CSINDEX, DATAINFO)
  # This test provides a p-value PVALUE for the NULL hypothesis H0 which is
  # X is independent by TARGET given CS. The pvalue is calculated following
  # nested models
  # This method requires the following inputs
  #   TARGET: a numeric matrix containing the values of the target (continuous) variable. 
  #   Its support can be R or any number betweeen 0 and 1, i.e. it contains proportions.
  #   DATASET: a numeric data matrix containing the variables for performing the test. They can be mixed variables. 
  #   XINDEX: the index of the variable whose association with the target we want to test. 
  #   CSINDEX: the indices if the variable to condition on. 
  #   DATAINFO: information on the structure of the data
  # this method returns: the pvalue PVALUE, the statistic STAT and a control variable FLAG.
  # if FLAG == 1 then the test was performed succesfully
  #if the test cannot performed succesfully these are the returned values
  pvalue = 1;
  stat = 0;
  flag = 0;
  csIndex[which(is.na(csIndex))] = 0;
  thres <- threshold * R + 1
  
  if ( hash )  {
    csIndex2 = csIndex[which(csIndex!=0)]
    csIndex2 = sort(csIndex2)
    xcs = c(xIndex,csIndex2)
    key = paste(as.character(xcs) , collapse=" ");
    if ( !is.null(stat_hash[[key]]) )   {
      stat = stat_hash[[key]];
      pvalue = pvalue_hash[[key]];
      flag = 1;
      results <- list(pvalue = pvalue, stat = stat, flag = flag , stat_hash=stat_hash, pvalue_hash=pvalue_hash);
      return(results);
    }
  }
  
  #if the xIndex is contained in csIndex, x does not bring any new
  #information with respect to cs
  if ( !is.na(match(xIndex,csIndex)) )   {
    if ( hash ) {     #update hash objects
      stat_hash$key <- 0;  #.set(stat_hash , key , 0)
      pvalue_hash$key <- 1;  #.set(pvalue_hash , key , 1)
    }
    results <- list(pvalue = 1, stat = 0, flag = 1, stat_hash=stat_hash, pvalue_hash=pvalue_hash);
    return(results);
  }
  #check input validity
  if(xIndex < 0 || csIndex < 0) {
    message(paste("error in testIndMVreg : wrong input of xIndex or csIndex"))
    results <- list(pvalue = pvalue, stat = stat, flag = flag, stat_hash=stat_hash, pvalue_hash=pvalue_hash);
    return(results);
  }
  
  xIndex = unique(xIndex);
  csIndex = unique(csIndex);
  #extract the data
  x = dataset[ , xIndex];
  cs = dataset[ , csIndex];
  #if x = any of the cs then pvalue = 1 and flag = 1.
  #That means that the x variable does not add more information to our model due to an exact copy of this in the cs, so it is independent from the target
  if ( length(cs) != 0 ) {
    if ( is.null(dim(cs)[2]) )  {     #cs is a vector
      if ( identical(x, cs) )  {    #if(!any(x == cs) == FALSE)
        if ( hash )  {    #update hash objects
          stat_hash$key <- 0;  #.set(stat_hash , key , 0)
          pvalue_hash$key <- 1;  #.set(pvalue_hash , key , 1)
        }
        results <- list(pvalue = 1, stat = 0, flag = 1, stat_hash=stat_hash, pvalue_hash=pvalue_hash);
        return(results);
      }
    } else { #more than one var
      for (col in 1:dim(cs)[2])  {
        if ( identical(x, cs[, col]) )  {   #if(!any(x == cs) == FALSE)
          if ( hash )  {    #update hash objects
            stat_hash$key <- 0;  #.set(stat_hash , key , 0)
            pvalue_hash$key <- 1;  #.set(pvalue_hash , key , 1)
          }
          results <- list(pvalue = 1, stat = 0, flag = 1, stat_hash=stat_hash, pvalue_hash=pvalue_hash);
          return(results);
        }
      }
    }
  }
  if ( length(cs) == 0 )  {
    #compute the relationship between x,target directly
    fit2 = lm(target ~ x, weights = wei)
    if ( !any(is.na(fit2$coefficients) ) ) {
      stat = anova( fit2 )[2, 3]
      step <- 0
      j <- 1		
      n <- length(x)
      while ( j <= R & step < thres ) {
        xb <- sample(x, n)  
        bit2 <- lm(target ~ xb, weights = wei )
        step <- step + ( anova(bit2)[2, 3] > stat )
        j <- j + 1
      }
      pvalue <- (step + 1) / (R + 1) 
	}	 
  } else {
    fit2 = lm(target ~ cs + x, weights = wei )  
	if ( !any(is.na(fit2$coefficients) ) ) {
      stat <- anova( fit2 )[3, 3]
      step <- 0
      j <- 1		
      n <- length(x)
      while ( j <= R & step < thres ) {
        xb <- sample(x, n)  
        bit2 <- lm(target ~ cs + xb, weights = wei )
        step <- step + ( anova(bit2)[3, 3] > stat )
        j <- j + 1
      }
      pvalue <- (step + 1) / (R + 1) 
	}   
  }  
  flag = 1;
  
  #last error check
  if ( is.na(pvalue) || is.na(stat) ) {
    pvalue = 1;
    stat = 0;
    flag = 0;
  } else {
    #update hash objects
    if( hash )  {
      stat_hash$key <- stat;     #.set(stat_hash , key , stat)
      pvalue_hash$key <- pvalue;       #.set(pvalue_hash , key , pvalue)
    }
  }
  results <- list(pvalue = pvalue, stat = stat, flag = flag , stat_hash=stat_hash, pvalue_hash=pvalue_hash);
  return(results);
}