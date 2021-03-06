# R Implementation of MMPC algorithm
# as described in the paper "The max-min hill-climbing Bayesian network structure learning algorithm". Machine learning, 65(1), 31-78, 2006
# by Tsamardinos, Brown and Aliferis
# R Implementation by Giorgos Athineou (2013-2014)
# VERSION: 17/3/2014
# INPUTS
# target : the class variable , provide either a vector, an 1D matrix, an 1D array (same length with the data rows), a factor 
# or a formula. The data can be either continuous data in R, values within (0,1), binary [0,1], nominal or ordinal data.
# dataset : tha dataset , provide a data frame (columns = variables , rows = samples) or a matrix or an ExpressionSet.
# max_k : the maximum conditioning set which is used in the current conditional indepedence test used.
# threshold : the significance threshold ( must be in (0,1) ) for testing the null hypothesis of the generated pvalues.
# test : the conditional independence test we are going to use. the available conditional independence tests so far in this 
# implementation are:
#   "testIndFisher" : Fisher conditional independence test for continous targets (or proportions) and continuous predictors only
#   "testIndSpearman" : Fisher conditional independence test for continous targets (or proportions) and continuous predictors only (Spearman correlation is calculated first)
#   "testIndReg" : Conditional independence test based on regression for continous targets (or proportions) and mixed predictors using the F test
#   "testIndRQ" : Conditional Independence Test based on quantile (median) regression for numerical class variables and mixed predictors (F test)
#   "testIndLogistic" : Conditional Independence Test based on logistic regression for binary,categorical or ordinal class variables and mixed predictors
#   "testIndPois" : Conditional Independence Test based on Poisson regression for discrete class variables and mixed predictors (log-likelihood ratio test)
#   "testIndSpeedglm" : Conditional Independence Test based on linear, binary logistic and poisson regression with mixed predictors (log-likelihood ratio test)
#   "testIndZIP" : Conditional Independence Test based on zero inflated poisson regression for discrete class variables and mixed predictors (log-likelihood ratio test)
#   "testIndNB" : Conditional Independence Test based on negative binomial regression for discrete class variables and mixed predictors (log-likelihood ratio test)
#   "testIndBeta" : Conditional Independence Test based on beta regression for proportions and mixed predictors (log likelihood ratio test)
#   "testIndMVreg" : Conditional Independence Test based on mu;ltivariate linear regression for Euclidean data and mixed predictors (log likelihood ratio test)
#   "gSquare" : Conditional Independence test based on the G test of independence (log likelihood ratio  test)
#   "censIndCR" : Conditional independence test for survival data based on the Log likelihood ratio test with mixed predictors (Cox regression)
# user_test : the user defined conditional independence test ( provide a closure type object )
# hash : a boolean variable whuch indicates whether (TRUE) or not (FALSE) to use the hash-based implementation of the statistics of MMPC.
# hashObject : a List with the hash objects (hash package) on which we have cached the generated statistics. 
#              MMPC requires this Object for the hash-based implementation of the statistics. This hashObject is produced or 
# updated by each run
#              of MMPC (if hash == TRUE) and it can be reused in next runs of MMPC.
# robust : Should the Fisher or the normal regression be robustly estimated? TRUE or FALSE 
# there are default values for all of the parameters of the algorithm.
# OUTPUT <LIST>
# The output of the algorithm is a LIST with the following quantities (14) :
# selectedVars : the selected variables i.e. the dependent of the target variables.
# selectedVarsOrder : the increasing order of the selected variables due to their pvalues
# hashObject : the hashObject with the cached statistic results of the current run.
# pvalues : the pvalues of all of the variables.
# stats : the stats of all of the variables.
# data : the dataset used in the current run.
# target : the class variable used in the current run.
# test : the conditional independence test used in the current run.
# max_k : the max_k option used in the current run.
# threshold : the threshold option used in the current run.
# runtime : the run time of the algorithm.
# Conditional independence test arguments have to be in this exact fixed order : 
# target(target variable), data(dataset), xIndex(x index), csIndex(cs index), dataInfo(list), 
# univariateModels(cached statistics for the univariate indepence test), hash(hash booleab), stat_hash(hash object), 
# pvalue_hash(hash object), robust=robust
# example: test(target, data, xIndex, csIndex, dataInfo=NULL, univariateModels=NULL, hash=FALSE, stat_hash=NULL, pvalue_hash=NULL, robust)
# output of each test: LIST of the generated pvalue, stat, flag and the updated hash objects.
# equal_case variable inside the code : it determines the method of the equivalent estimation
#   if equal_case = 1 then, if we have more than one equivalent vars in z , we select the one with the most closer pvalue to the pvalue of cvar
#   if equal_case = 2 then, if we have more than one equivalent vars in z , we select the one with the most minimum pvalue (>a)
#   else in any other case, if we have more than one equivalent vars in z , we select the first one
# In this version we support the equal_case = 3.
# 
# 
# #hashObject
# library(hash)
ma.mmpc = function(target, dataset, ina, statistic = FALSE, max_k = 3, threshold = 0.05, test = NULL, ini = NULL, user_test = NULL, hash=FALSE, hashObject=NULL, robust = FALSE, ncores = 1, backward = FALSE)
{
  #get the log threshold
  threshold = log(threshold)
  ##############################
  # initialization part of MMPC #
  ##############################
  stat_hash = NULL;
  pvalue_hash = NULL;
  
  if ( hash )  {
    if (requireNamespace("hash") ) {
      if ( is.null(hashObject) ) {
        stat_hash = hash();
        pvalue_hash = hash();
      } else if(class(hashObject) == "list") {
        stat_hash = hashObject$stat_hash;
        pvalue_hash = hashObject$pvalue_hash;
      } else {
        stop('hashObject must be a list of two hash objects (stat_hash, pvalue_hash)')
      }
    } else {
      cat('The hash version of MMPC requires the hash package');
      return(NULL);
    }
  }
  
  dataInfo = NULL;
  ##################################
  # target checking and initialize #
  ##################################
  targetID = -1;
  #check if the target is a string
  if (is.character(target) & length(target) == 1) {
    findingTarget <- target == colnames(dataset);#findingTarget <- target %in% colnames(dataset);
    if (!sum(findingTarget)==1 ) {
      warning('Target name not in colnames or it appears multiple times');
      return(NULL);
    }
    targetID <- which(findingTarget);
    target <- dataset[ , targetID];
  }
  #checking if target is a single number
  if ( is.numeric(target) & length(target) == 1 ) {
    if (target > dim(dataset)[2]) {
      warning('Target index larger than the number of variables');
      return(NULL);
    }
    targetID <- target;
    target <- dataset[ , targetID];
  }
  ################################
  # test checking and initialize #
  ################################
  #cat("\nConditional independence test used: ");cat(test);cat("\n");
    #available conditional independence tests
    av_tests = c("testIndFisher", "testIndSpearman", "testIndReg", "testIndRQ", "testIndBeta", "censIndCR","censIndWR", "testIndClogit", "testIndLogistic", "testIndPois", "testIndNB", "testIndBinom", "gSquare", "auto" , "testIndZIP" , "testIndSpeedglm", "testIndMVreg", NULL);
    ci_test = test
    #cat(test)
    
    if(length(test) == 1)  {#avoid vectors, matrices etc

      test = match.arg(test, av_tests, TRUE);
      #convert to closure type
      if(test == "testIndFisher") {
        #an einai posostiaio target
        if ( min(target) > 0  &  max(target) < 1 )   target = log( target/(1 - target) ) ## logistic normal 
        
        if ( is.data.frame(dataset) ) {
          if ( length( which_isFactor(dataset) ) > 0 ) {
            warning("Dataset contains categorical variables (factors). A regression model is advised to be used instead.")
          } else dataset <- as.matrix(dataset)
        }
            
        test = testIndFisher;
      }
      else if(test == "testIndSpearman") {
        #an einai posostiaio target
        if ( min(target) > 0  &  max(target) < 1 )   target = log( target / (1 - target) ) ## logistic normal 
        
        if ( is.data.frame(dataset) ) {
          if ( length( which_isFactor(dataset) ) > 0 ) {
            warning("Dataset contains categorical variables (factors). A regression model is advised to be used instead.")
          } else dataset <- as.matrix(dataset)
        }
        target = rank(target)
        dataset = apply(dataset, 2, rank)  
        test = testIndSpearman;  ## Spearman is Pearson on the ranks of the data
      }
	    
    } else   stop('invalid test option');
  
  ###################################
  # options checking and initialize #
  ###################################
  #extracting the parameters
  max_k = floor(max_k);
  varsize = ncol(dataset);
  if ( (typeof(max_k) != "double" ) || max_k < 1 )   stop('invalid max_k option');
  if ( max_k > varsize )   max_k = varsize;
  if ( (typeof(threshold) != "double" ) || exp(threshold) <= 0 || exp(threshold) > 1 )   stop('invalid threshold option');
  #######################################################################################
  if(!is.null(user_test))  ci_test = "user_test";

  D = max(ina)
  targ = list()
  data = list()
  for (l in 1:D) { 
   targ[[ l ]] = target[ ina == l ]
   data[[ l ]] = dataset[ ina == l, ]
  }
  ####### 
  for (i in 1:D) {
    if ( is.null(data[[ l ]] ) || is.null(targ[[ l ]]) ) {  #|| (dim(as.matrix(target))[2] != 1 & class(target) != "Surv" ))
      stop('invalid dataset or target (class feature) arguments.');
    } else {
      targ[[ l ]] = targ[[ l ]];
    }
    #check for NA values in the dataset and replace them with the variable median or the mode
   da <- data[[ l ]]	 
   if ( any( is.na( da ) ) ) {
    warning("The dataset contains missing values (NA) and they were replaced automatically by the variable (column) median (for numeric) or by the most frequent level (mode) if the variable is factor")
    if ( is.matrix( da ) )  {
      da <- apply( da, 2, function(x){ x[which(is.na(x))] = median(x, na.rm = TRUE) ; return(x) } ) 
    } else {
      poia <- unique( which( is.na(da), arr.ind = TRUE )[, 2] )
      for ( i in poia )  {
        xi <- da[, i]
        if ( is.numeric(xi) )  {                    
          xi[ which( is.na(xi) ) ] <- median(xi, na.rm = TRUE) 
        } else if ( is.factor( xi ) ) {
          xi[ which( is.na(xi) ) ] <- levels(xi)[ which.max( as.vector( table(xi) ) )]
        }
        da[, i] <- xi
      }
    }
   }
   data[[ l ]] <- da
  }
  #call the main MMPC function after the checks and the initializations
  results = Internalmammpc(targ, data, statistic, max_k, threshold, test, ini, user_test, dataInfo, hash, varsize, stat_hash, pvalue_hash, targetID, robust = robust, ncores = ncores);
  #for testing backward phase
  #   results$selectedVars = c(results$selectedVars,15)
  #   results$selectedVarsOrder = c(results$selectedVarsOrder,15)
  #   print(results$selectedVars)
  #   print(results$selectedVarsOrder)
  #backward phase
  mammpcoutput <-new("mammpc.output", selectedVars = results$selectedVars, selectedVarsOrder=results$selectedVarsOrder, hashObject=results$hashObject, pvalues=results$pvalues, stats=results$stats, univ=results$univ, max_k=results$max_k, threshold = results$threshold, runtime=results$runtime, test=ci_test, rob = robust);
  
  return(mammpcoutput);
}




