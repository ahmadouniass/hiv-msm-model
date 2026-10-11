# =============================================================================
# 1. Génération de données de surveillance simulées
# 2. Calibration de (beta1, beta2, delta) par maximum de vraisemblance de Poisson
# =============================================================================

simulate_surveillance <- function(p, y0, years_fit, years_obs, seed = 2027) {
  set.seed(seed)
  sim <- run_model(p, y0, years_fit)
  sim <- sim[sim$year %in% years_obs, ]
  data.frame(year = sim$year,
             diagnoses_obs = rpois(nrow(sim), sim$diagnoses),
             diagnoses_true = sim$diagnoses,
             incidence_true = sim$incidence)
}

# Paramètres estimés sur l'échelle log pour garantir leur positivité.
unpack <- function(theta, base) {
  p <- base
  p$beta1 <- exp(theta[1])
  p$beta2 <- exp(theta[2])
  p$delta <- exp(theta[3])
  p
}

neg_loglik <- function(theta, base, y0, years_fit, obs) {
  p <- unpack(theta, base)
  sim <- tryCatch(suppressWarnings(run_model(p, y0, years_fit)),
                  error = function(e) NULL)
  if (is.null(sim)) return(1e10)
  mu_hat <- sim$diagnoses[match(obs$year, sim$year)]
  if (any(!is.finite(mu_hat)) || any(mu_hat <= 0)) return(1e10)
  -sum(dpois(obs$diagnoses_obs, mu_hat, log = TRUE))
}

calibrate <- function(base, y0, years_fit, obs,
                      start = c(beta1 = 0.1, beta2 = 0.1, delta = 0.15)) {
  fit <- optim(log(start), neg_loglik, base = base, y0 = y0,
               years_fit = years_fit, obs = obs,
               method = "L-BFGS-B", hessian = TRUE,
               # bornes plausibles (échelle log) pour éviter des valeurs absurdes
               lower = log(c(0.05, 0.05, 0.02)), upper = log(c(3, 3, 2)),
               control = list(maxit = 500, factr = 1e5))

  # Intervalles de confiance à 95 % (approximation de Wald sur l'échelle log)
  se  <- sqrt(diag(solve(fit$hessian)))
  est <- data.frame(
    parameter = c("beta1", "beta2", "delta"),
    estimate  = exp(fit$par),
    lower95   = exp(fit$par - 1.96 * se),
    upper95   = exp(fit$par + 1.96 * se)
  )
  list(fit = fit, estimates = est, params = unpack(fit$par, base))
}
