# Apéndice B · Código

Implementaciones ejecutables de cada método del manual. Todo el código está escrito para ser **copiado y adaptado**, no para ser leído. Los datos de ejemplo son los que usan los paquetes (públicos) o simulados.

---

## B0. Instalación

```r
install.packages(c("fixest", "ivmodel", "modelsummary",   # IV y presentación
                   "micEconAids", "systemfit",            # AIDS
                   "mlogit", "gmnl",                      # elección discreta
                   "BLPestimatoR",                        # BLP en R
                   "strucchange", "MSwM",                 # quiebres, regímenes
                   "np", "ks",                            # no paramétrico (GPV)
                   "data.table", "ggplot2"))
```

```bash
pip install pyblp numpy pandas scipy linearmodels xlogit statsmodels matplotlib
```

```stata
ssc install ivreg2, ivreghdfe, weakivtest, weakiv, quaids, aidsills, ranktest
```

---

## B1. Simulación del problema de identificación (Cap. 02)

Útil para enseñar y para verificar que tu código de IV funciona.

```r
library(fixest)
set.seed(1)
T <- 1000
beta  <- -1.5    # pendiente verdadera de demanda
delta <-  0.8    # pendiente de oferta
z     <- rnorm(T)                    # instrumento: shifter de oferta
eps_d <- rnorm(T)                    # shock de demanda
eps_s <- rnorm(T)                    # shock de oferta

# Equilibrio: alpha + beta*P + eps_d = gamma + delta*P + z + eps_s
P <- (0 - 0 + (z + eps_s) - eps_d) / (beta - delta)
Q <- 0 + beta*P + eps_d

d <- data.frame(Q, P, z)

m_ols <- feols(Q ~ P, d)
m_iv  <- feols(Q ~ 1 | P ~ z, d)

cat(sprintf("Verdad : %6.3f\nOLS    : %6.3f  (sesgo = %+.3f)\nIV     : %6.3f\nF1     : %6.1f\n",
    beta, coef(m_ols)["P"], coef(m_ols)["P"]-beta,
    coef(m_iv)["fit_P"], fitstat(m_iv,"ivf1")$ivf1$stat))

# Verificar la fórmula del Cap. 02 §2.3: plim(OLS) = (1-lambda)*beta + lambda*delta
lambda <- var(eps_d) / (var(z + eps_s) + var(eps_d))
cat(sprintf("Predicho por la formula: %.3f\n", (1-lambda)*beta + lambda*delta))
```

---

## B2. Protocolo completo de diagnóstico IV (Caps. 02–03)

```r
library(fixest); library(ivmodel); library(modelsummary)

diagnosticar_iv <- function(data, y, x_endog, instrumentos, controles = NULL,
                            fe = NULL, cluster = NULL) {
  f_ctrl <- if (is.null(controles)) "1" else paste(controles, collapse = " + ")
  f_fe   <- if (is.null(fe))        "0" else paste(fe, collapse = " + ")
  f_iv   <- paste(x_endog, "~", paste(instrumentos, collapse = " + "))
  fml    <- as.formula(sprintf("%s ~ %s | %s | %s", y, f_ctrl, f_fe, f_iv))

  m_iv  <- feols(fml, data = data, cluster = cluster)
  m_ols <- feols(as.formula(sprintf("%s ~ %s + %s | %s", y, x_endog, f_ctrl, f_fe)),
                 data = data, cluster = cluster)
  m_fs  <- feols(as.formula(sprintf("%s ~ %s + %s | %s", x_endog,
                 paste(instrumentos, collapse=" + "), f_ctrl, f_fe)),
                 data = data, cluster = cluster)

  st <- fitstat(m_iv, c("ivf1","ivwald1","sargan","wh"))
  cat("=== DIAGNOSTICO IV ===\n")
  cat(sprintf("OLS           : %8.4f\n", coef(m_ols)[x_endog]))
  cat(sprintf("IV            : %8.4f\n", coef(m_iv)[paste0("fit_",x_endog)]))
  cat(sprintf("F primera et. : %8.2f  %s\n", st$ivf1$stat,
      ifelse(st$ivf1$stat > 104.7, "OK (Lee et al. 2022)",
      ifelse(st$ivf1$stat > 10, "DEBIL: reportar Anderson-Rubin", "MUY DEBIL"))))
  if (length(instrumentos) > 1)
    cat(sprintf("Sargan p      : %8.3f  %s\n", st$sargan$p,
        ifelse(st$sargan$p > 0.05, "no se rechaza", "RECHAZA: algun instrumento invalido")))
  cat(sprintf("Wu-Hausman p  : %8.3f  %s\n", st$wh$p,
      ifelse(st$wh$p < 0.05, "endogeneidad confirmada: usar IV", "OLS podria servir")))

  # Anderson-Rubin (robusto a instrumentos debiles)
  iv <- ivmodel(Y = data[[y]], D = data[[x_endog]],
                Z = as.matrix(data[, instrumentos, drop = FALSE]),
                X = if (is.null(controles)) NULL else as.matrix(data[, controles]))
  print(AR.test(iv))
  invisible(list(ols = m_ols, fs = m_fs, iv = m_iv))
}
```

