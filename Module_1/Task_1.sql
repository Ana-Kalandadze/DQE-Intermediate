	 WITH
	json_string AS
	(
		SELECT '[{"employee_id": "5181816516151", "department_id": "1", "class": "src\bin\comp\json"}, {"employee_id": "925155", "department_id": "1", "class": "src\bin\comp\json"}, {"employee_id": "815153", "department_id": "2", "class": "src\bin\comp\json"}, {"employee_id": "967", "department_id": "", "class": "src\bin\comp\json"}]' [str]
	),
	json_to_table as 
	( 
	SELECT 
	     try_cast(SUBSTRING(str,
          CHARINDEX('"employee_id": "', str) + LEN('"employee_id": "'), 
          CHARINDEX('"', str, CHARINDEX('"employee_id": "', str) + LEN('"employee_id": "')) - 
          (CHARINDEX('"employee_id": "', str) + LEN('"employee_id": "'))
         )  as BIGINT) [employee_id],
	     try_cast(SUBSTRING(str,
          CHARINDEX('"department_id": "', str) + LEN('"department_id": "'), 
          CHARINDEX('"', str, CHARINDEX('"department_id": "', str) + LEN('"department_id": "')) - 
          (CHARINDEX('"department_id": "', str) + LEN('"department_id": "'))
         ) as INT) [department_id],
		SUBSTRING(str, CHARINDEX('"department_id": "', str) + LEN('"department_id": "'), LEN(str)) [remaining_data]

     FROM json_string
              
       UNION ALL

	 SELECT 
	    TRY_CAST(SUBSTRING(remaining_data,
          CHARINDEX('"employee_id": "', remaining_data) + LEN('"employee_id": "'), 
          CHARINDEX('"', remaining_data, CHARINDEX('"employee_id": "', remaining_data) + LEN('"employee_id": "')) - 
          (CHARINDEX('"employee_id": "', remaining_data) + LEN('"employee_id": "'))
         ) AS BIGINT) [employee_id],
	     TRY_CAST(SUBSTRING(remaining_data,
          CHARINDEX('"department_id": "', remaining_data) + LEN('"department_id": "'), 
          CHARINDEX('"', remaining_data, CHARINDEX('"department_id": "', remaining_data) + LEN('"department_id": "')) - 
          (CHARINDEX('"department_id": "', remaining_data) + LEN('"department_id": "'))
         ) AS INT) [department_id],
		 SUBSTRING(remaining_data, CHARINDEX('"department_id": "', remaining_data) + LEN('"department_id": "'), LEN(remaining_data)) [remaining_data]

	 FROM json_to_table
		 WHERE (
	  SELECT
         CASE WHEN CHARINDEX('"employee_id": "', remaining_data) > 0 THEN 'True' ELSE 'False' END) =  'True'
	 ),
	 final_result as(
		SELECT CASE WHEN employee_id = 0 THEN NULL ELSE employee_id END [employee_id], 
		       CASE WHEN department_id = 0 THEN NULL ELSE  department_id END [department_id]
			   FROM json_to_table)
	SELECT [employee_id], [department_id]
	FROM final_result


