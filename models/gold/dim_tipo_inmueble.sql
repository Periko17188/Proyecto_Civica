-- dim_tipo_inmueble.sql
-- ============================================================================
-- CAPA: Gold
-- MATERIALIZACIÓN: table
--
-- OBJETIVO:
-- Dimensión de tipos de inmueble para análisis en Power BI.
-- Se construye desde la tabla Silver normalized tipos_inmueble.

{{ config(materialized='table') }}

with source as (

    select
        id_tipo_inmueble,
        nombre_tipo_inmueble,
        descripcion

    from {{ ref('tipos_inmueble') }}

),

final as (

    select
        id_tipo_inmueble,
        nombre_tipo_inmueble,
        descripcion

    from source

)

select *
from final