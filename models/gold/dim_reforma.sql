-- dim_reforma.sql
-- ============================================================================
-- CAPA: Gold
-- MATERIALIZACIÓN: table
--
-- OBJETIVO:
-- Dimensión de reformas para analizar costes según tipo de reforma,
-- categoría de trabajo y calidad del material.

{{ config(materialized='table') }}

with costes as (

    select distinct
        id_tipo_reforma,
        id_categoria_reforma,
        calidad_material

    from {{ ref('costes_reforma') }}

    where id_tipo_reforma is not null
      and id_categoria_reforma is not null
      and calidad_material is not null

),

tipos as (

    select
        id_tipo_reforma,
        nombre_tipo_reforma,
        descripcion as descripcion_tipo_reforma

    from {{ ref('tipos_reforma') }}

),

categorias as (

    select
        id_categoria_reforma,
        nombre_categoria_reforma,
        descripcion as descripcion_categoria_reforma

    from {{ ref('categorias_reforma') }}

),

final as (

    select
        {{ dbt_utils.generate_surrogate_key([
            'c.id_tipo_reforma',
            'c.id_categoria_reforma',
            'c.calidad_material'
        ]) }} as id_reforma,

        c.id_tipo_reforma,
        t.nombre_tipo_reforma as tipo_reforma,

        c.id_categoria_reforma,
        ca.nombre_categoria_reforma as categoria_reforma,

        c.calidad_material,

        t.descripcion_tipo_reforma,
        ca.descripcion_categoria_reforma

    from costes c

    left join tipos t
        on c.id_tipo_reforma = t.id_tipo_reforma

    left join categorias ca
        on c.id_categoria_reforma = ca.id_categoria_reforma

)

select *
from final