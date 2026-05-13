-- Este test falla si el score de oportunidad queda fuera del rango esperado 0-10.

select
    id_oportunidad,
    score_oportunidad

from {{ ref('fct_oportunidades_fix_flip') }}

where score_oportunidad < 0
   or score_oportunidad > 10