-- dim_fecha.sql
-- ============================================================================
-- CAPA: Gold
-- MATERIALIZACIÓN: table
--
-- OBJETIVO:
-- Dimensión de fechas para análisis temporal en Power BI.
-- Genera una fila por día entre 2024 y 2030.
--
-- IMPLEMENTACIÓN:
-- Se usa dbt_utils.date_spine para crear un calendario completo.

{{ config(materialized='table') }}

with spine as (

    {{ dbt_utils.date_spine(
        datepart = "day",
        start_date = "cast('2024-01-01' as date)",
        end_date = "cast('2030-12-31' as date)"
    ) }}

),

final as (

    select
        to_number(to_char(date_day, 'YYYYMMDD')) as id_fecha,

        date_day                                 as fecha,
        year(date_day)                           as anio,
        quarter(date_day)                        as trimestre,
        month(date_day)                          as mes,
        day(date_day)                            as dia,
        weekiso(date_day)                        as semana_iso,
        dayofweekiso(date_day)                   as dia_semana_numero,

        year(date_day) * 100 + month(date_day)   as anio_mes,

        case month(date_day)
            when 1  then 'Enero'
            when 2  then 'Febrero'
            when 3  then 'Marzo'
            when 4  then 'Abril'
            when 5  then 'Mayo'
            when 6  then 'Junio'
            when 7  then 'Julio'
            when 8  then 'Agosto'
            when 9  then 'Septiembre'
            when 10 then 'Octubre'
            when 11 then 'Noviembre'
            when 12 then 'Diciembre'
        end as nombre_mes,

        case dayofweekiso(date_day)
            when 1 then 'Lunes'
            when 2 then 'Martes'
            when 3 then 'Miércoles'
            when 4 then 'Jueves'
            when 5 then 'Viernes'
            when 6 then 'Sábado'
            when 7 then 'Domingo'
        end as nombre_dia_semana,

        case
            when dayofweekiso(date_day) in (6, 7) then true
            else false
        end as es_fin_semana

    from spine

)

select *
from final