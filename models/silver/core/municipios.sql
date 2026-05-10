-- Tabla Silver normalizada de municipios.
-- Se crea a partir de los municipios detectados en los modelos staging.
-- Relaciona cada municipio con su provincia correspondiente.

with municipios_anuncios as (

    select distinct
        municipio as nombre_municipio
    from {{ ref('stg_anuncios_propiedades') }}
    where municipio is not null

),

municipios_precios as (

    select distinct
        municipio as nombre_municipio
    from {{ ref('stg_precios_mercado_zona') }}
    where municipio is not null

),

municipios_zona as (

    select distinct
        municipio as nombre_municipio
    from {{ ref('stg_datos_zona') }}
    where municipio is not null

),

union_municipios as (

    select nombre_municipio from municipios_anuncios

    union

    select nombre_municipio from municipios_precios

    union

    select nombre_municipio from municipios_zona

),

municipios_con_provincia as (

    select
        nombre_municipio,

        case
            when nombre_municipio in (
                'Granada',
                'Maracena',
                'Armilla',
                'Albolote',
                'Churriana de la Vega',
                'Las Gabias',
                'Iznalloz'
            ) then 'Granada'

            when nombre_municipio in ('Málaga')  then 'Málaga'
            when nombre_municipio in ('Sevilla') then 'Sevilla'
            when nombre_municipio in ('Almería') then 'Almería'

            else 'Desconocido'
        end as nombre_provincia

    from union_municipios

),

final as (

    select
        {{ dbt_utils.generate_surrogate_key([
            'm.nombre_municipio',
            'm.nombre_provincia'
        ]) }} as id_municipio,

        p.id_provincia,
        m.nombre_municipio,
        m.nombre_provincia,

        null as codigo_ine_municipio

    from municipios_con_provincia m

    left join {{ ref('provincias') }} p
        on m.nombre_provincia = p.nombre_provincia

)

select *
from final