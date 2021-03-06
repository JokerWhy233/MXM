wald.mmpc = function(target, dataset, max_k = 3, threshold = 0.05, test = NULL, ini = NULL, wei = NULL, user_test = NULL, hash=FALSE, hashObject=NULL, robust = FALSE, ncores = 1, backward = FALSE)
{
  threshold = log(threshold)
  ##############################
  # initialization part of MMPC 
  #############################
  stat_hash = NULL;
  pvalue_hash = NULL;
  
  if( hash )  {
    if ( requireNamespace("hash") )  {
      if ( is.null(hashObject) )  {
        stat_hash = hash();
        pvalue_hash = hash();
      } else if(class(hashObject) == "list"){
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
  ###################################
  # dataset checking and initialize #
  ###################################
  if ( !is.null(dataset) ) {
    if ( sum( class(target) == "matrix") == 1 )  {
      if ( sum( class(target) == "Surv") == 1 )  stop('Invalid dataset class. For survival analysis provide a dataframe-class dataset');      
    }
  }  
  if ( is.null(dataset) || is.null(target) ) {  #|| (dim(as.matrix(target))[2] != 1 & class(target) != "Surv" ))
    stop('invalid dataset or target (class feature) arguments.');
  } else  target = target;
  if ( any(is.na(dataset)) ) {
    warning("The dataset contains missing values (NA) and they were replaced automatically by the variable (column) median (for numeric) or by the most frequent level (mode) if the variable is factor")
    dataset <- apply( dataset, 2, function(x){ x[which(is.na(x))] = median(x, na.rm = TRUE) ; return(x) } ) 
  }
  ##################################
  # target checking and initialize #
  ##################################
  targetID = -1;
  #check if the target is a string
  if (is.character(target) & length(target) == 1) {
    findingTarget <- target == colnames(dataset);#findingTarget <- target %in% colnames(dataset);
    if (!sum(findingTarget)==1){
      warning('Target name not in colnames or it appears multiple times');
      return(NULL);
    }
    targetID <- which(findingTarget);
    target <- dataset[ , targetID];
  }
  #checking if target is a single number
  if (is.numeric(target) & length(target) == 1){
    if (target > dim(dataset)[2]){
      warning('Target index larger than the number of variables');
      return(NULL);
    }
    targetID <- target;
    target <- dataset[ , targetID];
  }
  ################################
  # test checking and initialize #
  ################################
  la <- length( unique( as.numeric(target) ) )
  
  if (typeof(user_test) == "closure") {
    test = user_test;
  } else {
    #auto detect independence test in case of not defined by the user and the test is null or auto
    if (is.null(test) || test == "auto") {
      
      if ( la == 2 )   target <- as.factor(target)
      #if target is a factor then use the Logistic test
      if ( "factor" %in% class(target) )  {
        if ( is.ordered(target) & la > 2 )  {
          dataInfo$target_type = "ordinal";
          test = waldOrdinal
        } else {
          dataInfo$target_type = "binary"
          test = waldBinary
        }
        
      } else if ( ( is.numeric(target) || is.integer(target) ) & survival::is.Surv(target) == FALSE ) {
        
        if ( sum( floor(target) - target ) == 0  &  la > 2 ) {
          test = "waldPois";
        }
        
      } else if ( survival::is.Surv(target) ){
        test = "waldCR";
      } else   stop('Target must be a factor, vector, or a Surv object');
    }
    #cat("\nConditional independence test used: ");cat(test);cat("\n");
    #available conditional independence tests
    av_tests = c("waldBeta", "waldCR", "waldWR", "waldER", "waldClogit", "waldBinary", "waldPois", "waldNB", 
                 "waldBinom", "auto", "waldZIP", "waldSpeedglm", "waldMMreg", "waldIGreg", "waldOrdinal",
                 "waldGamma", "waldNormLog", "waldTobit", NULL);
    ci_test = test
    #cat(test)
    if ( length(test) == 1 ) {   #avoid vectors, matrices etc
      test = match.arg(test, av_tests, TRUE);
      #convert to closure type
      if (test == "waldBeta") {
        test = waldBeta;

      } else if (test == "waldMMreg") {
        test = waldMMreg;
        
      } else if (test == "waldIGreg") {
        test = waldIGreg;
        
      } else if (test == "waldPois") { 
        test = waldPois;
        
      } else if (test == "waldSpeedglm") {
        test = waldSpeedglm;
        
      } else if (test == "waldNB") {
        test = waldNB;
        
      } else if (test == "waldGamma") {  
        test = waldGamma;
        
      } else if (test == "waldNormLog") {  
        test = waldNormLog;
        
      } else if (test == "waldZIP") {
        test = waldZIP;
        
      } else if (test == "waldTobit") {  
        test = waldTobit;
        
      }  else if (test == "waldCR") {
        test = waldCR;
        
      } else if (test == "waldWR") {
        test = waldWR;
        
      } else if (test == "waldER") {
        test = waldER;

      } else if (test == "waldBinom") {
        test = waldBinom;
        
      } else if (test == "waldBinary") {
        test = waldBinary;
        
      } else if (test == "waldOrdinal") {
        test = waldOrdinal;
      }
      #more tests here
    } else {
      stop('invalid test option');
    }
  }
  ###################################
  # options checking and initialize #
  ###################################
  #extracting the parameters
  max_k = floor(max_k);
  varsize = ncol(dataset);
  #option checking
  if ( (typeof(max_k)!="double") || max_k < 1 )   stop('invalid max_k option');
  if ( max_k > varsize )    max_k = varsize;
  if ( (typeof(threshold) != "double") || exp(threshold) >= 1 )   stop('invalid threshold option');
  # if(typeof(equal_case)!="double")
  # {
  #   stop('invalid equal_case option');
  # }
  #######################################################################################
  if ( !is.null(user_test) )  ci_test = "user_test";
  #call the main MMPC function after the checks and the initializations
  options(warn = -1)
  results = wald.Internalmmpc(target, dataset, max_k, threshold, test, ini, wei, user_test, dataInfo, hash, varsize, stat_hash, pvalue_hash, targetID, robust = robust, ncores = ncores);

  if ( backward ) {
    varsToIterate = results$selectedVars
    varsOrder = results$selectedVarsOrder
    bc <- mmpcbackphase(target, dataset[, varsToIterate], test = test, wei = wei, max_k = max_k, threshold = exp(threshold), robust = robust ) 
    met <- bc$met
    results$selectedVars = varsToIterate[met]
    results$selectedVarsOrder = varsOrder[met]
    results$n.tests <- results$n.tests + bc$counter
  }
  MMPCoutput <-new("MMPCoutput", selectedVars = results$selectedVars, selectedVarsOrder=results$selectedVarsOrder, hashObject=results$hashObject, pvalues=results$pvalues, stats=results$stats, univ=results$univ, max_k=results$max_k, threshold = results$threshold, n.tests = results$n.tests, runtime=results$runtime, test=ci_test, rob = robust);
  return(MMPCoutput);
}


