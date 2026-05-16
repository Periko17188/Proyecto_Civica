-- Tabla Silver normalized de provincias.
-- Se crea a partir del seed municipios_provincias y de provincias detectadas
-- en los costes de reforma.

with provincias_seed as (

    select distinct
        nombre_provincia,
        comunidad_autonoma

    from {{ ref('municipios_provincias') }}

    where nombre_provincia is not null

),

provincias_costes as (

    select distinct
        provincia as nombre_provincia

    from {{ ref('stg_costes_reforma') }}

    where provincia is not null

),

union_provincias as (

    select nombre_provincia
    from provincias_seed

    union

    select nombre_provincia
    from provincias_costes

),

final as (

    select
        {{ dbt_utils.generate_surrogate_key(['u.nombre_provincia']) }} as id_provincia,

        u.nombre_provincia,

        coalesce(
            max(s.comunidad_autonoma),
            'Desconocido'
        ) as comunidad_autonoma

    from union_provincias u

    left join provincias_seed s
        on u.nombre_provincia = s.nombre_provincia

    group by
        u.nombre_provincia

)

select *
from final