#########################################################################################################

Internalmammpc = function(targ, data, statistic, max_k, threshold, test = NULL, ini = NULL, user_test = NULL , dataInfo = NULL , hash=FALSE, varsize, stat_hash, pvalue_hash, targetID, robust, ncores)
{
  #get the current time
  runtime = proc.time();
  
  #######################################################################################
 
  D = length(targ) 
  
  if ( is.null(ini) ) { 
    
    cols = ncol( data[[ 1 ]] )  
    sta = pval = matrix(0, D, cols)   
    univariateModels = list()
   
   if ( identical(test, testIndFisher)  &  !robust )  { ## Pearson's correlation 
	
	 for ( l in 1:D ) {  
	  target = targ[[ l ]]
	  dataset = data[[ l ]]
      rows = length(target)
      a = as.vector( cor(target, dataset) )
      dof = rows - 3; #degrees of freedom
      wa = abs( 0.5 * log( (1 + a) / (1 - a) ) * sqrt(dof) )
      if ( targetID != - 1 )   wa[ targetID ] = 0  
       sta[l, ] = wa
       pval[l, ] = log(2) + pt(-wa, dof, log.p = TRUE)
	 }  
      univariateModels$stat = - 2 * Rfast::colsums(pval);
      univariateModels$pvalue = pchisq(univariateModels$stat, 2 * D, lower.tail = FALSE, log.p = TRUE) ;
      univariateModels$flag = numeric(cols) + 1;
      univariateModels$stat_hash = stat_hash;
      univariateModels$pvalue_hash = pvalue_hash;
	 
    } else if ( identical(test, testIndSpearman) ) {  ## Spearman's correlation
	
	 for ( l in 1:D ) {  
    
	  target = targ[[ l ]]
	  dataset = data[[ l ]]
      rows = length(target) 
      a = as.vector( cor(target, dataset) )
      dof = rows - 3; #degrees of freedom
      wa = abs( 0.5 * log( (1 + a) / (1 - a) ) * sqrt(dof) / 1.029563 )
      if ( targetID != - 1 )  wa[ targetID ] = 0
	   sta[l, ] = wa
       pval[l, ] = log(2) + pt(-wa, dof, lower.tail = FALSE, log.p = TRUE)
	 }  
      univariateModels$stat = - 2 * Rfast::colsums(pval);
      univariateModels$pvalue = pchisq(univariateModels$stat, 2 * D, lower.tail = FALSE, log.p = TRUE) ;
      univariateModels$flag = numeric(cols) + 1;
      univariateModels$stat_hash = stat_hash;
      univariateModels$pvalue_hash = pvalue_hash;    
	 
    } else if ( identical(test, testIndReg)  & robust ) {  ## M (Robust) linear regression
      
      univariateModels = list();
      fit1 = MASS::rlm(target ~ 1)
      lik2 = numeric(cols)
      dof = numeric(cols)
      
      if ( ncores <= 1 | is.null(ncores) ) {
        
      for (l in 1:D) {

      target = targ[[ l ]]
	  dataset = data[[ l ]]

        for ( i in 1:cols ) {
          
          if ( i != targetID ) {
            
            fit2 = MASS::rlm(target ~ dataset[, i] )
            lik2[i] = as.numeric( logLik(fit2) )
            dof[i] = length( coef(fit2) ) - 1
          } else {
            lik2[i] = lik1
          }
          
        } 
        
        lik1 = as.numeric( logLik(fit1) )
        sta[l, ] = as.vector( 2 * abs(lik1 - lik2) )
        pval[l, ] = pchisq(sta[l, ], dof, lower.tail = FALSE, log.p = TRUE)

       } 

        univariateModels$stat = - 2 * Rfast::colsums(pval)
        univariateModels$pvalue = pchisq(univariateModels$stat, 2 * D, lower.tail = FALSE, log.p = TRUE) ;
        univariateModels$flag = numeric(cols) + 1;
        univariateModels$stat_hash = stat_hash;
        univariateModels$pvalue_hash = pvalue_hash;
        
      } else {
       
       for ( l in 1:D )	{
	   
	   target = targ[[ l ]]
	   dataset = data[[ l ]]
	  
        cl <- makePSOCKcluster(ncores)
        registerDoParallel(cl)
        mod <- foreach(i = 1:cols, .combine = rbind, .packages = "MASS") %dopar% {
          
          if ( i != targetID ) {
            fit2 = rlm(target ~ dataset[, i] )
            lik2 = as.numeric( logLik(fit2) )
            
            return( c(lik2, length( coef(fit2) ) ) )
          } else{
            return( c(0, 0) )
          }
          
        }
        stopCluster(cl)
        
        lik1 = as.numeric( logLik(fit1) )
        dof = as.vector( mod[, 2] ) - 1 
        sta[l, ] = as.vector( 2 * abs(lik1 - mod[, 1]) )
        pval[l, ] = pchisq(sta[l, ], dof, lower.tail = FALSE, log.p = TRUE)
		
       }
	   
        univariateModels$stat = - 2 * Rfast::colsums(pval)
        univariateModels$pvalue = pchisq(univariateModels$stat, 2 * D, lower.tail = FALSE, log.p = TRUE) ;
        univariateModels$flag = numeric(cols) + 1
        univariateModels$stat_hash = NULL
        univariateModels$pvalue_hash = NULL   
      }   
      
      
    } else if ( identical(test, testIndLogistic)  &  is.ordered(target) ) {  ## 
      
      lik2 = numeric(cols)
      dof = numeric(cols)
      univariateModels = list();
      
      fit1 = ordinal::clm(target ~ 1)
      df1 = length( coef(fit1) )
      
      if ( ncores <= 1 | is.null(ncores) ) {
       
       for ( l in 1:D )	{
	   
	   target = targ[[ l ]]
	   dataset = data[[ l ]]
	   
        for ( i in 1:cols ) {
          
          if (i != targetID){
            
            x <- model.matrix(target ~ dataset[, i] )
            fit2 <- ordinal::clm.fit(target, x)
            lik2[i] <- as.numeric( fit2$logLik )
            dof[i] <- length( coef(fit2) ) - df1
          } else {
            lik2[i] <- lik1
          }   
        }
        
        lik1 = as.numeric( logLik(fit1) )
        sta[l, ] = as.vector( 2 * abs(lik1 - lik2) )
        pval[l, ] = pchisq(sta[l, ], dof, lower.tail = FALSE, log.p = TRUE)
       
       }
 	   
        univariateModels$stat = - 2 * Rfast::colsums(pval)
        univariateModels$pvalue = pchisq(univariateModels$stat, 2 * D, lower.tail = FALSE, log.p = TRUE) ;
        univariateModels$flag = numeric(cols) + 1;
        univariateModels$stat_hash = stat_hash;
        univariateModels$pvalue_hash = pvalue_hash;
        
      } else {
        
       for ( l in 1:D )	{
	   
	   target = targ[[ l ]]
	   dataset = data[[ l ]]
	   
        cl <- makePSOCKcluster(ncores)
        registerDoParallel(cl)
        mod <- foreach(i = 1:cols, .combine = rbind, .packages = "ordinal") %dopar% {
          ## arguments order for any CI test are fixed
          if ( i != targetID ) {
            x <- model.matrix(target ~ dataset[, i] )
            fit2 <- ordinal::clm.fit(target, x)
            lik2 <- as.numeric( fit2$logLik )
            
            return( c(lik2, length( coef(fit2) ) ) )
          } else{
            return( c(0, 0) )
          }
        }
        stopCluster(cl)
        
        lik1 = as.numeric( logLik(fit1) )
        dof = as.vector( mod[, 2] ) - df1 
        sta[l, ] = as.vector( 2 * abs(lik1 - mod[, 1]) )
        pval[l, ] = pchisq(sta[l, ], dof, lower.tail = FALSE, log.p = TRUE)
		
	   }
	   
        univariateModels$stat = - 2 * Rfast::colsums(pval)
        univariateModels$pvalue = pchisq(univariateModels$stat, 2 * D, lower.tail = FALSE, log.p = TRUE) ;
        univariateModels$flag = numeric(cols) + 1
        univariateModels$stat_hash = NULL
        univariateModels$pvalue_hash = NULL   
      }
      
    } else {  
      univariateModels = univariateScore.ma(targ, data, test, statistic = FALSE, dataInfo = dataInfo, hash=hash, stat_hash=stat_hash, pvalue_hash=pvalue_hash, targetID=targetID, robust=robust, ncores=ncores);
    }
    
  } else {
    univariateModels = ini
  } 
 
  pvalues = univariateModels$pvalue;      
  stats = univariateModels$stat;
  flags = univariateModels$flag;
  #if we dont have any associations , return
  if ( min(pvalues , na.rm = TRUE) > threshold ) {
    #cat('No associations!');
    results = NULL;
    results$selectedVars = c();
    class(results$selectedVars) = "numeric";
    results$selectedVarsOrder = c();
    class(results$selectedVarsOrder) = "numeric";
    results$hashObject = NULL;
    class(results$hashObject) = 'list';
    class(results$univ) = 'list';
    results$pvalues = exp(pvalues);
    results$stats = stats;
    results$univ = univariateModels
    results$max_k = max_k;
    results$threshold = exp(threshold);
    runtime = proc.time() - runtime;
    results$runtime = runtime;
    results$rob = robust
    return(results);
  }
  
  #Initialize the data structs
  selectedVars = numeric(varsize);
  selectedVarsOrder = numeric(varsize)
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
  loop = any(as.logical(remainingVars));
  #rep = 1;
  while(loop) {
    #lets find the variable with the max min association
    max_min_results = max_min_assoc.ma(target, dataset, test, threshold, statistic, max_k, selectedVars, pvalues, stats, remainingVars, univariateModels, selectedVarsOrder, hash=hash, dataInfo, stat_hash=stat_hash, pvalue_hash=pvalue_hash, robust = robust, ncores = ncores);
    selectedVar = max_min_results$selected_var;
    selectedPvalue = max_min_results$selected_pvalue;
    remainingVars = max_min_results$remainingVars;
    pvalues = max_min_results$pvalues;
    stats = max_min_results$stats;
    stat_hash=max_min_results$stat_hash;
    pvalue_hash=max_min_results$pvalue_hash;
    #if the selected variable is associated with target , add it to the selected variables
    if(selectedPvalue <= threshold) {
      #print(paste("rep: ",rep,", selected var: ",selectedVar,", pvalue = ",exp(selectedPvalue)))
      #rep = rep + 1;
      selectedVars[selectedVar] = 1;
      selectedVarsOrder[selectedVar] = max(selectedVarsOrder) + 1;
      remainingVars[selectedVar] = 0;
    }
    loop = any(as.logical(remainingVars));
  }
  
  
  selectedVarsOrder[which(!selectedVars)] = varsize;#
  numberofSelectedVars = sum(selectedVars);#
  selectedVarsOrder = sort(selectedVarsOrder);#
  #adjusting the results
  if(targetID > 0)  {
    toAdjust <- which(selectedVars > targetID);
    selectedVars[toAdjust] = selectedVars[toAdjust] + 1;
  }
  
  results = NULL;
  results$selectedVars = which(selectedVars == 1);
  svorder = sort(pvalues[results$selectedVars] , index.return = TRUE);
  svorder = results$selectedVars[svorder$ix];
  results$selectedVarsOrder = svorder;
  hashObject = NULL;
  hashObject$stat_hash = stat_hash;
  hashObject$pvalue_hash = pvalue_hash;
  results$hashObject = hashObject;
  class(results$hashObject) = 'list';
  results$pvalues = exp(pvalues);
  results$stats = stats;
  results$univ = univariateModels
  results$max_k = max_k;
  results$threshold = exp(threshold);
  runtime = proc.time() - runtime;
  results$runtime = runtime;
  results$rob = robust
   
  return(results);
}
















