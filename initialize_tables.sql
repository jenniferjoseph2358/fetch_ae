-- First, create database called FETCH with schema called PUBLIC 

-- create tables for each given entity, with a column to store the json blob from source files 
create or replace table "FETCH"."PUBLIC"."BRANDS" ( json variant ); 
create or replace table "FETCH"."PUBLIC"."USERS" ( json variant ); 
create or replace table "FETCH"."PUBLIC"."RECEIPTS" ( json variant ); 

-- I did this within snowflake, so I could navigate to these files via the GUI to load them into their respective tables
-- underlying code generated for doing so: 

COPY INTO "FETCH"."PUBLIC"."RECEIPTS"
FROM '@"FETCH"."PUBLIC"."UPLOAD_FILES_STAGE"'
FILES = ('receipts.json')
FILE_FORMAT = (
    TYPE=JSON,
    STRIP_OUTER_ARRAY=FALSE,
    REPLACE_INVALID_CHARACTERS=TRUE,
    DATE_FORMAT=AUTO,
    TIME_FORMAT=AUTO,
    TIMESTAMP_FORMAT=AUTO
)
MATCH_BY_COLUMN_NAME=NONE
ON_ERROR=ABORT_STATEMENT;

-- and repeat for other tables 
