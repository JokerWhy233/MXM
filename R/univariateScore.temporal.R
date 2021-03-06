univariateScore.temporal = function(target, reps = NULL, group, dataset, test, wei, dataInfo, targetID, slopes, ncores) {
  univariateModels <- list();
  dm <- dim(dataset)
  rows <- dm[1]
  cols <- dm[2]

  la <- length( unique(target) )
  if ( la > 2  &  sum( round(target) - target ) != 0  &  !slopes  &  is.null(wei) ) {
    group <- as.numeric(group)
    if ( !is.null(reps) )   reps <- as.numeric(reps)
    univariateModels <- rint.regs(target = target, dataset = dataset, targetID = targetID, id = group, reps = reps, tol = 1e-08)

  } else {
  
    if (targetID != -1 ) {
      target <- dataset[, targetID]
      dataset[, targetID] <- rnorm(rows)
    }
  
    poia <- Rfast::check_data(dataset)
    if ( sum(poia) > 0 )   dataset[, poia] <- rnorm(rows * length(poia) )    
    nTests = cols
    univariateModels = NULL;
    univariateModels$pvalue = numeric(nTests) 
    univariateModels$stat = numeric(nTests)
    univariateModels$flag = numeric(nTests);
    test_results = NULL;
    if ( ncores == 1 | is.null(ncores) | ncores <= 0 ) {
    
      for(i in 1:nTests) {
        test_results = test(target, reps, group, dataset, i, 0, wei = wei, dataInfo = dataInfo, slopes = slopes)
        univariateModels$pvalue[[i]] = test_results$pvalue;
        univariateModels$stat[[i]] = test_results$stat;
        univariateModels$flag[[i]] = test_results$flag;
        univariateModels$stat_hash = test_results$stat_hash
        univariateModels$pvalue_hash = test_results$pvalue_hash      
      } 
    } else {
      #require(doParallel, quiet = TRUE, warn.conflicts = FALSE)  
      cl <- makePSOCKcluster(4)
      registerDoParallel(cl)
      test = test
      mod <- foreach(i = 1:nTests, .combine = rbind, .export = "lmer", .packages = "lme4") %dopar% {
        test_results = test(target, reps, group, dataset, i, 0, wei = wei, dataInfo=dataInfo, slopes = slopes)
        return( c(test_results$pvalue, test_results$stat, test_results$flag, test_results$stat_hash, test_results$pvalue_hash) )
      }
      stopCluster(cl)
      univariateModels$pvalue = as.vector( mod[, 1] )
      univariateModels$stat = as.vector( mod[, 2] )
      univariateModels$flag = as.vector( mod[, 3] )
    }

    if ( sum(poia>0) > 0 ) {
      univariateModels$stat[poia] = 0
      univariateModels$pvalue[poia] = log(1)
    }
    
  }
  if ( !is.null(univariateModels) )  {
    univariateModels$flag = numeric(cols) + 1  
    if (targetID != - 1) {
      univariateModels$stat[targetID] = 0
      univariateModels$pvalue[targetID] = log(1)
    }
  }
  
  univariateModels
}
