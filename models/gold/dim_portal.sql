-- dim_portal.sql
-- ============================================================================
-- CAPA: Gold
-- MATERIALIZACIÓN: table
--
-- OBJETIVO:
-- Dimensión de portales inmobiliarios para analizar el origen de los anuncios.
-- Se construye desde la tabla Silver normalized portales.

{{ config(materialized='table') }}

with source as (

    select
        id_portal,
        nombre_portal,
        url_base,
        activo

    from {{ ref('portales') }}

),

final as (

    select
        id_portal,
        nombre_portal,
        url_base,
        activo

    from source

)

select *
from final