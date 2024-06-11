create or replace table stg_brands as 

with base as (
    select 
        json, 
        replace(trim(json:_id:"$oid"), '"', '') as id, 
        replace(trim(json:barcode), '"', '') as barcode, 
        replace(trim(json:brandCode), '"', '') as brandCode, 
        replace(trim(json:category), '"', '') as category, 
        replace(trim(json:categoryCode), '"', '') as categoryCode, 
        replace(trim(json:cpg:"$id":"$oid"), '"', '') as cpg_id, -- cpg = consumer packaged goods 
        replace(trim(json:cpg:"$ref"), '"', '') as cpg_ref,  -- cpg = consumer packaged goods 
        replace(trim(json:topBrand), '"', '') as topBrand, 
        replace(trim(json:name), '"', '') as name
    from brands 
)
, base_cleaned as (
    select 
        id as brand_id,
        barcode as brand_item_barcode,
        UPPER(brandCode) as partner_product_brand_code, -- align casing 
        name as brand_name,
        category as brand_product_category, 
    --> most values of category that have a value are the same as category but with _ and upper case -> opportunity to fill in blanks? 
    -- health and wellness does not match this, because it is "Healthy" in the source code
        categoryCode as brand_category_code,
        cpg_id as cpg_brand_collection_id, -- cpg = consumer packaged goods 
        cpg_ref as cpg_brand_collection_reference, --- cpg = consumer packaged goods --> values are [Cogs, Cpgs]
        coalesce(topBrand, FALSE)::boolean as is_featured_as_top_brand -- when null, populate as false 
    from base 
)
 select 
    brand_id,
    brand_name,
    brand_item_barcode,
    partner_product_brand_code,
    brand_product_category,
    brand_category_code,
    cpg_brand_collection_id, 
    cpg_brand_collection_reference, 
    is_featured_as_top_brand 
from base_cleaned ;

-- ligh QA / validate data model design 
select 
  brand_id 
from stg_brands 
group by brand_id 
having count(*) > 1; -- none, ID is unique here

select 
  * 
from stg_brands 
order by brand_id 
limit 10;
