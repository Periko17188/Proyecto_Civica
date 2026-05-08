-- Limpieza inicial de anuncios inmobiliarios procedentes de Bronze.
-- Aquí normalizamos textos, fechas, importes, booleanos y categorías.

with source as (

    select *
    from {{ source('fix_flip_bronze', 'raw_anuncios_propiedades') }}

),

cleaned as (

    select
        trim(id_raw)                    as id_raw,              
        trim(id_anuncio_externo)        as id_anuncio_externo,
        lower(trim(portal_origen))      as portal_origen_clean,
        trim(url_anuncio)               as url_anuncio,
        trim(fecha_captura)             as fecha_captura_raw,
        trim(titulo_anuncio)            as titulo_anuncio,
        trim(descripcion_anuncio)       as descripcion_anuncio,
        trim(precio_publicado)          as precio_publicado_raw,
        trim(superficie_m2)             as superficie_m2_raw,
        trim(habitaciones)              as habitaciones_raw,
        trim(banos)                     as banos_raw,
        trim(planta)                    as planta,          --trim: quita espacios
        lower(trim(ascensor))           as ascensor_clean,  --lower: texto minúscula
        lower(trim(estado_inmueble))    as estado_inmueble_clean,
        lower(trim(tipo_inmueble))      as tipo_inmueble_clean,
        trim(direccion_aproximada)      as direccion_aproximada,
        lower(trim(municipio))          as municipio_clean,
        lower(trim(barrio_zona))        as barrio_zona_clean,
        nullif(trim(codigo_postal), '') as codigo_postal,
        lower(trim(vendedor_tipo))      as vendedor_tipo_clean,
        lower(trim(estado_anuncio))     as estado_anuncio_clean,
        trim(_cargado_en)               as cargado_en_raw,
        trim(_origen)                   as origen

    from source

),

final as (

    select
        id_raw,
        id_anuncio_externo,

        -- Normalización de catálogos de texto
        case
            when portal_origen_clean like '%idealista%' then 'Idealista'
            when portal_origen_clean like '%fotocasa%' then 'Fotocasa'
            when portal_origen_clean like '%solvia%' then 'Solvia'
            when portal_origen_clean like '%servihabitat%' then 'Servihabitat'
            when portal_origen_clean like '%aliseda%' then 'Aliseda'
            else initcap(portal_origen_clean)
        end as portal_origen,

        url_anuncio,

        -- Conversión de fechas con varios formatos posibles
        coalesce(
            try_to_date(fecha_captura_raw, 'YYYY-MM-DD'),
            try_to_date(fecha_captura_raw, 'DD/MM/YYYY'),
            try_to_date(fecha_captura_raw, 'DD-MM-YYYY'),
            try_to_date(fecha_captura_raw, 'YYYY/MM/DD')
        ) as fecha_captura,

        titulo_anuncio,
        descripcion_anuncio,

        -- Limpieza de importes y números
        try_to_decimal(
            replace(replace(regexp_replace(precio_publicado_raw, '[^0-9,.-]', ''), '.', ''), ',', '.'),
            12, 2
        ) as precio_publicado,

        try_to_decimal(
            replace(regexp_replace(superficie_m2_raw, '[^0-9,.-]', ''), ',', '.'),
            10, 2
        ) as superficie_m2,

        try_to_number(regexp_replace(habitaciones_raw, '[^0-9]', ''))   as habitaciones,
        try_to_number(regexp_replace(banos_raw, '[^0-9]', ''))          as banos,

        planta,

        -- Conversión de booleanos
        case
            when ascensor_clean in ('true', '1', 'si', 'sí', 'yes', 'verdadero') then true
            when ascensor_clean in ('false', '0', 'no', 'falso') then false
            else null
        end as tiene_ascensor,

        case
            when estado_inmueble_clean in ('para reformar', 'a reformar', 'needs renovation', 'para reforma') then 'Para reformar'
            when estado_inmueble_clean in ('mal estado', 'malo', 'poor condition') then 'Mal estado'
            when estado_inmueble_clean in ('reforma parcial', 'semi reformado', 'partial renovation') then 'Reforma parcial'
            when estado_inmueble_clean in ('buen estado', 'good condition') then 'Buen estado'
            else initcap(estado_inmueble_clean)
        end as estado_inmueble,

        case
            when tipo_inmueble_clean in ('piso', 'flat', 'apartamento') then 'Piso'
            when tipo_inmueble_clean in ('casa', 'house') then 'Casa'
            when tipo_inmueble_clean in ('local', 'local comercial', 'commercial unit') then 'Local'
            when tipo_inmueble_clean in ('atico', 'ático', 'penthouse') then 'Ático'
            when tipo_inmueble_clean in ('duplex', 'dúplex') then 'Dúplex'
            else initcap(tipo_inmueble_clean)
        end as tipo_inmueble,

        direccion_aproximada,

        case
            when municipio_clean in ('granada', 'graná') then 'Granada'
            when municipio_clean = 'maracena' then 'Maracena'
            when municipio_clean in ('armilla', 'armila') then 'Armilla'
            when municipio_clean = 'albolote' then 'Albolote'
            when municipio_clean in ('churriana', 'churriana de la vega') then 'Churriana de la Vega'
            when municipio_clean in ('gabias', 'las gabias') then 'Las Gabias'
            else initcap(municipio_clean)
        end as municipio,

        case
            when barrio_zona_clean in ('la chana', 'la chna', 'chana') then 'La Chana'
            when barrio_zona_clean in ('zaidin', 'zaidín') then 'Zaidín'
            when barrio_zona_clean in ('centro', 'cento') then 'Centro'
            when barrio_zona_clean in ('norte', 'zona norte') then 'Norte'
            when barrio_zona_clean = 'realejo' then 'Realejo'
            else initcap(barrio_zona_clean)
        end as barrio_zona,

        codigo_postal,

        case
            when vendedor_tipo_clean in ('particular', 'owner', 'propietario') then 'Particular'
            when vendedor_tipo_clean in ('inmobiliaria', 'agency', 'agencia') then 'Inmobiliaria'
            when vendedor_tipo_clean in ('banco', 'bank') then 'Banco'
            when vendedor_tipo_clean in ('fondo inversion', 'fondo de inversión', 'investment fund', 'fondo') then 'Fondo de inversión'
            else initcap(vendedor_tipo_clean)
        end as vendedor_tipo,

        case
            when estado_anuncio_clean in ('activo', 'active') then 'Activo'
            when estado_anuncio_clean = 'reservado' then 'Reservado'
            when estado_anuncio_clean = 'bajado de precio' then 'Bajado de precio'
            when estado_anuncio_clean = 'publicado recientemente' then 'Publicado recientemente'
            else initcap(estado_anuncio_clean)
        end as estado_anuncio,

        coalesce(  -- deuelve el primer valor que no sea Null
            try_to_timestamp_ntz(cargado_en_raw, 'YYYY-MM-DD HH24:MI:SS'),
            try_to_timestamp_ntz(cargado_en_raw, 'YYYY/MM/DD HH24:MI:SS'),
            try_to_timestamp_ntz(replace(cargado_en_raw, ' UTC', ''), 'YYYY-MM-DD HH24:MI:SS')
        ) as cargado_en,

        origen

    from cleaned

)

select *
from final