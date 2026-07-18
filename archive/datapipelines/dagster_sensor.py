#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.10"
# dependencies = [
#     "dagster",
#     "dagster_sqlmesh",
#     "psycopg2-binary",
# ]
# ///
import psycopg2
from dagster import Definitions, RunRequest, SkipReason, sensor
from dagster_sqlmesh import SQLMeshProject

# Initialize your SQLMesh project
sqlmesh_project = SQLMeshProject(project_dir=".")

# Create a Dagster job from your SQLMesh models
ada_pipeline_job = sqlmesh_project.build_dagster_job(name="process_jakebase_telemetry")


@sensor(job=ada_pipeline_job, minimum_interval_seconds=60)
def jakebase_arrival_sensor(context):
    """
    Polls the local Coffeecan database (which reaches out to JakeBase via FDW).
    If it connects and finds new rows, it triggers the pipeline.
    """
    try:
        # Connect to Coffeecan's local Postgres database
        conn = psycopg2.connect(
            dbname="datalake", user="ada", password="your_password", host="localhost"
        )
        cur = conn.cursor()

        # Query the FDW schema pointing to JakeBase
        # We wrap it in a quick timeout so the sensor doesn't hang if Jake is offline
        cur.execute("SET statement_timeout = '2000';")
        cur.execute("SELECT count(*) FROM staging.raw_telemetry;")

        record_count = cur.fetchone()[0]
        cur.close()
        conn.close()

        # If JakeBase is plugged in AND has data, trigger the run!
        if record_count > 0:
            context.log.info(
                f"JakeBase detected! {record_count} new records found. Initiating ingest."
            )

            # The run_key ensures Dagster doesn't trigger the exact same job twice simultaneously
            return RunRequest(run_key="jakebase_sync_run", run_config={})
        else:
            return SkipReason("JakeBase is online, but no new data found.")

    except psycopg2.OperationalError:
        # JakeBase is out in the field or powered off. Normal behavior.
        return SkipReason("JakeBase is currently unreachable.")
    except Exception as e:
        context.log.error(f"Unexpected error: {e}")
        return SkipReason(f"Error checking JakeBase: {e}")


# Register everything with Dagster
defs = Definitions(
    jobs=[ada_pipeline_job],
    sensors=[jakebase_arrival_sensor],
)
