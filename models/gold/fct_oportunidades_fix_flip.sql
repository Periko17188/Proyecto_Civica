-- ============================================================================
-- fct_oportunidades_fix_flip.sql
-- ============================================================================
-- CAPA: Gold
-- MATERIALIZACIÓN: incremental
--
-- OBJETIVO:
-- Tabla de hechos principal para analizar oportunidades Fix & Flip.
-- Parte de todos los anuncios capturados y añade el análisis interno cuando existe.
--
-- GRANULARIDAD:
-- Una fila por anuncio capturado.
--
-- LÓGICA:
--   - ANALISIS_INTERNO: anuncio con operación asociada.
--   - PREANALISIS_AUTOMATICO: anuncio sin operación, estimado con precio publicado,
--     precio de mercado y coste medio de reforma.
--
-- SCORE:
-- Calcula una puntuación simple de oportunidad entre 0 y 10.
-- ============================================================================

{{
    config(
        materialized = 'incremental',
        unique_key = 'id_oportunidad',
        incremental_strategy = 'merge',
        on_schema_change = 'sync_all_columns'
    )
}}

with anuncios as (

    select
        id_anuncio,
        id_propiedad,
        id_portal,
        id_anuncio_externo,
        url_anuncio,
        fecha_captura,
        titulo_anuncio,
        precio_publicado,
        vendedor_tipo,
        estado_anuncio,
        cargado_en,
        origen

    from {{ ref('anuncios_propiedades') }}

    where fecha_captura is not null

),

operaciones_base as (

    select
        id_operacion,
        id_anuncio,
        fecha_analisis,
        precio_compra_estimado,
        precio_negociado,
        coste_reforma_estimado,
        gastos_compra_estimados,
        precio_venta_estimado,
        tiempo_reforma_estimado_dias,
        tiempo_venta_estimado_dias,
        decision_inversion,
        observaciones,
        cargado_en as operacion_cargado_en,

        row_number() over (
            partition by id_anuncio
            order by fecha_analisis desc, cargado_en desc
        ) as rn

    from {{ ref('operaciones_fix_flip') }}

),

operaciones as (

    select
        id_operacion,
        id_anuncio,
        fecha_analisis,
        precio_compra_estimado,
        precio_negociado,
        coste_reforma_estimado,
        gastos_compra_estimados,
        precio_venta_estimado,
        tiempo_reforma_estimado_dias,
        tiempo_venta_estimado_dias,
        decision_inversion,
        observaciones,
        operacion_cargado_en

    from operaciones_base

    where rn = 1

),

precios_mercado_anuncio as (

    select
        a.id_anuncio,
        pm.fecha_captura as fecha_precio_mercado,
        pm.precio_medio_venta_m2,
        pm.numero_anuncios_venta as numero_anuncios_mercado,
        pm.fuente_dato as fuente_precio_mercado,
        pm.cargado_en as precio_mercado_cargado_en,

        row_number() over (
            partition by a.id_anuncio
            order by pm.fecha_captura desc, pm.cargado_en desc
        ) as rn

    from anuncios a

    inner join {{ ref('dim_propiedad') }} dp
        on a.id_propiedad = dp.id_propiedad

    left join {{ ref('precios_mercado_zona') }} pm
        on dp.id_ubicacion = pm.id_zona
       and dp.id_tipo_inmueble = pm.id_tipo_inmueble
       and pm.fecha_captura <= a.fecha_captura

),

precios_mercado_final as (

    select
        id_anuncio,
        fecha_precio_mercado,
        precio_medio_venta_m2,
        numero_anuncios_mercado,
        fuente_precio_mercado,
        precio_mercado_cargado_en

    from precios_mercado_anuncio

    where rn = 1

),

indicadores_anuncio as (

    select
        a.id_anuncio,
        dz.fecha_captura as fecha_indicador_zona,

        (
            iff(coalesce(dz.tiene_servicios_cercanos, false), 1, 0)
            + iff(coalesce(dz.tiene_transporte_publico, false), 1, 0)
            + iff(coalesce(dz.tiene_colegios_cercanos, false), 1, 0)
            + iff(coalesce(dz.tiene_zonas_verdes, false), 1, 0)
        ) as numero_servicios_disponibles,

        (
            (
                iff(coalesce(dz.tiene_servicios_cercanos, false), 1, 0)
                + iff(coalesce(dz.tiene_transporte_publico, false), 1, 0)
                + iff(coalesce(dz.tiene_colegios_cercanos, false), 1, 0)
                + iff(coalesce(dz.tiene_zonas_verdes, false), 1, 0)
            )
            +
            case
                when dz.renta_media >= 25000 then 3
                when dz.renta_media >= 20000 then 2
                when dz.renta_media >= 15000 then 1
                else 0
            end
            +
            case
                when dz.tasa_paro <= 12 then 3
                when dz.tasa_paro <= 18 then 2
                when dz.tasa_paro <= 25 then 1
                else 0
            end
        ) as puntuacion_atractivo_zona,

        dz.cargado_en as indicador_cargado_en,

        row_number() over (
            partition by a.id_anuncio
            order by dz.fecha_captura desc, dz.cargado_en desc
        ) as rn

    from anuncios a

    inner join {{ ref('dim_propiedad') }} dp
        on a.id_propiedad = dp.id_propiedad

    left join {{ ref('datos_zona') }} dz
        on dp.id_ubicacion = dz.id_zona
       and dz.fecha_captura <= a.fecha_captura

),

