-- Esta macro controla en qué base de datos se crea cada modelo.
-- Si el modelo tiene una database personalizada, usa esa.
-- Si no, usa la database configurada en el entorno de dbt.

{% macro generate_database_name(custom_database_name, node) -%}

{%- if custom_database_name is not none -%}
    {{ custom_database_name | trim }}
{%- else -%}
    {{ target.database | trim }}
{%- endif -%}
{%- endmacro %}