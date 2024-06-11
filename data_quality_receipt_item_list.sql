-- shows that the submitted receipts do not generate item lists 
select 
    a.receipt_rewards_status,
    count(distinct a.receipt_id) as total_receipts,
    count(distinct b.receipt_id) as total_receipts_with_receipt_item_list
from stg_receipts a
left outer join stg_rewards_receipt_item_list b on a.receipt_id = b.receipt_id
group by 1;

-- total receipts compared to total list items 
select 
    count(*) as total_records, 
    count(distinct unique_key) as total_receipt_list_items, 
    count(distinct receipt_id) as total_receipts 
from stg_rewards_receipt_item_list;

-- 100 of 679 receipts have at least one item using a coupon 
select 
    count(distinct receipt_id) as total_receipts,
    count(distinct case when receipt_item_price_after_coupon is not null then receipt_id else null end) as receipts_with_coupons
from stg_rewards_receipt_item_list
;

-- how many need review 
select 
    receipt_item_needs_fetch_review,
    count(distinct receipt_id) as total_receipts
from stg_rewards_receipt_item_list
group by 1

-- lots more to understand with amount of fields for spend / price / volume but going to skip to most important piece for  
  
-- this receipt_item_list_brands is the approach I could find for matching receipt data to brands, but as you can see this only finds a match on 82/6941 receipt line items, barely 1% 
-- if we are to use the evaluation above on brand data pulled in to receipt line items, we would need to revisit other approaches I missed or better understand why there is such a low match rate on the shared keys  
with receipt_item_list_brands as (
    select 
        b.*,
        a.*
    from stg_rewards_receipt_item_list a
    left outer join stg_brands b on a.receipt_item_barcode = b.brand_item_barcode AND coalesce(a.receipt_item_brand_code, a.receipt_item_description) = b.partner_product_brand_code
) 
select 
    count(unique_key) as total_receipt_line_items,
    (select count(unique_key) from stg_rewards_receipt_item_list) as check_for_dupes_in_cte,
    count(case when brand_id is not null then unique_key else null end) receipt_items_matched_to_brand,
    receipt_items_matched_to_brand / total_receipt_line_items as pct_matched_to_brand
from receipt_item_list_brands;
