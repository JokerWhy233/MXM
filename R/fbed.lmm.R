fbed.lmm <- function(y, x, id, alpha = 0.05, wei = NULL, K = 0) { 

  dm <- dim(x)
  p <- dm[2]
  n <- dm[1]
  ind <- 1:p
  sig <- log(alpha)
  lik2 <- numeric(p)
  sela <- NULL
  card <- 0
  sa <- NULL
  pva <- NULL
  
  ep <- Rfast::check_data(x)
  if ( sum(ep>0) > 0 )  x[, ep] <- rnorm( n * ep )
  
  runtime <- proc.time()
  
  if ( min(y) > 0  &  max(y) < 1 )  y = log( y/(1 - y) )
  
  for ( i in ind ) {
    fit2 <- lme4::lmer( y ~ x[, i] + (1|id), REML = FALSE, weights = wei )
    lik2[i] <- summary(fit2)[[ 10 ]][2, 3]^2
  }
  n.tests <- p
  stat <- lik2
  pval <- pf(stat, 1, n - 4, lower.tail = FALSE, log.p = TRUE)
  s <- which(pval < sig)
  
  if ( length(s) > 0 ) {
    sel <- which.min(pval)
    sela <- sel
    s <- s[ - which(s == sel) ]
    lik1 <- lik2[sel] 
    sa <- stat[sel]
    pva <- pval[sel]
    lik2 <- rep( 0, p )
    param <- rep(0, p)
    #########
    while ( sum(s>0) > 0 ) {
      d0 <- length(sela)
      for ( i in ind[s] )  {
        fit2 <- lme4::lmer( y ~ x[, c(sela, i)] + (1|id), REML = FALSE, weights = wei )
        d1 <- summary(fit2)[[3]]$dims[3]
        lik2[i] <- summary(fit2)[[ 10 ]][d1, 3]^2
        param[i] <- d1 - d0
      }
      n.tests <- n.tests + length( ind[s] ) 
      stat <- lik2
      pval <- pf(stat, 1, n - param - 2, lower.tail = FALSE, log.p = TRUE)
      s <- which(pval < sig) 
      sel <- which.min(pval) * ( length(s) > 0 )
      sa <- c(sa, stat[sel]) 
      pva <- c(pva, pval[sel])
      sela <- c(sela, sel[sel>0])
      s <- s[ - which(s == sel) ]
      if (sel > 0)  lik2 <- rep(0, p)
    } ## end while ( sum(s > 0) > 0 )
    
    card <- sum(sela > 0)
    
    if (K == 1) {
      d0 <- length(sela)
      for ( i in ind[-sela] )  {
        fit2 <- lme4::lmer( y ~ x[, c(sela, i)] + (1|id), REML = FALSE, weights = wei )
        d1 <- summary(fit2)[[3]]$dims[3]
        lik2[i] <- summary(fit2)[[ 10 ]][d1, 3]^2
        param[i] <- d1 - d0
      }
      n.tests[2] <- length( ind[-sela] )
      stat <- lik2
      pval <- pf(stat, 1, n - param - 2, lower.tail = FALSE, log.p = TRUE)
      s <- which(pval < sig)
      sel <- which.min(pval) * ( length(s)>0 )
      sa <- c(sa, stat[sel]) 
      pva <- c(pva, pval[sel])
      sela <- c(sela, sel[sel>0])
      s <- s[ - which(s == sel) ]
      while ( sum(s>0) > 0 ) {
        d0 <- length(sela)
        for ( i in ind[s] )  {
          fit2 <- lme4::lmer( y ~ x[, c(sela, i)] + (1|id), REML = FALSE, weights = wei )
          d1 <- summary(fit2)[[3]]$dims[3]
          lik2[i] <- summary(fit2)[[ 10 ]][d1, 3]^2
          param[i] <- d1 - d0
        }
        n.tests[2] <- n.tests[2] + length( ind[s] )
        stat <- lik2 - lik1
        pval <- pf(stat, 1, n - param - 2, lower.tail = FALSE, log.p = TRUE)
        s <- which(pval < sig)
        sel <- which.min(pval) * ( length(s)>0 )
        sa <- c(sa, stat[sel]) 
        pva <- c(pva, pval[sel])
        sela <- c(sela, sel[sel>0])
        s <- s[ - which(s == sel) ]
        if (sel > 0)  lik2 <- rep(0, p)
      } ## end while ( sum(s>0) > 0 ) 
      card <- c(card, sum(sela>0) )
    }  ## end if ( K == 1 ) 
    
    if ( K > 1) {
      
      d0 <- length(sela)
      for ( i in ind[-sela] )  {
        fit2 <- lme4::lmer( y ~ x[, c(sela, i)] + (1|id), REML = FALSE, weights = wei )
        d1 <- summary(fit2)[[3]]$dims[3]
        lik2[i] <- summary(fit2)[[ 10 ]][d1, 3]^2
        param[i] <- d1 - d0
      }
      n.tests[2] <- length( ind[-sela] )
      stat <- lik2
      pval <- pf(stat, 1, n - param - 2, lower.tail = FALSE, log.p = TRUE)
      s <- which(pval < sig)
      sel <- which.min(pval) * ( length(s)>0 )
      sa <- c(sa, stat[sel]) 
      pva <- c(pva, pval[sel])
      sela <- c(sela, sel[sel>0])
      s <- s[ - which(s == sel) ]
      if (sel > 0)  lik2 <- rep(0, p)
      
      while ( sum(s > 0) > 0 ) {
        d0 <- length(sela)
        for ( i in ind[s] )  {
          fit2 <- lme4::lmer( y ~ x[, c(sela, i)] + (1|id), REML = FALSE, weights = wei )
          d1 <- summary(fit2)[[3]]$dims[3]
          lik2[i] <- summary(fit2)[[ 10 ]][d1, 3]^2
          param[i] <- d1 - d0
        }
        n.tests[2] <- n.tests[2] + length( ind[s] )  
        stat <- lik2
        pval <- pf(stat, 1, n - param - 2, lower.tail = FALSE, log.p = TRUE)
        s <- which(pval < sig)
        sel <- which.min(pval) * ( length(s)>0 )
        sa <- c(sa, stat[sel]) 
        pva <- c(pva, pval[sel])
        sela <- c(sela, sel[sel>0])
        s <- s[ - which(s == sel) ]
        if (sel > 0)  lik2 <- rep(0, p)
      } ## end while ( sum(s>0) > 0 ) 
      
      card <- c(card, sum(sela > 0) )
      vim <- 1
      while ( vim < K  & card[vim + 1] - card[vim] > 0 ) {
        vim <- vim + 1
        d0 <- length(sela)
        for ( i in ind[-sela] )  {
          fit2 <- lme4::lmer( y ~ x[, c(sela, i)] + (1|id), REML = FALSE, weights = wei )
          d1 <- summary(fit2)[[3]]$dims[3]
          lik2[i] <- summary(fit2)[[ 10 ]][d1, 3]^2
          param[i] <- d1 - d0
        }
        n.tests[vim + 1] <- length( ind[-sela] )
        stat <- lik2 
        pval <- pf(stat, 1, n - param - 2, lower.tail = FALSE, log.p = TRUE)
        s <- which(pval < sig)
        sel <- which.min(pval) * ( length(s)>0 )
        sa <- c(sa, stat[sel]) 
        pva <- c(pva, pval[sel])
        sela <- c(sela, sel[sel>0])
        s <- s[ - which(s == sel) ]
        if (sel > 0)  lik2 <- rep(0, p)
        
        while ( sum(s > 0) > 0 ) {
          d0 <- length(sela)
          for ( i in ind[s] )  {
            fit2 <- lme4::lmer( y ~ x[, c(sela, i)] + (1|id), REML = FALSE, weights = wei )
            d1 <- summary(fit2)[[3]]$dims[3]
            lik2[i] <- summary(fit2)[[ 10 ]][d1, 3]^2
            param[i] <- d1 - d0
          }
          n.tests[vim + 1] <- n.tests[vim + 1] + length( ind[s] )
          stat <- lik2 - lik1
          pval <- pf(stat, 1, n - param - 2, lower.tail = FALSE, log.p = TRUE)
          s <- which(pval < sig)
          sel <- which.min(pval) * ( length(s)>0 )
          sa <- c(sa, stat[sel]) 
          pva <- c(pva, pval[sel])
          sela <- c(sela, sel[sel>0])
          s <- s[ - which(s == sel) ]
          if (sel > 0)  lik2 <- rep(0, p)
        } ## end while ( sum(s > 0) > 0 ) 
        card <- c(card, sum(sela>0) )
      }  ## end while ( vim < K )
    } ## end if ( K > 1)
  } ## end if ( length(s) > 0 )
  
  runtime <- proc.time() - runtime
  len <- sum( sela > 0 )
  if (len > 0) {
    res <- cbind(sela[1:len], sa[1:len], pva[1:len] )
    info <- matrix(nrow = length(card), ncol = 2)
    info[, 1] <- card
    info[, 2] <- n.tests
  } else {
    res <- matrix(c(0, 0, 0), ncol = 3)
    info <- matrix(c(0, p), ncol = 2)
  }  
  colnames(res) <- c("Vars", "stat", "log p-value")
  rownames(info) <- paste("K=", 1:length(card)- 1, sep = "")
  colnames(info) <- c("Number of vars", "Number of tests")
  list(res = res, info = info, runtime = runtime)
}
