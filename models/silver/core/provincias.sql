-- Tabla Silver normalizada de provincias.
-- Se crea a partir de las provincias detectadas en los costes de reforma
-- y de los municipios presentes en los datos inmobiliarios.

with provincias_costes as (

    select distinct
        provincia as nombre_provincia

    from {{ ref('stg_costes_reforma') }}

    where provincia is not null

),

provincias_municipios as (

    select distinct
        case
            when municipio in (
                'Granada',
                'Maracena',
                'Armilla',
                'Albolote',
                'Churriana de la Vega',
                'Las Gabias'
            ) then 'Granada'

            else null
        end as nombre_provincia

    from {{ ref('stg_anuncios_propiedades') }}

    where municipio is not null

),

union_provincias as (

    select nombre_provincia
    from provincias_costes

    union

    select nombre_provincia
    from provincias_municipios
    where nombre_provincia is not null

),

final as (

    select
        {{ dbt_utils.generate_surrogate_key(['nombre_provincia']) }} as id_provincia,

        nombre_provincia,

        case
            when nombre_provincia in (
                'Granada',
                'Málaga',
                'Sevilla',
                'Almería',
                'Córdoba',
                'Jaén',
                'Huelva',
                'Cádiz'
            ) then 'Andalucía'

            else 'Desconocido'
        end as comunidad_autonoma

    from union_provincias

)

select *
from final