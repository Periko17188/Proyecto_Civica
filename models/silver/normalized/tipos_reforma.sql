-- Tabla Silver normalized de tipos de reforma.
-- Catálogo normalizado creado a partir de los tipos detectados en costes de reforma.

with tipos_origen as (

    select distinct
        tipo_reforma as nombre_tipo_reforma

    from {{ ref('stg_costes_reforma') }}

    where tipo_reforma is not null

),

final as (

    select
        {{ dbt_utils.generate_surrogate_key(['nombre_tipo_reforma']) }} as id_tipo_reforma,

        nombre_tipo_reforma,

        case
            when nombre_tipo_reforma = 'Integral'        then 'Reforma completa del inmueble'
            when nombre_tipo_reforma = 'Parcial'         then 'Reforma limitada a una parte del inmueble'
            when nombre_tipo_reforma = 'Lavado de cara'  then 'Mejora estética o reforma ligera'
            else 'Tipo de reforma detectado en origen'
        end as descripcion

    from tipos_origen

)

select *
from final