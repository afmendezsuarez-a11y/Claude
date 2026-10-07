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
  ## CSV exportados a mano desde BCRPData (formato: 2 líneas de encabezado con
  ## el código y el nombre de la serie, luego `periodo,valor` y "n.d." como
  ## faltante; codificación latin1). Si existen, 05 los usa y NO se necesita red.
  ## Ninguno es obligatorio: la energía es física (GWh) y el VAB entra real, así
  ## que no hay nada que deflactar. Son controles, no regresores.
  csv_files = list(
    pbi_nacional_yoy = list(
      path  = "data/raw/bcrp_pbi_nacional_yoy.csv",
      label = "PBI nacional, variación % interanual (mensual)",
      kind  = "yoy_pct",      # se encadena a índice anual
      role  = "driver_alternativo"),
    ipc_lima = list(
      path  = "data/raw/bcrp_ipc_lima.csv",
      label = "IPC Lima Metropolitana (Dic.2021 = 100)",
      kind  = "index",
      role  = "control"),
    tc_venta = list(
      path  = "data/raw/bcrp_tc_venta.csv",
      label = "Tipo de cambio interbancario venta (S/ por US$), diario",
      kind  = "level",
      role  = "control")
  ),
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
  mandatory   = FALSE,  # si falta, se usa PBI nacional como PROXY (se marca)
  ## Archivo ya provisto por el usuario (VAB de Ica a precios constantes).
  xlsx = "data/raw/inei_vab_ica.xlsx",
  ## La tabla del INEI trae el departamento en el TÍTULO, no en una fila, así
  ## que la fila a extraer se identifica por su rótulo de total.
  total_row_regex = "^\\s*valor\\s+agregado\\s+bruto\\s*$",
  ## El libro tiene varias hojas con la MISMA fila de total: niveles (miles de
  ## soles), estructura porcentual (=100) y variación porcentual. Sólo la de
  ## niveles pasa este piso, así que es la que se toma.
  min_level = 1000
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
  ## Tabla armada por el usuario a partir de las Memorias Anuales de ELDU.
  memorias_csv = "data/raw/eldu_demanda_memorias.csv",
  ## Variable de volumen. `dist_eld_gwh` = energía distribuida a clientes
  ## propios: es la serie más larga (2018-2025) y la medida de demanda más
  ## limpia. `dist_total_gwh` incluye el peaje de terceros (otra economía) y se
  ## corre sólo como robustez. `ventas_total_eld_gwh` existe recién desde 2022
  ## (4 años): no alcanza para estimar.
  memorias_variable   = "dist_eld_gwh",
  memorias_robustness = "dist_total_gwh",
  memorias_clients    = "clientes_total",
  ## Filas cuyo año no es un entero de 4 dígitos (p.ej. "2026_U12M_jun", un año
  ## móvil parcial) se EXCLUYEN: mezclar un periodo parcial con años completos
  ## es justamente el tipo de error que produce saltos irreales.
  year_regex = "^(19|20)\\d{2}$",
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
  alpha            = 0.05,
  ## En una distribuidora el volumen crece por DOS vías: más conexiones y más
  ## consumo por conexión. Estimar eta sobre la energía total mezcla ambas y
  ## carga el crecimiento de clientes dentro de la elasticidad-ingreso. Por eso
  ## el modelo PRINCIPAL es la descomposición: eta se estima sobre energía POR
  ## CLIENTE y la proyección lleva dos términos.
  per_client       = TRUE,
  ## Con muestras cortas, separar "efecto ingreso" de "tendencia" en niveles es
  ## frágil. Por debajo de este n, la estimación que se reporta como principal
  ## es la de DIFERENCIAS, y los niveles quedan como corroboración.
  prefer_differences_below_n = 12L,
  ## Si eta cambia más que esto entre especificaciones razonables, se recomienda
  ## un RANGO en vez de un punto, aunque el IC de cada una sea estrecho: la
  ## incertidumbre real es de especificación, no sólo de muestreo.
  spec_spread_range = 0.15,
  ## Años a excluir en el chequeo de robustez por choque extremo. 2020-2021 son
  ## el desplome y el rebote del COVID; en n=8 pueden determinar eta por sí solos.
  shock_years = c(2020L, 2021L)
)

## ---- Crecimiento de clientes (el OTRO término de la proyección) -----------
## No se modela econométricamente: las conexiones responden a política de
## expansión y demografía, no al PBI. Entra como supuesto EXPLÍCITO.
##   g_source = "historico" -> usa el CAGR observado de clientes en el panel
##   g_override            -> fija una tasa (ej. 0.02); manda sobre lo anterior
##   taper_to / taper_years-> converge linealmente a esa tasa en N años
## Sostener el CAGR histórico hasta 2035 es el supuesto más fuerte de toda la
## proyección: es una decisión del comité, no del modelo.
CFG$clientes <- list(
  g_source    = "historico",
  g_override  = NULL,
  taper_to    = NULL,
  taper_years = NULL
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
