apply_ideq.temporal = function(i , queues , target , reps, group, dataset , cvar , z , test , wei, threshold , univariateModels, hash, dataInfo, stat_hash, pvalue_hash, slopes = slopes)
{
  w = z[,i];
  w = t(t(w));
  zPrime = c(setdiff(z , w) , cvar);
  cur_results = test(target , reps, group, dataset , w, zPrime , wei = wei, dataInfo=dataInfo, univariateModels, hash = hash, stat_hash, pvalue_hash, slopes = slopes);
  
  if ( cur_results$flag & (cur_results$pvalue > threshold) ) {
    queues[[w]] = as.matrix(c(queues[[w]] , queues[[cvar]]));
    return(queues[[w]]);
  } else  return(NA);
}