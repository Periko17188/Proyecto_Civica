-- Tabla Silver normalized de operaciones Fix & Flip.
-- Relaciona cada análisis de inversión con el anuncio analizado.

with operaciones_base as (

    select
        id_operacion_externa,
        id_anuncio_externo,
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
        cargado_en,
        origen

    from {{ ref('stg_operaciones_fix_flip') }}

    where id_operacion_externa is not null
      and id_anuncio_externo is not null
      and fecha_analisis is not null

),

anuncios_ultimos as (

    select
        id_anuncio,
        id_anuncio_externo,
        fecha_captura,
        cargado_en,

        row_number() over (
            partition by id_anuncio_externo
            order by fecha_captura desc, cargado_en desc
        ) as rn

    from {{ ref('anuncios_propiedades') }}

),

operaciones_enriquecidas as (

    select
        o.*,
        a.id_anuncio

    from operaciones_base o

    left join anuncios_ultimos a
        on o.id_anuncio_externo = a.id_anuncio_externo
       and a.rn = 1

),

deduplicated as (

    select
        *,

        row_number() over (
            partition by id_operacion_externa
            order by cargado_en desc
        ) as rn

    from operaciones_enriquecidas

    where id_anuncio is not null

),

final as (

    select
        {{ dbt_utils.generate_surrogate_key(['id_operacion_externa']) }} as id_operacion,

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
        cargado_en,
        origen

    from deduplicated

    where rn = 1

)

select *
from final