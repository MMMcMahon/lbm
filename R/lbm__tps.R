
lbm__tps = function( p, x, pa, phi ) {
  #\\ this is the core engine of lbm .. localised space (no-time) modelling interpolation 
  # \ as a 2D gaussian process (basically, simple krigimg or TPS -- time is treated as being independent)
  #\\ note: time is not being modelled and treated independently 
  #\\      .. you had better have enough data in each time slice ..  essentially this is kriging 
  sdTotal = sd(x[,p$variable$Y], na.rm=T)

  x$mean = NA
  pa$mean = NA
  pa$sd = sdTotal  # leave as this as sd estimation is too expensive

  for ( ti in 1:p$nt ) {
    
    if ( exists("TIME", p$variables) ) {
      xi = which( x[ , p$variables$TIME ] == p$prediction.ts[ti] )
      pa_i = which( pa[, p$variables$TIME]==p$prediction.ts[ti])
    } else {
      xi = 1:nrow(x) # all data as p$nt==1
      pa_i = 1:nrow(pa)
    }

    ftpsmodel = try( Tps(x=x[xi, p$variables$LOCS], Y=x[xi, p$variables$Y], theta=theta, lambda=lambda ) )
    if (inherits(ftpsmodel, "try-error") )  next()
    x$mean[xi] = ftpsmodel$fitted.values 
    ss = lm( x$mean[xi] ~ x[xi,p$variables$Y], na.action=na.omit)
    if ( "try-error" %in% class( ss ) ) next()
    rsquared = summary(ss)$r.squared
    if (rsquared < p$lbm_rsquared_threshold ) next()
    pa$mean[pa_i] = predict(ftpsmodel, x=pa[pa_i, p$variables$LOCS] )
    pa$sd[pa_i]   = predictSE(ftpsmodel, x=pa[pa_i, p$variables$LOCS] ) # SE estimates are slooow
    if ( 0 ){
      # debugging plots
      surface(ftpsmodel)
      fsp.p<- predictSurface(ftpsmodel, lambda=fsp$pars["lambda"], nx=200, ny=200 )
      surface(fsp.p, type="I")
      fsp.p2<- predictSurfaceSE(ftpsmodel)
      surface(fsp.p, type="C")
    }
  }

  # plot(pred ~ z , x)
  # lattice::levelplot( mean ~ plon + plat, data=pa, col.regions=heat.colors(100), scale=list(draw=FALSE) , aspect="iso" )
  ss = lm( x$mean ~ x[,p$variables$Y], na.action=na.omit)
  if ( "try-error" %in% class( ss ) ) return( NULL )
  rsquared = summary(ss)$r.squared
  if (rsquared < p$lbm_rsquared_threshold ) return(NULL)

  lbm_stats = list( sdTotal=sdTotal, rsquared=rsquared, ndata=nrow(x) ) # must be same order as p$statsvars
  return( list( predictions=pa, lbm_stats=lbm_stats ) )  
}