indicadores_final as (

    select
        id_anuncio,
        fecha_indicador_zona,
        numero_servicios_disponibles,
        puntuacion_atractivo_zona,
        indicador_cargado_en

    from indicadores_anuncio

    where rn = 1

),

costes_medios_provincia as (

    select
        id_provincia,
        fecha_captura,
        avg(coste_estimado_m2) as coste_medio_reforma_m2,
        max(cargado_en) as coste_reforma_cargado_en

    from {{ ref('costes_reforma') }}

    where coste_estimado_m2 is not null

    group by
        id_provincia,
        fecha_captura

),

costes_anuncio as (

    select
        a.id_anuncio,
        c.fecha_captura as fecha_coste_reforma,
        c.coste_medio_reforma_m2,
        c.coste_reforma_cargado_en,

        row_number() over (
            partition by a.id_anuncio
            order by c.fecha_captura desc, c.coste_reforma_cargado_en desc
        ) as rn

    from anuncios a

    inner join {{ ref('dim_propiedad') }} dp
        on a.id_propiedad = dp.id_propiedad

    inner join {{ ref('dim_ubicacion') }} du
        on dp.id_ubicacion = du.id_ubicacion

    left join costes_medios_provincia c
        on du.id_provincia = c.id_provincia
       and c.fecha_captura <= a.fecha_captura

),

costes_final as (

    select
        id_anuncio,
        fecha_coste_reforma,
        coste_medio_reforma_m2,
        coste_reforma_cargado_en

    from costes_anuncio

    where rn = 1

),

base as (

    select
        -- Una oportunidad representa un anuncio capturado.
        a.id_anuncio as id_oportunidad,
        a.id_anuncio,
        o.id_operacion,

        dp.id_propiedad,
        dp.id_ubicacion,
        dp.id_tipo_inmueble,
        a.id_portal,

        fcap.id_fecha as id_fecha_captura,
        fanalisis.id_fecha as id_fecha_analisis,
        di.id_decision,

        a.fecha_captura,
        o.fecha_analisis,
        pm.fecha_precio_mercado,
        iz.fecha_indicador_zona,
        cf.fecha_coste_reforma,

        a.id_anuncio_externo,
        a.url_anuncio,
        a.titulo_anuncio,
        a.vendedor_tipo,
        a.estado_anuncio,

        case
            when o.id_operacion is not null then 'ANALISIS_INTERNO'
            else 'PREANALISIS_AUTOMATICO'
        end as tipo_analisis,

        coalesce(o.decision_inversion, 'NO_ANALIZADO') as decision_inversion,
        o.observaciones,

        a.precio_publicado,
        dp.superficie_m2,

        pm.precio_medio_venta_m2,
        pm.numero_anuncios_mercado,
        pm.fuente_precio_mercado,

        iz.numero_servicios_disponibles,
        iz.puntuacion_atractivo_zona,

        cf.coste_medio_reforma_m2,

        o.precio_compra_estimado,
        o.precio_negociado,
        o.coste_reforma_estimado as coste_reforma_estimado_operacion,
        o.gastos_compra_estimados as gastos_compra_estimados_operacion,
        o.precio_venta_estimado as precio_venta_estimado_operacion,
        o.tiempo_reforma_estimado_dias,
        o.tiempo_venta_estimado_dias,

        greatest(
            coalesce(a.cargado_en, to_timestamp_ntz('1900-01-01')),
            coalesce(o.operacion_cargado_en, to_timestamp_ntz('1900-01-01')),
            coalesce(pm.precio_mercado_cargado_en, to_timestamp_ntz('1900-01-01')),
            coalesce(iz.indicador_cargado_en, to_timestamp_ntz('1900-01-01')),
            coalesce(cf.coste_reforma_cargado_en, to_timestamp_ntz('1900-01-01'))
        ) as cargado_en,

        a.origen

    from anuncios a

    inner join {{ ref('dim_propiedad') }} dp
        on a.id_propiedad = dp.id_propiedad

    inner join {{ ref('dim_portal') }} po
        on a.id_portal = po.id_portal

    inner join {{ ref('dim_fecha') }} fcap
        on to_date(a.fecha_captura) = fcap.fecha

    left join operaciones o
        on a.id_anuncio = o.id_anuncio

    left join {{ ref('dim_fecha') }} fanalisis
        on to_date(o.fecha_analisis) = fanalisis.fecha

    inner join {{ ref('dim_decision_inversion') }} di
        on coalesce(o.decision_inversion, 'NO_ANALIZADO') = di.decision_inversion

    left join precios_mercado_final pm
        on a.id_anuncio = pm.id_anuncio

    left join indicadores_final iz
        on a.id_anuncio = iz.id_anuncio

    left join costes_final cf
        on a.id_anuncio = cf.id_anuncio

),

