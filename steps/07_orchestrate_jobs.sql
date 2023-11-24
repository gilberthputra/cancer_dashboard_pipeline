USE ROLE ACCOUNTADMIN;
USE WAREHOUSE HOL_WH;
USE SCHEMA CANCERANALYTICS_DB.TRANSFORMED_DATA;

-- ----------------------------------------------------------------------------
-- Create the tasks to call our Python stored procedures
-- ----------------------------------------------------------------------------
SELECT * FROM CANCERANALYTICS_DB.RAW_DATA.RAW_INCIDENCE_STREAM;

CREATE OR REPLACE TASK TRANSFORM_DATA_TASK
WAREHOUSE = HOL_WH
WHEN 
    SYSTEM$STREAM_HAS_DATA('CANCERANALYTICS_DB.RAW_DATA.RAW_INCIDENCE_STREAM')
    OR
    SYSTEM$STREAM_HAS_DATA('CANCERANALYTICS_DB.RAW_DATA.RAW_MORTALITY_STREAM')
    OR
    SYSTEM$STREAM_HAS_DATA('CANCERANALYTICS_DB.RAW_DATA.RAW_TERRITORY_STREAM')
    OR
    SYSTEM$STREAM_HAS_DATA('CANCERANALYTICS_DB.RAW_DATA.RAW_SURVIVAL_STREAM')
AS
CALL TRANSFORMED_DATA.TRANSFORM_DATA_SP();

CREATE OR REPLACE TASK UPDATE_DIMENSION_TASK
WAREHOUSE = HOL_WH
AFTER TRANSFORM_DATA_TASK
AS
CALL TRANSFORMED_DATA.UPDATE_DIMENSION_SP();

CREATE OR REPLACE TASK UPDATE_FACT_TASK
WAREHOUSE = HOL_WH
AFTER UPDATE_DIMENSION_TASK
AS
CALL TRANSFORMED_DATA.UPDATE_FACT_SP();

-- ----------------------------------------------------------------------------
-- Execute the tasks
-- ----------------------------------------------------------------------------

EXECUTE TASK TRANSFORM_DATA_TASK;
ALTER TASK UPDATE_DIMENSION_TASK RESUME;
ALTER TASK UPDATE_FACT_TASK RESUME;

DROP TASK TRANSFORM_DATA_TASK;
DROP TASK UPDATE_DIMENSION_TASK;
DROP TASK UPDATE_FACT_TASK;