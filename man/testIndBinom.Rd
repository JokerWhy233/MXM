\name{Conditional independence tests for sucess rates}
\alias{testIndBinom}
\alias{permBinom}
\alias{waldBinom}
\title{
Binomial regression conditional independence test for success rates (binomial)
}

\description{
The main task of this test is to provide a p-value PVALUE for the null hypothesis: feature 'X' is independent from 'TARGET' given a conditioning set CS. The pvalue is calculated by comparing a binomial logistic regression model based on the conditioning set CS against a model whose regressor are both X and CS. The comparison is performed through a chi-square test with the appropriate degrees of freedom on the difference between the deviances of the two models. 
}

\usage{
testIndBinom(target, dataset, xIndex, csIndex, wei = NULL, dataInfo = NULL, 
univariateModels = NULL, hash = FALSE, stat_hash = NULL, pvalue_hash = NULL, 
robust = FALSE)

permBinom(target, dataset, xIndex, csIndex, wei = NULL, dataInfo = NULL, 
univariateModels = NULL, hash = FALSE, stat_hash = NULL, pvalue_hash = NULL, 
robust = FALSE, threshold = 0.05, R = 999)

waldBinom(target, dataset, xIndex, csIndex, wei = NULL, dataInfo = NULL, 
univariateModels = NULL , hash = FALSE, stat_hash = NULL, pvalue_hash = NULL, 
robust = FALSE) 

}

\arguments{
\item{target}{
A matrix with two two columns, the first one is the number of successes, the cases (integer) and the second one is the totals (integers).
}
\item{dataset}{
A numeric matrix or data frame, in case of categorical predictors (factors), containing the variables for performing the test. Rows as samples and columns as features. In the case of "waldBinom" this is strictly a matrix. 
}
\item{xIndex}{
The index of the variable whose association with the target we want to test.
}
\item{csIndex}{
The indices of the variables to condition on. If you have no variables set this equal to 0.
}
\item{wei}{
A vector of weights to be used for weighted regression. The default value is NULL and should stay as is, since the totals (second column of the target) is used as weights. 
}
\item{dataInfo}{
A list object with information on the structure of the data. Default value is NULL.
}
\item{univariateModels}{
Fast alternative to the hash object for univariate test. List with vectors "pvalues" (p-values), "stats" (statistics) and "flags" (flag = TRUE if the test was succesful) representing the univariate association of each variable with the target. Default value is NULL.
}
\item{hash}{
A boolean variable which indicates whether (TRUE) or not (FALSE) to use tha hash-based implementation of the statistics of SES. Default value is FALSE. If TRUE you have to specify the stat_hash argument and the pvalue_hash argument.
}
\item{stat_hash}{
A hash object (hash package required) which contains the cached generated statistics of a SES run in the current dataset, using the current test.
}
\item{pvalue_hash}{
A hash object (hash package required) which contains the cached generated p-values of a SES run in the current dataset, using the current test.
}
\item{robust}{
A boolean variable which indicates whether (TRUE) or not (FALSE) to use a robust version of the statistical test if it is available. It takes more time than non robust version but it is suggested in case of outliers. Default value is FALSE as it is currently nor supported.
}
\item{threshold}{
Threshold (suitable values in [0,1]) for assessing p-values significance. 
}
\item{R}{
The number of permutations, set to 999 by default. There is a trick to avoind doing all permutations. As soon as the number of times the permuted test statistic is more than the observed test statistic is more than 50 (if threshold = 0.05 and R = 999), the p-value has exceeded the signifiance level (threshold value) and hence the predictor variable is not significant. There is no need to continue do the extra permutations, as a decision has already been made. 
}
}

\details{
If hash = TRUE, all three tests require the arguments 'stat_hash' and 'pvalue_hash' for the hash-based implementation of the statistic test. These hash Objects are produced or updated by each run of SES (if hash == TRUE) and they can be reused in order to speed up next runs of the current statistic test. If "SESoutput" is the output of a SES run, then these objects can be retrieved by SESoutput@hashObject$stat_hash and the SESoutput@hashObject$pvalue_hash.
  
Important: Use these arguments only with the same dataset that was used at initialization. For all the available conditional independence tests that are currently included on the package, please see "?CondIndTests".
  
If you have overdispersion, the variance is higher than the mean, a negative binomial is to be used. If you have more zeros than expected under a Poisson model, not overdispersion, then zero inlfated Poisson is to be used. This is in fact a logistic reression where the target is the ratio of successes divided by the totals and the weights are the totals. 

The log-likelihood ratio test used in "testIndBinom" requires the fitting of two models. The Wald test used in "waldBinom" requires fitting of only one model, the full one. The significance of the variable is examined only. Only continuous (or binary) predictor variables are currently accepted in this test. 
}

\value{
  A list including:
    \item{pvalue}{
      A numeric value that represents the logarithm of the generated p-value due to the count data regression (see references below).
    }
  \item{stat}{
    A numeric value that represents the generated statistic due to Poisson regression(see reference below).
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
McCullagh P., and Nelder J.A. (1989). Generalized linear models.  CRC press, USA, 2nd edition.
}

\author{
Vincenzo Lagani, Ioannis Tsamardinos, Giorgos Athineou and Michail Tsagris.
  
R implementation and documentation: Giorgos Athineou <athineou@csd.uoc.gr>, Vincenzo Lagani <vlagani@csd.uoc.gr> and Michail Tsagris <mtsagris@csd.uoc.gr>
}

%\note{
  %%  ~~further notes~~
    %}

\seealso{
  \code{ \link{testIndLogistic}, \link{testIndBeta}, \link{testIndReg}, \link{CondIndTests}}
}

\examples{
#simulate a dataset with continuous data
dataset <- matrix(runif(400 * 50, 1, 50), ncol = 50 ) 
#the target feature is the last column of the dataset as a vector
y <- rbinom(400, 10, 0.6)
N <- sample(11:20, 400, replace = TRUE)
target <- cbind(y, N)
results <- testIndBinom(target, dataset, xIndex = 24, csIndex = 10)
results

#run the SES algorithm using the testIndPois conditional independence test
a1 <- SES(target, dataset, max_k = 3, threshold = 0.05, test = "testIndBinom");
a2 <- MMPC(target, dataset, max_k = 3, threshold = 0.05, test = "testIndBinom");
}

\keyword{ Binomial logistic regression }
\keyword{ Conditional independence test }