---

## B3. AIDS y QUAIDS (Cap. 04)

```r
library(micEconAids); library(systemfit)
data("Blanciforti86", package = "micEconAids")
d <- Blanciforti86[1:32, ]

pN <- c("pFood1","pFood2","pFood3","pFood4")
sN <- c("wFood1","wFood2","wFood3","wFood4")

# AIDS exacto, con homogeneidad y simetria impuestas
a_hs <- aidsEst(pN, sN, "xFood", data = d,
                priceIndex = "T", method = "IL", hom = TRUE, sym = TRUE)
summary(a_hs)

# Elasticidades
el <- aidsElas(a_hs$coef, shares = colMeans(d[, sN], na.rm = TRUE),
               prices = colMeans(d[, pN], na.rm = TRUE), method = "Ch")
print(el)

# Tests de restricciones
a_u <- aidsEst(pN, sN, "xFood", data = d, priceIndex="T", method="IL",
               hom = FALSE, sym = FALSE)
LR <- 2*(logLik(a_u) - logLik(a_hs))
cat(sprintf("LR = %.2f,  gl = %d,  p = %.4f\n",
            LR, 6, pchisq(LR, 6, lower.tail = FALSE)))

# Test de NEGATIVIDAD (el que casi nadie hace)
test_negatividad <- function(gamma, beta, w) {
  n <- length(w); S <- matrix(0, n, n)
  for (i in 1:n) for (j in 1:n)
    S[i,j] <- gamma[i,j] + w[i]*w[j] - (i==j)*w[i]
  ev <- eigen(S, symmetric = TRUE)$values
  cat("Autovalores de Slutsky:", round(ev, 4), "\n")
  if (any(ev > 1e-8)) cat(">>> VIOLACION: el sistema no es integrable\n")
  else cat(">>> OK: negatividad satisfecha\n")
  invisible(ev)
}
```

```stata
* QUAIDS con encuesta de hogares, pesos y demografia
quaids w1 w2 w3 w4, anot(10) prices(lnp1 lnp2 lnp3 lnp4) ///
      expenditure(lngasto) demographics(nmiembros educjefe urbano) [pw = factor]
quaids_elas, atmeans
* Por decil (elasticidades distributivas)
forvalues k = 1/10 {
    quietly quaids_elas if decil == `k', atmeans
    display "Decil `k':" _col(12) %6.3f el[1,1]
}
```

---

## B4. Elección discreta (Cap. 05)

```r
library(mlogit)
data("Heating", package = "mlogit")
H <- dfidx(Heating, choice = "depvar", varying = c(3:12),
           idx = list(c("idcase","id")), idnames = c("chid","alt"))

# 1. Logit condicional
m1 <- mlogit(depvar ~ ic + oc | 0, data = H)
summary(m1)

