## ============================================================================
## config/config.R — Parámetros y fuentes del pipeline ELDU
## ----------------------------------------------------------------------------
## Todo lo configurable vive aquí. Ningún script contiene rutas, URLs ni
## supuestos "hardcodeados" fuera de este archivo.
##
## REGLA DURA DEL PROYECTO: ninguna serie se inventa, simula ni imputa en
## silencio. Si una fuente no se obtiene, el pipeline se detiene y lo reporta.
## ============================================================================

CFG <- list()

## ---- Semilla y horizonte ---------------------------------------------------
CFG$seed          <- 20261007L
CFG$fy_last_hist  <- NA_integer_   # se infiere de la data (no se asume)
CFG$fy_horizon    <- 2035L         # proyectar hasta FY2035

## ---- Reproducibilidad de red ----------------------------------------------
CFG$http <- list(
  timeout_s   = 90,
  retries     = 4,                      # 4 reintentos
  backoff_s   = c(2, 4, 8, 16),         # backoff exponencial
  user_agent  = "ELDU-demand-study/1.0 (R; investigacion academica)"
)

## ---- 1) BCRP ---------------------------------------------------------------
## La API REST del BCRP es pública y sin clave:
##   https://estadisticas.bcrp.gob.pe/estadisticas/series/api/[codigos]/json/[inicio]/[fin]
##
## Los CÓDIGOS de serie NO se asumen. El script 01 primero intenta resolverlos
## contra el catálogo de metadatos del BCRP buscando por nombre; si eso falla,
## prueba los códigos candidato de abajo y VALIDA el nombre que devuelve la API
## contra `name_regex`. Si el nombre no coincide, descarta la serie y lo registra
## en el log — nunca acepta una serie "a ciegas".
CFG$bcrp <- list(
  api_base = "https://estadisticas.bcrp.gob.pe/estadisticas/series/api",
  ## Candidatos de URL del catálogo de metadatos (CSV). Se prueban en orden.
  metadata_urls = c(
    "https://estadisticas.bcrp.gob.pe/estadisticas/series/metadata",
    "https://estadisticas.bcrp.gob.pe/estadisticas/series/ayuda/metadatos"
  ),
  start = "1990-1",
  end   = format(Sys.Date(), "%Y-%m"),
  series = list(
    pbi_real = list(
      label        = "PBI real (indice de volumen fisico)",
      search_terms = c("producto bruto interno", "indice de volumen"),
      ## Candidatos NO VERIFICADOS: el script valida el nombre devuelto.
      candidates   = c("PN01770AM", "PN02079AM", "PN01773AM"),
      name_regex   = "(?i)producto\\s+bruto\\s+interno|\\bPBI\\b",
      mandatory    = TRUE
    ),
    ipc = list(
      label        = "IPC Lima Metropolitana",
      search_terms = c("indice de precios al consumidor", "Lima Metropolitana"),
      candidates   = c("PN01270PM", "PN38705PM"),
      name_regex   = "(?i)precios\\s+al\\s+consumidor|\\bIPC\\b",
      ## No es obligatoria: la energía es una magnitud física (GWh) y el PBI
      ## entra como índice de volumen real, así que no hay nada que deflactar.
      ## Queda como control y como deflactor para variables nominales futuras.
      mandatory    = FALSE
    ),
    tc = list(
      label        = "Tipo de cambio bancario PEN/USD",
      search_terms = c("tipo de cambio", "bancario", "promedio"),
      candidates   = c("PN01208PM", "PN01210PM", "PN01209PM"),
      name_regex   = "(?i)tipo\\s+de\\s+cambio",
      mandatory    = FALSE
    )
  )
)

## ---- 2) NOAA CPC (clima / El Nino) ----------------------------------------
## Opcional: si no descarga, el pipeline sigue sin clima y lo anota.
CFG$noaa <- list(
  oni    = "https://www.cpc.ncep.noaa.gov/data/indices/oni.ascii.txt",
  nino34 = "https://www.cpc.ncep.noaa.gov/data/indices/ersst5.nino.mth.91-20.ascii",
  ## Meses del verano austral usados para el agregado anual (DJF + ventana agro)
  austral_summer_months = c(12L, 1L, 2L, 3L),
  mandatory = FALSE
)

## ---- 3) MINEM / Osinergmin / INEI -----------------------------------------
## Las URLs profundas de estos portales cambian cada año, así que el script 03
## NO adivina un deep-link: raspa las páginas de publicaciones y busca enlaces
## que calcen con los patrones. Se puede forzar una URL directa en `direct_urls`.
CFG$minem <- list(
  landing_pages = c(
    "https://www.gob.pe/institucion/minem/informes-publicaciones",
    "https://www.gob.pe/institucion/minem/colecciones/4425-anuario-estadistico-electrico"
  ),
  link_regex  = "(?i)anuario.*(electric|electrico).*\\.(xlsx|xls|zip|pdf)|(?i)anuario.*estadistic.*\\.(xlsx|xls|zip)",
  direct_urls = character(0),   # <- pegar aquí URLs directas si se conocen
  mandatory   = FALSE,          # obligatorio es "energía ELDU por ALGUNA vía"
  ## La extracción del Excel del Anuario se auto-ingiere SÓLO si pasa las
  ## validaciones de abajo, y siempre deja traza (hoja, fila, celdas) en
  ## output/tables/minem_extraccion_traza.csv.
  auto_ingest = TRUE
)

