create or replace table stg_receipts as 

with base as (
    select 
        json, 
        replace(trim(json:_id:"$oid"), '"', '') as id, 
        replace(trim(json:bonusPointsEarned), '"', '') as bonusPointsEarned, 
        replace(trim(json:bonusPointsEarnedReason), '"', '') as bonusPointsEarnedReason, 
        replace(trim(json:createDate:"$date"), '"', '') as createDate, 
        replace(trim(json:dateScanned:"$date"), '"', '') as dateScanned, 
        replace(trim(json:finishedDate:"$date"), '"', '') as finishedDate, 
        replace(trim(json:modifyDate:"$date"), '"', '') as modifyDate, 
        replace(trim(json:pointsAwardedDate:"$date"), '"', '') as pointsAwardedDate, 
        replace(trim(json:purchaseDate:"$date"), '"', '') as purchaseDate, 
        replace(trim(json:pointsEarned), '"', '') as pointsEarned, 
        replace(trim(json:purchasedItemCount), '"', '')::int as purchasedItemCount, 
        replace(trim(json:rewardsReceiptStatus), '"', '') as rewardsReceiptStatus, 
        replace(trim(json:totalSpent), '"', '') as totalSpent, 
        replace(trim(json:userId), '"', '') as userId
    from receipts 
)
, base_cleaned as (
    select 
        id as receipt_id,
        bonusPointsEarned::number as receipt_bonus_points_earned, --> post completion 
        bonusPointsEarnedReason as receipt_bonus_points_earned_reason, 
        to_timestamp(createDate::int/1000) as receipt_event_created_at,  
        to_timestamp(dateScanned::int/1000) as receipt_scanned_at,  
        to_timestamp(finishedDate::int/1000) as receipt_finished_processing_at, 
        to_timestamp(modifyDate::int/1000) receipt_event_modified_at, 
        to_timestamp(pointsAwardedDate::int/1000) as receipt_awarded_points_at, 
        to_timestamp(purchaseDate::int/1000) as receipt_purchase_at, 
        pointsEarned::double as receipt_points_earned, 
        purchasedItemCount as receipt_number_of_items_purchased, 
        UPPER(rewardsReceiptStatus) as receipt_rewards_status, 
        totalSpent::double as receipt_total_amount_spent, 
        userId as receipt_user_id -- who scanned the receipt
    from base 
)
 select 
    receipt_id, 
    receipt_user_id,
    receipt_event_created_at,  
    receipt_scanned_at, 
    receipt_finished_processing_at, 
    receipt_event_modified_at, 
    receipt_awarded_points_at, 
    receipt_purchase_at, 
    receipt_bonus_points_earned,  
    receipt_bonus_points_earned_reason,
    receipt_points_earned, 
    receipt_number_of_items_purchased, 
    receipt_rewards_status, 
    receipt_total_amount_spent
from base_cleaned ;

-- light QA 
select receipt_id from stg_receipts group by receipt_id having count(*) > 1; -- none, ID is unique here

select * from stg_receipts order by receipt_id limit 10; 