# 2. Tasa de descuento implicita
r_imp <- coef(m1)["ic"]/coef(m1)["oc"]
f <- function(r) sum(1/(1+r)^(1:30)) - 1/r_imp
cat(sprintf("Factor de capitalizacion: %.2f -> tasa implicita: %.1f%%\n",
            1/r_imp, 100*uniroot(f, c(.001, 1))$root))

# 3. Matriz de elasticidades (observar la huella de IIA: columnas constantes)
E <- sapply(c("gc","gr","ec","er","hp"), function(a)
       effects(m1, covariate = "ic", type = "rr", data = H)[, a])
round(E, 3)

# 4. Nested logit + test de IIA con potencia
m2 <- mlogit(depvar ~ ic + oc | 0, data = H,
             nests = list(gas = c("gc","gr"), elec = c("ec","er","hp")),
             un.nest.el = TRUE)
lrtest(m1, m2)

# 5. Mixed logit
m3 <- mlogit(depvar ~ ic + oc | 0, data = H,
             rpar = c(ic = "n"), R = 1000, halton = NA)
summary(m3)

# 6. Comparar los tres en el objeto que importa: el contrafactual
#    (ej. subir el IC de las bombas de calor 10%)
```

---

## B5. Logit agregado y nested logit (Cap. 06)

```r
library(fixest)

# Preparacion de datos
d <- within(d, {
  s_0      <- 1 - ave(share, mercado, FUN = sum)
  y        <- log(share) - log(s_0)              # inversion de Berry
  s_dentro <- share / ave(share, list(mercado, nido), FUN = sum)
  ln_s_g   <- log(s_dentro)
})

# OLS (sesgado, pero es el punto de comparacion)
m_ols <- feols(y ~ precio + x1 + x2 | marca + mercado, d)

# Logit IV
m_iv  <- feols(y ~ x1 + x2 | marca + mercado | precio ~ z_hausman, d)

# Nested logit IV: DOS endogenos, DOS instrumentos
m_nl  <- feols(y ~ x1 + x2 | marca + mercado |
                 precio + ln_s_g ~ z_hausman + n_prod_nido, d)

etable(m_ols, m_iv, m_nl, fitstat = ~ ivf1 + ivf2 + n)

# Verificaciones
sigma <- coef(m_nl)["fit_ln_s_g"]
stopifnot(sigma >= 0 && sigma < 1)   # fuera de [0,1) => nidos mal especificados

# Elasticidades agregadas
alpha <- -coef(m_nl)["fit_precio"]
d$e_propia <- -alpha * d$precio * (1 - d$share)                     # logit
d$e_propia_nl <- -alpha * d$precio *
   (1/(1-sigma) - (sigma/(1-sigma))*d$s_dentro - d$share)           # nested
summary(d$e_propia_nl)
```

---

## B6. BLP completo con pyblp (Cap. 06)

```python
import pyblp, numpy as np, pandas as pd
pyblp.options.digits, pyblp.options.verbose = 3, True

product_data = pd.read_csv(pyblp.data.NEVO_PRODUCTS_LOCATION)
agent_data   = pd.read_csv(pyblp.data.NEVO_AGENTS_LOCATION)

# --- PASO 0: SIEMPRE empezar por el logit simple (es tu test de regresion) ---
logit_problem = pyblp.Problem(
    pyblp.Formulation('0 + prices', absorb='C(product_ids)'), product_data)
logit_results = logit_problem.solve()
print(logit_results)

# --- PASO 1: instrumentos de diferenciacion (Gandhi-Houde) ---
diff_iv = pyblp.build_differentiation_instruments(
    pyblp.Formulation('0 + sugar + mushy'), product_data, version='local')
for i in range(diff_iv.shape[1]):
    product_data[f'demand_instruments{i}'] = diff_iv[:, i]

# --- PASO 2: random coefficients ---
problem = pyblp.Problem(
    product_formulations=(
        pyblp.Formulation('0 + prices', absorb='C(product_ids)'),
        pyblp.Formulation('1 + prices + sugar + mushy'),
    ),
    product_data=product_data,
    agent_formulation=pyblp.Formulation('0 + income + income_squared + age + child'),
    agent_data=agent_data,
)

