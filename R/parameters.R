# =============================================================================
# Paramètres ILLUSTRATIFS (ordres de grandeur plausibles, non estimés sur des
# données réelles). Les "vraies" valeurs servent à générer les données simulées ;
# la calibration doit ensuite les retrouver.
# Unité de temps : l'année.
# =============================================================================

true_params <- list(
  beta1   = 0.28,   # transmission avant la rupture (par infecté non traité et par an)
  beta2   = 0.33,   # transmission après la rupture
  t_break = 2019,   # année de rupture testée
  kappa   = 1.0,    # infectiosité relative des diagnostiqués non traités
  delta   = 0.30,   # taux de diagnostic (délai moyen ~ 1 / 0,30 = 3,3 ans)
  tau     = 2.0,    # mise sous traitement efficace (délai moyen ~ 6 mois)
  mu      = 1 / 35, # sortie de la population sexuellement active
  entry   = 1 / 35, # entrée (égale à la sortie : population de taille stable)
  t_prep  = 2016,   # introduction de la PrEP
  rho     = 0.02,   # taux d'initiation de la PrEP
  omega   = 0.25,   # taux d'arrêt de la PrEP
  eps     = 0.86    # efficacité de la PrEP
)

# État initial au 1er janvier 2008 (population de 300 000 HSH, valeur fictive).
y0 <- c(S = 280000, P = 0, U = 3500, D = 500, T = 14800)

years_fit  <- 2008:2023   # période simulée pour la calibration
years_obs  <- 2012:2023   # années où l'on "observe" les diagnostics
years_proj <- 2008:2030   # horizon des scénarios
