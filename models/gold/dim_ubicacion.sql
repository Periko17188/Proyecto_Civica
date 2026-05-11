-- dim_ubicacion.sql
-- ============================================================================
-- CAPA: Gold
-- MATERIALIZACIÓN: table
--
-- OBJETIVO:
-- Dimensión de ubicación para análisis territorial.
-- Une zona, municipio y provincia en una sola tabla para facilitar Power BI.

{{ config(materialized='table') }}

with zonas as (

    select
        id_zona,
        id_municipio,
        nombre_zona,
        codigo_postal

    from {{ ref('zonas') }}

),

municipios as (

    select
        id_municipio,
        id_provincia,
        nombre_municipio,
        codigo_ine_municipio

    from {{ ref('municipios') }}

),

provincias as (

    select
        id_provincia,
        nombre_provincia,
        comunidad_autonoma

    from {{ ref('provincias') }}

),

final as (

    select
        z.id_zona as id_ubicacion,

        z.id_zona,
        z.nombre_zona as barrio_zona,
        z.codigo_postal,

        m.id_municipio,
        m.nombre_municipio as municipio,
        m.codigo_ine_municipio,

        p.id_provincia,
        p.nombre_provincia as provincia,
        p.comunidad_autonoma

    from zonas z

    left join municipios m
        on z.id_municipio = m.id_municipio

    left join provincias p
        on m.id_provincia = p.id_provincia

)

select *
from final