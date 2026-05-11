# Arquitectura del proyecto Fix & Flip

Este documento describe la arquitectura del proyecto dbt para analizar oportunidades inmobiliarias de Fix & Flip: compra, reforma y venta de propiedades.

## Objetivo del proyecto

El objetivo es construir un modelo de datos que permita analizar oportunidades inmobiliarias, precios de mercado por zona, costes de reforma, datos de zona y operaciones de inversión.

El proyecto usa una arquitectura Medallion:

BRONZE → SILVER → GOLD

## Capas del proyecto

### Bronze

La capa Bronze contiene los datos raw cargados en Snowflake.

En esta capa los datos se mantienen casi sin transformar. La mayoría de campos llegan como texto.

Tablas principales:

- raw_anuncios_propiedades
- raw_precios_mercado_zona
- raw_costes_reforma
- raw_datos_zona
- raw_operaciones_fix_flip

dbt no transforma directamente Bronze. Solo declara estas tablas como sources.

---

### Silver staging

La carpeta `models/silver/staging` contiene modelos `stg_`.

Estos modelos limpian los datos raw:

- eliminan espacios
- convierten fechas
- convierten importes y números
- normalizan textos
- convierten booleanos
- preparan los datos para el modelo relacional

Ejemplos:

- stg_anuncios_propiedades
- stg_precios_mercado_zona
- stg_costes_reforma
- stg_datos_zona
- stg_operaciones_fix_flip

---

### Silver core

La carpeta `models/silver/core` contiene el modelo relacional normalizado:

- provincias
- municipios
- zonas
- portales
- tipos_inmueble
- propiedades
- anuncios_propiedades
- precios_mercado_zona
- tipos_reforma
- categorias_reforma
- costes_reforma
- operaciones_fix_flip
- datos_zona

Esta capa reduce duplicidades, crea claves únicas y relaciona tablas mediante claves foráneas.

---

### Seeds

El proyecto usa un seed llamado `municipios_provincias`.

Este seed contiene municipios de Andalucía con provincia, comunidad autónoma y código INE.

Sirve para evitar mapeos manuales en los modelos `provincias` y `municipios`.

---

### Snapshots

El proyecto usa un snapshot sobre anuncios inmobiliarios.

Snapshot:

- snp_anuncios_propiedades

Objetivo:

- conservar histórico de cambios de precio
- conservar cambios de estado del anuncio
- conservar cambios en el tipo de vendedor

Se usa estrategia `check`, porque se comparan columnas concretas de negocio.

---

### Gold

La capa Gold se usará para crear tablas finales de análisis y Power BI.

Estará formada por dimensiones y hechos:

Dimensiones previstas:

- dim_fecha
- dim_provincia
- dim_ubicacion
- dim_tipo_inmueble
- dim_propiedad
- dim_portal
- dim_decision_inversion
- dim_reforma

Hechos previstos:

- fct_precios_mercado_zona
- fct_indicadores_zona
- fct_costes_reforma
- fct_oportunidades_fix_flip

## Flujo general

raw_anuncios_propiedades
→ stg_anuncios_propiedades
→ anuncios_propiedades
→ snp_anuncios_propiedades
→ Gold

raw_precios_mercado_zona
→ stg_precios_mercado_zona
→ precios_mercado_zona
→ fct_precios_mercado_zona

raw_costes_reforma
→ stg_costes_reforma
→ tipos_reforma / categorias_reforma / costes_reforma
→ fct_costes_reforma

raw_datos_zona
→ stg_datos_zona
→ datos_zona
→ fct_indicadores_zona

raw_operaciones_fix_flip
→ stg_operaciones_fix_flip
→ operaciones_fix_flip
→ fct_oportunidades_fix_flip

## Convenciones de nombres

- `raw_` → tablas Bronze
- `stg_` → modelos de limpieza
- `dim_` → dimensiones Gold
- `fct_` → tablas de hechos Gold
- `snp_` → snapshots
- `id_` → claves técnicas o surrogate keys

## Comandos principales

dbt deps                                      # Instalar packages
dbt seed                                      # Cargar CSVs como tablas
dbt run                                       # Ejecutar todos los modelos
dbt run --select staging                      # Solo staging
dbt run --select +fct_orders                  # fct_orders y sus padres
dbt run --select stg_sql_server_dbo__users+   # users y sus hijos
dbt test                                      # Ejecutar todos los tests
dbt build                                     # seed + run + snapshot + test (en orden)
dbt snapshot                                  # Ejecutar snapshots
dbt docs generate && dbt docs serve           # Generar y servir documentación
dbt source freshness                          # Validar freshness de los sources