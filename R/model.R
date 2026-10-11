# =============================================================================
# Modèle compartimental de transmission du VIH chez les HSH
# -----------------------------------------------------------------------------
# Compartiments (effectifs) :
#   S : susceptibles sans PrEP
#   P : susceptibles sous PrEP
#   U : infectés non diagnostiqués
#   D : diagnostiqués, pas encore sous traitement efficace
#   T : sous traitement, charge virale indétectable (ne transmettent pas, I = I)
#
# Force d'infection : lambda(t) = beta(t) * (U + kappa * D) / N
# Les personnes sous traitement efficace ne contribuent pas à la transmission.
# =============================================================================

library(deSolve)

# Taux de transmission par morceaux : beta1 avant l'année de rupture, beta2 après.
# Cela permet de tester l'hypothèse d'un changement de dynamique (plateau de
# l'incidence observé depuis 2021).
beta_t <- function(t, p) {
  if (t < p$t_break) p$beta1 else p$beta2
}

# Taux d'entrée sous PrEP : nul avant l'année d'introduction (2016 en France).
rho_t <- function(t, p) {
  if (t < p$t_prep) 0 else p$rho
}

hiv_ode <- function(t, y, p) {
  S <- y[["S"]]; P <- y[["P"]]; U <- y[["U"]]; D <- y[["D"]]; Tr <- y[["T"]]
  N <- S + P + U + D + Tr

  lambda <- beta_t(t, p) * (U + p$kappa * D) / N
  rho    <- rho_t(t, p)
  inf_S  <- lambda * S
  inf_P  <- (1 - p$eps) * lambda * P

  dS <- p$entry * N - inf_S - rho * S + p$omega * P - p$mu * S
  dP <- rho * S - p$omega * P - inf_P - p$mu * P
  dU <- inf_S + inf_P - p$delta * U - p$mu * U
  dD <- p$delta * U - p$tau * D - p$mu * D
  dT <- p$tau * D - p$mu * Tr

  # Compteurs cumulés : on en déduit les flux annuels par différence.
  dCumInc  <- inf_S + inf_P      # nouvelles infections
  dCumDiag <- p$delta * U        # nouveaux diagnostics

  list(c(dS, dP, dU, dD, dT, dCumInc, dCumDiag))
}

# Simule le modèle et renvoie les indicateurs annuels.
run_model <- function(p, y0, years) {
  times <- seq(min(years), max(years) + 1, by = 1)
  state <- c(y0, CumInc = 0, CumDiag = 0)
  out <- as.data.frame(ode(y = state, times = times, func = hiv_ode,
                           parms = p, method = "lsoda"))
  n <- nrow(out)
  data.frame(
    year         = out$time[-n],
    incidence    = diff(out$CumInc),          # infections dans l'année
    diagnoses    = diff(out$CumDiag),         # diagnostics dans l'année
    undiagnosed  = out$U[-n],                 # non diagnostiqués au 1er janvier
    on_prep      = out$P[-n],
    prevalence   = (out$U + out$D + out$T)[-n],
    N            = (out$S + out$P + out$U + out$D + out$T)[-n]
  )
}
