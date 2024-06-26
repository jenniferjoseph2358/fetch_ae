create or replace table stg_rewards_receipt_item_list as (

with base as (
    select 
        replace(trim(json:_id:"$oid"), '"', '') as receipt_id, 
        b.index as receipt_item_list_index,
        replace(trim(b.value:itemNumber), '"', '') as itemNumber,
        concat(receipt_id,'&',receipt_item_list_index) as unique_key,
        replace(trim(b.value:barcode), '"', '') as barcode, 
        replace(trim(b.value:brandCode), '"', '') as brandCode, 
        replace(trim(b.value:description), '"', '') as description, 
        replace(trim(b.value:discountedItemPrice), '"', '') as discountedItemPrice, 
        replace(trim(b.value:finalPrice), '"', '') as finalPrice, 
        replace(trim(b.value:itemPrice), '"', '') as itemPrice,  
        coalesce(replace(trim(b.value:needsFetchReview), '"', ''),FALSE) as needsFetchReview, 
        replace(trim(b.value:needsFetchReviewReason), '"', '') as needsFetchReviewReason, 
        replace(trim(b.value:partnerItemId), '"', '') as partnerItemId, 
        replace(trim(b.value:quantityPurchased), '"', '') as quantityPurchased,
        replace(trim(b.value:rewardsGroup), '"', '') as rewardsGroup,
        replace(trim(b.value:rewardsProductPartnerId), '"', '') as rewardsProductPartnerId,
        coalesce(replace(trim(b.value:competitiveProduct), '"', ''), FALSE) as competitiveProduct,
        replace(trim(b.value:competitorRewardsGroup), '"', '') as competitorRewardsGroup,
        coalesce(replace(trim(b.value:preventTargetGapPoints), '"', ''), FALSE) as preventTargetGapPoints,
        replace(trim(b.value:userFlaggedBarcode), '"', '') as userFlaggedBarcode,
        replace(trim(b.value:userFlaggedDescription), '"', '') as userFlaggedDescription,
        coalesce(replace(trim(b.value:userFlaggedNewItem), '"', ''), FALSE) as userFlaggedNewItem,
        replace(trim(b.value:userFlaggedPrice), '"', '') as userFlaggedPrice,
        replace(trim(b.value:userFlaggedQuantity), '"', '') as userFlaggedQuantity,
        coalesce(replace(trim(b.value:deleted), '"', ''), FALSE) as deleted,
        replace(trim(b.value:originalFinalPrice), '"', '') as originalFinalPrice,
        replace(trim(b.value:originalMetaBriteDescription), '"', '') as originalMetaBriteDescription,
        replace(trim(b.value:originalMetaBriteItemPrice), '"', '') as originalMetaBriteItemPrice,
        replace(trim(b.value:originalMetaBriteQuantityPurchased), '"', '') as originalMetaBriteQuantityPurchased,
        replace(trim(b.value:metabriteCampaignId), '"', '') as metabriteCampaignId, 
        replace(trim(b.value:originalMetaBriteBarcode), '"', '') as originalMetaBriteBarcode, 
        replace(trim(b.value:originalReceiptItemText), '"', '') as originalReceiptItemText,
        replace(trim(b.value:pointsEarned), '"', '') as pointsEarned,         
        replace(trim(b.value:pointsNotAwardedReason), '"', '') as pointsNotAwardedReason,
        replace(trim(b.value:pointsPayerId), '"', '') as pointsPayerId,
        replace(trim(b.value:priceAfterCoupon), '"', '') as priceAfterCoupon,
        replace(trim(b.value:targetPrice), '"', '') as targetPrice
    from (select * from receipts where json:rewardsReceiptItemList is not null) a, -- no need to evaluate the 40% of receipt records without this
        lateral flatten (a.json:rewardsReceiptItemList) b )
, base_cleaned as (
    select
        receipt_id, 
        receipt_item_list_index,
        itemNumber as receipt_item_number,
        unique_key,
        barcode as receipt_item_barcode, 
        brandCode as receipt_item_brand_code, 
        description as receipt_item_description, 
        discountedItemPrice::double as receipt_item_discounted_item_price, 
        finalPrice::double receipt_item_final_price, 
        itemPrice::double as receipt_item_price,  
        needsFetchReview::boolean as receipt_item_needs_fetch_review, 
        needsFetchReviewReason as receipt_item_needs_fetch_review_reason, 
        partnerItemId as receipt_item_partner_item_id, 
        quantityPurchased::int as receipt_item_quantity_purchased,
        rewardsGroup as receipt_item_rewards_group,
        rewardsProductPartnerId as receipt_item_rewards_product_partner_id,
        competitiveProduct::boolean as receipt_item_is_competitive_product,
        competitorRewardsGroup as receipt_item_competitor_rewards_group,
        preventTargetGapPoints::boolean as receipt_item_prevent_target_gap_points,
        userFlaggedBarcode as receipt_item_user_flagged_barcode,
        userFlaggedDescription as receipt_item_user_flagged_description,
        userFlaggedNewItem::boolean as receipt_item_user_flagged_new_item,
        userFlaggedPrice::double as receipt_item_user_flagged_price,
        userFlaggedQuantity::number as receipt_item_user_flagged_quantity,
        originalFinalPrice::double as receipt_item_original_final_price,
        originalMetaBriteDescription as receipt_item_original_meta_brite_description,
        originalMetaBriteItemPrice::double as receipt_item_original_meta_brite_item_price,
        originalMetaBriteQuantityPurchased::number as receipt_item_original_meta_brite_quantity_purchased,
        metabriteCampaignId as receipt_item_meta_brite_campaign_id, 
        originalMetaBriteBarcode as receipt_item_original_meta_brite_barcode, 
        originalReceiptItemText as receipt_item_original_receipt_item_text,
        pointsEarned::double as receipt_item_points_earned,         
        pointsNotAwardedReason as receipt_item_points_not_awarded_reason,
        pointsPayerId as receipt_item_points_payer_id,
        priceAfterCoupon::double as receipt_item_price_after_coupon,
        targetPrice::double as receipt_item_target_price,
        deleted::boolean as receipt_item_deleted
    from base
)
select
    receipt_id, 
    receipt_item_list_index,
    receipt_item_number,
    unique_key,
    receipt_item_barcode, 
    receipt_item_brand_code, 
    receipt_item_description, 
    receipt_item_discounted_item_price, 
    receipt_item_final_price, 
    receipt_item_price,  
    receipt_item_price_after_coupon,
    receipt_item_target_price,
    receipt_item_needs_fetch_review, 
    receipt_item_needs_fetch_review_reason, 
    receipt_item_quantity_purchased,
    receipt_item_partner_item_id, 
    receipt_item_rewards_group,
    receipt_item_rewards_product_partner_id,
    receipt_item_is_competitive_product,
    receipt_item_competitor_rewards_group,
    receipt_item_prevent_target_gap_points,
    receipt_item_points_earned,         
    receipt_item_points_not_awarded_reason,
    receipt_item_points_payer_id,
    -- user flagged
    receipt_item_user_flagged_barcode,
    receipt_item_user_flagged_description,
    receipt_item_user_flagged_new_item,
    receipt_item_user_flagged_price,
    receipt_item_user_flagged_quantity,
    -- original
    receipt_item_original_final_price,
    receipt_item_original_receipt_item_text,
    receipt_item_original_meta_brite_description,
    receipt_item_original_meta_brite_item_price,
    receipt_item_original_meta_brite_quantity_purchased,
    receipt_item_meta_brite_campaign_id, 
    receipt_item_original_meta_brite_barcode, 
    receipt_item_deleted
from base_cleaned
);

-- light QA 

select unique_key from stg_rewards_receipt_item_list group by unique_key having count(*) > 1; -- none, ID is unique here

select count(*) row_count, count(distinct receipt_id) receipt_count from stg_rewards_receipt_item_list; 
-- 6,941 items on 679 receipts

select * from stg_rewards_receipt_item_list order by receipt_id, receipt_item_list_index limit 100;
