perm.mmpc = function(target, dataset, max_k = 3, threshold = 0.05, test = NULL, ini = NULL, wei = NULL, user_test = NULL, hash=FALSE, hashObject=NULL, robust = FALSE, R = 999, ncores = 1, backward = FALSE)
{
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
    #check if dataset is an ExpressionSet object of Biobase package
    # if(class(dataset) == "ExpressionSet") {
    #get the elements (numeric matrix) of the current ExpressionSet object.
    #  dataset = Biobase::exprs(dataset);
    #  dataset = t(dataset);#take the features as columns and the samples as rows
    #     } else if(is.data.frame(dataset)) {
    #       if(class(target) != "Surv")
    #       {
    #         dataset = as.matrix(dataset);
    #       }
    # } else if((class(dataset) != "matrix") & (is.data.frame(dataset) == FALSE) ) {
    #   stop('Invalid dataset class. It must be either a matrix, a dataframe or an ExpressionSet');
    # }	
  }
  if( is.null(dataset) || is.null(target) ) {  #|| (dim(as.matrix(target))[2] != 1 & class(target) != "Surv" ))
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
  
  if ( sum( class(target) == "matrix") == 1 ) {
    if (ncol(target) >= 2 & class(target) != "Surv") {
      if ( (is.null(test) || test == "auto") & (is.null(user_test)) ) {
        test = "testIndMVreg"
        warning("Multivariate target (ncol(target) >= 2) requires a multivariate test of conditional independence. The testIndMVreg was used. For a user-defined multivariate test, please provide one in the user_test argument.");
      }
    }
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
      if ( sum( class(target) == "matrix") == 1 )  test = "testIndMVreg"
      
      #if target is a factor then use the Logistic test
      if ( "factor" %in% class(target) )  {
        test = "permLogistic";
        if ( is.ordered(target) )  {
          dataInfo$target_type = "ordinal";
        } else {
          if ( la == 2 ) {
            dataInfo$target_type = "binary"
          } else {
            dataInfo$target_type = "nominal"
          }
        }
        
      } else if ( ( is.numeric(target) || is.integer(target) ) & survival::is.Surv(target) == FALSE ) {
        
        if ( sum( floor(target) - target ) == 0  &  la > 2 ) {
          test = "permPois";
        } else {
          if(class(dataset) == "matrix") {
            test = "permFisher";
          } 
          else if ( is.data.frame(dataset) ) {
            if ( length( Rfast::which_isFactor(dataset)  ) > 0  ) {
              test = "permReg";
            } else   test = "permFisher";
          }
        }
        
      } else if ( survival::is.Surv(target) ){
        test = "permCR";
      } else   stop('Target must be a factor, vector, matrix with at least 2 columns column or a Surv object');
    }
    
    if (test == "permLogistic") {
      if ( is.ordered(target) )  {
        dataInfo$target_type = "ordinal";

      } else {
        if ( la == 2 ) {
          dataInfo$target_type = "binary"
        } else {
          dataInfo$target_type = "nominal"
        }
      }
    }
    #cat("\nConditional independence test used: ");cat(test);cat("\n");
    #available conditional independence tests
    av_tests = c("permFisher", "permReg", "permRQ", "permBeta", "permCR", "permWR", "permER", "permClogit", 
                 "permLogistic", "permPois", "permNB", "permBinom", "permgSquare", "permZIP", "permMVreg", 
                 "permIGreg", "permGamma", "permNormLog", "permTobit", "permDcor", "auto", NULL);
    ci_test = test
    #cat(test)
    if(length(test) == 1) {   #avoid vectors, matrices etc
      test = match.arg(test, av_tests, TRUE);
      #convert to closure type
      if (test == "permFisher") {
        #an einai posostiaio target
        test = permFisher;
        
      } else if (test == "permDcor") {   ## It uMMPC the F test
        #an einai posostiaio target
        test = permDcor;
        
      } else if (test == "permReg") {   ## It uMMPC the F test
        #an einai posostiaio target
        test = permReg;
        
      } else if(test == "permMVreg") {
        if ( min(target) > 0  &  Rfast::Var( Rfast::rowsums(target) ) == 0 )  target = log( target[, -1]/target[, 1] ) 
        test = permMVreg;
        
      } else if(test == "permBeta") {
        test = permBeta;
        
      } else if(test == "permRQ") {   ## quantile regression
        #an einai posostiaio target
        test = permRQ;
        
      } else if (test == "permIGreg")  {   
        test = permIGreg;
        
      } else if (test == "permPois") {  
        test = permPois;
        
      } else if (test == "permGamma") { ## Gamma regression
        test = permGamma;
        
      } else if (test == "permNormLog") { ## Normal regression with a log link
        test = permNormLog;
        
      } else if (test == "permNB") {   
        test = permNB;
        
      } else if (test == "permZIP") {
        test = permZIP;
        
      } else if (test == "permTobit") { ## Tobit regression
        test = permTobit;
        
      }  else if(test == "permCR") {
        test = permCR;
        
      } else if (test == "permWR") {
        test = permWR;
        
      }  else if (test == "permER") {
        test = permER;
        
      } else if (test == "permClogit") {
        test = permClogit;
        
      } else if (test == "permBinom") {
        test = permBinom;
        
      } else if (test == "permLogistic") {
        test = permLogistic;
        
      } else if (test == "permgSquare") {
        test = permgSquare;
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
  max_k <- floor(max_k);
  varsize <- dim(dataset)[2];
  #option checking
  if ( (typeof(max_k) != "double") || max_k < 1 )   stop('invalid max_k option');
  if ( max_k > varsize)   max_k <- varsize;
  if ( (typeof(threshold) != "double") || threshold <= 0  || threshold >= 1 )    stop('invalid threshold option');
  # if(typeof(equal_case)!="double")
  # {
  #   stop('invalid equal_case option');
  # }
  #######################################################################################
  if ( !is.null(user_test) )  ci_test = "user_test";
  #call the main MMPC function after the checks and the initializations
  options(warn = -1)
  results = perm.Internalmmpc(target, dataset, max_k, threshold, test, ini, wei, user_test, dataInfo, hash, varsize, stat_hash, pvalue_hash, targetID, robust = robust, R = R, ncores = ncores);
  #for testing backward phase
  #   results$selectedVars = c(results$selectedVars,15)
  #   results$selectedVarsOrder = c(results$selectedVarsOrder,15)
  #   print(results$selectedVars)
  #   print(results$selectedVarsOrder)
  #backward phase
  
  varsToIterate <- results$selectedVarsOrder
  
  if ( backward & length( varsToIterate ) > 0 ) {
    varsOrder <- results$selectedVarsOrder
    bc <- mmpcbackphase(target, dataset[, varsToIterate], max_k = max_k, threshold = threshold, test = test, wei = wei, dataInfo = dataInfo, robust = robust, R = R ) 
    met <- bc$met
    results$selectedVars <- varsToIterate[met]
    results$selectedVarsOrder <- varsOrder[met]
    results$n.tests <- results$n.tests + bc$counter
  }
  MMPCoutput <-new("MMPCoutput", selectedVars = results$selectedVars, selectedVarsOrder=results$selectedVarsOrder, hashObject=results$hashObject, pvalues=results$pvalues, stats=results$stats, univ=results$univ, max_k=results$max_k, threshold = results$threshold, n.tests = results$n.tests, runtime=results$runtime, test=ci_test, rob = robust);
  return(MMPCoutput);
}