## ---- Validaciones que debe pasar cualquier serie de energía extraída -------
## Si no las pasa, NO se usa: el pipeline se detiene y pide revisión humana.
CFG$validate_energy <- list(
  min_obs        = 8L,      # mínimo de años para intentar estimar
  min_gwh        = 50,      # cota inferior de plausibilidad (GWh/año)
  max_gwh        = 20000,   # cota superior de plausibilidad (GWh/año)
  max_abs_growth = 0.60     # salto interanual máximo tolerado sin revisión
)

CFG$osinergmin <- list(
  landing_pages = c(
    "https://www.gob.pe/institucion/osinergmin/informes-publicaciones"
  ),
  link_regex  = "(?i)(anuario|rsmme).*\\.(xlsx|xls|zip|pdf)",
  direct_urls = character(0),
  mandatory   = FALSE
)

CFG$inei <- list(
  landing_pages = c(
    "https://www.inei.gob.pe/estadisticas/indice-tematico/economia/",
    "https://www.inei.gob.pe/media/MenuRecursivo/publicaciones_digitales/Est/"
  ),
  link_regex  = "(?i)(pbi|producto\\s*bruto).*(departament|region).*\\.(xlsx|xls|zip|pdf)",
  direct_urls = character(0),
  region      = "Ica",
  mandatory   = FALSE   # si falta, se usa PBI nacional como PROXY (se marca)
)

## ---- 4) Memorias Anuales ELDU (PDF provistos por el usuario) --------------
CFG$memorias <- list(
  dir = "data/raw/pdf",
  ## Patrones para localizar la cifra de energía en el texto del PDF.
  energy_patterns = c(
    "(?i)energ[ií]a\\s+(vendida|distribuida|facturada)",
    "(?i)ventas\\s+de\\s+energ[ií]a"
  ),
  clients_patterns = c(
    "(?i)n[uú]mero\\s+de\\s+clientes",
    "(?i)clientes\\s+(totales|regulados|libres)"
  ),
  ## Una lectura por regex de una tabla en PDF es justamente donde entran los
  ## errores silenciosos. Por eso 04 extrae CANDIDATOS con su línea literal de
  ## origen y NO los inyecta al panel automáticamente. Revise
  ## output/tables/memorias_extraccion_candidatos.csv contra el PDF y promueva
  ## las cifras verificadas a CFG$eldu$manual_csv. Ponga TRUE sólo si acepta
  ## el riesgo de una extracción sin revisión humana.
  auto_ingest = FALSE,
  mandatory = FALSE
)

## ---- Variable dependiente: energía ELDU -----------------------------------
## OBLIGATORIA. Puede venir de MINEM, Osinergmin o Memorias. Además se acepta
## un CSV curado a mano por el usuario (extraído de esas fuentes) en esta ruta,
## siempre que quede registrado en data/raw/SOURCES.md.
CFG$eldu <- list(
  manual_csv = "data/raw/eldu_energia_anual.csv",
  ## Esquema esperado del CSV: year,energia_gwh[,clientes][,segmento]
  required_cols = c("year", "energia_gwh"),
  company_regex = "(?i)electro\\s*dunas|\\bELDU\\b"
)

## ---- Escenarios de crecimiento del PBI ------------------------------------
## El usuario provee data/raw/escenarios.csv (cols: escenario,year,g_pbi).
## Si NO existe, se usan estos defaults y se marcan como SUPUESTO en el informe.
CFG$escenarios <- list(
  path = "data/raw/escenarios.csv",
  defaults = c(base = 0.030, optimista = 0.045, pesimista = 0.015),
  defaults_are_assumption = TRUE
)

## ---- Supuesto actual del DCF (dato provisto por el usuario) ---------------
CFG$dcf_benchmark <- c(BT = 0.80, MT = 0.90)

## ---- Reparto por segmento --------------------------------------------------
## NO se inventan pesos. Si el usuario quiere el desagregado BT/MT/libres debe
## poner los pesos de ingreso aquí (deben sumar 1). NULL => solo agregado.
CFG$segment_weights <- NULL   # ej: c(BT = 0.55, MT = 0.30, libres = 0.15)

## ---- Reglas de estimación (dependen del n disponible) ---------------------
CFG$est <- list(
  min_n_adf        = 12L,   # raíz unitaria solo si n >= 12
  min_n_ecm        = 15L,   # ECM solo si n >= 15 Y hay cointegración
  min_n_holdout    = 12L,   # validación out-of-sample solo si n >= 12
  holdout_years    = 2L,
  ## Regla de prudencia: si el IC95 de eta es más ancho que esto, se reporta
  ## como RANGO y no como punto.
  wide_ci_width    = 1.00,
  hac_lag          = NULL,  # NULL => Newey-West automático (bwNeweyWest)
  alpha            = 0.05
)

CFG$paths <- list(
  raw        = "data/raw",
  processed  = "data/processed",
  output     = "output",
  tables     = "output/tables",
  figures    = "output/figures",
  fetch_log  = "output/fetch_log.txt",
  sources_md = "data/raw/SOURCES.md",
  sources_csv= "data/raw/sources_registry.csv",
  blockers   = "output/BLOCKERS.md"
)
