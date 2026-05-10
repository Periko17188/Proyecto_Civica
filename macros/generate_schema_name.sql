-- Esta macro controla en qué schema se crea cada modelo.
-- Evita que dbt añada automáticamente el schema personal delante.
-- Así podemos crear los modelos directamente en SQL_DATOS.

{% macro generate_schema_name(custom_schema_name, node) -%}

{%- set default_schema = target.schema -%}

{%- if custom_schema_name is not none -%}
    {{ custom_schema_name | trim }}
{%- else -%}
    {{ default_schema }}
{%- endif -%}
{%- endmacro %}