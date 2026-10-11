# =============================================================================
# Point d'entrée : Rscript run_all.R
# Produit les tableaux dans output/ et les figures dans figures/.
# =============================================================================

source("R/model.R")
source("R/parameters.R")
source("R/calibrate.R")
source("R/scenarios.R")

dir.create("output",  showWarnings = FALSE)
dir.create("figures", showWarnings = FALSE)

# --- 1. Données simulées ------------------------------------------------------
obs <- simulate_surveillance(true_params, y0, years_fit, years_obs)
write.csv(obs, "output/surveillance_simulee.csv", row.names = FALSE)

# --- 2. Calibration -----------------------------------------------------------
cal <- calibrate(true_params, y0, years_fit, obs)
est <- cal$estimates
est$true_value <- unlist(true_params[est$parameter])
write.csv(est, "output/estimations.csv", row.names = FALSE)
cat("\nParamètres estimés (vraies valeurs en dernière colonne) :\n")
print(est, digits = 3, row.names = FALSE)

fitted <- run_model(cal$params, y0, years_fit)

png("figures/calibration.png", width = 1600, height = 700, res = 160)
par(mfrow = c(1, 2), mar = c(4.2, 4.5, 2.5, 1))
plot(obs$year, obs$diagnoses_obs, pch = 19, col = "grey30",
     ylim = range(0, obs$diagnoses_obs, fitted$diagnoses) * c(1, 1.1),
     xlab = "Année", ylab = "Nouveaux diagnostics",
     main = "Diagnostics : observés vs ajustés")
lines(fitted$year, fitted$diagnoses, col = "#1F4E79", lwd = 2.5)
legend("bottomleft", c("Observés (simulés)", "Modèle calibré"),
       pch = c(19, NA), lty = c(NA, 1), lwd = c(NA, 2.5),
       col = c("grey30", "#1F4E79"), bty = "n")
plot(obs$year, obs$incidence_true, type = "l", lty = 2, lwd = 2,
     col = "grey30", ylim = range(0, obs$incidence_true, fitted$incidence) * c(1, 1.1),
     xlab = "Année", ylab = "Nouvelles infections",
     main = "Incidence : vraie vs estimée")
lines(fitted$year, fitted$incidence, col = "#C0392B", lwd = 2.5)
abline(v = true_params$t_break, col = "grey70", lty = 3)
legend("bottomleft", c("Vraie (non observée)", "Estimée par le modèle"),
       lty = c(2, 1), lwd = c(2, 2.5), col = c("grey30", "#C0392B"), bty = "n")
dev.off()

# --- 3. Scénarios -------------------------------------------------------------
res <- lapply(scenario_list, function(ch)
  run_scenario(cal$params, y0, years_proj, from = 2024, changes = ch))

summary_tab <- do.call(rbind, lapply(names(res), function(nm) {
  r <- res[[nm]]
  data.frame(scenario = nm,
             incidence_2023 = round(r$incidence[r$year == 2023]),
             incidence_2030 = round(r$incidence[r$year == 2030]),
             non_diag_2030  = round(r$undiagnosed[r$year == 2030]))
}))
write.csv(summary_tab, "output/scenarios.csv", row.names = FALSE)
cat("\nScénarios :\n"); print(summary_tab, row.names = FALSE)

cols <- c("grey30", "#1F4E79", "#2E8B57", "#C0392B")
png("figures/scenarios.png", width = 1600, height = 700, res = 160)
par(mfrow = c(1, 2), mar = c(4.2, 4.5, 2.5, 1))
for (ind in c("incidence", "undiagnosed")) {
  yr <- range(0, sapply(res, function(r) r[[ind]][r$year >= 2015]))
  plot(NA, xlim = c(2015, 2030), ylim = yr * c(1, 1.08), xlab = "Année",
       ylab = if (ind == "incidence") "Nouvelles infections" else "Personnes non diagnostiquées",
       main = if (ind == "incidence") "Incidence projetée" else "Population non diagnostiquée")
  abline(v = 2024, col = "grey80", lty = 3)
  for (i in seq_along(res)) {
    r <- res[[i]]; k <- r$year >= 2015
    lines(r$year[k], r[[ind]][k], col = cols[i], lwd = 2.3)
  }
  if (ind == "incidence")
    legend("bottomleft", names(res), col = cols, lwd = 2.3, bty = "n", cex = 0.8)
}
dev.off()

cat("\nFigures écrites dans figures/, tableaux dans output/.\n")
