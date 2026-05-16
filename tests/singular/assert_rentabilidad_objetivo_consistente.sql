-- Falla si el booleano cumple_rentabilidad_objetivo no coincide
-- con la rentabilidad estimada calculada.

select
    id_oportunidad,
    rentabilidad_estimada_pct,
    cumple_rentabilidad_objetivo

from {{ ref('fct_oportunidades_fix_flip') }}

where rentabilidad_estimada_pct is not null
  and (
        (rentabilidad_estimada_pct >= 20 and cumple_rentabilidad_objetivo != true)
        or
        (rentabilidad_estimada_pct < 20 and cumple_rentabilidad_objetivo != false)
      )