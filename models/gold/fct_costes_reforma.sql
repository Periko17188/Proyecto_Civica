-- ============================================================================
-- fct_costes_reforma.sql
-- ============================================================================
-- CAPA: Gold
-- MATERIALIZACIÓN: incremental
--
-- OBJETIVO:
-- Tabla de hechos para analizar costes estimados de reforma por provincia,
-- tipo de reforma, categoría, calidad de material y fecha.
--
-- INCREMENTAL:
-- Solo procesa registros nuevos o modificados según cargado_en.
-- ============================================================================

{{
    config(
        materialized = 'incremental',
        unique_key = 'id_coste_reforma',
        incremental_strategy = 'merge',
        on_schema_change = 'sync_all_columns'
    )
}}

with source as (

    select
        id_coste_reforma,
        id_tipo_reforma,
        id_categoria_reforma,
        id_provincia,
        fecha_captura,
        descripcion_trabajo,
        calidad_material,
        coste_estimado_m2,
        unidad_medida,
        fuente_coste,
        cargado_en,
        origen

    from {{ ref('costes_reforma') }}

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
        s.id_coste_reforma,

        s.fecha_captura,
        f.id_fecha as id_fecha_captura,

        r.id_reforma,
        p.id_provincia,

        s.descripcion_trabajo,
        s.coste_estimado_m2,
        s.unidad_medida,
        s.fuente_coste,
        s.cargado_en,
        s.origen

    from source s

    inner join {{ ref('dim_fecha') }} f
        on to_date(s.fecha_captura) = f.fecha

    inner join {{ ref('dim_reforma') }} r
        on s.id_tipo_reforma = r.id_tipo_reforma
       and s.id_categoria_reforma = r.id_categoria_reforma
       and s.calidad_material = r.calidad_material

    inner join {{ ref('dim_provincia') }} p
        on s.id_provincia = p.id_provincia

)

select *
from final