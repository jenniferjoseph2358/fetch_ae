-- Brands 

-- distinct ID, 1167 total 
select count(*) as total, count(distinct brand_id) as distinct_brands from stg_brands ; 

-- 37% of brand names show as potentially test records 
select 
    count(*) as total_brands,
    count(case when lower(brand_name) ilike '%test%' then brand_id else null end) as total_test_brands,
    total_test_brands / total_brands as pct_test_brands
from stg_brands;

-- almost unique, this is related to the the issue previously identified with Prego and DietChris2
select count(*) as total, count(distinct brand_item_barcode) as distinct_barcodes from stg_brands;

with dupes as (select brand_item_barcode from stg_brands group by 1 having count(*) > 1)
select 
    * 
from stg_brands
where brand_item_barcode in (select * from dupes) 
order by brand_item_barcode;

-- this combination is unique, and was what I used for relationship to brands and receipt line items  
select brand_item_barcode, partner_product_brand_code, count(*) from stg_brands group by 1,2 having count(*) > 1;

-- brand_item_barcode is never null, but partner_product_brand_code is missing in 20% of brands -- could be problematic for receipt item matching 
select count(*) from stg_brands where brand_item_barcode is null;
select 
    count(*) as total, 
    count(case when partner_product_brand_code is null then brand_id else null end) as missing_partner_product_brand_code, 
    missing_partner_product_brand_code / total as pct_of_total
from stg_brands;

-- check out category spread 
select brand_product_category, count(*) from stg_brands group by 1 order by 2 desc;

-- check out category code spread 
select brand_category_code, count(*) from stg_brands group by 1 order by 2 desc;

-- seeing if I can plug the missing values --> matches on everything except for health and wealness 
with test as (
    select brand_category_code, brand_product_category, replace(replace(UPPER(brand_product_category), ' & ', '_AND_'), ' ', '_') test_filler_brand_category_code from stg_brands 
) 
, existing_brand_category_code as(
    select distinct brand_category_code from stg_brands
)
select 
    distinct a.brand_category_code, b.test_filler_brand_category_code
from existing_brand_category_code a 
left outer join test b on a.brand_category_code = b.test_filler_brand_category_code;

-- Top Brands
-- 31 brands of 1167 
select is_featured_as_top_brand, count(*) as total from stg_brands group by 1; 

--- would need more context on what this identifies
select 
    cpg_brand_collection_id, 
    count(distinct brand_id) brands, 
    count(distinct partner_product_brand_code) as partner_product_brand_codes
from stg_brands 
group by 1
order by 2 desc; 
