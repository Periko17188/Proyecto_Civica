-- dim_decision_inversion.sql
-- ============================================================================
-- CAPA: Gold
-- MATERIALIZACIÓN: table
--
-- OBJETIVO:
-- Dimensión de decisiones de inversión para clasificar operaciones Fix & Flip.
-- Se crea como catálogo controlado con los estados posibles del negocio.

{{ config(materialized='table') }}

with decisiones as (

    select
        'NO_ANALIZADO' as decision_inversion,
        'Anuncio capturado sin análisis de inversión realizado por el equipo' as descripcion

    union all

    select
        'EN_ESTUDIO' as decision_inversion,
        'Operación pendiente de análisis o revisión' as descripcion

    union all

    select
        'APROBADA' as decision_inversion,
        'Operación viable para invertir' as descripcion

    union all

    select
        'RECHAZADA' as decision_inversion,
        'Operación descartada por no cumplir criterios de inversión' as descripcion

    union all

    select
        'CANCELADA' as decision_inversion,
        'Operación cancelada antes de completarse' as descripcion

),

final as (

    select
        {{ dbt_utils.generate_surrogate_key(['decision_inversion']) }} as id_decision,

        decision_inversion,
        descripcion

    from decisiones

)

select *
from final