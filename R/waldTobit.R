waldTobit = function(target, dataset, xIndex, csIndex, wei = NULL, dataInfo=NULL, univariateModels=NULL, hash = FALSE, stat_hash=NULL, pvalue_hash=NULL,robust=FALSE){
  # Conditional independence test based on the Log Likelihood ratio test
  if (!survival::is.Surv(target) )   stop('The survival test can not be performed without a Surv object target');
  csIndex[which(is.na(csIndex))] = 0;
  if ( hash )  {
    csIndex2 = csIndex[which(csIndex!=0)]
    csIndex2 = sort(csIndex2)
    xcs = c(xIndex,csIndex2)
    key = paste(as.character(xcs) , collapse=" ");
    if (is.null(stat_hash[[key]]) == FALSE) {
      stat = stat_hash[[key]];
      pvalue = pvalue_hash[[key]];
      flag = 1;
      results <- list(pvalue = pvalue, stat = stat, flag = flag, stat_hash=stat_hash, pvalue_hash=pvalue_hash);
      return(results);
    }
  }
  #initialization: these values will be returned whether the test cannot be carried out
  pvalue = log(1);
  stat = 0;
  flag = 0;
  results <- list(pvalue = pvalue, stat = stat, flag = flag, stat_hash=stat_hash, pvalue_hash=pvalue_hash);
  tob = NULL;
  tob_full = NULL;
  #if the censored indicator is empty, a dummy variable is created
  numCases = dim(dataset)[1];
  if (is.na(csIndex) || length(csIndex) == 0 || csIndex == 0) {
    tob <- survival::survreg(target ~ dataset[, xIndex], weights = wei, dist = "gaussian")
    res = summary(tob)[[ 9 ]]
    stat = res[2, 3]^2
    pvalue = pchisq(stat, 1, lower.tail = FALSE, log.p = TRUE);
  } else {
    tob_full <- survival::survreg(target ~ ., data = as.data.frame(  dataset[ , c(csIndex, xIndex)] ), weights = wei, dist = "gaussian" )
    res = summary(tob_full)[[ 9 ]]
    pr = dim(res)[1] - 1
    stat = res[pr, 3]^2
    pvalue = pchisq(stat, 1, lower.tail = FALSE, log.p = TRUE)
  }  
  flag = 1;
  if ( is.na(pvalue) || is.na(stat) ) {
    pvalue = log(1);
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
