

CREATE OR ALTER PROCEDURE PopulateVMs
AS
BEGIN
	DELETE
	FROM [dbo].[VMSizes]
END

BEGIN
	UPDATE [dbo].[loadStatus]
	SET STATUS = 2
END

BEGIN
	DECLARE @region VARCHAR(50)

	DECLARE db_cursor CURSOR
	FOR
	SELECT region
	FROM AzureRegions

	OPEN DB_cursor

	FETCH NEXT
	FROM db_cursor
	INTO @region

	WHILE @@FETCH_STATUS = 0
	BEGIN
		DECLARE @file VARCHAR(50) = 'my' + @region + '.json'
		--PRINT @file
		DECLARE @sql NVARCHAR(max) = 'insert into [dbo].[VMSizesTemp] select Name, CPU, MemoryGB, IOPS, MaxNICs, MaxDataDisks, AcceleratedNetworking,EphemeralOSDiskSupported,Region from openrowset (bulk ''' + @file + ''', data_source= ''DemoLogicApp'', single_clob) as j
CROSS APPLY openjson (j.bulkcolumn) with ([Name] char (24),CPU int,MemoryGB decimal,IOPS int,MaxNICS int, MaxDataDisks int, AcceleratedNetworking varchar(10),EphemeralOSDiskSupported varchar(10), Region varchar (64))'

		EXEC sp_executesql @sql

		FETCH NEXT
		FROM db_cursor
		INTO @region
	END

	CLOSE db_cursor

	DEALLOCATE db_cursor

	BEGIN
		DELETE
		FROM VMSizesTemp
		WHERE Region IS NULL;

		INSERT INTO VMSizes
		SELECT *
		FROM VMSizesTemp;

		DELETE
		FROM [VMSizesTemp]
	END

	BEGIN
		UPDATE [dbo].[loadStatus]
		SET STATUS = 1
	END
END

