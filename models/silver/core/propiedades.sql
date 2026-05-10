-- Tabla Silver normalizada de propiedades.
-- Representa una propiedad física identificada a partir de los anuncios.
-- Se relaciona con zona y tipo de inmueble.

with base as (

    select
        municipio,
        barrio_zona,
        codigo_postal,
        tipo_inmueble,
        direccion_aproximada,
        superficie_m2,
        habitaciones,
        banos,
        planta,
        tiene_ascensor,
        estado_inmueble,
        fecha_captura

    from {{ ref('stg_anuncios_propiedades') }}

    where municipio is not null
      and barrio_zona is not null
      and tipo_inmueble is not null

),

propiedades_deduplicadas as (

    select
        *,
        min(fecha_captura) over (
            partition by
                municipio,
                barrio_zona,
                codigo_postal,
                tipo_inmueble,
                direccion_aproximada,
                superficie_m2,
                planta
        ) as fecha_creacion,

        row_number() over (
            partition by
                municipio,
                barrio_zona,
                codigo_postal,
                tipo_inmueble,
                direccion_aproximada,
                superficie_m2,
                planta
            order by fecha_captura desc
        ) as rn

    from base

),

final as (

    select
        {{ dbt_utils.generate_surrogate_key([
            'z.id_zona',
            't.id_tipo_inmueble',
            'p.direccion_aproximada',
            'p.superficie_m2',
            'p.planta'
        ]) }} as id_propiedad,

        z.id_zona,
        t.id_tipo_inmueble,

        null as referencia_catastral,

        p.direccion_aproximada,
        p.superficie_m2,
        p.habitaciones,
        p.banos,
        p.planta,
        p.tiene_ascensor,
        p.estado_inmueble,
        p.fecha_creacion

    from propiedades_deduplicadas p

    left join {{ ref('zonas') }} z
        on p.municipio = z.nombre_municipio
       and p.barrio_zona = z.nombre_zona
       and coalesce(p.codigo_postal, 'SIN_CP') = coalesce(z.codigo_postal, 'SIN_CP')

    left join {{ ref('tipos_inmueble') }} t
        on p.tipo_inmueble = t.nombre_tipo_inmueble

    where p.rn = 1
      and z.id_zona is not null
      and t.id_tipo_inmueble is not null

)

select *
from final