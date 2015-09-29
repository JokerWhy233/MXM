\name{cv.ses}
\alias{cv.ses}
\alias{auc.mxm}
\alias{acc.mxm}
\alias{mse.mxm}
\alias{ci.mxm}
\alias{glm.mxm}
\alias{lm.mxm}
\alias{coxph.mxm}
\title{
Cross-Validation for SES
}
\description{
The function performs a k-fold cross-validation for identifying the best values for the SES 'max_k' and 'threshold' hyper-parameters
}
\usage{
cv.ses (target, dataset, kfolds = 10, folds = NULL, alphas = NULL, max_ks = NULL,
task = NULL, metric = NULL, modeler = NULL, ses_test = NULL)
}
\arguments{
  \item{target}{
  The target or class variable as in SES.
}
  \item{dataset}{
  The dataset object as in SES.
}
  \item{kfolds}{
  The number of the folds in the k-fold Cross Validation (integer).
}
  \item{folds}{
  The folds of the data to use (a list generated by the function generateCVRuns {TunePareto}). If NULL the folds are created internally with the same function.
}
  \item{alphas}{
  A vector of SES thresholds hyper parameters used in CV. Default is c(0.1, 0.05, 0.01).
}
  \item{max_ks}{
  A vector of SES max_ks parameters used in CV. Default is c(3, 2).
}
  \item{task}{
  A character ("C", "R" or "S"). It can be "C" for classification (logistic regression classifier), "R" for regression (linear regression classifier), "S" for cox survival analysis (cox regression classifier)
}
  \item{metric}{
  A metric function provided by the user. If NULL the following functions will be used: auc.mxm, mse.mxm, ci.mxm for classification, regression and survival analysis tasks, respectively. See details for more.
}
  \item{modeler}{
  A modeling function provided by the user. If NULL the following functions will be used: glm.mxm, lm.mxm, coxph.mxm for classification, regression and survival analysis tasks, respectively. See details for more.
}
  \item{ses_test}{
  A function object that defines the conditional independence test used in the SES function (see also SES help page). If NULL, testIndFisher, testIndLogistic and censIndLR are used for classification, regression and survival analysis tasks, respectively.
}
}
\details{

Input for metric functions:
predictions: A vector of predictions to be tested.
test_target: target variable actual values to be compared with the predictions.

The output of a metric function is a single numeric value. \bold{Higher values indicate better performance}. Metric based on error measures should be modified accordingly (e.g., multiplying the error for -1)

The Metric functions that are currently supported are:
\itemize{
  \item auc.mxm: "area under the receiver operator characteristic curve" metric, as provided in the package ROCR.
  \item acc.mxm: accuracy metric.
	\item mse.mxm: -1 * (mean squared error).
	\item ci.mxm: concordance index as provided in the rcorr.cens function from the Hmisc package.
}
Usage: metric(predictions, test_target)


Input of modelling functions:
train_target: target variable used in the training procedure.
sign_data: training set.
sign_test: test set.

Modelling functions provide a single vector of predictions obtained by applying the model fit on sign_data and train_target on the sign_test

The modelling functions that are currently supported are:
\itemize{
  \item glm.mxm: fits a glm model (stats) for a binomial family (Classification task)
  \item lm.mxm: fits an lm model (stats) for the regression task.
  \item coxph.mxm: fits a cox proportional hazards regression model for the survival task.
}
Usage: modeler(train_target, sign_data, sign_test)


}

\value{
A list including:
\item{cv_results_all}{
A list with predictions, performances and signatures for each fold and each SES configuration (e.g cv_results_all[[3]]$performances[1] indicates the performance of the 1st fold with the 3d configuration of SES).
}
\item{best_performance}{
A numeric value that represents the best average performance.
}
\item{best_configuration}{
A list that corresponds to the best configuration of SES including id, threshold (named 'a') and max_k.
}
}
%\references{
%}
\author{
R implementation and documentation: Giorgos Athineou <athineou@ics.forth.gr> and Vincenzo Lagani <vlagani@ics.forth.gr>
}
%\note{
%%  ~~further notes~~
%}
\seealso{
\code{\link{SES}, \link{CondIndTests}, \link{testIndFisher}, \link{testIndLogistic}, \link{gSquare}, \link{censIndLR}}
}
\examples{

set.seed(1234)

#simulate a dataset with continuous data
dataset <- matrix(nrow = 100 , ncol = 100)
dataset <- apply(dataset, 1:2, function(i) runif(1, 1, 10))
#the target feature is the last column of the dataset as a vector
target <- dataset[,100]

#get 50 percent of the dataset as a train set
train_set <- dataset[1:50,]
train_target=target[1:50]

#run a 10 fold CV for the regression task
best_model = cv.ses(target = train_target, dataset = train_set, kfolds = 10, task = "R")

#get the results
best_model$best_configuration
best_model$best_performance

#summary elements of the process. Press tab after each $ to view all the elements and
#choose the one you are intresting in.
#best_model$cv_results_all[[...]]$...
#i.e.
#mse value for the 1st configuration of SES of the 5 fold
abs(best_model$cv_results_all[[1]]$performances[5])

best_a = best_model$best_configuration$a
best_max_k = best_model$best_configuration$max_k

}
\keyword{ Cross Validation}
\keyword{ CV }
\keyword{ CV SES }
