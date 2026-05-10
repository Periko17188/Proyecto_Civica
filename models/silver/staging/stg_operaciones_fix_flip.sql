-- Limpieza inicial de operaciones Fix & Flip procedentes de Bronze.
-- Normalizamos fechas, importes, tiempos y decisiones de inversión.
-- Algunas limpiezas repetidas se hacen con macros reutilizables.

with source as (

    select *
    from {{ source('fix_flip_bronze', 'raw_operaciones_fix_flip') }}

),

cleaned as (

    select
        trim(id_raw)                         as id_raw,
        trim(id_operacion_externa)           as id_operacion_externa,
        trim(id_anuncio_externo)             as id_anuncio_externo,
        trim(fecha_analisis)                 as fecha_analisis_raw,
        trim(precio_compra_estimado)         as precio_compra_estimado_raw,
        trim(precio_negociado)               as precio_negociado_raw,
        trim(coste_reforma_estimado)         as coste_reforma_estimado_raw,
        trim(gastos_compra_estimados)        as gastos_compra_estimados_raw,
        trim(precio_venta_estimado)          as precio_venta_estimado_raw,
        trim(tiempo_reforma_estimado_dias)   as tiempo_reforma_estimado_dias_raw,
        trim(tiempo_venta_estimado_dias)     as tiempo_venta_estimado_dias_raw,
        lower(trim(decision_inversion))      as decision_inversion_clean,
        trim(observaciones)                  as observaciones,
        trim(_cargado_en)                    as cargado_en_raw,
        trim(_origen)                        as origen

    from source

),

final as (

    select
        id_raw,

        -- Si viene vacío se genera un ID técnico a partir de id_raw
        coalesce(
            nullif(id_operacion_externa, ''),
            concat('OP_GENERADA_', id_raw)
        ) as id_operacion_externa,

        id_anuncio_externo,

        -- Conversión de fecha con macro reutilizable
        {{ clean_date('fecha_analisis_raw', 'cargado_en_raw') }} as fecha_analisis,

        -- Conversión de importes con macro reutilizable
        {{ clean_decimal('precio_compra_estimado_raw', 12, 2) }}   as precio_compra_estimado,
        {{ clean_decimal('precio_negociado_raw', 12, 2) }}         as precio_negociado,
        {{ clean_decimal('coste_reforma_estimado_raw', 12, 2) }}   as coste_reforma_estimado,
        {{ clean_decimal('gastos_compra_estimados_raw', 12, 2) }}  as gastos_compra_estimados,
        {{ clean_decimal('precio_venta_estimado_raw', 12, 2) }}    as precio_venta_estimado,

        -- Conversión de días a número entero
        {{ clean_integer('tiempo_reforma_estimado_dias_raw') }}    as tiempo_reforma_estimado_dias,
        {{ clean_integer('tiempo_venta_estimado_dias_raw') }}      as tiempo_venta_estimado_dias,

        case
            when decision_inversion_clean in ('aprobada', 'aprobado', 'ok', 'sí invertir', 'si invertir')       then 'APROBADA'
            when decision_inversion_clean in ('rechazada', 'no', 'descartada', 'no interesa')                   then 'RECHAZADA'
            when decision_inversion_clean in ('en_estudio', 'en estudio', 'pendiente', 'revisar', 'analizar')   then 'EN_ESTUDIO'
            when decision_inversion_clean in ('cancelada', 'cancelado')                                         then 'CANCELADA'
            when decision_inversion_clean in ('n/a', '-', 'desconocido', '')                                    then 'EN_ESTUDIO'
            when decision_inversion_clean is null                                                               then 'EN_ESTUDIO'
            else 'EN_ESTUDIO'
        end as decision_inversion,

        observaciones,

        -- Conversión de timestamp con macro reutilizable
        {{ clean_timestamp('cargado_en_raw') }} as cargado_en,

        origen

    from cleaned

)

select *
from final