# --- PASO 3: MULTI-START (la diferencia entre replicable y no) ---
best, best_obj = None, np.inf
for seed in range(20):
    rng = np.random.default_rng(seed)
    try:
        r = problem.solve(
            sigma=np.diag(rng.uniform(0, 1, 4)),
            pi=rng.normal(0, 0.5, (4, 4)),
            optimization=pyblp.Optimization('trust-constr', {'gtol': 1e-8}),
            iteration=pyblp.Iteration('squarem', {'atol': 1e-14}),   # tolerancia estricta
            method='1s',
        )
        if r.objective < best_obj:
            best, best_obj = r, float(r.objective)
            print(f'  seed {seed}: nuevo mejor objetivo = {best_obj:.6f}')
    except Exception as e:
        print(f'  seed {seed} fallo: {e}')

results = best
print(results)

# --- PASO 4: DIAGNOSTICOS OBLIGATORIOS ---
costs = results.compute_costs()
assert (costs > 0).all(), "COSTOS MARGINALES NEGATIVOS: el modelo esta mal"

elas = results.compute_elasticities()
own  = np.array([elas[i, i] for i in range(elas.shape[0])])
assert (own < -1).all(), "Elasticidades propias > -1: inconsistente con la FOC"

print("Markup medio      :", results.compute_markups().mean())
print("Lerner medio      :", (results.compute_markups()/product_data.prices.values[:,None]).mean())
print("Diversion ratios  :\n", results.compute_diversion_ratios()[:5, :5])

# --- PASO 5: SENSIBILIDAD AL TAMANO DE MERCADO ---
for f in (0.5, 1.0, 2.0):
    pd2 = product_data.copy()
    pd2['shares'] = product_data['shares'] / f
    # (re-estimar y comparar alpha; si cambia el signo de la conclusion, reportarlo)

# --- PASO 6: SIMULACION DE FUSION ---
merged = product_data['firm_ids'].replace({2: 1})   # firma 2 absorbida por la 1
p_post = results.compute_prices(firm_ids=merged, costs=costs)
dp = (p_post - product_data['prices'].values[:, None]) / product_data['prices'].values[:, None]
print(f"Cambio medio de precio: {100*np.average(dp, weights=product_data.shares):.2f}%")

# Eficiencia de compensacion
from scipy.optimize import brentq
def avg_dp(e):
    p = results.compute_prices(firm_ids=merged, costs=costs*(1-e))
    return float(np.average((p - product_data['prices'].values[:,None]) /
                            product_data['prices'].values[:,None],
                            weights=product_data.shares))
print(f"Eficiencia de compensacion: {100*brentq(avg_dp, 0, 0.6):.1f}%")
```

---

## B7. Markups y simulación de fusiones sin BLP (Cap. 07)

Cuando no hay datos para estimar demanda completa, pero sí diversion ratios y márgenes.

```r
# GUPPI
guppi <- function(D12, margen2, p2, p1) D12 * margen2 * (p2/p1)

# Tabla de GUPPI para un rango de supuestos
D   <- seq(0.05, 0.40, by = 0.05)
M   <- seq(0.20, 0.60, by = 0.10)
tab <- outer(D, M, function(d, m) d*m)
dimnames(tab) <- list(paste0("D=", D), paste0("margen=", M))
round(100*tab, 1)   # en %, asumiendo p2 = p1
# Lectura: valores > 10 implican revision sustantiva probable

# Markups logit multiproducto
markup_logit <- function(alpha, shares_de_la_firma)
  1 / (alpha * (1 - sum(shares_de_la_firma)))

# Simulacion de fusion en logit (forma cerrada!)
fusion_logit <- function(alpha, shares, firma_pre, firma_post, mc) {
  m_pre  <- sapply(firma_pre,  function(f) markup_logit(alpha, shares[firma_pre  == f]))
  m_post <- sapply(firma_post, function(f) markup_logit(alpha, shares[firma_post == f]))
  data.frame(p_pre = mc + m_pre, p_post = mc + m_post,
             pct_dp = 100*((mc+m_post)/(mc+m_pre) - 1))
}
# Nota: esto es aproximado porque las shares cambian con los precios.
# Para precision, resolver el punto fijo.

