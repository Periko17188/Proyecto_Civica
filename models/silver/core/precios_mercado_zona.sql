-- Tabla Silver normalizada de precios de mercado por zona.
-- Relaciona cada precio medio con una zona, un tipo de inmueble y una fecha.

with base as (

    select
        fecha_captura,
        municipio,
        barrio_zona,
        tipo_inmueble,
        precio_medio_venta_m2,
        numero_anuncios_venta,
        fuente_dato,
        cargado_en,
        origen

    from {{ ref('stg_precios_mercado_zona') }}

    where fecha_captura is not null
      and municipio is not null
      and barrio_zona is not null
      and tipo_inmueble is not null

),

enriched as (

    select
        b.*,
        z.id_zona,
        t.id_tipo_inmueble

    from base b

    left join {{ ref('zonas') }} z
        on b.municipio = z.nombre_municipio
       and b.barrio_zona = z.nombre_zona

    left join {{ ref('tipos_inmueble') }} t
        on b.tipo_inmueble = t.nombre_tipo_inmueble

),

deduplicated as (

    select
        id_zona,
        id_tipo_inmueble,
        fecha_captura,
        precio_medio_venta_m2,
        numero_anuncios_venta,
        fuente_dato,
        cargado_en,
        origen,

        row_number() over (
            partition by
                id_zona,
                id_tipo_inmueble,
                fecha_captura,
                fuente_dato
            order by cargado_en desc
        ) as rn

    from enriched

    where id_zona is not null
      and id_tipo_inmueble is not null

),

final as (

    select
        {{ dbt_utils.generate_surrogate_key([
            'id_zona',
            'id_tipo_inmueble',
            'fecha_captura',
            'fuente_dato'
        ]) }} as id_precio_mercado,

        id_zona,
        id_tipo_inmueble,
        fecha_captura,
        precio_medio_venta_m2,
        numero_anuncios_venta,
        fuente_dato,
        cargado_en,
        origen

    from deduplicated

    where rn = 1

)

select *
from final