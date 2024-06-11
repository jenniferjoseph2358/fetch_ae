------ Second: Write queries that directly answer predetermined questions from a business stakeholder
---- When creating your data model be mindful of the other requests being made by the business stakeholder. If you can capture more than two bullet points in your model while keeping it clean, efficient, and performant, that benefits you as well as your team._

-- Group 1: Calculations Aggregated by Status 
-- #1 Question: When considering average spend from receipts with 'rewardsReceiptStatus’ of ‘Accepted’ or ‘Rejected’, which is greater?
-- #2 Question: When considering total number of items purchased from receipts with 'rewardsReceiptStatus’ of ‘Accepted’ or ‘Rejected’, which is greater?

select distinct receipt_rewards_status from stg_receipts; 
-- 'Accepted' is not a current value for receipt reward statuses, would flag to stakeholders and confirm the status values they want compared 

select 
    r.receipt_rewards_status,
    avg(r.receipt_total_amount_spent) as avg_spend_by_rewards_status, -- #1
    sum(r.receipt_number_of_items_purchased) as total_number_of_purchased_items_by_rewards_status --#2 
from stg_receipts r 
group by 1 
order by 1 desc;

-- #1 Answer: When considering average spend from receipts with 'rewardsReceiptStatus’ of ‘Accepted’ or ‘Rejected’, 'Rejected' has the least average spend per receipt when compared to all other statuses (excluding null). 
-- #2 Answer: When considering total number of items purchased from receipts with 'rewardsReceiptStatus’ of ‘Accepted’ or ‘Rejected’, 'Rejected' also has the least amount of purchased items across statuses (excluding null). 

-- Additional Findings:
-- Receipts a status of "PENDING" do not capture a number of items; submitted does not capture either 
-- 48/50 of the pending receipts have total amount as 28.57
-- Flagged has some 2 major outliers, 1 receipt with 599 items and $4268 total spend, 1 with 300 items and $2084 in spend


-- Group 2: Calculations Aggregated by Brand
---- This requires Brands data to be connected with Receipts data. 

-- initial section for scrap work on finding connection between the two 
-- roughly 7000 receipt items
-- trying to find common key between receipt line items and brands 

---- when looking at receipt item list, only ~1/3 of receipts populate with a product partner ID 
select 
    count(*) total,
    count(case when receipt_item_rewards_product_partner_id is not null then unique_key else null end) has_rewards_product_partner_id,
    has_rewards_product_partner_id / total pct_with,
    count(case when receipt_item_rewards_product_partner_id is null then unique_key else null end) doesnt_have_rewards_product_partner_id,
    doesnt_have_rewards_product_partner_id / total pct_without
from stg_rewards_receipt_item_list;

-- only about 18% have a points payer id 
select 
    count(*) total,
    count(case when receipt_item_points_payer_id is not null then unique_key else null end) has_receipt_item_points_payer_id,
    has_receipt_item_points_payer_id / total pct_with,
    count(case when receipt_item_points_payer_id is null then unique_key else null end) doesnt_have_receipt_item_points_payer_id,
    doesnt_have_receipt_item_points_payer_id / total pct_without
from stg_rewards_receipt_item_list;

-- 45% with barcode here  
select 
    count(*) total,
    count(case when receipt_item_barcode is not null then unique_key else null end) has_receipt_item_barcode,
    has_receipt_item_barcode / total pct_with,
    count(case when receipt_item_barcode is null then unique_key else null end) doesnt_have_receipt_item_barcode,
    doesnt_have_receipt_item_barcode / total pct_without
from stg_rewards_receipt_item_list;

-- 47% with barcode here  
select 
    count(*) total,
    count(case when coalesce(receipt_item_barcode, receipt_item_user_flagged_barcode, receipt_item_original_meta_brite_barcode) is not null then unique_key else null end) has_receipt_item_barcode,
    has_receipt_item_barcode / total pct_with,
    count(case when coalesce(receipt_item_barcode, receipt_item_user_flagged_barcode, receipt_item_original_meta_brite_barcode) is null then unique_key else null end) doesnt_have_receipt_item_barcode,
    doesnt_have_receipt_item_barcode / total pct_without
from stg_rewards_receipt_item_list;

------ attempts at finding join key 

