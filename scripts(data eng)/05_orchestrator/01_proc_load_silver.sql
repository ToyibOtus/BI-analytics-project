/*
==============================================================================
Stored Procedure: Load Silver (Bronze -> Silver)
==============================================================================
Script Purpose:
	This script loads the silver layer.

Parameter: None

Usage: EXEC silver.usp_load_silver;
==============================================================================
*/
CREATE OR ALTER PROCEDURE silver.usp_load_silver AS
BEGIN
	-- Declare and map values to variables where necessary
	DECLARE
	@job_run_id INT,
	@job_name NVARCHAR(50) = 'silver.usp_load_silver',
	@job_scope NVARCHAR(50) = 'SILVER',
	@start_time DATETIME,
	@end_time DATETIME,
	@job_duration INT,
	@job_status NVARCHAR(50) = 'RUNNING';

	-- Capture start time
	SET @start_time = GETDATE();

	-- Load job-level log details into log table
	INSERT INTO metadata.etl_job_run
	(
		job_name,
		job_scope,
		start_time,
		job_status
	)
	VALUES
	(
		@job_name,
		@job_scope,
		@start_time,
		@job_status
	);
	-- Retrieve newly generated job run id
	SET @job_run_id = SCOPE_IDENTITY();

	BEGIN TRY
		-- Load silver layer
		EXEC silver.usp_load_silver_customers @job_run_id;
		EXEC silver.usp_load_silver_products @job_run_id; 
		EXEC silver.usp_load_silver_orders @job_run_id;

		-- Map values to variables in try block
		SET @end_time = GETDATE();
		SET @job_duration = DATEDIFF(second, @start_time, @end_time);
		SET @job_status = 'SUCCESSFUL';

		-- Update job-level log table on success
		UPDATE metadata.etl_job_run
			SET
				end_time = @end_time,
				job_duration_seconds = @job_duration,
				job_status = @job_status
			WHERE job_run_id = @job_run_id;
	END TRY

	BEGIN CATCH
		-- Map values to variables in catch block
		SET @end_time = GETDATE();
		SET @job_duration = DATEDIFF(second, @start_time, @end_time);
		SET @job_status = 'FAILED';

		-- Update job-level log table on failure
		UPDATE metadata.etl_job_run
			SET
				end_time = @end_time,
				job_duration_seconds = @job_duration,
				job_status = @job_status
			WHERE job_run_id = @job_run_id;

		-- Load error detail at job-level
		INSERT INTO metadata.etl_job_run_error_log
		(
			job_run_id,
			job_status,
			err_procedure,
			err_message
		)
		VALUES
		(
			@job_run_id,
			@job_status,
			ERROR_PROCEDURE(),
			ERROR_MESSAGE()
		);
	END CATCH;
END;
