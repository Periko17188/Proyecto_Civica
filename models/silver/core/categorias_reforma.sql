-- Tabla Silver core de categorías de reforma.
-- Catálogo normalizado creado a partir de las categorías detectadas en costes de reforma.

with categorias_origen as (

    select distinct
        categoria_trabajo as nombre_categoria_reforma

    from {{ ref('stg_costes_reforma') }}

    where categoria_trabajo is not null

),

final as (

    select
        {{ dbt_utils.generate_surrogate_key(['nombre_categoria_reforma']) }} as id_categoria_reforma,

        nombre_categoria_reforma,

        case
            when nombre_categoria_reforma in ('Cocina', 'Baño')             then 'Reforma de estancia principal'
            when nombre_categoria_reforma in ('Suelos', 'Pintura')          then 'Acabados interiores'
            when nombre_categoria_reforma in ('Electricidad', 'Fontanería') then 'Instalaciones técnicas'
            when nombre_categoria_reforma in ('Carpintería')                then 'Carpintería y elementos interiores'
            else 'Categoría de reforma detectada en origen'
        end as descripcion

    from categorias_origen

)

select *
from final