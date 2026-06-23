-- Inside home database (which SQLMesh will connect to),
-- run these SQL commands to mount JakeBase over the network.

-- Enable the extension
CREATE EXTENSION postgres_fdw;

-- Tell Coffeecan where JakeBase is on the network
CREATE SERVER jakebase_server
FOREIGN DATA WRAPPER postgres_fdw
OPTIONS (host 'IP_OF_JAKEBASE', port '5432', dbname 'telegres');

-- Give Coffeecan the login credentials to JakeBase
CREATE USER MAPPING FOR current_user
SERVER jakebase_server
OPTIONS (user 'postgres', password 'YOUR_JAKEBASE_PASSWORD');

-- Import JakeBase's raw tables into a 'staging' schema on Coffeecan
IMPORT FOREIGN SCHEMA public
FROM SERVER jakebase_server
INTO staging;
