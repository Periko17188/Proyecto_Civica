# 🏠 Proyecto Fix & Flip — dbt Platform + Snowflake + Power BI

> Proyecto final de **Data Engineering** con **dbt, Snowflake y Power BI**.  
> Caso de uso: análisis de oportunidades inmobiliarias **Fix & Flip**: comprar, reformar y vender propiedades con beneficio.

Este repo contiene un proyecto dbt completo y funcional con arquitectura **Medallion**:

- **Bronze**: datos raw cargados desde CSV en S3 hacia Snowflake.
- **Silver**: limpieza, tipado y normalización de datos.
- **Gold**: modelo analítico con dimensiones y facts para Power BI.

El objetivo es detectar oportunidades de inversión, analizar zonas con potencial y controlar costes de reforma según tipo, categoría y calidad del material.

---

## 📑 Tabla de contenidos

- [Pre-requisitos](#pre-requisitos)
- [Estructura del proyecto](#estructura-del-proyecto)
- [Caso de uso Fix & Flip](#caso-de-uso-fix--flip)
- [Arquitectura Medallion](#arquitectura-medallion)
- [Setup inicial](#setup-inicial)
- [Cómo ejecutar el proyecto](#cómo-ejecutar-el-proyecto)
- [Decisiones técnicas importantes](#decisiones-técnicas-importantes)
- [Mapa del curso → archivos del repo](#mapa-del-curso--archivos-del-repo)
- [Errores comunes y soluciones](#errores-comunes-y-soluciones)
- [Siguientes pasos](#siguientes-pasos)

---

## Pre-requisitos

Antes de ejecutar este proyecto, asegúrate de tener:

- ✅ Acceso a Snowflake.
- ✅ Bases de datos creadas para cada capa:
  - `DEV_BRONZE_DB`
  - `DEV_SILVER_DB`
  - `DEV_GOLD_DB`
- ✅ Warehouse disponible para ejecutar dbt.
- ✅ Proyecto configurado en dbt Cloud/Fusion.
- ✅ Variable de entorno configurada:

```text
DBT_ENVIRONMENTS=DEV
```

- ✅ Tablas Bronze cargadas desde CSV en Snowflake.
- ✅ Paquetes instalados con `dbt deps`.

---

## Estructura del proyecto

```text
proyecto_civica/
├── README.md
├── dbt_project.yml
├── packages.yml
├── package-lock.yml
│
├── macros/
│   ├── cleaning_utils.sql                 ← Macros de limpieza de fechas, importes, booleanos
│   ├── generate_database_name.sql          ← Control de base de datos por entorno
│   └── generate_schema_name.sql            ← Control del schema destino
│
├── models/
│   ├── silver/
│   │   ├── staging/
│   │   │   ├── _fix_flip__sources.yml      ← Sources Bronze + freshness
│   │   │   ├── _fix_flip__staging_models.yml
│   │   │   ├── stg_anuncios_propiedades.sql
│   │   │   ├── stg_precios_mercado_zona.sql
│   │   │   ├── stg_costes_reforma.sql
│   │   │   ├── stg_datos_zona.sql
│   │   │   └── stg_operaciones_fix_flip.sql
│   │   │
│   │   └── core/
│   │       ├── _fix_flip__core_models.yml
│   │       ├── provincias.sql
│   │       ├── municipios.sql
│   │       ├── zonas.sql
│   │       ├── portales.sql
│   │       ├── tipos_inmueble.sql
│   │       ├── propiedades.sql
│   │       ├── anuncios_propiedades.sql
│   │       ├── precios_mercado_zona.sql
│   │       ├── datos_zona.sql
│   │       ├── tipos_reforma.sql
│   │       ├── categorias_reforma.sql
│   │       ├── costes_reforma.sql
│   │       └── operaciones_fix_flip.sql
│   │
│   └── gold/
│       ├── _fix_flip__gold_models.yml
│       ├── dim_fecha.sql
│       ├── dim_provincia.sql
│       ├── dim_ubicacion.sql
│       ├── dim_tipo_inmueble.sql
│       ├── dim_propiedad.sql
│       ├── dim_portal.sql
│       ├── dim_decision_inversion.sql
│       ├── dim_reforma.sql
│       ├── fct_precios_mercado_zona.sql
│       ├── fct_indicadores_zona.sql
│       ├── fct_costes_reforma.sql
│       └── fct_oportunidades_fix_flip.sql
│
├── seeds/
│   ├── _fix_flip__seeds.yml
│   └── municipios_provincias.csv           ← Municipios, provincias, CCAA y código INE
│
├── snapshots/
│   ├── _snapshots.yml
│   └── snp_anuncios_propiedades.sql        ← Snapshot SCD Tipo 2 de anuncios
│
├── tests/
│   └── singular/
│       ├── assert_anuncios_precio_positivo.sql
│       |── assert_costes_reforma_positivos.sql
│       └── assert_score_oportunidad_rango.sql
|
└── docs/
    └── architecture.md                     ← Explicación de arquitectura y decisiones
```

---

## Caso de uso Fix & Flip

El proyecto analiza oportunidades inmobiliarias para comprar, reformar y vender propiedades.

### Fuentes del proyecto

| Fuente Bronze | Descripción |
|---|---|
| `RAW_ANUNCIOS_PROPIEDADES` | Anuncios inmobiliarios capturados desde portales |
| `RAW_PRECIOS_MERCADO_ZONA` | Precios medios de mercado por zona y tipo de inmueble |
| `RAW_COSTES_REFORMA` | Costes estimados de reforma por provincia, tipo y calidad |
| `RAW_DATOS_ZONA` | Indicadores de zona: renta, paro, servicios, transporte, colegios |
| `RAW_OPERACIONES_FIX_FLIP` | Análisis internos de posibles operaciones de inversión |

### Casos de uso analíticos

| Caso de uso | Pregunta que responde |
|---|---|
| Detectar oportunidades rentables | ¿Qué propiedades pueden comprarse, reformarse y venderse con beneficio? |
| Analizar zonas con potencial | ¿Qué zonas tienen mejores precios, servicios y atractivo inversor? |
| Controlar costes de reforma | ¿Cuánto cuesta reformar según tipo, categoría y calidad del material? |

---

## Arquitectura Medallion

### Bronze

Datos raw cargados desde CSV en S3 hacia Snowflake.  
Se mantienen sin limpiar para conservar el dato original.

### Silver staging

Modelos `stg_` que limpian:

- Fechas en distintos formatos.
- Importes con símbolos, puntos, comas o espacios.
- Booleanos en varios formatos.
- Textos con errores, mayúsculas, minúsculas o valores en inglés.
- Categorías de negocio.

### Silver core

Modelo relacional normalizado con entidades como:

- Provincias.
- Municipios.
- Zonas.
- Portales.
- Tipos de inmueble.
- Propiedades.
- Anuncios.
- Precios de mercado.
- Costes de reforma.
- Operaciones Fix & Flip.

### Gold

Modelo estrella para Power BI.

#### Dimensiones

| Dimensión | Descripción |
|---|---|
| `dim_fecha` | Calendario de análisis |
| `dim_provincia` | Provincias |
| `dim_ubicacion` | Zona, municipio y provincia |
| `dim_tipo_inmueble` | Tipos de inmueble |
| `dim_propiedad` | Atributos físicos de la propiedad |
| `dim_portal` | Portales inmobiliarios |
| `dim_decision_inversion` | Estados de decisión de inversión |
| `dim_reforma` | Tipo, categoría y calidad de reforma |

#### Facts

| Fact | Descripción |
|---|---|
| `fct_precios_mercado_zona` | Precios medios por zona, fecha y tipo de inmueble |
| `fct_indicadores_zona` | Indicadores socioeconómicos y score de zona |
| `fct_costes_reforma` | Costes estimados de reforma |
| `fct_oportunidades_fix_flip` | Fact principal de oportunidades de inversión |

---

## Setup inicial

### 1️⃣ Configurar variable de entorno

En dbt Cloud/Fusion configura:

```text
DBT_ENVIRONMENTS=DEV
```

El proyecto usa esta variable para resolver las bases de datos:

```text
DEV_BRONZE_DB
DEV_SILVER_DB
DEV_GOLD_DB
```

### 2️⃣ Instalar paquetes

```bash
dbt deps
```

Paquetes usados:

- `dbt_utils`
- `codegen`
- `dbt_expectations`

### 3️⃣ Cargar seed de municipios

```bash
dbt seed
```

Esto carga el seed:

```text
municipios_provincias.csv
```

Se usa para enriquecer municipios con provincia, comunidad autónoma y código INE.

### 4️⃣ Validar freshness

```bash
dbt source freshness --select source:fix_flip_bronze
```

El proyecto usa freshness con ventanas amplias porque la ingesta es académica:

```text
warn_after: 30 días
error_after: 60 días
```

En producción diaria estos umbrales deberían ser más estrictos.

---

## Cómo ejecutar el proyecto

### Build completo recomendado

```bash
dbt build
```

`dbt build` ejecuta modelos y tests respetando dependencias.

---

### Ejecutar Silver

```bash
dbt build --select path:models/silver --full-refresh
```

---

### Ejecutar Gold

```bash
dbt build --select path:models/gold --full-refresh
```

---

### Ejecutar solo modelos Gold por tag

```bash
dbt build --select tag:gold --full-refresh
```

---

### Ejecutar snapshots

```bash
dbt snapshot
```

---

### Ejecutar tests singulares

```bash
dbt test --select test_type:singular
```

---

### Generar documentación

```bash
dbt docs generate
```

En dbt Cloud/Fusion la documentación se consulta desde la interfaz.  
En dbt Core local también se puede usar:

```bash
dbt docs serve
```

---

### Reconstruir modelos incrementales

```bash
dbt build --select nombre_modelo --full-refresh
```

Se usa cuando cambia la lógica de un modelo incremental o se corrigen datos históricos.

---

## Decisiones técnicas importantes

### ¿Por qué arquitectura Medallion?

Porque separa responsabilidades:

- Bronze guarda el dato original.
- Silver limpia y normaliza.
- Gold prepara el dato para análisis.

---

### ¿Por qué Bronze mantiene datos en bruto?

Porque permite conservar el dato original y aplicar la limpieza de forma controlada en dbt.

---

### ¿Por qué separar Silver en staging y core?

Porque staging limpia datos y core construye el modelo relacional final.

---

### ¿Por qué usar un seed de municipios?

Para evitar `CASE` manuales y hacer el modelo más escalable.  
Si el proyecto crece, se puede ampliar el CSV sin cambiar la lógica de los modelos.

---

### ¿Por qué usar snapshots?

Para conservar histórico de cambios en anuncios inmobiliarios.

El snapshot controla cambios en:

- Precio publicado.
- Estado del anuncio.
- Tipo de vendedor.

---

### ¿Por qué `strategy='check'` en el snapshot?

Porque no dependemos de un timestamp de actualización fiable.  
dbt compara columnas concretas de negocio y detecta cambios reales.

---

### ¿Por qué no usar `id_anuncio` como unique key del snapshot?

Porque `id_anuncio` representa una captura concreta.  
Para el snapshot se usa una clave de negocio estable:

```text
id_portal + id_anuncio_externo
```

---

### ¿Por qué Gold usa dimensiones y facts?

Porque Power BI funciona mejor con modelo estrella.  
Las dimensiones describen el contexto y las facts contienen métricas.

---

### ¿Por qué algunas facts son incrementales?

Porque precios, indicadores, costes y oportunidades pueden crecer con nuevas cargas.  
El incremental evita recalcular toda la tabla en cada ejecución.

---

### ¿Por qué existe `PREANALISIS_AUTOMATICO`?

Porque no todos los anuncios tienen análisis interno.  
Si no hay operación, se estima una oportunidad usando:

- Precio publicado.
- Precio medio de mercado.
- Indicadores de zona.
- Coste medio de reforma.

Así el dashboard también sirve para priorizar anuncios pendientes de analizar.

---

### ¿Dónde está la capa semántica?

La capa semántica final se hará en Power BI.

dbt prepara:

- Datos limpios.
- Dimensiones.
- Facts.
- Métricas base.
- Tests.
- Documentación.
- Lineage.

Power BI construirá:

- Relaciones.
- Medidas DAX.
- Jerarquías.
- KPIs.
- Visualizaciones.

---

## Mapa del curso → archivos del repo

| Tema del curso | Archivos donde se aplica |
|---|---|
| Sources | `models/silver/staging/_fix_flip__sources.yml` |
| Freshness | `_fix_flip__sources.yml` |
| Staging | `models/silver/staging/stg_*.sql` |
| Modelos core | `models/silver/core/*.sql` |
| Modelo Gold | `models/gold/dim_*.sql`, `models/gold/fct_*.sql` |
| Seeds | `seeds/municipios_provincias.csv`, `_fix_flip__seeds.yml` |
| Snapshots | `snapshots/snp_anuncios_propiedades.sql` |
| Tests genéricos | Archivos `_models.yml` |
| Tests singulares | `tests/singular/*.sql` |
| Macros | `macros/cleaning_utils.sql` |
| Packages | `packages.yml` |
| Documentación | `docs/architecture.md`, `dbt docs generate` |
| Lineage | DAG generado con `ref()` y `source()` |
| Incrementales | Facts Gold incrementales |

---

## Errores comunes y soluciones

### ❌ `Database 'FAIL_SILVER_DB' does not exist`

**Causa:** no está configurada la variable `DBT_ENVIRONMENTS`.

**Solución:**

```text
DBT_ENVIRONMENTS=DEV
```

---

### ❌ Fechas como `0025-01-01`

**Causa:** fechas con año corto o formato ambiguo en Bronze.

**Solución:** revisar la macro `clean_date` en:

```text
macros/cleaning_utils.sql
```

---

### ❌ Test `relationships` fallando

**Causa:** una clave de una fact no existe en su dimensión.

**Solución:** revisar el join entre fact y dimensión y comprobar que la dimensión se ha construido correctamente.

---

### ❌ Un modelo incremental no refleja cambios nuevos

**Causa:** la tabla conserva datos calculados con una lógica anterior.

**Solución:**

```bash
dbt build --select nombre_modelo --full-refresh
```

---

### ❌ `dbt docs serve` no funciona en dbt Cloud/Fusion

**Causa:** `dbt docs serve` está pensado para dbt Core local.

**Solución:** usar:

```bash
dbt docs generate
```

y consultar la documentación desde la interfaz de dbt.

---

## Siguientes pasos

El siguiente paso es conectar Power BI a:

```text
DEV_GOLD_DB.SQL_DATOS
```

Y construir el modelo semántico con:

- Relaciones entre dimensiones y facts.
- Medidas DAX.
- Formatos de moneda y porcentaje.
- KPIs principales.
- Dashboard de oportunidades, zonas y costes de reforma.

---

## Autor

Proyecto realizado por **Pedro** como parte del curso de **Data Engineering con dbt, Snowflake y Power BI**.