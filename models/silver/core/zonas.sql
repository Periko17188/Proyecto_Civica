-- Tabla Silver normalizada de zonas.
-- Se crea a partir de barrios/zonas detectados en los modelos staging.
-- Cada zona queda relacionada con su municipio.

with zonas_anuncios as (

    select distinct
        municipio      as nombre_municipio,
        barrio_zona    as nombre_zona,
        codigo_postal  as codigo_postal

    from {{ ref('stg_anuncios_propiedades') }}

    where municipio is not null
      and barrio_zona is not null

),

zonas_precios as (

    select distinct
        municipio      as nombre_municipio,
        barrio_zona    as nombre_zona,
        null           as codigo_postal

    from {{ ref('stg_precios_mercado_zona') }}

    where municipio is not null
      and barrio_zona is not null

),

zonas_datos as (

    select distinct
        municipio      as nombre_municipio,
        barrio_zona    as nombre_zona,
        null           as codigo_postal

    from {{ ref('stg_datos_zona') }}

    where municipio is not null
      and barrio_zona is not null

),

union_zonas as (

    select * from zonas_anuncios

    union all

    select * from zonas_precios

    union all

    select * from zonas_datos

),

zonas_agrupadas as (

    select
        nombre_municipio,
        nombre_zona,
        min(codigo_postal) as codigo_postal

    from union_zonas

    group by
        nombre_municipio,
        nombre_zona

),

final as (

    select
        {{ dbt_utils.generate_surrogate_key([
            'z.nombre_municipio',
            'z.nombre_zona',
            'z.codigo_postal'
        ]) }} as id_zona,

        m.id_municipio,
        z.nombre_municipio,
        z.nombre_zona,
        z.codigo_postal

    from zonas_agrupadas z

    left join {{ ref('municipios') }} m
        on z.nombre_municipio = m.nombre_municipio

)

select *
from final