with test as (
    select 
        b.*,
        a.receipt_id, 
        a.receipt_item_list_index, 
        a.receipt_item_number, 
        a.receipt_item_barcode, 
        a.receipt_item_user_flagged_barcode, 
        a.receipt_item_original_meta_brite_barcode, 
        a.receipt_item_brand_code, 
        a.receipt_item_description, 
        a.receipt_item_rewards_group,
        a.receipt_item_rewards_product_partner_id,
        a.receipt_item_points_payer_id, 
        a.receipt_item_partner_item_id,
        a.unique_key 
    from stg_rewards_receipt_item_list a
    left outer join stg_brands b on 
    -- a.receipt_item_rewards_product_partner_id = b.cpg_brand_collection_id 
    ----- this does not work, seems like there is a potenital composite key. but cpg_brand_collection_id is not unique within brands, so you duplicate the matching receipt line items 
    -- a.receipt_item_barcode = b.brand_item_barcode -- only matched 89 receipts, and caused dupes on receipt item barcode = 511111704140 (PREGO and DIETCHRIS2)
    a.receipt_item_barcode = b.brand_item_barcode AND coalesce(a.receipt_item_brand_code, a.receipt_item_description) = b.partner_product_brand_code -- only matched 81 receipts, 

)
, dupes as (
select 
    unique_key
from test 
group by 1 
having count(*) > 1)

select 
    * 
from test 
where brand_id is not null order by receipt_id, receipt_item_list_index;

-- more data quality implications in data quality file 

--- FINAL APPROACH --> major callout on how little matches this produces 

with receipt_item_list_brands as (
    select 
        b.*,
        a.receipt_id, 
        a.receipt_item_list_index, 
        a.receipt_item_number, 
        a.receipt_item_barcode, 
        a.receipt_item_user_flagged_barcode, 
        a.receipt_item_original_meta_brite_barcode, 
        a.receipt_item_brand_code, 
        a.receipt_item_description, 
        a.receipt_item_rewards_group,
        a.receipt_item_rewards_product_partner_id,
        a.receipt_item_points_payer_id, 
        a.receipt_item_partner_item_id,
        a.unique_key 
    from stg_rewards_receipt_item_list a
    left outer join stg_brands b on a.receipt_item_barcode = b.brand_item_barcode AND coalesce(a.receipt_item_brand_code, a.receipt_item_description) = b.partner_product_brand_code
    where b.brand_id is not null
)
select 
    * 
from receipt_item_list_brands 
order by receipt_id, receipt_item_list_index;

-- #1: Which brand has the most spend among users who were created within the past 6 months?
-- #2: Which brand has the most transactions among users who were created within the past 6 months?

with receipt_item_list_brands as (
    select 
        b.*,
        a.*
    from stg_rewards_receipt_item_list a
    left outer join stg_brands b on a.receipt_item_barcode = b.brand_item_barcode AND coalesce(a.receipt_item_brand_code, a.receipt_item_description) = b.partner_product_brand_code
    where b.brand_id is not null
)
, max_user_created_date as ( -- note: using today's date, no user is created in last 6 months. so I used this as my point in time reference date 
    select 
      max(user_created_account_at)::date user_created_date 
    from stg_users 
    where user_discriminant = 1 
    and user_role <> 'fetch-staff' -- filter out staff and duplicate user records
)
, users_past_6_months as (
    select 
        user_id
    from stg_users 
    where user_created_account_at::date >= dateadd('month', -6, (select user_created_date from max_user_created_date))::date
        and user_discriminant = 1 
        and user_role <> 'fetch-staff'
)
, receipt_item_list_brands_users as (
    select
        a.receipt_id,
        b.receipt_user_id,
        a.brand_name,
        a.receipt_item_list_index,
        a.unique_key,
        a.receipt_item_discounted_item_price,
        a.receipt_item_final_price,
        a.receipt_item_price,
        a.receipt_item_target_price,
        a.receipt_item_needs_fetch_review,
        a.receipt_item_quantity_purchased,
        a.receipt_item_points_earned
    from receipt_item_list_brands a  
    left outer join (select receipt_id, receipt_user_id from stg_receipts) b on a.receipt_id = b.receipt_id
    where b.receipt_user_id in (select * from users_past_6_months)
    order by a.receipt_id, a.receipt_item_list_index
)
select 
    brand_name,
    sum(receipt_item_final_price * receipt_item_quantity_purchased) total_spend, -- #1
    count(distinct receipt_id) total_transactions, -- #2
    count(distinct unique_key) total_transactions_line_items -- also #2 after clarification
from receipt_item_list_brands_users
group by 1
order by 2 desc -- 3 desc
;

-- #1 Answer: Cracket Barrel Cheese has the most total spend, totaling $1,041.18, from users created within the 6 most prior to the most recently created user. Total spend here is calculated using the final item price * the quanity of that receipt item 

-- #2 Answer: Swanson and Tostitos are tied with the most transitions from this user group, defined by unique receipts with line items for those brands, with 11 total transactions. However, if you define transactions as line items, Tostitos has the most with 23 transaction line items, followed by Swanson at 11.

-- Both of these are calculated exclude fetch employees as users 
