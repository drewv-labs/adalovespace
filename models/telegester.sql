-- Inside your SQLMesh model file (e.g., models/ingest_telemetry.sql)
MODEL (
  name datalake.core_telemetry,
  kind INCREMENTAL_BY_TIME (
    time_column time_stamp
  ),
  -- After a successful run, execute this command on the FDW!
  post_hook = "TRUNCATE TABLE staging.raw_telemetry;"
);

SELECT * FROM staging.raw_telemetry;
