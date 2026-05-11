-- dim_propiedad.sql
-- ============================================================================
-- CAPA: Gold
-- MATERIALIZACIÓN: table
--
-- OBJETIVO:
-- Dimensión de propiedades para análisis Fix & Flip.
-- Contiene los atributos físicos principales del inmueble.

{{ config(materialized='table') }}

with source as (

    select
        id_propiedad,
        id_zona,
        id_tipo_inmueble,
        referencia_catastral,
        direccion_aproximada,
        superficie_m2,
        habitaciones,
        banos,
        planta,
        tiene_ascensor,
        estado_inmueble,
        fecha_creacion

    from {{ ref('propiedades') }}

),

final as (

    select
        id_propiedad,

        -- En dim_ubicacion hemos usado id_zona como id_ubicacion
        id_zona as id_ubicacion,

        id_tipo_inmueble,
        referencia_catastral,
        direccion_aproximada,
        superficie_m2,
        habitaciones,
        banos,
        planta,
        tiene_ascensor,
        estado_inmueble,
        fecha_creacion,

        case
            when fecha_creacion is not null
                then to_number(to_char(fecha_creacion, 'YYYYMMDD'))
            else null
        end as id_fecha_creacion

    from source

)

select *
from final