# Punto fijo exacto
equilibrio_logit <- function(alpha, delta, mc, firma, tol = 1e-10) {
  p <- mc + 1/alpha
  repeat {
    s  <- exp(delta - alpha*p); s <- s/(1 + sum(s))
    S  <- sapply(firma, function(f) sum(s[firma == f]))
    p1 <- mc + 1/(alpha*(1 - S))
    if (max(abs(p1 - p)) < tol) break
    p <- p1
  }
  list(p = p, s = s)
}
```

---

## B8. Screens de colusión (Cap. 08)

```r
library(data.table); library(strucchange)

# --- Screen de varianza ---
screen_varianza <- function(dt, precio, grupo, ventana = 12) {
  dt <- as.data.table(dt)
  dt[, cv := frollapply(get(precio), ventana, function(x) sd(x)/mean(x)), by = grupo]
  dt[, nivel := frollmean(get(precio), ventana), by = grupo]
  dt[, sospechoso := cv < quantile(cv, .20, na.rm=TRUE) &
                     nivel > quantile(nivel, .80, na.rm=TRUE)]
  dt[]
}

# --- Screens de licitaciones ---
screens_licitacion <- function(pujas) {
  dt <- as.data.table(pujas)
  dt[, `:=`(
    b_min  = min(monto),
    b_2do  = sort(monto)[2],
    cv     = sd(monto)/mean(monto),
    n      = .N,
    kurt   = {m <- mean(monto); s <- sd(monto); mean(((monto-m)/s)^4)}
  ), by = licitacion]
  dt[, dif_rel := (b_2do - b_min)/b_min]
  res <- unique(dt[, .(licitacion, dif_rel, cv, n, kurt)])
  res[, flag := dif_rel > quantile(dif_rel, .80, na.rm=TRUE) &
                cv      < quantile(cv,      .20, na.rm=TRUE)]
  res[]
}

# --- Rotacion de ganadores (test chi2) ---
test_rotacion <- function(pujas) {
  g <- table(pujas[pujas$gano == 1, "postor"])
  chisq.test(g)   # H0: todos ganan con igual probabilidad
  # Con reparto, la distribucion es MAS uniforme de lo que la competencia
  # con costos heterogeneos produciria -> el test "no rechaza" demasiado bien
}

# --- Bajari-Ye: correlacion de residuos entre pares ---
bajari_ye <- function(pujas, formula_costos) {
  m <- lm(formula_costos, data = pujas)
  pujas$r <- resid(m)
  firmas <- unique(pujas$postor)
  out <- data.frame()
  for (p in combn(firmas, 2, simplify = FALSE)) {
    a <- pujas[pujas$postor == p[1], c("licitacion","r")]
    b <- pujas[pujas$postor == p[2], c("licitacion","r")]
    m2 <- merge(a, b, by = "licitacion")
    if (nrow(m2) >= 10) {
      ct <- cor.test(m2$r.x, m2$r.y)
      out <- rbind(out, data.frame(f1=p[1], f2=p[2], n=nrow(m2),
                                   rho=ct$estimate, p=ct$p.value))
    }
  }
  out[order(out$p), ]
}
```

---

## B9. GPV: estimación no paramétrica de costos (Cap. 08)

```r
gpv <- function(pujas, n_postores, trim = 0.05, bw = "SJ") {
  b <- pujas
  n <- n_postores
  G <- ecdf(b)
  dens <- density(b, bw = bw, n = 2048)
  g <- approx(dens$x, dens$y, xout = b, rule = 2)$y

  # Subasta inversa (compras): gana el menor
  c_hat <- b - (1 - G(b)) / ((n - 1) * g)

  # Trimming: el kernel tiene sesgo cerca de los bordes
  lo <- quantile(b, trim); hi <- quantile(b, 1 - trim)
  keep <- b > lo & b < hi

  list(costos = c_hat[keep],
       markup = (b[keep] - c_hat[keep]) / b[keep],
       b = b[keep])
}

