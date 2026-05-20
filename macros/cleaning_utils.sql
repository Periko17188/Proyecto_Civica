-- Macros de limpieza reutilizables
-- ============================================================================
-- Sirven para evitar repetir la misma lógica en varios modelos.
-- Se usan dentro de los .sql con {{ nombre_macro('campo') }}.

{% macro clean_timestamp(campo) -%}

coalesce(
    try_to_timestamp_ntz({{ campo }}, 'YYYY-MM-DD HH24:MI:SS'),
    try_to_timestamp_ntz({{ campo }}, 'YYYY/MM/DD HH24:MI:SS'),
    try_to_timestamp_ntz(replace({{ campo }}, ' UTC', ''), 'YYYY-MM-DD HH24:MI:SS'),
    try_to_timestamp_ntz(replace(replace({{ campo }}, 'T', ' '), 'Z', ''), 'YYYY-MM-DD HH24:MI:SS'),
    try_to_timestamp_ntz({{ campo }})
)

{%- endmacro %}


{% macro clean_date(campo_fecha, campo_respaldo_timestamp=none) -%}

coalesce(
    case
        when {{ campo_fecha }} is null then null
        when nullif(trim({{ campo_fecha }}), '') is null then null

        -- Formato YYYYMMDD: 20250101
        when regexp_like(trim({{ campo_fecha }}), '^[0-9]{8}$')
            then try_to_date(trim({{ campo_fecha }}), 'YYYYMMDD')

        -- Formato DD/MM/YY: 01/01/25 -> 2025-01-01
        when regexp_like(trim({{ campo_fecha }}), '^[0-9]{2}[/][0-9]{2}[/][0-9]{2}$')
            then try_to_date(
                substr(trim({{ campo_fecha }}), 1, 6) || '20' || substr(trim({{ campo_fecha }}), 7, 2),
                'DD/MM/YYYY'
            )

        -- Formato DD-MM-YY: 01-01-25 -> 2025-01-01
        when regexp_like(trim({{ campo_fecha }}), '^[0-9]{2}[-][0-9]{2}[-][0-9]{2}$')
            then try_to_date(
                substr(trim({{ campo_fecha }}), 1, 6) || '20' || substr(trim({{ campo_fecha }}), 7, 2),
                'DD-MM-YYYY'
            )

        else null
    end,

    try_to_date(trim({{ campo_fecha }}), 'YYYY-MM-DD'),
    try_to_date(trim({{ campo_fecha }}), 'YYYY-M-DD'),
    try_to_date(trim({{ campo_fecha }}), 'YYYY/MM/DD'),
    try_to_date(trim({{ campo_fecha }}), 'DD/MM/YYYY'),
    try_to_date(trim({{ campo_fecha }}), 'DD-MM-YYYY'),
    try_to_date(trim({{ campo_fecha }}), 'DD-MON-YYYY')

    {%- if campo_respaldo_timestamp is not none -%}
        , to_date({{ clean_timestamp(campo_respaldo_timestamp) }})
    {%- endif -%}
)

{%- endmacro %}


{% macro clean_decimal(campo, precision=12, scale=2) -%}

{% set campo_sin_unidad = "regexp_replace(lower(trim(" ~ campo ~ ")), '(€/m2|€/m²|eur_m2|eur/m2|eur/m²|euros/m2|euros/m²|euro/m2|euro/m²|/m2|/m²|m2|m²)', '')" %}

try_to_decimal(
    case
        when {{ campo }} is null then null
        when nullif(trim({{ campo }}), '') is null then null

        -- Europeo con miles y coma decimal: 186.500,50 € -> 186500.50
        when regexp_like({{ campo_sin_unidad }}, '^[^0-9-]*[0-9]{1,3}([.][0-9]{3})+[,][0-9]+[^0-9]*$')
            then replace(
                    replace(
                        regexp_replace({{ campo_sin_unidad }}, '[^0-9,.-]', ''),
                        '.',
                        ''
                    ),
                    ',',
                    '.'
                 )

        -- Europeo con miles sin decimales: 186.500 € -> 186500
        when regexp_like({{ campo_sin_unidad }}, '^[^0-9-]*[0-9]{1,3}([.][0-9]{3})+[^0-9]*$')
            then replace(
                    regexp_replace({{ campo_sin_unidad }}, '[^0-9.-]', ''),
                    '.',
                    ''
                 )

        -- Decimal con coma: 786,94 -> 786.94
        when regexp_like({{ campo_sin_unidad }}, '.*,.*')
            then replace(
                    regexp_replace({{ campo_sin_unidad }}, '[^0-9,.-]', ''),
                    ',',
                    '.'
                 )

        -- Formato estándar: 186500.50 o 186500
        else regexp_replace({{ campo_sin_unidad }}, '[^0-9.-]', '')
    end,
    {{ precision }},
    {{ scale }}
)

{%- endmacro %}


{% macro clean_integer(campo) -%}

try_to_number(
    regexp_replace({{ campo }}, '[^0-9]', '')
)

{%- endmacro %}


{% macro clean_boolean(campo) -%}

case
    when lower(trim({{ campo }})) in ('true', '1', 'si', 'sí', 'yes', 'verdadero') then true
    when lower(trim({{ campo }})) in ('false', '0', 'no', 'falso')                 then false
    else null
end

{%- endmacro %}