calculo_base as (

    select
        *,

        case
            when id_operacion is not null
                then coalesce(precio_negociado, precio_compra_estimado, precio_publicado)
            else precio_publicado
        end as precio_compra_base,

        round(
            precio_publicado / nullif(superficie_m2, 0),
            2
        ) as precio_publicado_m2,

        round(
            precio_medio_venta_m2 * superficie_m2,
            2
        ) as valor_mercado_estimado,

        case
            when id_operacion is not null
                then coste_reforma_estimado_operacion
            when coste_medio_reforma_m2 is not null
             and superficie_m2 is not null
                then round(coste_medio_reforma_m2 * superficie_m2, 2)
            else null
        end as coste_reforma_estimado,

        case
            when id_operacion is not null
                then gastos_compra_estimados_operacion
            when precio_publicado is not null
                then round(precio_publicado * 0.10, 2)
            else null
        end as gastos_compra_estimados,

        case
            when id_operacion is not null
                then precio_venta_estimado_operacion
            when precio_medio_venta_m2 is not null
             and superficie_m2 is not null
                then round(precio_medio_venta_m2 * superficie_m2, 2)
            else null
        end as precio_venta_estimado,

        case
            when tiempo_reforma_estimado_dias is not null
              or tiempo_venta_estimado_dias is not null
                then coalesce(tiempo_reforma_estimado_dias, 0)
                   + coalesce(tiempo_venta_estimado_dias, 0)
            else null
        end as tiempo_total_estimado_dias

    from base

),

calculo_financiero as (

    select
        *,

        round(
            (valor_mercado_estimado - precio_compra_base)
            / nullif(valor_mercado_estimado, 0) * 100,
            2
        ) as descuento_vs_mercado_pct,

        case
            when precio_compra_base is not null
             and coste_reforma_estimado is not null
             and gastos_compra_estimados is not null
                then precio_compra_base
                   + coste_reforma_estimado
                   + gastos_compra_estimados
            else null
        end as inversion_total_estimada

    from calculo_base

),

calculo_rentabilidad as (

    select
        *,

        case
            when precio_venta_estimado is not null
             and inversion_total_estimada is not null
                then precio_venta_estimado - inversion_total_estimada
            else null
        end as beneficio_estimado,

        round(
            (
                case
                    when precio_venta_estimado is not null
                     and inversion_total_estimada is not null
                        then precio_venta_estimado - inversion_total_estimada
                    else null
                end
            ) / nullif(inversion_total_estimada, 0) * 100,
            2
        ) as rentabilidad_estimada_pct,

        round(
            (
                case
                    when precio_venta_estimado is not null
                     and inversion_total_estimada is not null
                        then precio_venta_estimado - inversion_total_estimada
                    else null
                end
            ) / nullif(precio_venta_estimado, 0) * 100,
            2
        ) as margen_sobre_venta_pct

    from calculo_financiero

),

final as (

    select
        id_oportunidad,
        id_anuncio,
        id_operacion,

        id_propiedad,
        id_ubicacion,
        id_tipo_inmueble,
        id_portal,
        id_fecha_captura,
        id_fecha_analisis,
        id_decision,

        fecha_captura,
        fecha_analisis,
        fecha_precio_mercado,
        fecha_indicador_zona,
        fecha_coste_reforma,

        id_anuncio_externo,
        url_anuncio,
        titulo_anuncio,
        vendedor_tipo,
        estado_anuncio,
        tipo_analisis,
        decision_inversion,
        observaciones,

        precio_publicado,
        superficie_m2,
        precio_publicado_m2,

        precio_medio_venta_m2,
        valor_mercado_estimado,
        descuento_vs_mercado_pct,
        numero_anuncios_mercado,
        fuente_precio_mercado,

        coste_medio_reforma_m2,
        precio_compra_estimado,
        precio_negociado,
        precio_compra_base,
        coste_reforma_estimado,
        gastos_compra_estimados,
        precio_venta_estimado,
        inversion_total_estimada,
        beneficio_estimado,
        rentabilidad_estimada_pct,
        margen_sobre_venta_pct,

        tiempo_reforma_estimado_dias,
        tiempo_venta_estimado_dias,
        tiempo_total_estimado_dias,

        puntuacion_atractivo_zona,
        numero_servicios_disponibles,

        (
            case when descuento_vs_mercado_pct >= 15 then 3 else 0 end
            + case when rentabilidad_estimada_pct >= 20 then 3 else 0 end
            + case when tiempo_total_estimado_dias <= 180 then 2 else 0 end
            + case when puntuacion_atractivo_zona >= 6 then 2 else 0 end
        ) as score_oportunidad,

        case
            when rentabilidad_estimada_pct is null then null
            when rentabilidad_estimada_pct >= 20 then true
            else false
        end as cumple_rentabilidad_objetivo,

        cargado_en,
        origen

    from calculo_rentabilidad

    {% if is_incremental() %}
        where cargado_en >= (
            select coalesce(max(cargado_en), to_timestamp_ntz('1900-01-01'))
            from {{ this }}
        )
    {% endif %}

)

select *
from final