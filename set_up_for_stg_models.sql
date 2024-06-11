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

-- #3: Receipts 

-- Bonus #4: Receipt Item List 