\name{Conditional independence test for binary, categorical or ordinal data}
\alias{testIndLogistic}
\alias{permLogistic}
\alias{waldBinary}
\alias{waldOrdinal}
\title{
Conditional independence test for binary, categorical or ordinal class variables
}

\description{
The main task of this test is to provide a p-value PVALUE for the null hypothesis: feature 'X' is independent from 'TARGET' given a conditioning set CS. The pvalue is calculated by comparing a logistic model based on the conditioning set CS against a model whose regressor are both X and CS. The comparison is performed through a chi-square test with the aproprirate degrees of freedom on the difference between the deviances of the two models.
}

\usage{
testIndLogistic(target, dataset, xIndex, csIndex, wei = NULL, dataInfo = NULL, 
univariateModels = NULL, hash = FALSE, stat_hash = NULL, pvalue_hash = NULL, 
target_type = 0, robust = FALSE)

permLogistic(target, dataset, xIndex, csIndex, wei = NULL, dataInfo = NULL, 
univariateModels = NULL, hash = FALSE, stat_hash = NULL, pvalue_hash = NULL, 
robust = FALSE, threshold = 0.05, R = 999)

waldBinary(target, dataset, xIndex, csIndex, wei = NULL, dataInfo = NULL, 
univariateModels = NULL, hash = FALSE, stat_hash = NULL, pvalue_hash = NULL, 
robust = FALSE)

waldOrdinal(target, dataset, xIndex, csIndex, wei = NULL, dataInfo = NULL, 
univariateModels = NULL, hash = FALSE, stat_hash = NULL, pvalue_hash = NULL, 
robust = FALSE)

}

\arguments{
\item{target}{
A numeric vector containing the values of the target variable. For the "testIndLogistic" this can either be a binary numerical variable or a factor variable. The factor variable can have two values (binary logistic regression), more than two values (multinomial logistic regression) or it can be an ordered factor with more than two values (ordinal regression). The last one is for example, factor(x, ordered = TRUE). The "waldBinary" is the Wald test version of the binary logistic regression. The "waldOrdinal" is the Wald test version of the ordinal regression.
}
\item{dataset}{
A numeric matrix or data frame, in case of categorical predictors (factors), containing the variables for performing the test. Rows as samples and columns as features. In the cases of "waldBinary", "waldOrdinal" this is strictly a matrix. 
}
\item{xIndex}{
The index of the variable whose association with the target we want to test.
}
\item{csIndex}{
The indices of the variables to condition on. If you have no variables set this equal to 0.
}
\item{wei}{
A vector of weights to be used for weighted regression. The default value is NULL. 
}
\item{dataInfo}{
A list object with information on the structure of the data. Default value is NULL.
}
\item{univariateModels}{
Fast alternative to the hash object for univariate test. List with vectors "pvalues" (p-values), "stats" (statistics) and "flags" (flag = TRUE if the test was succesful) representing the univariate association of each variable with the target. Default value is NULL.
}
\item{hash}{
A boolean variable which indicates whether (TRUE) or not (FALSE) to use the hash-based implementation of the statistics of SES. Default value is FALSE. If TRUE you have to specify the stat_hash argument and the pvalue_hash argument.
}
\item{stat_hash}{
A hash object (hash package required) which contains the cached generated statistics of a SES run in the current dataset, using the current test.
}
\item{pvalue_hash}{
A hash object (hash package required) which contains the cached generated p-values of a SES run in the current dataset, using the current test.
}
\item{target_type}{
A numeric vector that represents the type of the target. Default value is 0. See details for more.
\itemize{
\item target_type = 1 (binary target)
\item target_type = 2 (nominal target)
\item target_type = 3 (ordinal target)
}
}
\item{robust}{
A boolean variable which indicates whether (TRUE) or not (FALSE) to use a robustified version of the logistic regressions available here. Currently it is not available.
}
\item{threshold}{
Threshold (suitable values in [0,1]) for assessing p-values significance. 
}
\item{R}{
The number of permutations, set to 999 by default. There is a trick to avoind doing all permutations. As soon as the number of times the permuted test statistic is more than the observed test statistic is more than 50 (if threshold = 0.05 and R = 999), the p-value has exceeded the signifiance level (threshold value) and hence the predictor variable is not significant. There is no need to continue do the extra permutations, as a decision has already been made. 
}
}

