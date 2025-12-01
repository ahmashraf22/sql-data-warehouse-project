-- Removing Duplicated, nulls and whitespaces
-- crm_cust_info TABLE

INSERT INTO silver.crm_cust_info (
	cst_id,
	cst_key,
	cst_firstname,
	cst_lastname,
	cst_marital_status,
	cst_gndr,
	cst_create_date
)

SELECT
cst_id,
cst_key,
TRIM(cst_firstname) as cst_firstname,
TRIM(cst_lastname) as cst_lastname,
CASE WHEN UPPER(TRIM(cst_marital_status)) = 'M' THEN 'Married'
	 WHEN UPPER(TRIM(cst_marital_status)) = 'S' THEN 'Single' -- Removing unwanted spaces
	 ELSE 'N/A'
END AS cst_marital_status, -- Normalizing values in Marital Status Full Word
CASE WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male'
	 WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Female'
	 ELSE 'N/A'
END AS cst_gndr, -- Normalizing values in gndr Full Word
cst_create_date 
FROM (
	SELECT 
	*,
	ROW_NUMBER() OVER(PARTITION BY cst_id ORDER BY cst_create_date DESC ) as flag_last
	FROM 
	bronze.crm_cust_info
	WHERE cst_id IS NOT NULL
)t WHERE flag_last = 1; -- Selecting the newest record 

-- crm_prd_info TABLE

INSERT INTO silver.crm_prd_info (
	prd_id,
	cat_id,
	prd_key,
	prd_nm,
	prd_cost,
	prd_line,
	prd_start_dt,
	prd_end_dt
)

SELECT 
prd_id,
REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_') AS cat_id, -- Replacing so we can do joins later, Extracting product ID
SUBSTRING(prd_key, 7, LEN(prd_key)) AS prd_key, -- Extracting Product Key
prd_nm,
ISNULL(prd_cost, 0) AS prd_cost, -- Replacing Nulls with 0
CASE WHEN UPPER(TRIM(prd_line)) = 'R' THEN 'Road'
	 WHEN UPPER(TRIM(prd_line)) = 'M' THEN 'Mountain'
	 WHEN UPPER(TRIM(prd_line)) = 'S' THEN 'Other Sales'
	 WHEN UPPER(TRIM(prd_line)) = 'T' THEN 'Touring'
	ELSE 'N/A'
END AS prd_line,
CAST(prd_start_dt AS DATE) AS prd_start_dt,
CAST(LEAD(prd_start_dt) OVER(PARTITION BY prd_key ORDER BY prd_start_dt) -1 AS DATE) AS prd_end_dt
/* As we are having overlaying in the original prd_end_dt coloumn we created a new one by taking
 The leading start date minus one as en end date, also we removed the time as it's useless */ 
FROM bronze.crm_prd_info;
SELECT * FROM silver.crm_prd_info
