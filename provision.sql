-------------------------------- 0. Set up schemachange users, roles and grants --------------------------------

-- This script is provided as a sample setup to use database roles, warehouse, admin role, deploy role as an example.
-- You may choose to have your own RBAC and SCHEMACHANGE database setup depending on your organization objectives.
-- Set these to personalize your deployment
--SET SERVICE_USER_PASSWORD = '';
SET ADMIN_USER = 'ACCOUNTADMIN';
SET TARGET_DB_NAME = 'SCHEMACHANGE_POC'; -- Name of database that will have the SCHEMACHANGE Schema for change tracking.


-- Dependent Variables; Change the naming pattern if you want but not necessary
SET ADMIN_ROLE = $TARGET_DB_NAME || '_ADMIN_ROLE'; -- This role will own the database and schemas.
-- The deploy role is name with hyphen is used to allow us to test the use of hyphenated identifiers.
SET DEPLOY_ROLE = '"' || $TARGET_DB_NAME || '_DEPLOYER_ROLE"'; -- This role will be granted privileges to create objects in any schema in the database
SET SERVICE_USER = $TARGET_DB_NAME || '_SVC'; -- This user will be granted the Deploy role.
SET WAREHOUSE_NAME = $TARGET_DB_NAME || '_WH';
SET AC_U = '_AC_U_' || $WAREHOUSE_NAME;
SET AC_O = '_AC_O_' || $WAREHOUSE_NAME;

USE ROLE USERADMIN;
-- Service user used to run SCHEMACHANGE deployments
CREATE USER IF NOT EXISTS IDENTIFIER($SERVICE_USER) WITH PASSWORD=$SERVICE_USER_PASSWORD MUST_CHANGE_PASSWORD=FALSE;

-- Role granted to a human user to manage the database permissions and database roles.
CREATE ROLE IF NOT EXISTS IDENTIFIER($ADMIN_ROLE);
CREATE ROLE IF NOT EXISTS IDENTIFIER($DEPLOY_ROLE);
CREATE ROLE IF NOT EXISTS IDENTIFIER($AC_U);
CREATE ROLE IF NOT EXISTS IDENTIFIER($AC_O);
GRANT ROLE IDENTIFIER($AC_U) TO ROLE IDENTIFIER($AC_O);

-- Role hierarchy tied to SYSADMIN;
USE ROLE SECURITYADMIN;
GRANT ROLE IDENTIFIER($DEPLOY_ROLE) TO ROLE IDENTIFIER($ADMIN_ROLE);
GRANT ROLE IDENTIFIER($ADMIN_ROLE) TO ROLE SYSADMIN;

GRANT ROLE IDENTIFIER($ADMIN_ROLE) TO USER IDENTIFIER($SERVICE_USER);
--GRANT ROLE IDENTIFIER($ADMIN_ROLE) TO USER IDENTIFIER($ADMIN_USER);

USE ROLE SYSADMIN;
CREATE DATABASE IF NOT EXISTS IDENTIFIER($TARGET_DB_NAME);

USE ROLE SECURITYADMIN;
GRANT OWNERSHIP ON DATABASE IDENTIFIER($TARGET_DB_NAME) TO ROLE IDENTIFIER($ADMIN_ROLE) WITH GRANT OPTION;

USE ROLE SYSADMIN;
CREATE WAREHOUSE IF NOT EXISTS IDENTIFIER($WAREHOUSE_NAME);
USE ROLE SECURITYADMIN;
GRANT OWNERSHIP ON WAREHOUSE IDENTIFIER($WAREHOUSE_NAME) TO ROLE IDENTIFIER($ADMIN_ROLE) WITH GRANT OPTION;
GRANT USAGE ON WAREHOUSE IDENTIFIER($WAREHOUSE_NAME) TO ROLE IDENTIFIER($AC_U);
GRANT OPERATE ON WAREHOUSE IDENTIFIER($WAREHOUSE_NAME) TO ROLE IDENTIFIER($AC_O);
GRANT ROLE IDENTIFIER($AC_U) TO ROLE IDENTIFIER($DEPLOY_ROLE);

-------------------------------- 1. Create schemachange change history objects --------------------------------
--DROP DATABASE METADATA;

USE ROLE SYSADMIN;
SET SCHEMACHANGE_METADATA_DATABASE_NAME = 'METADATA';
SET SCHEMACHANGE_METADATA_SCHEMA_NAME = 'SCHEMACHANGE';
SET SCHEMACHANGE_METADATA_TABLE_NAME = 'CHANGE_HISTORY';

SET FQPATH = $SCHEMACHANGE_METADATA_DATABASE_NAME || '.' || $SCHEMACHANGE_METADATA_SCHEMA_NAME || '.' || $SCHEMACHANGE_METADATA_TABLE_NAME;

CREATE DATABASE IF NOT EXISTS IDENTIFIER($SCHEMACHANGE_METADATA_DATABASE_NAME);
CREATE SCHEMA IF NOT EXISTS IDENTIFIER($SCHEMACHANGE_METADATA_SCHEMA_NAME);
CREATE TABLE IF NOT EXISTS IDENTIFIER($FQPATH)
(
    VERSION VARCHAR
   ,DESCRIPTION VARCHAR
   ,SCRIPT VARCHAR
   ,SCRIPT_TYPE VARCHAR
   ,CHECKSUM VARCHAR
   ,EXECUTION_TIME NUMBER
   ,STATUS VARCHAR
   ,INSTALLED_BY VARCHAR
   ,INSTALLED_ON TIMESTAMP_LTZ
);

GRANT USAGE ON DATABASE METADATA TO ROLE SCHEMACHANGE_POC_DEPLOYER_ROLE WITH GRANT OPTION;
GRANT USAGE ON SCHEMA METADATA.SCHEMACHANGE TO ROLE SCHEMACHANGE_POC_DEPLOYER_ROLE WITH GRANT OPTION;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA METADATA.SCHEMACHANGE TO ROLE SCHEMACHANGE_POC_DEPLOYER_ROLE WITH GRANT OPTION;

-------------------------------- 2. Get DDL  --------------------------------

SELECT GET_DDL('DATABASE', 'SCHEMACHANGE_POC', true)