\details{
If argument target_type=0 then testIndLogistic requires the dataInfo argument to indicate the type of the current target:
\itemize{
\item dataInfo$target_type = "binary" (binary target).
\item dataInfo$target_type = "nominal" (nominal target).
\item dataInfo$target_type = "ordinal" (ordinal target).
}

If hash = TRUE, testIndLogistic requires the arguments 'stat_hash' and 'pvalue_hash' for the hash-based implementation of the statistic test. These hash Objects are produced or updated by each run of SES (if hash == TRUE) and they can be reused in order to speed up next runs of the current statistic test. If "SESoutput" is the output of a SES run, then these objects can be retrieved by SESoutput@hashObject$stat_hash and the SESoutput@hashObject$pvalue_hash.

Important: Use these arguments only with the same dataset that was used at initialization. For all the available conditional independence tests that are currently included on the package, please see "?CondIndTests".

The log-likelihood ratio test used in "testIndLogistic" requires the fitting of two models. The Wald test used in waldBinary" and "waldOrdinal" requires fitting of only one model, the full one. The significance of the variable is examined only. Only continuous (or binary) predictor variables are currently accepted in this test. 
}

\value{
A list including:
\item{pvalue}{
A numeric value that represents the logarithm of the generated p-value.
}
\item{stat}{
A numeric value that represents the generated statistic.
}
\item{flag}{
A numeric value (control flag) which indicates whether the test was succesful (0) or not (1).
}
\item{stat_hash}{
The current hash object used for the statistics. See argument stat_hash and details. If argument hash = FALSE this is NULL.
}
\item{pvalue_hash}{
The current hash object used for the p-values. See argument stat_hash and details. If argument hash = FALSE this is NULL.
}
}

\references{
Hampel F. R., Ronchetti E. M., Rousseeuw P. J., and Stahel W. A. (1986). Robust statistics: the approach based on influence functions. John Wiley & Sons. 

Vincenzo Lagani, George Kortas and Ioannis Tsamardinos (2013), Biomarker signature identification in "omics" with multiclass outcome. Computational and Structural Biotechnology Journal, 6(7):1-7.

McCullagh, Peter, and John A. Nelder. Generalized linear models.  CRC press, USA, 2nd edition, 1989.
}

\author{
Vincenzo Lagani and Ioannis Tsamardinos 

R implementation and documentation: Vincenzo Lagani <vlagani@csd.uoc.gr>, Giorgos Athineou <athineou@csd.uoc.gr> and Michail Tsagris <mtsagris@csd.uoc.gr>
}

\note{
This test uses the function multinom (package nnet) for multinomial logistic regression, the function clm (package ordinal) for ordinal logit regression and the function glm (package stats) for binomial regression.
}

\seealso{
\code{\link{SES}, \link{testIndSpeedglm}, \link{gSquare}, \link{CondIndTests}}
}

\examples{
#require(nnet)
#require(ordinal)

#simulate a dataset with categorical data 
dataset_m <- matrix( sample(c(0, 1, 2), 50 * 100, replace = TRUE), ncol = 50)
#initialize categorical target
target_m <- dataset_m[, 50]
#remove target from the dataset
dataset_m <- dataset_m[, -50]

  #run the conditional independence test for the nominal class variable
  results_m <- testIndLogistic(target_m, dataset_m, xIndex = 44, csIndex = c(10, 20), 
  target_type = 2)
  results_m

  #run the SES algorithm using the testIndLogistic conditional independence test 
  #for the nominal class variable
  sesObject <- SES(as.factor(target_m), dataset_m, max_k = 3, threshold = 0.05, 
  test = "testIndLogistic");
  #print summary of the SES output
  summary(sesObject);
  # plot the SES output
  # plot(sesObject, mode = "all");


########################################################################

  #run the conditional independence test for the ordinal class variable
  results_o <- testIndLogistic(as.factor(target_m), dataset_m, xIndex = 44, csIndex = c(10, 20), 
  target_type = 3)
  results_o
  
  #run the SES algorithm using the testIndLogistic conditional independence test 
  #for the ordinal class variable
  sesObject <- SES(factor(target_m, ordered=TRUE), dataset_m, max_k = 3 , 
  threshold = 0.05, test = "testIndLogistic");
  #print summary of the SES output
  summary(sesObject);
  # plot the SES output
  # plot(sesObject, mode = "all");


########################################################################

#simulate a dataset with binary data
dataset_b <- matrix(sample(c(0,1),50 * 60, replace = TRUE), ncol = 50)
#initialize binary target
target_b <- dataset_b[, 50]
#remove target from the dataset
dataset_b <- dataset_b[, -50]

  #run the conditional independence test for the binary class variable
  results_b <- testIndLogistic(target_b, dataset_b, xIndex = 44, csIndex = c(10, 20), 
  target_type = 1)
  results_b
  
  #run the SES algorithm using the testIndLogistic conditional independence test
  #for the binary class variable
  sesObject <- SES(target_b, dataset_b, max_k = 3, threshold = 0.05, 
  test = "testIndLogistic");
  #print summary of the SES output
  summary(sesObject);
}

\keyword{ Binary logistic regression }
\keyword{ Multinomial logistic regression }
\keyword{ Ordinal logistic regression }
\keyword{ Conditional independence test }
