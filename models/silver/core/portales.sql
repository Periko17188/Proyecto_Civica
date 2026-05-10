-- Tabla Silver normalizada de portales inmobiliarios.
-- Se crea a partir de los portales detectados en los anuncios.

with portales_origen as (

    select distinct
        portal_origen as nombre_portal

    from {{ ref('stg_anuncios_propiedades') }}

    where portal_origen is not null

),

final as (

    select
        {{ dbt_utils.generate_surrogate_key(['nombre_portal']) }} as id_portal,

        nombre_portal,

        case
            when nombre_portal = 'Idealista'     then 'https://www.idealista.com'
            when nombre_portal = 'Fotocasa'      then 'https://www.fotocasa.es'
            when nombre_portal = 'Solvia'        then 'https://www.solvia.es'
            when nombre_portal = 'Servihabitat'  then 'https://www.servihabitat.com'
            when nombre_portal = 'Aliseda'       then 'https://www.alisedainmobiliaria.com'
            when nombre_portal = 'Yaencontre'    then 'https://www.yaencontre.com'
            when nombre_portal = 'Pisos.Com'     then 'https://www.pisos.com'
            when nombre_portal = 'Habitaclia'    then 'https://www.habitaclia.com'
            else null
        end as url_base,

        true as activo

    from portales_origen

)

select *
from final