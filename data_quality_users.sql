-- ACROSS ALL TABLES -- WHAT IS THE TIMEZONE FOR ANY DATETIME FIELDS 

-- Users 
-- non distinct ID 
select count(*) as total, count(distinct user_id) as distinct_users from stg_users ; 

-- understanding if all IDs are duped the same
with dupe_count as (
    select 
        user_id, 
        max(user_discriminant) number_of_duplicates 
    from stg_users 
    group by 1 
    having number_of_duplicates > 1
) select number_of_duplicates, count(distinct user_id) as users_in_bucket from dupe_count group by 1 order by 2 desc; 

-- ACROSS ALL TABLES -- WHAT IS THE TIMEZONE FOR ANY DATETIME FIELDS 

-- identifying 80% of users are created in Jan 2021
select 
    date_trunc('month',user_created_account_at)::date as created_month, 
    count(distinct user_id) as total_users 
from stg_users 
group by 1 
order by 1 desc; 

-- not driven by staff
select 
    date_trunc('month',user_created_account_at)::date as created_month, 
    user_role,
    count(distinct user_id) as total_users 
from stg_users 
group by 1,2
order by 1,2 desc; 

-- isolating by user role; 8 staff users out 212 total
select 
    user_role, 
    count(distinct user_id) as total_users 
from stg_users 
group by 1 
order by 2 desc; 

-- do we expect this very minimal amount from google?
select 
    user_sign_up_source, 
    count(distinct user_id) as total_users 
from stg_users 
group by 1 
order by 2 desc;

-- similar to above, is this exepcted 
select 
    user_state, 
    count(distinct user_id) as total_users 
from stg_users 
group by 1 
order by 2 desc;

-- check for impact from staff
select 
    user_state, 
    user_role,
    count(distinct user_id) as total_users 
from stg_users 
group by 1,2 
order by 1,2 desc; 

-- 436 receipts from one staff user 
select a.user_id, count(distinct b.receipt_id) total_receipts
from stg_users a
left outer join stg_receipts b on a.user_id = b.receipt_user_id
group by 1;

-- 71 of 212 users do not have a receipt 
select count(distinct a.user_id) total_users
from stg_users a
left outer join stg_receipts b on a.user_id = b.receipt_user_id
where b.receipt_id is null;
