-- Limpieza inicial de precios de mercado por zona procedentes de Bronze.
-- Normalizamos fechas, municipios, zonas, tipos de inmueble, importes y números.
-- Algunas limpiezas repetidas se hacen con macros reutilizables.

with source as (

    select *
    from {{ source('fix_flip_bronze', 'raw_precios_mercado_zona') }}

),

cleaned as (

    select
        trim(id_raw)                as id_raw,
        trim(fecha_captura)         as fecha_captura_raw,
        lower(trim(municipio))      as municipio_clean,
        lower(trim(barrio_zona))    as barrio_zona_clean,
        lower(trim(tipo_inmueble))  as tipo_inmueble_clean,
        trim(precio_medio_venta_m2) as precio_medio_venta_m2_raw,
        trim(numero_anuncios_venta) as numero_anuncios_venta_raw,
        trim(fuente_dato)           as fuente_dato,
        trim(_cargado_en)           as cargado_en_raw,
        trim(_origen)               as origen

    from source

),

final as (

    select
        id_raw,

        -- Conversión de fecha con macro reutilizable
        {{ clean_date('fecha_captura_raw', 'cargado_en_raw') }} as fecha_captura,

        {{ normalizar_municipio('municipio_clean') }} as municipio,

        {{ normalizar_barrio_zona('barrio_zona_clean') }} as barrio_zona,

        case
            when tipo_inmueble_clean in ('piso', 'flat', 'apartamento', 'estudio', 'bajo') then 'Piso'
            when tipo_inmueble_clean in ('casa', 'house', 'chalet')                        then 'Casa'
            when tipo_inmueble_clean in ('local', 'local comercial', 'commercial unit')    then 'Local'
            when tipo_inmueble_clean in ('atico', 'ático', 'penthouse')                    then 'Ático'
            when tipo_inmueble_clean in ('duplex', 'dúplex')                               then 'Dúplex'
            when tipo_inmueble_clean in ('n/a', '-', 'desconocido', '')                    then 'Desconocido'
            when tipo_inmueble_clean is null                                               then 'Desconocido'
            else 'Desconocido'
        end as tipo_inmueble,

        -- Conversión de importes y números con macros reutilizables
        {{ clean_decimal('precio_medio_venta_m2_raw', 12, 2) }} as precio_medio_venta_m2,
        {{ clean_integer('numero_anuncios_venta_raw') }}        as numero_anuncios_venta,

        fuente_dato,

        -- Conversión de timestamp con macro reutilizable
        {{ clean_timestamp('cargado_en_raw') }} as cargado_en,

        origen

    from cleaned

)

select *
from final