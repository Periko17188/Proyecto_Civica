-- dim_provincia.sql
-- ============================================================================
-- CAPA: Gold
-- MATERIALIZACIÓN: table
--
-- OBJETIVO:
-- Dimensión de provincias para análisis territorial.
-- Se construye desde la tabla Silver normalized provincias.

{{ config(materialized='table') }}

with source as (

    select
        id_provincia,
        nombre_provincia,
        comunidad_autonoma

    from {{ ref('provincias') }}

),

final as (

    select
        id_provincia,
        nombre_provincia,
        comunidad_autonoma

    from source

)

select *
from final