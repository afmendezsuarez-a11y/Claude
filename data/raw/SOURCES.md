# SOURCES.md — procedencia de cada archivo en `data/raw/`

Generado automáticamente por el pipeline. **No editar a mano**: se
re-genera desde `data/raw/sources_registry.csv` en cada corrida.

Toda cifra del informe debe ser trazable a uno de estos archivos.

Última actualización: 2026-10-07 17:23:48 UTC

| Archivo | Descripción | URL | Descargado (UTC) | Bytes | SHA256 | Notas |
|---|---|---|---|---|---|---|
| `data/raw/bcrp_ipc_lima.csv` | BCRP — IPC Lima Metropolitana (Dic.2021 = 100) | <https://estadisticas.bcrp.gob.pe/estadisticas/series/> | 2026-10-07 17:23:40 | 9,556 | `d4826bba78208e8f` | código PN38705PM; serie ''; 428 observaciones (1991-2026); exportado a mano de BCRPData |
| `data/raw/bcrp_pbi_nacional_yoy.csv` | BCRP — PBI nacional, variación % interanual (mensual) | <https://estadisticas.bcrp.gob.pe/estadisticas/series/> | 2026-10-07 17:23:40 | 8,863 | `11753342405022f3` | código PN01728AM; serie 'Producto bruto interno y demanda interna (variaci'; 379 observaciones (1995-2026); exportado a mano de BCRPData |
| `data/raw/bcrp_tc_venta.csv` | BCRP — Tipo de cambio interbancario venta (S/ por US$), diario | <https://estadisticas.bcrp.gob.pe/estadisticas/series/> | 2026-10-07 17:23:40 | 154,489 | `f8a9005e82af0ccf` | código PD04638PD; serie 'Tipo de cambio - TC Interbancario (S/ por US$) - Venta'; 7411 observaciones (1997-2026); exportado a mano de BCRPData |
| `data/raw/eldu_demanda_memorias.csv` | Electro Dunas — demanda y clientes por año, compilado de las Memorias Anuales | — | 2026-10-07 17:23:40 | 891 | `98e8f0c4de8a863d` | tabla provista por el usuario; columna `fuente` indica la memoria de origen de cada fila |
| `data/raw/eldu_energia_anual.csv` | Serie anual canónica de ELDU (variable: dist_eld_gwh) | — | 2026-10-07 17:23:40 | 218 | `b8a6779c4c9066c1` | derivada de eldu_demanda_memorias.csv por 04b; 8 años (2018-2025); periodos parciales excluidos |
| `data/raw/inei_vab_ica.xlsx` | INEI — VAB de Ica por años y actividad, precios constantes | — | 2026-10-07 17:23:41 | 46,587 | `779d9e22a51e9afa` | archivo=inei_vab_ica.xlsx; hoja=cuadro1; fila_anios=7; fila_total=21; rotulo='Valor Agregado Bruto'; 19 años (2007-2025) |
