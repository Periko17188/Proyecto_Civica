-- Limpieza inicial de costes de reforma procedentes de Bronze.
-- Normalizamos fechas, provincia, tipo de reforma, categoría, calidad de material e importes.
-- Algunas limpiezas repetidas se hacen con macros reutilizables.

with source as (

    select *
    from {{ source('fix_flip_bronze', 'raw_costes_reforma') }}

),

cleaned as (

    select
        trim(id_raw)                    as id_raw,
        trim(fecha_captura)             as fecha_captura_raw,
        lower(trim(tipo_reforma))       as tipo_reforma_clean,
        lower(trim(categoria_trabajo))  as categoria_trabajo_clean,
        trim(descripcion_trabajo)       as descripcion_trabajo,
        lower(trim(calidad_material))   as calidad_material_clean,
        trim(coste_estimado_m2)         as coste_estimado_m2_raw,
        lower(trim(unidad_medida))      as unidad_medida_clean,
        trim(fuente_coste)              as fuente_coste,
        lower(trim(provincia))          as provincia_clean,
        trim(_cargado_en)               as cargado_en_raw,
        trim(_origen)                   as origen

    from source

),

final as (

    select
        id_raw,

        -- Conversión de fecha con macro reutilizable
        {{ clean_date('fecha_captura_raw', 'cargado_en_raw') }} as fecha_captura,

        case
            when provincia_clean in ('granada')             then 'Granada'
            when provincia_clean in ('málaga', 'malaga')    then 'Málaga'
            when provincia_clean in ('almería', 'almeria')  then 'Almería'
            else initcap(provincia_clean)
        end as provincia,

        case
            when tipo_reforma_clean in ('integral', 'full renovation', 'reforma completa', 'estructural', 'instalaciones')  then 'Integral'
            when tipo_reforma_clean in ('parcial', 'partial', 'media reforma')                                              then 'Parcial'
            when tipo_reforma_clean in ('lavado cara', 'lavado de cara', 'cosmetic', 'puesta a punto', 'acabados')          then 'Lavado de cara'
            else 'Parcial'
        end as tipo_reforma,

        case
            when categoria_trabajo_clean in ('cocina', 'kitchen')                       then 'Cocina'
            when categoria_trabajo_clean in ('baño', 'bano', 'bathroom')                then 'Baño'
            when categoria_trabajo_clean in ('suelos', 'flooring')                      then 'Suelos'
            when categoria_trabajo_clean in ('pintura', 'paint')                        then 'Pintura'
            when categoria_trabajo_clean in ('electricidad', 'electric')                then 'Electricidad'
            when categoria_trabajo_clean in ('fontanería', 'fontaneria', 'plumbing')    then 'Fontanería'
            when categoria_trabajo_clean in ('carpintería', 'carpinteria', 'woodwork')  then 'Carpintería'
            else initcap(categoria_trabajo_clean)
        end as categoria_trabajo,

        descripcion_trabajo,

        case
            when calidad_material_clean in ('baja', 'low', 'económica', 'economica', 'barata')      then 'Baja'
            when calidad_material_clean in ('media', 'standard', 'estándar', 'estandar', 'normal')  then 'Media'
            when calidad_material_clean in ('alta', 'premium', 'high', 'lujo')                      then 'Alta'
            else initcap(calidad_material_clean)
        end as calidad_material,

        -- Conversión de importe con macro reutilizable
        {{ clean_decimal('coste_estimado_m2_raw', 12, 2) }} as coste_estimado_m2,

        case
            when unidad_medida_clean in ('eur_m2', '€/m2', '€/m²', 'eur/m2', 'eur/m²', 'euros/m2', 'euros/m²', 'euro/m2', 'euro/m²', 'euros metro', 'm2', 'm²') then 'EUR_M2'
            else 'EUR_M2'
        end as unidad_medida,

        fuente_coste,

        -- Conversión de timestamp con macro reutilizable
        {{ clean_timestamp('cargado_en_raw') }} as cargado_en,

        origen

    from cleaned

)

select *
from final