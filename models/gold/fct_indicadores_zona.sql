-- fct_indicadores_zona.sql
-- ============================================================================
-- CAPA: Gold
-- MATERIALIZACIÓN: incremental
--
-- OBJETIVO:
-- Tabla de hechos para analizar indicadores socioeconómicos y servicios
-- disponibles por zona y fecha.
--
-- INCREMENTAL:
-- Solo procesa registros nuevos o modificados según cargado_en.

{{
    config(
        materialized = 'incremental',
        unique_key = 'id_dato_zona',
        incremental_strategy = 'merge',
        on_schema_change = 'sync_all_columns'
    )
}}

with source as (

    select
        id_dato_zona,
        id_zona,
        fecha_captura,
        poblacion,
        renta_media,
        tasa_paro,
        tiene_servicios_cercanos,
        tiene_transporte_publico,
        tiene_colegios_cercanos,
        tiene_zonas_verdes,
        proyectos_urbanisticos,
        fuente_dato,
        cargado_en,
        origen

    from {{ ref('datos_zona') }}

    where fecha_captura is not null

    {% if is_incremental() %}
        and cargado_en >= (
            select coalesce(max(cargado_en), to_timestamp_ntz('1900-01-01'))
            from {{ this }}
        )
    {% endif %}

),

scored as (

    select
        s.*,

        (
            iff(coalesce(s.tiene_servicios_cercanos, false), 1, 0)
            + iff(coalesce(s.tiene_transporte_publico, false), 1, 0)
            + iff(coalesce(s.tiene_colegios_cercanos, false), 1, 0)
            + iff(coalesce(s.tiene_zonas_verdes, false), 1, 0)
        ) as numero_servicios_disponibles,

        case
            when s.renta_media >= 25000 then 3
            when s.renta_media >= 20000 then 2
            when s.renta_media >= 15000 then 1
            else 0
        end as puntuacion_renta,

        case
            when s.tasa_paro <= 12 then 3
            when s.tasa_paro <= 18 then 2
            when s.tasa_paro <= 25 then 1
            else 0
        end as puntuacion_paro

    from source s

),

final as (

    select
        s.id_dato_zona,

        s.fecha_captura,
        f.id_fecha as id_fecha_captura,

        -- En dim_ubicacion usamos id_zona como id_ubicacion
        s.id_zona as id_ubicacion,

        s.poblacion,
        s.renta_media,
        s.tasa_paro,

        s.tiene_servicios_cercanos,
        s.tiene_transporte_publico,
        s.tiene_colegios_cercanos,
        s.tiene_zonas_verdes,

        s.numero_servicios_disponibles,

        (
            s.numero_servicios_disponibles
            + s.puntuacion_renta
            + s.puntuacion_paro
        ) as puntuacion_atractivo_zona,

        s.proyectos_urbanisticos,
        s.fuente_dato,
        s.cargado_en,
        s.origen

    from scored s

    inner join {{ ref('dim_fecha') }} f
        on to_date(s.fecha_captura) = f.fecha

)

select *
from final