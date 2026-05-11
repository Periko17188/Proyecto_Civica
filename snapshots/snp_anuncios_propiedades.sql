-- snp_anuncios_propiedades.sql
-- ===========================================================================
-- TIPO: Snapshot SCD Tipo 2 sobre anuncios inmobiliarios.
-- ESTRATEGIA: check.
--
-- OBJETIVO:
-- Guardar histórico de cambios relevantes en anuncios Fix & Flip.
-- Si cambia el precio, el estado del anuncio o el tipo de vendedor,
-- dbt cierra la versión anterior y crea una nueva versión vigente.
--
-- CLAVE DE NEGOCIO:
-- id_anuncio_negocio = id_portal + id_anuncio_externo
--
-- No usamos id_anuncio como unique_key porque id_anuncio representa una captura
-- concreta e incluye fecha_captura. Para snapshot necesitamos una clave estable.
--
-- COMANDO:
-- dbt snapshot --select snp_anuncios_propiedades

{% snapshot snp_anuncios_propiedades %}

{{
    config(
        unique_key = 'id_anuncio_negocio',
        strategy = 'check',
        check_cols = [
            'precio_publicado',
            'estado_anuncio',
            'vendedor_tipo'
        ],
        hard_deletes = 'new_record'
    )
}}

with anuncios_actuales as (

    select
        {{ dbt_utils.generate_surrogate_key([
            'id_portal',
            'id_anuncio_externo'
        ]) }} as id_anuncio_negocio,

        id_anuncio,
        id_propiedad,
        id_portal,
        id_anuncio_externo,
        url_anuncio,
        fecha_captura,
        titulo_anuncio,
        descripcion_anuncio,
        precio_publicado,
        vendedor_tipo,
        estado_anuncio,
        cargado_en,
        origen,

        row_number() over (
            partition by
                id_portal,
                id_anuncio_externo
            order by
                fecha_captura desc,
                cargado_en desc
        ) as rn

    from {{ ref('anuncios_propiedades') }}

)

select
    id_anuncio_negocio,
    id_anuncio,
    id_propiedad,
    id_portal,
    id_anuncio_externo,
    url_anuncio,
    fecha_captura,
    titulo_anuncio,
    descripcion_anuncio,
    precio_publicado,
    vendedor_tipo,
    estado_anuncio,
    cargado_en,
    origen

from anuncios_actuales

where rn = 1

{% endsnapshot %}