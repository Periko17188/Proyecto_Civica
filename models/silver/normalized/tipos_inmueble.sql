-- Tabla Silver normalizada de tipos de inmueble.
-- Se crea a partir de los tipos detectados en anuncios y precios de mercado.

with tipos_anuncios as (

    select distinct
        tipo_inmueble as nombre_tipo_inmueble

    from {{ ref('stg_anuncios_propiedades') }}

    where tipo_inmueble is not null

),

tipos_precios as (

    select distinct
        tipo_inmueble as nombre_tipo_inmueble

    from {{ ref('stg_precios_mercado_zona') }}

    where tipo_inmueble is not null

),

union_tipos as (

    select nombre_tipo_inmueble from tipos_anuncios

    union

    select nombre_tipo_inmueble from tipos_precios

),

final as (

    select
        {{ dbt_utils.generate_surrogate_key(['nombre_tipo_inmueble']) }} as id_tipo_inmueble,

        nombre_tipo_inmueble,

        case
            when nombre_tipo_inmueble = 'Piso'         then 'Vivienda en edificio residencial'
            when nombre_tipo_inmueble = 'Casa'         then 'Vivienda unifamiliar'
            when nombre_tipo_inmueble = 'Local'        then 'Local comercial susceptible de análisis inmobiliario'
            when nombre_tipo_inmueble = 'Ático'        then 'Vivienda situada en la última planta del edificio'
            when nombre_tipo_inmueble = 'Dúplex'       then 'Vivienda distribuida en dos plantas'
            when nombre_tipo_inmueble = 'Desconocido'  then 'Tipo de inmueble no informado en origen'
            else 'Tipo de inmueble detectado en origen'
        end as descripcion

    from union_tipos

)

select *
from final