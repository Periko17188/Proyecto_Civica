-- Tabla Silver normalized de municipios.
-- Se crea a partir de los municipios detectados en staging.
-- Se enriquece con el seed municipios_provincias para obtener provincia y código INE.

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

municipios_enriquecidos as (

    select
        u.nombre_municipio,
        s.nombre_provincia,
        s.codigo_ine_municipio

    from union_municipios u

    left join {{ ref('municipios_provincias') }} s
        on u.nombre_municipio = s.nombre_municipio

),

final as (

    select
        {{ dbt_utils.generate_surrogate_key([
            'm.nombre_municipio',
            'm.nombre_provincia'
        ]) }} as id_municipio,

        p.id_provincia,
        m.nombre_municipio,
        m.codigo_ine_municipio

    from municipios_enriquecidos m

    left join {{ ref('provincias') }} p
        on m.nombre_provincia = p.nombre_provincia

)

select *
from final