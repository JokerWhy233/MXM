testIndZIP = function(target, dataset, xIndex, csIndex, dataInfo=NULL, univariateModels=NULL , hash = FALSE, stat_hash=NULL, 
                       pvalue_hash=NULL,robust=FALSE) 
{
  # testIndZIP Conditional Independence Test for discrete class variables 
  # PVALUE = testIndZIP(Y, DATA, XINDEX, CSINDEX, DATAINFO)
  # This test provides a p-value PVALUE for the NULL hypothesis H0 which is
  # X is independent by TARGET given CS. The pvalue is calculated following
  # nested models
  
  # This method requires the following inputs
  #   TARGET: a numeric vector containing the values of the target (discrete) variable. 
  #   Its support can be R or any number betweeen 0 and 1, i.e. it contains proportions.
  #   DATASET: a numeric data matrix containing the variables for performing the test. They can be mixed variables. 
  #   XINDEX: the index of the variable whose association with the target we want to test. 
  #   CSINDEX: the indices if the variable to condition on. 
  #   DATAINFO: information on the structure of the data
  
  # this method returns: the pvalue PVALUE, the statistic STAT and a control variable FLAG.
  # if FLAG == 1 then the test was performed succesfully
  
  # References
  # [1] McCullagh, Peter, and John A. Nelder. Generalized linear models. CRC press, USA, 2nd edition, 1989.
  
  
  #########################################################################################################
  
  #initialization
  
  #if the test cannot performed succesfully these are the returned values
  pvalue = 1;
  stat = 0;
  flag = 0;
  csIndex[which(is.na(csIndex))] = 0;
  
  if(hash == TRUE)
  {
    csIndex2 = csIndex[which(csIndex!=0)]
    csindex2 = sort(csIndex2)
    xcs = c(xIndex,csIndex2)
    key = paste(as.character(xcs) , collapse=" ");
    if(is.null(stat_hash[[key]]) == FALSE)
    {
      stat = stat_hash[[key]];
      pvalue = pvalue_hash[[key]];
      flag = 1;
      
      results <- list(pvalue = pvalue, stat = stat, flag = flag , stat_hash=stat_hash, pvalue_hash=pvalue_hash);
      return(results);
    }
  }
  
  #if the xIndex is contained in csIndex, x does not bring any new
  #information with respect to cs
  if(!is.na(match(xIndex,csIndex)))
  {
    if(hash == TRUE)#update hash objects
    {
      stat_hash[[key]] <- 0;#.set(stat_hash , key , 0)
      pvalue_hash[[key]] <- 1;#.set(pvalue_hash , key , 1)
    }
    results <- list(pvalue = 1, stat = 0, flag = 1 , stat_hash=stat_hash, pvalue_hash=pvalue_hash);
    return(results);
  }
  
  #check input validity
  if(xIndex < 0 || csIndex < 0)
  {
    message(paste("error in testIndZIP : wrong input of xIndex or csIndex"))
    results <- list(pvalue = pvalue, stat = stat, flag = flag , stat_hash=stat_hash, pvalue_hash=pvalue_hash);
    return(results);
  }
  
  xIndex = unique(xIndex);
  csIndex = unique(csIndex);
  
  #extract the data
  x = dataset[ , xIndex];
  cs = dataset[ , csIndex];
  
  #remove equal columns of the CS (takes a lot of time)
  #   if(length(csIndex) > 1)
  #   {
  #     #remove same columns
  #     #cs = unique(as.matrix(cs), MARGIN = 2);
  #     #or
  #     w = which(duplicated(cs, MARGIN = 2))
  #     if(length(w) > 0)
  #     {
  #       cs = cs[,-w]
  #     }
  #   }
  
  #checking the length
  if (length(x) == 0 || length(target) == 0)
  {
    message(paste("error in testIndZIP : empty variable x or target"))
    results <- list(pvalue = pvalue, stat = stat, flag = flag , stat_hash=stat_hash, pvalue_hash=pvalue_hash);
    return(results);
  }
  
  #if x = any of the cs then pvalue = 1 and flag = 1.
  #That means that the x variable does not add more information to our model due to an exact copy of this in the cs, so it is independent from the target
  if(length(cs)!=0)
  {
    if(is.null(dim(cs)[2]) == TRUE) #cs is a vector
    {
      if(any(x != cs) == FALSE)  #if(!any(x == cs) == FALSE)
      {
        if(hash == TRUE)#update hash objects
        {
          stat_hash[[key]] <- 0;#.set(stat_hash , key , 0)
          pvalue_hash[[key]] <- 1;#.set(pvalue_hash , key , 1)
        }
        results <- list(pvalue = 1, stat = 0, flag = 1 , stat_hash=stat_hash, pvalue_hash=pvalue_hash);
        return(results);
      }
    }else{ #more than one var
      for(col in 1:dim(cs)[2])
      {
        if(any(x != cs[,col]) == FALSE)  #if(!any(x == cs) == FALSE)
        {
          if(hash == TRUE)#update hash objects
          {
            stat_hash[[key]] <- 0;#.set(stat_hash , key , 0)
            pvalue_hash[[key]] <- 1;#.set(pvalue_hash , key , 1)
          }
          results <- list(pvalue = 1, stat = 0, flag = 1 , stat_hash=stat_hash, pvalue_hash=pvalue_hash);
          return(results);
        }
      }
    }
  }
  
  #if x or target is constant then there is no point to perform the test
  if(var(x) == 0 || var(target) == 0)
  {
    if(hash == TRUE)#update hash objects
    {
      stat_hash[[key]] <- 0;#.set(stat_hash , key , 0)
      pvalue_hash[[key]] <- 1;#.set(pvalue_hash , key , 1)
    }
    results <- list(pvalue = 1, stat = 0, flag = 1 , stat_hash=stat_hash, pvalue_hash=pvalue_hash);
    return(results);
  }
  
  #remove constant columns of cs
  cs = as.matrix(cs)
  cs = cs[,apply(cs, 2, var, na.rm=TRUE) != 0]
  
  #trycatch for dealing with errors
  res <- tryCatch(
    {
      #if the conditioning set (cs) is empty, we use a simplified formula
      if(length(cs) == 0)
      {
        #compute the relationship between x,target directly
        fit1 = pscl::zeroinfl(target ~ 1 | 1)
        fit2 = pscl::zeroinfl(target ~ x | x )
      } else {
        fit1 = pscl::zeroinfl( target ~. | ., data = as.data.frame( dataset[, csIndex] ) )
        fit2 = pscl::zeroinfl( target ~. | ., data = as.data.frame( dataset[, c(csIndex, xIndex)] ) )
      } 
      
      lik1 = as.numeric( logLik(fit1) )
      lik2 = as.numeric( logLik(fit2) )
      stat = 2 * abs(lik1 -lik2)
      dof = length( coef(fit2) ) - 1
      pvalue = pchisq(stat, dof, lower.tail = FALSE, log.p = TRUE)   
      flag = 1;
      
      #last error check
      if(is.na(pvalue) || is.na(stat))
      {
        pvalue = 1;
        stat = 0;
        flag = 0;
      }else{
        #update hash objects
        if(hash == TRUE)
        {
          stat_hash[[key]] <- stat;#.set(stat_hash , key , stat)
          pvalue_hash[[key]] <- pvalue;#.set(pvalue_hash , key , pvalue)
        }
      }
      
      #testerrorcaseintrycatch(4);
      
      results <- list(pvalue = pvalue, stat = stat, flag = flag , stat_hash=stat_hash, pvalue_hash=pvalue_hash);
      return(results);
      
    },
    error=function(cond) {
      #   message(paste("error in try catch of the testIndZIP test"))
      #   message("Here's the original error message:")
      #   message(cond)
      #   
      #   #        
      #   #        #for debug
      #   #        print("\nxIndex = \n");
      #   #        print(xIndex);
      #   #        print("\ncsindex = \n");
      #   #        print(csIndex);
      #   
      #   stop();
      
      #error case
      pvalue = 1;
      stat = 0;
      flag = 0;
      
      results <- list(pvalue = pvalue, stat = stat, flag = flag , stat_hash=stat_hash, pvalue_hash=pvalue_hash);
      return(results);
    },
    finally={}
  )    
  return(res);
}