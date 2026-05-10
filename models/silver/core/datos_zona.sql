-- Tabla Silver core de datos de zona.
-- Relaciona indicadores socioeconómicos y cualitativos con una zona y una fecha.

with base as (

    select
        fecha_captura,
        municipio,
        barrio_zona,
        poblacion,
        renta_media,
        tasa_paro,
        tiene_servicios_cercanos,
        tiene_transporte_publico,
        tiene_colegios_cercanos,
        tiene_zonas_verdes,
        proyectos_urbanisticos,
        fuente_dato,
        cargado_en,
        origen

    from {{ ref('stg_datos_zona') }}

    where fecha_captura is not null
      and municipio is not null
      and barrio_zona is not null

),

enriched as (

    select
        b.*,
        z.id_zona

    from base b

    left join {{ ref('zonas') }} z
        on b.municipio = z.nombre_municipio
       and b.barrio_zona = z.nombre_zona

),

deduplicated as (

    select
        id_zona,
        fecha_captura,
        poblacion,
        renta_media,
        tasa_paro,
        tiene_servicios_cercanos,
        tiene_transporte_publico,
        tiene_colegios_cercanos,
        tiene_zonas_verdes,
        proyectos_urbanisticos,
        fuente_dato,
        cargado_en,
        origen,

        row_number() over (
            partition by
                id_zona,
                fecha_captura,
                fuente_dato
            order by cargado_en desc
        ) as rn

    from enriched

    where id_zona is not null

),

final as (

    select
        {{ dbt_utils.generate_surrogate_key([
            'id_zona',
            'fecha_captura',
            'fuente_dato'
        ]) }} as id_dato_zona,

        id_zona,
        fecha_captura,
        poblacion,
        renta_media,
        tasa_paro,
        tiene_servicios_cercanos,
        tiene_transporte_publico,
        tiene_colegios_cercanos,
        tiene_zonas_verdes,
        proyectos_urbanisticos,
        fuente_dato,
        cargado_en,
        origen

    from deduplicated

    where rn = 1

)

select *
from final