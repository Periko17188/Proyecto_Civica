{% macro normalizar_municipio(campo) -%}

case
    when {{ campo }} in ('granada', 'graná')                         then 'Granada'
    when {{ campo }} = 'maracena'                                    then 'Maracena'
    when {{ campo }} in ('armilla', 'armila')                        then 'Armilla'
    when {{ campo }} = 'albolote'                                    then 'Albolote'
    when {{ campo }} in ('churriana', 'churriana de la vega')        then 'Churriana de la Vega'
    when {{ campo }} in ('gabias', 'las gabias')                     then 'Las Gabias'

    when {{ campo }} in ('almunecar', 'almuñecar', 'almuñécar')      then 'Almuñécar'
    when {{ campo }} in ('cullar', 'cúllar')                         then 'Cúllar'
    when {{ campo }} in ('cullar vega', 'cúllar vega')               then 'Cúllar Vega'
    when {{ campo }} in ('ogijares', 'ogíjares', 'ogijar', 'ogíjar') then 'Ogíjares'

    else initcap({{ campo }})
end

{%- endmacro %}


{% macro normalizar_barrio_zona(campo) -%}

case
    when {{ campo }} in ('la chana', 'la chna', 'chana') then 'La Chana'
    when {{ campo }} in ('zaidin', 'zaidín')             then 'Zaidín'
    when {{ campo }} in ('centro', 'cento')              then 'Centro'
    when {{ campo }} in ('norte', 'zona norte')          then 'Norte'
    when {{ campo }} = 'realejo'                         then 'Realejo'

    -- Barrios / zonas con tildes / variantes
    when {{ campo }} in ('albaicin', 'albaicín', 'albayzin', 'albayzín') then 'Albaicín'

    -- Almuñécar
    when {{ campo }} in (
        'centro almunecar', 'centro almuñecar', 'centro almuñécar', 'centro almunécar'
    ) then 'Centro'

    -- Centros de municipios: quitamos el nombre del municipio porque ya existe en DIM_UBICACION[MUNICIPIO]
    when {{ campo }} in (
        'centro las gabias', 'centro gabias',
        'centro ogijares', 'centro ogíjares',
        'centro cullar',  'centro cúllar',
        'centro cullar vega', 'centro cúllar vega',
        'centro guadix',
        'centro iznalloz',
        'centro maracena',
        'centro motril',
        'centro armilla',
        'centro albolote',
        'centro churriana', 'centro churriana de la vega'
    ) then 'Centro'

    else initcap({{ campo }})
end

{%- endmacro %}