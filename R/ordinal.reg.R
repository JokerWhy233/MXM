ordinal.reg <- function(formula, data) {
   call <- match.call()
   mf <- match.call(expand.dots = FALSE)
   m <- match(c("formula", "data"), names(mf), 0)
   mf <- mf[c(1, m)]
   mf$drop.unused.levels <- TRUE
   mf[[1]] <- as.name("model.frame")
   mf <- eval.parent(mf)
   mt <- attr(mf, "terms")
   y <- model.response(mf)
   x <- model.matrix(mt, mf, contrasts)
   k <- length( unique(y) )

  if ( k == 2 ) {
    mod <- glm(formula, data = data, binomial)
    return( list(be = coef(mod), devi = mod$deviance) )
  }  
  
  if ( sum(x) == 2 * length(y) ) {
    mod <- Rfast::ordinal.mle(y)
    return( list(be = mod$param, devi = - 2 * mod$loglik) )
  }

  yd <- model.matrix( ~ y - 1)
  y <- as.numeric(y)
  dm <- dim(x)
  n <- dm[1]
  m <- dm[2]
  b <- matrix(0, m, k - 1)
  options(warn = -1)
  for (i in 1:k - 1) {
    y1 <- y
    y1[y <= i ] <- 0
    y1[ y > i ] <- 1
    b[, i] <- - glm.fit(x, y1, family =  binomial(logit) )$coefficients 
  }
  u <- x %*% b
  cump <- 1 / (1 + exp(-u) )
  p <- cbind(cump[, 1], Rfast::coldiffs(cump), 1 - cump[, k - 1] )
  mess <- NULL

  if ( any( p < 0) ) {
    poia <- which(p < 0, arr.ind = TRUE)[, 1]
    a <- p[poia, , drop = FALSE]
    a <- abs( a )  
    a <- a / Rfast::rowsums(a)   
    p[poia, ] = a
    mess <- "problematic region"
  }
  
  devi <-  - 2 * sum( log( p[yd > 0] ) )
  list(mess = mess, be = b, devi = devi)
}
 
 
