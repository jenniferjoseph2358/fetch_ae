-- informed by set_up file in identifying the fields if they had more layers within them 
-- took a second revision after flattening the blob to understand appropriate data types to use 

create or replace table stg_users as 

with base as (
    select 
        json, 
        replace(trim(json:_id:"$oid"), '"', '') as id, 
        replace(trim(json:active), '"', '') as active, 
        replace(trim(json:createdDate:"$date"), '"', '') as createdDate, 
        replace(trim(json:lastLogin:"$date"), '"', '') as lastLogin, 
        replace(trim(json:role), '"', '') as role, 
        replace(trim(json:signUpSource), '"', '') as signUpSource, 
        replace(trim(json:state), '"', '') as state
    from users 
)
, base_cleaned as (
    select 
        id as user_id,
        to_timestamp(createdDate::int/1000) as user_created_account_at, --> timezone? 
        to_timestamp(lastLogin::int/1000) as user_most_recent_app_login_at, --> timezone? 
        role as user_role, -- consumer or fetch-staff 
        signUpSource as user_sign_up_source, 
        active::boolean as is_user_active_fetch_only, ----> rethink name from schema 
        UPPER(state) as user_state,
        ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY user_created_account_at) as user_discriminant -- introduced because of data quality investigation
    from base 
)
 select 
    user_id,
    user_discriminant,
    user_created_account_at,
    user_most_recent_app_login_at,
    user_role,
    user_sign_up_source, -- not included in schema given? was unsure if I should include all or what was listened 
    is_user_active_fetch_only,
    user_state
from base_cleaned ;

-- Area of Improvement:
-- Iterate through the columns parsed out above in a loop, rather than writing each one out in the base CTE 
-- I have some light exposure to doing so with jinja in dbt, but could not resolve an error throwing here when trying to use execute() 
-- could store the table generated in the set_up file as a file to reference or have a hard-coded list maintained my the developers within this model so that we are aware of new fields and data types being introduced

-- light QA in addition to the Data Quality inspection for part 3 

select count(distinct user_id) distinct_users, count(*) total_rows from stg_users; -- 212 users, 495 records 
select * from stg_users order by user_id, user_discriminant limit 10; 

select
    user_id, 
    count(*) user_id_records,
    max(user_discriminant) user_id_records_alt 
from stg_users 
group by user_id 
order by 1,2,3; -- two ways to show records per "unique" ID

-- to see if all user records are duped X number of times, if one user was duped and the others weren't, etc
with user_max_count as (
    select
        user_id, 
        max(user_discriminant) user_total_rows
    from stg_users 
    group by user_id 
)
select
   user_total_rows,
   count(distinct user_id) total_users
from user_max_count
group by 1 
order by 1; 
