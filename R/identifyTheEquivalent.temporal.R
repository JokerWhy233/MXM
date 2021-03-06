identifyTheEquivalent.temporal = function(equal_case, queues, target, reps, group, dataset, cvar, z, test, wei, threshold, univariateModels, pvalues, hash, dataInfo, stat_hash, pvalue_hash, slopes)
{
  z = t(z);
  #case 3
  #if we have more than one equivalent vars in z , we select the first one
  #for loop if we dont use the below lapply function
  #equalsY = 0;
  for(i in 1:ncol(z)) {
    w = z[, i];
    w = t(t(w));
    zPrime = c(setdiff(z, w), cvar);
    cur_results = test(target, reps, group, dataset, w, zPrime, wei = wei, dataInfo=dataInfo, univariateModels, hash = hash, stat_hash, pvalue_hash, slopes = slopes);
    
    if (cur_results$flag & (cur_results$pvalue > threshold) ) {  
      queues[[w]] = as.matrix( c(queues[[w]], queues[[cvar]]) );
      break;
      #equalsY = equalsY+1;
    }
  }
  #cat("\nEquals Ys in the current z subset = %d",equalsY);
  return(queues);
}