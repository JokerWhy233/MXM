ebic.fbed.multinom <- function(y, x, gam = NULL, wei = NULL, K = 0) { 
  dm <- dim(x)
  n <- dm[1]
  p <- dm[2]
  ind <- 1:p
  lik2 <- numeric(p)
  epa <- length( Rfast::sort_unique(y) ) - 1
  sela <- NULL
  card <- 0
  
  if ( is.null(gam) ) {
    con <- 2 - log(p) / log(n)
    if ( (con) < 0 )  con <- 0
  } else con <- 2 * gam
  lik1 <- BIC( nnet::multinom(y ~ 1, weights = wei) ) 
  
  runtime <- proc.time()
  
  for ( i in ind ) {
    fit2 <- nnet::multinom( y ~ x[, i], weights = wei, trace = FALSE ) 
    lik2[i] <- BIC(fit2) + con * log(p)
  }
  n.tests <- p
  stat <- lik1 - lik2
  s <- which(stat > 0)

    if ( length(s) > 0 ) {
      sel <- which.max(stat)
      sela <- sel
      s <- s[ - which(s == sel) ]
      lik1 <- lik2[sel] 
      sa <- stat[sel]
      lik2 <- rep( lik1, p )
      #########
      while ( sum(s > 0) > 0 ) {
	    M <- length(sela) + 1
        for ( i in ind[s] )  {
          fit2 <- nnet::multinom( y ~., data = x[, c(sela, i)], weights = wei, trace = FALSE )
          lik2[i] <- BIC(fit2) + con * lchoose(p, M)
        }
        n.tests <- n.tests + length(ind[s])
        stat <- lik1 - lik2
        s <- which(stat > 0) 
        sel <- which.max(stat) * ( length(s)>0 )
        sa <- c(sa, stat[sel]) 
        sela <- c(sela, sel[sel>0])
        s <- s[ - which(s == sel) ]
        if (sel > 0) {
          lik1 <- lik2[sel] 
          lik2 <- rep(lik1, p)
        }  
      } ## end while ( sum(s > 0) > 0)

    card <- length(sela)

   if (K == 1) {
     M <- length(sela) + 1
     for ( i in ind[-sela] )  {
        fit2 <- nnet::multinom( y ~., data = x[, c(sela, i)], weights = wei, trace = FALSE )
        lik2[i] <- BIC(fit2) + con * lchoose(p, M)
      }
      n.tests[2] <- length( ind[-sela] )
      stat <- lik1 - lik2
      s <- which(stat > 0) 
      sel <- which.max(stat) * ( length(s)>0 )
      sa <- c(sa, stat[sel]) 
      sela <- c(sela, sel[sel>0])
      s <- s[ - which(s == sel) ]
      if (sel > 0) {
        lik1 <- lik2[sel] 
        lik2 <- rep(lik1, p)
      }  
      while ( sum(s > 0) > 0 ) {
	    M <- length(sela) + 1
        for ( i in ind[s] )  {
          fit2 <- nnet::multinom( y ~., data = x[, c(sela, i)], weights = wei, trace = FALSE )
          lik2[i] <- BIC(fit2) + con * lchoose(p, M)
        }
        n.tests[2] <- n.tests[2] + length( ind[s] )
        stat <- lik1 - lik2
        s <- which(stat > 0)
        sel <- which.max(stat) * ( length(s)>0 )
        sa <- c(sa, stat[sel]) 
        sela <- c(sela, sel[sel>0])
        s <- s[ - which(s == sel) ]
        if (sel > 0) {
          lik1 <- lik2[sel] 
          lik2 <- rep(lik1, p)
        }  
      } ## end while ( sum(s > 0) > 0 )
      card <- c(card, sum(sela > 0) )
   }  ## end if ( K == 1 ) 
  
  if ( K > 1) {
    M <- length(sela) + 1
    for ( i in ind[-sela] )  {
      fit2 <- nnet::multinom( y ~., data = x[, c(sela, i)], weights = wei, trace = FALSE )
      lik2[i] <- BIC(fit2) + con * lchoose(p, M)
    }
    n.tests[2] <- length(ind[-sela])
    stat <- lik1 - lik2
    s <- which(stat > 0) 
    sel <- which.max(stat) * ( length(s)>0 )
    sa <- c(sa, stat[sel]) 
    sela <- c(sela, sel[sel>0])
    s <- s[ - which(s == sel) ]
    if (sel > 0) {
      lik1 <- lik2[sel] 
      lik2 <- rep(lik1, p)
    }  
    while ( sum(s > 0) > 0 ) {
	  M <- length(sela) + 1
      for ( i in ind[s] )  {
        fit2 <- nnet::multinom( y ~., data = x[, c(sela, i)], weights = wei, trace = FALSE )
        lik2[i] <- BIC(fit2) + con * lchoose(p, M)
      }
      n.tests[2] <- n.tests[2] + length(ind[s])
      stat <- lik1 - lik2
      s <- which(stat > 0)
      sel <- which.max(stat) * ( length(s)>0 )
      sa <- c(sa, stat[sel]) 
      sela <- c(sela, sel[sel>0])
      s <- s[ - which(s == sel) ]
      if (sel > 0) {
        lik1 <- lik2[sel] 
        lik2 <- rep(lik1, p)
      }  
    } ## end while ( sum(s > 0) > 0 )
	  
    vim <- 1
    card <- c(card, sum(sela > 0) )
    while ( vim < K  & card[vim + 1] - card[vim] > 0 ) {
      vim <- vim + 1
	  M <- length(sela) + 1 
      for ( i in ind[-sela] )  {
        fit2 <- nnet::multinom( y ~., data = x[, c(sela, i)], weights = wei, trace = FALSE )
        lik2[i] <- BIC(fit2) + con * lchoose(p, M)
      }
      n.tests[vim + 1] <- length(ind[-sela])
      stat <- lik1 - lik2
      s <- which(stat > 0)
      sel <- which.max(stat) * ( length(s)>0 )
      sa <- c(sa, stat[sel]) 
      sela <- c(sela, sel[sel>0])
      s <- s[ - which(s == sel) ]
      if (sel > 0) {
        lik1 <- lik2[sel] 
        lik2 <- rep(lik1, p)
      }     
      while ( sum(s > 0) > 0 ) {
	    M <- length(sela) + 1
        for ( i in ind[s] )  {
          fit2 <- nnet::multinom( y ~., data = x[, c(sela, i)], weights = wei, trace = FALSE )
          lik2[i] <- BIC(fit2) + con * lchoose(p, M)
        }
        n.tests[vim + 1] <- n.tests[vim + 1] + length(ind[s])
        stat <- lik1 - lik2
        s <- which(stat > 0)
        sel <- which.max(stat) * ( length(s)>0 )
        sa <- c(sa, stat[sel]) 
        sela <- c(sela, sel[sel>0])
        s <- s[ - which(s == sel) ]
        if (sel > 0) {
          lik1 <- lik2[sel] 
          lik2 <- rep(lik1, p)
        }  
      } ## end while ( sum(s > 0) > 0 )
      card <- c(card, sum(sela > 0) )
    }  ## end while ( vim < K )
  } ## end if ( K > 1)
  } ## end if ( length(s) > 0 )
  
  runtime <- proc.time() - runtime
  len <- sum( sela > 0 )
  if (len > 0) {
    res <- cbind(sela[1:len], sa[1:len] )
    info <- matrix(nrow = length(card), ncol = 2)
    info[, 1] <- card
    info[, 2] <- n.tests
  } else {
    res <- matrix(c(0, 0), ncol = 2)
    info <- matrix(c(0, p), ncol = 2)
  }  
  colnames(res) <- c("Vars", "eBIC")
  rownames(info) <- paste("K=", 1:length(card)- 1, sep = "")
  colnames(info) <- c("Number of vars", "Number of tests")
  list(res = res, info = info, runtime = runtime)
}
 