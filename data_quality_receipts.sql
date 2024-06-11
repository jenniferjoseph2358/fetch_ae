-- Receipts 

-- 1119 distinct receipts
select count(*), count(distinct receipt_id) from stg_receipts; 

-- all receipts have user ids
select
    case when receipt_user_id is not null then true else false end as receipt_has_user_id,
    count(*)
from stg_receipts
group by 1;

-- volume concentrated to january and february 2021, same if you sub in scanned
select
    date_trunc('month',receipt_event_created_at)::date as receipt_created_month,
    count(*) as receipt_count
from stg_receipts
group by 1
order by 1;

-- interesting drop off between created and processed 
select
    date_trunc('month',receipt_event_created_at)::date receipt_created_month,
    date_trunc('month',receipt_finished_processing_at)::date receipt_finished_processing_month,
    count(*)
from stg_receipts
group by 1,2
order by 1,2;

-- better way to look at this 
-- first validate how long the process should take (all receipts)
select avg(datediff('d',receipt_event_created_at, receipt_finished_processing_at)) as avg_days_to_process from stg_receipts;
select receipt_rewards_status, avg(datediff('d',receipt_event_created_at, receipt_finished_processing_at)) as avg_days_to_process from stg_receipts;

-- then look at it month over month --> assuming that most of these are the same receipts, big drop off in processed receipts in Feb  
with created as (
    select
        date_trunc('month',receipt_event_created_at)::date as date_month,
        count(*) as receipts_created
    from stg_receipts
    group by 1
)
, processed as (
    select
        date_trunc('month',receipt_finished_processing_at)::date as date_month,
        count(*) as receipts_processed
    from stg_receipts
    group by 1
)
select
    a.date_month,
    receipts_created,
    receipts_processed,
    receipts_processed/receipts_created as rough_estimate_pct_receipts_processed
from created a
left outer join processed b on a.date_month = b.date_month
order by 1;

-- from there see if status plays a part, and % by group 
select 
    receipt_rewards_status, 
    avg(datediff('d',receipt_event_created_at, receipt_finished_processing_at)) as avg_days_to_process,
    count(*) as receipt_count,
    receipt_count / (select count(*) from stg_receipts) as pct_of_receipts
from stg_receipts 
group by 1
order by 4,3;

-- check out points range 
select 
    avg(receipt_bonus_points_earned) as average_points_earned, 
    max(receipt_bonus_points_earned) as max_points_earned,
    min(receipt_bonus_points_earned) as min_points_earned
from stg_receipts;

--- spead of points earned; 51% of receipts without any rewards bonus points 
select 
    receipt_bonus_points_earned,
    count(*) as receipts,
    receipts / (select count(*) from stg_receipts) as pct_of_receipts
from stg_receipts
group by 1 
order by 1;

-- same with items purchased
select 
    avg(receipt_number_of_items_purchased) as average_receipt_number_of_items_purchased, 
    max(receipt_number_of_items_purchased) as max_receipt_number_of_items_purchased,
    min(receipt_number_of_items_purchased) as min_receipt_number_of_items_purchased
from stg_receipts;

--- spead of items purchased earned, grouped to 10s becuase of unique values
select 
    round(receipt_number_of_items_purchased, -1) as receipt_number_of_items_purchased_in_tens,
    count(*) as receipts,
    receipts / (select count(*) from stg_receipts) as pct_of_receipts
from stg_receipts
group by 1 
order by 2 desc;

-- same thing for amount spent as above 
-- additionally add the following for "money left on table" or group by receipt to prioritize review / action 
select 
    receipt_rewards_status,
    sum(receipt_total_amount_spent) as total_spend_in_status,
from stg_receipts
group by 1;
