CREATE PROCEDURE db_statistics 
    @p_DatabaseName NVARCHAR(MAX), 
    @p_SchemaName NVARCHAR(MAX), 
    @p_TableName NVARCHAR(MAX) = '%' 
AS 
BEGIN 
    DECLARE @COLUMN_NAME NVARCHAR(MAX); 
    DECLARE @TABLE_NAME NVARCHAR(MAX);
    DECLARE @sql NVARCHAR(MAX); 

    DECLARE table_cursor CURSOR READ_ONLY
    FOR
    SELECT TABLE_NAME
    FROM INFORMATION_SCHEMA.TABLES 
    WHERE TABLE_SCHEMA = @p_SchemaName AND TABLE_NAME LIKE @p_TableName   

    -- create a temp table to keep the results 

    CREATE TABLE ##StatsTable 
    ( 
        [Database name] NVARCHAR(MAX), 
        [Schema name] NVARCHAR(MAX), 
        [Table name] NVARCHAR(MAX), 
        [Total row count] INT, 
        [Column name] NVARCHAR(MAX),
		[Count of NULL values] INT,
		[Only UPPERCASE strings] INT,
        [Count of DISTINCT values] INT, 
        [Data type] NVARCHAR(MAX),
        [MIN value] NVARCHAR(MAX) 
    ); 

    OPEN table_cursor; 
    FETCH NEXT FROM table_cursor INTO @TABLE_NAME; 

	WHILE @@FETCH_STATUS = 0 
	BEGIN 
    -- creating cursor for each column of the table 
    DECLARE column_cursor CURSOR 
    FOR 
    SELECT COLUMN_NAME 
    FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = @p_SchemaName 
        AND TABLE_NAME = @TABLE_NAME; 

    OPEN column_cursor; 
    FETCH NEXT FROM column_cursor INTO @COLUMN_NAME; 

    -- iterate through cursor 
    WHILE @@FETCH_STATUS = 0 
    BEGIN 
        SET @sql = N' INSERT INTO ##StatsTable 
                  SELECT  
                      ''' + @p_DatabaseName + ''' AS [Database Name], 
                      ''' + @p_SchemaName + ''' AS [Schema Name], 
                      ''' + @TABLE_NAME + ''' AS [Table Name], 
                      (SELECT COUNT(*) FROM ' + QUOTENAME(@p_SchemaName) + '.' + QUOTENAME(@TABLE_NAME) + ') AS [Total row count], 
                      ''' + @COLUMN_NAME + ''' AS [Column name], 
                      (SELECT COUNT(*) FROM ' + QUOTENAME(@p_SchemaName) + '.' + QUOTENAME(@TABLE_NAME) + ' WHERE ' + QUOTENAME(@COLUMN_NAME) +' IS NULL) AS [Count of NULL values],
                      (SELECT COUNT(*) FROM ' + QUOTENAME(@p_SchemaName) + '.' + QUOTENAME(@TABLE_NAME) +  ' WHERE ' + QUOTENAME(@COLUMN_NAME) + ' = UPPER(' + QUOTENAME(@COLUMN_NAME) + ') COLLATE SQL_Latin1_General_CP1_CS_AS)  AS [Only UPPERCASE strings], 
                      (SELECT COUNT(DISTINCT ' + QUOTENAME(@COLUMN_NAME) + ') FROM ' + QUOTENAME(@p_SchemaName) + '.' + QUOTENAME(@TABLE_NAME) + ') AS [Count of DISTINCT values], 
                      ISNULL((SELECT DATA_TYPE FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = ''' + @p_SchemaName + ''' AND TABLE_NAME = ''' + @TABLE_NAME + ''' AND COLUMN_NAME = ''' + @COLUMN_NAME + '''), '''') AS "Data Type",
                      ISNULL((SELECT MIN(' + QUOTENAME(@COLUMN_NAME) + ') FROM ' + QUOTENAME(@p_SchemaName) + '.' + QUOTENAME(@TABLE_NAME) + '), '''') AS "MIN value"'; 

        -- execute the SQL 
        EXEC sp_executesql @sql;

        FETCH NEXT FROM column_cursor INTO @COLUMN_NAME; 
    END; 

    CLOSE column_cursor; 
    DEALLOCATE column_cursor; 

    FETCH NEXT FROM table_cursor INTO @TABLE_NAME; 
END; 

    CLOSE table_cursor; 
    DEALLOCATE table_cursor;

    SELECT * FROM ##StatsTable; 

    DROP TABLE ##StatsTable;
END;

