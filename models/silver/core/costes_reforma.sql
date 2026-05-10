-- Tabla Silver core de costes de reforma.
-- Relaciona cada coste con tipo de reforma, categoría y provincia.

with base as (

    select
        fecha_captura,
        tipo_reforma,
        categoria_trabajo,
        descripcion_trabajo,
        calidad_material,
        coste_estimado_m2,
        unidad_medida,
        fuente_coste,
        provincia,
        cargado_en,
        origen

    from {{ ref('stg_costes_reforma') }}

    where tipo_reforma is not null
      and categoria_trabajo is not null
      and provincia is not null

),

enriched as (

    select
        b.*,
        tr.id_tipo_reforma,
        cr.id_categoria_reforma,
        p.id_provincia

    from base b

    left join {{ ref('tipos_reforma') }} tr
        on b.tipo_reforma = tr.nombre_tipo_reforma

    left join {{ ref('categorias_reforma') }} cr
        on b.categoria_trabajo = cr.nombre_categoria_reforma

    left join {{ ref('provincias') }} p
        on b.provincia = p.nombre_provincia

),

deduplicated as (

    select
        id_tipo_reforma,
        id_categoria_reforma,
        id_provincia,
        fecha_captura,
        descripcion_trabajo,
        calidad_material,
        coste_estimado_m2,
        unidad_medida,
        fuente_coste,
        cargado_en,
        origen,

        row_number() over (
            partition by
                id_tipo_reforma,
                id_categoria_reforma,
                id_provincia,
                fecha_captura,
                calidad_material,
                fuente_coste
            order by cargado_en desc
        ) as rn

    from enriched

    where id_tipo_reforma is not null
      and id_categoria_reforma is not null
      and id_provincia is not null

),

final as (

    select
        {{ dbt_utils.generate_surrogate_key([
            'id_tipo_reforma',
            'id_categoria_reforma',
            'id_provincia',
            'fecha_captura',
            'calidad_material',
            'fuente_coste'
        ]) }} as id_coste_reforma,

        id_tipo_reforma,
        id_categoria_reforma,
        id_provincia,
        fecha_captura,
        descripcion_trabajo,
        calidad_material,
        coste_estimado_m2,
        unidad_medida,
        fuente_coste,
        cargado_en,
        origen

    from deduplicated

    where rn = 1

)

select *
from final