# Uso
res <- gpv(pujas$monto_normalizado, pujas$n_postores)
cat(sprintf("Markup mediano: %.1f%%\n", 100*median(res$markup)))
hist(res$markup, breaks = 40, main = "Distribucion de markups (GPV)")

# Robustez al ancho de banda (OBLIGATORIO reportarlo)
for (bw in c("nrd0","SJ","ucv")) {
  r <- gpv(pujas$monto_normalizado, pujas$n_postores, bw = bw)
  cat(sprintf("bw = %-5s: markup mediano = %.1f%%\n", bw, 100*median(r$markup)))
}

# Contrafactual: efecto de un postor adicional
# (re-resolver el equilibrio con n+1 usando la F_c estimada)
```

---

## B10. Pass-through (Caps. 07, 12)

```r
library(fixest)

# Pass-through estatico
pt <- feols(log(precio) ~ log(costo) | producto + mercado + periodo,
            data = d, cluster = ~mercado)

# Pass-through dinamico (cuanto tarda)
d <- panel(d, ~ producto + periodo)
pt_din <- feols(log(precio) ~ l(log(costo), 0:8) | producto + periodo, d)
lp <- sum(coef(pt_din)[grep("costo", names(coef(pt_din)))])
cat(sprintf("Pass-through de largo plazo: %.2f\n", lp))

# Asimetria (cohete y pluma)
d[, `:=`(dpos = pmax(d_log_costo, 0), dneg = pmin(d_log_costo, 0))]
asim <- feols(d_log_precio ~ l(dpos, 0:4) + l(dneg, 0:4) | producto + periodo, d)
# Test: suma(dpos) == suma(dneg)?
car::linearHypothesis(asim, "l(dpos,0) + l(dpos,1) + l(dpos,2) =
                             l(dneg,0) + l(dneg,1) + l(dneg,2)")

# Curvatura implicita de la demanda a partir del pass-through observado
# rho = 1/(2 - kappa)  =>  kappa = 2 - 1/rho
kappa <- 2 - 1/lp
cat(sprintf("Curvatura implicita: %.2f  (0 = lineal, 1 = exponencial/logit, >1 = CES)\n", kappa))
```

---

## B11. Plantilla de reporte reproducible

```r
# ---- 00_setup.R -------------------------------------------------------
library(data.table); library(fixest); library(modelsummary)
set.seed(20260101)
options(scipen = 999)
RUTA <- list(crudo = "data/raw", limpio = "data/clean", out = "output")

# ---- 01_datos.R -------------------------------------------------------
# Leer, limpiar, documentar. Guardar un diccionario de variables.
# REGLA: nunca modificar data/raw. Todo output va a data/clean.

# ---- 02_descriptivo.R -------------------------------------------------
# Tabla 1 y los graficos. Si los hechos estilizados no son interesantes,
# parar aqui y repensar la pregunta.

# ---- 03_reducida.R ----------------------------------------------------
# OLS, primera etapa, IV, diagnosticos.

# ---- 04_estructural.R -------------------------------------------------
# Logit -> nested -> BLP, en ese orden.

# ---- 05_contrafactual.R -----------------------------------------------
# La simulacion principal + sensibilidad (M_t, forma funcional, instrumentos).

# ---- 06_tablas.R ------------------------------------------------------
modelsummary(lista_modelos,
             stars = c('*'=.1,'**'=.05,'***'=.01),
             gof_map = c("nobs","r.squared","FE: producto"),
             output = file.path(RUTA$out, "tabla_principal.tex"))

# ---- run_all.R --------------------------------------------------------
for (f in sprintf("0%d_%s.R", 0:6,
      c("setup","datos","descriptivo","reducida","estructural",
        "contrafactual","tablas"))) source(f, echo = TRUE)
```

> **La prueba de reproducibilidad:** borra la carpeta `output`, corre `run_all.R` en una máquina limpia, y verifica que todas las cifras del reporte se regeneran. Si no, el proyecto no está terminado.
