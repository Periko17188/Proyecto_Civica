-- fct_precios_mercado_zona.sql
-- ============================================================================
-- CAPA: Gold
-- MATERIALIZACIÓN: incremental
--
-- OBJETIVO:
-- Tabla de hechos para analizar precios medios de mercado por zona,
-- tipo de inmueble y fecha.
--
-- INCREMENTAL:
-- Solo procesa registros nuevos o modificados según cargado_en.

{{
    config(
        materialized = 'incremental',
        unique_key = 'id_precio_mercado',
        incremental_strategy = 'merge',
        on_schema_change = 'sync_all_columns'
    )
}}

with source as (

    select
        id_precio_mercado,
        id_zona,
        id_tipo_inmueble,
        fecha_captura,
        precio_medio_venta_m2,
        numero_anuncios_venta,
        fuente_dato,
        cargado_en,
        origen

    from {{ ref('precios_mercado_zona') }}

    where fecha_captura is not null

    {% if is_incremental() %}
        and cargado_en >= (
            select coalesce(max(cargado_en), to_timestamp_ntz('1900-01-01'))
            from {{ this }}
        )
    {% endif %}

),

final as (

    select
        s.id_precio_mercado,

        s.fecha_captura,
        f.id_fecha as id_fecha_captura,

        u.id_ubicacion,
        t.id_tipo_inmueble,

        s.precio_medio_venta_m2,
        s.numero_anuncios_venta,
        s.fuente_dato,
        s.cargado_en,
        s.origen

    from source s

    inner join {{ ref('dim_fecha') }} f
        on to_date(s.fecha_captura) = f.fecha

    inner join {{ ref('dim_ubicacion') }} u
        on s.id_zona = u.id_ubicacion

    inner join {{ ref('dim_tipo_inmueble') }} t
        on s.id_tipo_inmueble = t.id_tipo_inmueble

)

select *
from final