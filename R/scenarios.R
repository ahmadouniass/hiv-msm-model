# =============================================================================
# Projections 2024–2030 à partir des paramètres calibrés.
# Chaque scénario modifie un levier à partir de 2024.
# =============================================================================

# Applique un multiplicateur à un paramètre à partir d'une année donnée,
# en simulant en deux temps (avant / après l'intervention).
run_scenario <- function(p, y0, years, from = 2024, changes = list()) {
  before <- years[years < from]
  after  <- years[years >= from]

  # Phase 1 : jusqu'à l'intervention
  times1 <- seq(min(before), from, by = 1)
  out1 <- ode(y = c(y0, CumInc = 0, CumDiag = 0), times = times1,
              func = hiv_ode, parms = p, method = "lsoda")
  y_from <- out1[nrow(out1), c("S", "P", "U", "D", "T")]

  # Phase 2 : paramètres modifiés
  p2 <- p
  for (nm in names(changes)) p2[[nm]] <- p[[nm]] * changes[[nm]]

  rbind(run_model(p, y0, before), run_model(p2, y_from, after))
}

scenario_list <- list(
  "Statu quo"                 = list(),
  "Dépistage x 1,5"           = list(delta = 1.5),
  "Recours à la PrEP x 2"     = list(rho = 2),
  "Dépistage x 1,5 + PrEP x 2" = list(delta = 1.5, rho = 2)
)
