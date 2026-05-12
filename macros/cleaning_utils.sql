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
        when regexp_like(trim({{ campo_fecha }}), '^[0-9]{8}$')
            then try_to_date(trim({{ campo_fecha }}), 'YYYYMMDD')
        -- Formatos DD/MM/YY y DD-MM-YY → reconstruir con 20 delante
        when regexp_like(trim({{ campo_fecha }}), '^[0-9]{2}[/][0-9]{2}[/][0-9]{2}$')
            then try_to_date(
                substr(trim({{ campo_fecha }}), 1, 6) || '20' || substr(trim({{ campo_fecha }}), 7, 2),
                'DD/MM/YYYY'
            )
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

try_to_decimal(
    case
        when {{ campo }} is null then null
        when regexp_like({{ campo }}, '.*,.*')
            then replace(
                    replace(
                        regexp_replace({{ campo }}, '[^0-9,.-]', ''), '.', ''), ',', '.')
        else regexp_replace({{ campo }}, '[^0-9.-]', '')
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