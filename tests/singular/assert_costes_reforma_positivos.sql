-- Este test falla si hay costes de reforma por m2 menores o iguales a cero.

select
    id_coste_reforma,
    coste_estimado_m2

from {{ ref('costes_reforma') }}

where coste_estimado_m2 is not null
  and coste_estimado_m2 <= 0