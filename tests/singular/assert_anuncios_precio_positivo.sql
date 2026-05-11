-- Este test falla si hay anuncios con precio publicado menor o igual a cero.

select
    id_anuncio,
    precio_publicado

from {{ ref('anuncios_propiedades') }}

where precio_publicado is not null
  and precio_publicado <= 0