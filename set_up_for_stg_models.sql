--- investigate json structures 
-- #1: Users 
 
select count(*) from users; -- 495
select * from users limit 10; 

-- admittedly, I initially looked at example records to inform my approach for creating a table, but missed some fields after this manual first pass 
-- I revisited with the following approach so the query for would catch all columns programatically 

with flattened_json as (
    select 
        f.key as nested_key,
        case
            when is_object(f.value) then 'nested_json_object'
            when is_array(f.value) then 'nested_json_array'
        else 'primitive_value' end as value_type
    from users r,
        lateral flatten(input => parse_json(r.json)) as f
)
select 
    distinct a.nested_key, a.value_type
from flattened_json a
order by 1,2;
 
----- the value type here helps identify if the field contains another nested structure within it
-- will need to unpack the date fields and the id

-- #2: Brands 

--- Area of Improvement:
-- Can we loop again by having a "source table" where we can input user / brand / receipts instead? or create a macro to do this flattening? 

select count(*) from brands; -- 1,167
select * from brands limit 10; 

with flattened_json as (
    select 
        f.key as nested_key,
        case
            when is_object(f.value) then 'nested_json_object'
            when is_array(f.value) then 'nested_json_array'
        else 'primitive_value' end as value_type
    from brands r,
        lateral flatten(input => parse_json(r.json)) as f
)
select 
    distinct a.nested_key, a.value_type
from flattened_json a
order by 1,2;
 
-- -- will need to unpack the id again, and also cpg

-- #3: Receipts 

select count(*) from receipts; -- 1119
select * from receipts limit 10; 

with flattened_json as (
    select 
        f.key as nested_key,
        case
            when is_object(f.value) then 'nested_json_object'
            when is_array(f.value) then 'nested_json_array'
        else 'primitive_value' end as value_type
    from receipts r,
        lateral flatten(input => parse_json(r.json)) as f
)
select 
    distinct a.nested_key, a.value_type
from flattened_json a
order by 1,2;
 
-- NEW VALUE TYPE --> rewardsReceiptItemList needs to be flattened as well 

-- Bonus #4: Receipt Item List 
-- notice the slight difference for input 
with a as (
    select value as rewardsReceiptItemList_item
    from receipts,
     lateral flatten(input => PARSE_JSON(json):rewardsReceiptItemList) AS f
) 
select  
    distinct
    key AS nested_key,
    case
        when IS_OBJECT(value) then 'nested_json_object'
        when IS_ARRAY(value) then 'nested_json_array'
        else 'primitive_value'
    end as value_type,
from a, 
    lateral flatten(input => parse_json(rewardsReceiptItemList_item))
order by 1;
