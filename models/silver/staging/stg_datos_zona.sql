-- Limpieza inicial de indicadores de zona.
-- Normalizamos fechas, municipios, barrios, importes, porcentajes y booleanos.
-- Algunas limpiezas repetidas se hacen con macros reutilizables.

with source as (

    select *
    from {{ source('fix_flip_bronze', 'raw_datos_zona') }}

),

cleaned as (

    select
        trim(id_raw)                     as id_raw,
        trim(fecha_captura)              as fecha_captura_raw,
        lower(trim(municipio))           as municipio_clean,
        lower(trim(barrio_zona))         as barrio_zona_clean,
        trim(poblacion)                  as poblacion_raw,
        trim(renta_media)                as renta_media_raw,
        trim(tasa_paro)                  as tasa_paro_raw,
        lower(trim(servicios_cercanos))  as servicios_cercanos_clean,
        lower(trim(transporte_publico))  as transporte_publico_clean,
        lower(trim(colegios_cercanos))   as colegios_cercanos_clean,
        lower(trim(zonas_verdes))        as zonas_verdes_clean,
        trim(proyectos_urbanisticos)     as proyectos_urbanisticos,
        trim(fuente_dato)                as fuente_dato,
        trim(_cargado_en)                as cargado_en_raw,
        trim(_origen)                    as origen

    from source

),

final as (

    select
        id_raw,

        -- Conversión de fecha con macro reutilizable
        {{ clean_date('fecha_captura_raw', 'cargado_en_raw') }} as fecha_captura,

        {{ normalizar_municipio('municipio_clean') }} as municipio,

        {{ normalizar_barrio_zona('barrio_zona_clean') }} as barrio_zona,

        -- Conversión de números e importes con macros reutilizables
        {{ clean_integer('poblacion_raw') }}          as poblacion,
        {{ clean_decimal('renta_media_raw', 12, 2) }} as renta_media,
        {{ clean_decimal('tasa_paro_raw', 5, 2) }}    as tasa_paro,

        -- Conversión de booleanos con macro reutilizable
        {{ clean_boolean('servicios_cercanos_clean') }} as tiene_servicios_cercanos,
        {{ clean_boolean('transporte_publico_clean') }} as tiene_transporte_publico,
        {{ clean_boolean('colegios_cercanos_clean') }}  as tiene_colegios_cercanos,
        {{ clean_boolean('zonas_verdes_clean') }}       as tiene_zonas_verdes,

        proyectos_urbanisticos,
        fuente_dato,

        -- Conversión de timestamp con macro reutilizable
        {{ clean_timestamp('cargado_en_raw') }} as cargado_en,

        origen

    from cleaned

)

select *
from final