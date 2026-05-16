-- Tabla Silver normalizada de anuncios de propiedades.
-- Representa cada captura histórica de un anuncio en un portal.
-- Se relaciona con propiedad física y portal inmobiliario.

with base as (

    select
        id_anuncio_externo,
        portal_origen,
        url_anuncio,
        fecha_captura,
        titulo_anuncio,
        descripcion_anuncio,
        precio_publicado,
        vendedor_tipo,
        estado_anuncio,
        municipio,
        barrio_zona,
        codigo_postal,
        tipo_inmueble,
        direccion_aproximada,
        superficie_m2,
        planta,
        cargado_en,
        origen

    from {{ ref('stg_anuncios_propiedades') }}

    where id_anuncio_externo is not null
      and portal_origen is not null
      and fecha_captura is not null

),

enriched as (

    select
        b.*,
        z.id_zona,
        t.id_tipo_inmueble,
        po.id_portal

    from base b

    left join {{ ref('zonas') }} z
        on b.municipio = z.nombre_municipio
       and b.barrio_zona = z.nombre_zona
       and coalesce(b.codigo_postal, 'SIN_CP') = coalesce(z.codigo_postal, 'SIN_CP')

    left join {{ ref('tipos_inmueble') }} t
        on b.tipo_inmueble = t.nombre_tipo_inmueble

    left join {{ ref('portales') }} po
        on b.portal_origen = po.nombre_portal

),

final as (

    select
        {{ dbt_utils.generate_surrogate_key([
            'e.id_portal',
            'e.id_anuncio_externo',
            'e.fecha_captura'
        ]) }} as id_anuncio,

        pr.id_propiedad,
        e.id_portal,
        e.id_anuncio_externo,
        e.url_anuncio,
        e.fecha_captura,
        e.titulo_anuncio,
        e.descripcion_anuncio,
        e.precio_publicado,
        e.vendedor_tipo,
        e.estado_anuncio,
        e.cargado_en,
        e.origen

    from enriched e

    left join {{ ref('propiedades') }} pr
        on e.id_zona = pr.id_zona
       and e.id_tipo_inmueble = pr.id_tipo_inmueble
       and coalesce(e.direccion_aproximada, 'SIN_DIRECCION') = coalesce(pr.direccion_aproximada, 'SIN_DIRECCION')
       and coalesce(e.superficie_m2, -1) = coalesce(pr.superficie_m2, -1)
       and coalesce(e.planta, 'SIN_PLANTA') = coalesce(pr.planta, 'SIN_PLANTA')

    -- Se descartan anuncios que no pueden relacionarse con una propiedad
    -- o portal válido, para mantener integridad referencial en Silver.
    where pr.id_propiedad is not null
      and e.id_portal is not null

)

select *
from final