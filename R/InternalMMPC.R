InternalMMPC = function(target, dataset, max_k, threshold, test=NULL, ini=NULL, wei=NULL, user_test=NULL, dataInfo=NULL, hash=FALSE, varsize, stat_hash, pvalue_hash, targetID, robust, ncores, logged)
{
  #get the current time
  runtime <- proc.time();
  #######################################################################################
  #univariate feature selection test
  if ( is.null(ini) ) { 
    univariateModels = univregs(target = target, dataset = dataset, targetID = targetID, test = test, user_test = user_test, wei = wei, dataInfo = dataInfo, robust = robust, ncores = ncores) 
  } else  univariateModels = ini
  
  pvalues = univariateModels$pvalue;      
  stats = univariateModels$stat;
  flags = univariateModels$flag;
  #   stat_hash = univariateModels$stat_hash;
  #   pvalue_hash = univariateModels$pvalue_hash;
  #if we dont have any associations , return
  if ( min(pvalues, na.rm = TRUE) > threshold )  {
    #cat('No associations!');
    results = NULL;
    results$selectedVars = c();
    class(results$selectedVars) = "numeric";
    results$selectedVarsOrder = c();
    class(results$selectedVarsOrder) = "numeric";
    results$hashObject = NULL;
    class(results$hashObject) = 'list';
    class(results$univ) = 'list';
    if (logged) {
      results$pvalues = pvalues;
    } else  results$pvalues = exp(pvalues);
    results$stats = stats;
    results$univ = univariateModels
    results$max_k = max_k;
    results$threshold = exp(threshold);
    runtime = proc.time() - runtime;
    results$runtime = runtime;
    results$rob = robust
    results$n.tests <- length(flags)
    
    return(results);
  }
  #Initialize the data structs
  selectedVars = numeric(varsize);
  selectedVarsOrder = numeric(varsize);
  #select the variable with the highest association
  #selectedVar = which(flags == 1 & stats == stats[[which.max(stats)]]);
  selectedVar = which(flags == 1 & pvalues == pvalues[[which.min(pvalues)]]);
  selectedVars[selectedVar] = 1;
  selectedVarsOrder[selectedVar] = 1; #CHANGE
  #print(paste("rep: ",0,", selected var: ",selectedVar,", pvalue = ",exp(pvalues[selectedVar])))
  #lets check the first selected var
  #cat('First selected var: %d, p-value: %.6f\n', selectedVar, pvalues[selectedVar]);
  #remaining variables to be considered
  remainingVars = numeric(varsize) + 1;
  remainingVars[selectedVar] = 0;
  remainingVars[pvalues > threshold] = 0;
  if (targetID > 0)  remainingVars[targetID] = 0;
  ################ main MMPC loop ################
  #main MMPC loop
  #loop until there are not remaining vars
  loop = any( as.logical(remainingVars) );
  #rep = 1;
  while (loop) {
    max_min_results = max_min_assoc(target, dataset, test, wei, threshold, max_k, selectedVars, pvalues, stats, remainingVars , univariateModels, selectedVarsOrder, hash=hash, dataInfo, stat_hash=stat_hash, pvalue_hash=pvalue_hash, robust = robust, ncores = ncores);
    selectedVar = max_min_results$selected_var;
    selectedPvalue = max_min_results$selected_pvalue;
    remainingVars = max_min_results$remainingVars;
    pvalues = max_min_results$pvalues;
    stats = max_min_results$stats;
    stat_hash=max_min_results$stat_hash;
    pvalue_hash=max_min_results$pvalue_hash;
    #if the selected variable is associated with target , add it to the selected variables
    if ( selectedPvalue <= threshold ) {
      #print(paste("rep: ",rep,", selected var: ",selectedVar,", pvalue = ",exp(selectedPvalue)))
      #rep = rep + 1;
      selectedVars[selectedVar] = 1;
      selectedVarsOrder[selectedVar] = max(selectedVarsOrder) + 1;
      remainingVars[selectedVar] = 0;
    }
    
    loop = any( as.logical(remainingVars) );
  }
  
  selectedVarsOrder[which(!selectedVars)] = varsize;#
  numberofSelectedVars = sum(selectedVars);#
  selectedVarsOrder = sort(selectedVarsOrder);#
  #   selectedVars = selectedVarsOrder[1:numberofSelectedVars];
  # #queues correctness
  # all_queues = queues
  # queues = queues[which(selectedVars==1)];
  # queues <- lapply(1:length(queues) , function(i){queues[[i]] = unique(queues[[i]]);});
  #adjusting the results
  if (targetID > 0) {
    toAdjust <- which(selectedVars > targetID)
    selectedVars[toAdjust] = selectedVars[toAdjust] + 1
  }
  results = NULL;
  results$selectedVars = which( selectedVars == 1 )
  svorder = sort(pvalues[results$selectedVars], index.return = TRUE)
  svorder = results$selectedVars[svorder$ix]
  results$selectedVarsOrder = svorder
  hashObject = NULL
  hashObject$stat_hash = stat_hash
  hashObject$pvalue_hash = pvalue_hash
  results$hashObject = hashObject
  class(results$hashObject) = 'list'
  if (logged) {
    results$pvalues = pvalues;
  } else  results$pvalues = exp(pvalues);
  results$stats = stats;
  results$univ = univariateModels
  #   results$all_queues = all_queues;
  #   already known
  #   results$data = dataset;
  #   results$target = target;
  #   results$test = test;
  results$max_k = max_k
  results$threshold = exp(threshold)
  runtime = proc.time() - runtime
  results$runtime = runtime
  results$rob = robust
  results$n.tests <- length(flags) + length( hashObject$stat_hash )
  return(results)
}
