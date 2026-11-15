CREATE DATABASE IF NOT EXISTS epharmacy;

USE epharmacy;

DROP TABLE IF EXISTS raw_az;

SELECT COUNT(*) AS total_records
FROM raw_az;

DESCRIBE raw_az;

CREATE TABLE medicine_dataset_test
LIKE raw_az;

SHOW TABLES;

SHOW CREATE TABLE medicine_dataset_test;

CREATE TABLE medicine_dataset_load_test
LIKE medicine_dataset_test;

SHOW VARIABLES LIKE 'local_infile';

LOAD DATA LOCAL INFILE
'C:/Users/salil/Desktop/Project 1/medicine A-Z/medicine_dataset_utf8.csv'
INTO TABLE medicine_dataset_load_test
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES;

SELECT COUNT(*) AS total_records
FROM medicine_dataset_load_test;

SELECT * FROM medicine_dataset_load_test;

ALTER table medicine_dataset_load_test
RENAME COLUMN `price(â‚¹)` TO price;

RENAME TABLE medicine_dataset_load_test TO raw_az;

CREATE TABLE raw_250K
LIKE medicine_dataset;

SELECT * FROM raw_250k;

CREATE TABLE raw_imr
LIKE raw_imd;

SELECT * FROM raw_imr;

SHOW TABLES;

DESCRIBE raw_az;

describe raw_250K;

desc raw_imr;

USE epharmacy;

SELECT
    'A-Z Medicine' AS source,
    COUNT(*) AS total_rows,
    COUNT(DISTINCT name) AS distinct_names,
    SUM(
        name IS NULL OR TRIM(name) = ''
    ) AS missing_name_rows
FROM raw_az
UNION ALL
SELECT
    '250K Medicines',
    COUNT(*),
    COUNT(DISTINCT name),
    SUM(
        name IS NULL OR TRIM(name) = ''
    )
FROM raw_250k
UNION ALL
SELECT
    'Indian Medicine Data',
    COUNT(*),
    COUNT(DISTINCT product_name),
    SUM(
        product_name IS NULL OR TRIM(product_name) = ''
    )
FROM raw_imr;

SELECT
    'A-Z Medicine' AS source,
    COUNT(*) AS total_rows,
    SUM(price IS NULL) AS missing_prices,
    SUM(price IS NOT NULL AND price <= 0)
        AS zero_or_negative_prices,
    0 AS prices_needing_text_review,
    MIN(CASE WHEN price > 0 THEN price END)
        AS min_positive_price,
    MAX(CASE WHEN price > 0 THEN price END)
        AS max_positive_price
FROM raw_az
UNION ALL
SELECT
    'Indian Medicine Data',
    COUNT(*),
    SUM(
        product_price IS NULL
        OR TRIM(product_price) = ''
    ),
    SUM(
        CASE
            WHEN TRIM(product_price)
                 REGEXP '^-?[0-9]+([.][0-9]+)?$'
             AND CAST(TRIM(product_price) AS DECIMAL(12,2)) <= 0
            THEN 1
            ELSE 0
        END
    ),
    SUM(
        product_price IS NOT NULL
        AND TRIM(product_price) <> ''
        AND TRIM(product_price)
            NOT REGEXP '^-?[0-9]+([.][0-9]+)?$'
    ),
    MIN(
        CASE
            WHEN TRIM(product_price)
                 REGEXP '^[0-9]+([.][0-9]+)?$'
             AND CAST(TRIM(product_price) AS DECIMAL(12,2)) > 0
            THEN CAST(TRIM(product_price) AS DECIMAL(12,2))
        END
    ),
    MAX(
        CASE
            WHEN TRIM(product_price)
                 REGEXP '^[0-9]+([.][0-9]+)?$'
             AND CAST(TRIM(product_price) AS DECIMAL(12,2)) > 0
            THEN CAST(TRIM(product_price) AS DECIMAL(12,2))
        END
    )
FROM raw_imr;


SELECT
    product_price,
    COUNT(*) AS occurrences
FROM raw_imr
WHERE product_price IS NOT NULL
  AND TRIM(product_price) <> ''
GROUP BY product_price
ORDER BY occurrences DESC
LIMIT 25;


SELECT
    COUNT(*) AS total_rows,
    SUM(
        raw_price IS NULL OR TRIM(raw_price) = ''
    ) AS missing_prices,
    SUM(
        TRIM(raw_price) <> ''
        AND clean_price REGEXP '^[0-9]+([.][0-9]+)?$'
    ) AS valid_numeric_after_cleaning,
    SUM(
        TRIM(raw_price) <> ''
        AND clean_price NOT REGEXP '^[0-9]+([.][0-9]+)?$'
    ) AS still_needs_review,
    MIN(
        CASE
            WHEN clean_price REGEXP '^[0-9]+([.][0-9]+)?$'
             AND CAST(clean_price AS DECIMAL(12,2)) > 0
            THEN CAST(clean_price AS DECIMAL(12,2))
        END
    ) AS min_positive_price,
    MAX(
        CASE
            WHEN clean_price REGEXP '^[0-9]+([.][0-9]+)?$'
             AND CAST(clean_price AS DECIMAL(12,2)) > 0
            THEN CAST(clean_price AS DECIMAL(12,2))
        END
    ) AS max_positive_price
FROM (
    SELECT
        product_price AS raw_price,
        REPLACE(
            REPLACE(
                REPLACE(TRIM(product_price), '₹', ''),
                ',', ''
            ),
            ' ', ''
        ) AS clean_price
    FROM raw_imr
) AS price_check;


WITH imr_prices AS (
    SELECT
        product_name,
        product_price AS raw_price,
        REPLACE(
            REPLACE(
                REPLACE(TRIM(product_price), '₹', ''),
                ',',
                ''
            ),
            ' ',
            ''
        ) AS clean_price
    FROM raw_imr
),
nonpositive_prices AS (
    SELECT
        'A-Z Medicine' AS source,
        name AS product_name,
        CAST(price AS CHAR) AS raw_price,
        CAST(price AS DECIMAL(12,2)) AS numeric_price
    FROM raw_az
    WHERE price IS NOT NULL
      AND price <= 0
    UNION ALL
    SELECT
        'Indian Medicine Data',
        product_name,
        raw_price,
        CAST(clean_price AS DECIMAL(12,2))
    FROM imr_prices
    WHERE clean_price REGEXP '^-?[0-9]+([.][0-9]+)?$'
      AND CAST(clean_price AS DECIMAL(12,2)) <= 0
)
SELECT *
FROM nonpositive_prices
ORDER BY source, numeric_price;


SELECT
    id,
    name,
    price,
    manufacturer_name,
    type,
    pack_size_label
FROM raw_az
WHERE price IS NOT NULL
ORDER BY price DESC
LIMIT 10;


WITH cleaned_prices AS (
    SELECT
        product_name,
        product_manufactured,
        product_price,
        REPLACE(
            REPLACE(
                REPLACE(TRIM(product_price), '₹', ''),
                ',',
                ''
            ),
            ' ',
            ''
        ) AS clean_price
    FROM raw_imr
)
SELECT
    product_name,
    product_manufactured,
    product_price,
    CAST(clean_price AS DECIMAL(12,2)) AS numeric_price
FROM cleaned_prices
WHERE clean_price REGEXP '^[0-9]+([.][0-9]+)?$'
ORDER BY numeric_price DESC
LIMIT 10;


SELECT
    product_name,
    product_manufactured,
    product_price,
    COUNT(*) AS occurrences
FROM raw_imr
GROUP BY
    product_name,
    product_manufactured,
    product_price
HAVING COUNT(*) > 1
ORDER BY occurrences DESC
LIMIT 20;


SELECT
    COUNT(*) AS total_matching_rows,
    COUNT(DISTINCT sub_category) AS distinct_categories,
    COUNT(DISTINCT salt_composition) AS distinct_compositions,
    COUNT(DISTINCT medicine_desc) AS distinct_descriptions,
    COUNT(DISTINCT side_effects) AS distinct_side_effects,
    COUNT(DISTINCT CAST(drug_interactions AS CHAR))
        AS distinct_interaction_values
FROM raw_imr
WHERE product_name = 'Monocef 1gm Injection'
  AND product_manufactured = 'Aristo Pharmaceuticals Pvt Ltd'
  AND product_price = '₹51.17';
 
 
SELECT
    COUNT(*) AS total_rows,
    COUNT(sub_category) AS rows_with_category,
    COUNT(salt_composition) AS rows_with_composition,
    COUNT(medicine_desc) AS rows_with_description,
    COUNT(side_effects) AS rows_with_side_effects,
    COUNT(drug_interactions) AS rows_with_interactions
FROM raw_imr
WHERE product_name = 'Monocef 1gm Injection'
  AND product_manufactured = 'Aristo Pharmaceuticals Pvt Ltd'
  AND product_price = '₹51.17';
 
 
WITH full_record_groups AS (
    SELECT
        COUNT(*) AS occurrences
    FROM raw_imr
    GROUP BY
        sub_category,
        product_name,
        salt_composition,
        product_price,
        product_manufactured,
        medicine_desc,
        side_effects,
        CAST(drug_interactions AS CHAR)
)
SELECT
    SUM(occurrences) AS total_rows,

    COUNT(*) AS distinct_full_record_groups,

    SUM(CASE
            WHEN occurrences > 1 THEN 1
            ELSE 0
        END) AS repeated_groups,

    SUM(CASE
            WHEN occurrences > 1 THEN occurrences
            ELSE 0
        END) AS rows_in_repeated_groups,

    SUM(CASE
            WHEN occurrences > 1 THEN occurrences - 1
            ELSE 0
        END) AS excess_duplicate_rows,

    MAX(occurrences) AS highest_repeat_count

FROM full_record_groups;


WITH full_record_groups AS (
    SELECT
        COUNT(*) AS occurrences
    FROM raw_imr
    GROUP BY
        sub_category,
        product_name,
        salt_composition,
        product_price,
        product_manufactured,
        medicine_desc,
        side_effects,
        CAST(drug_interactions AS CHAR)
)
SELECT
    occurrences,
    COUNT(*) AS number_of_groups,
    SUM(occurrences) AS rows_in_these_groups,
    SUM(occurrences - 1) AS excess_copies
FROM full_record_groups
GROUP BY occurrences
ORDER BY occurrences DESC
LIMIT 15;


CREATE TABLE dedup_imr AS
SELECT
    sub_category,
    product_name,
    salt_composition,
    product_price,
    product_manufactured,
    medicine_desc,
    side_effects,
    CAST(drug_interactions AS CHAR) AS drug_interactions
FROM raw_imr
GROUP BY
    sub_category,
    product_name,
    salt_composition,
    product_price,
    product_manufactured,
    medicine_desc,
    side_effects,
    CAST(drug_interactions AS CHAR);

    
SELECT
    'Raw' AS table_name,
    COUNT(*) AS total_rows
FROM raw_imr
UNION ALL
SELECT
    'Deduplicated',
    COUNT(*)
FROM dedup_imr;

/* Out of total 195,605 original rows, only 7645 distinct full records groups are present in Indian Medicine Data*/

DROP TABLE IF EXISTS clean_imr;

CREATE TABLE clean_imr AS
SELECT
    NULLIF(TRIM(sub_category), '') AS sub_category,
    NULLIF(TRIM(product_name), '') AS product_name,
    NULLIF(TRIM(salt_composition), '') AS salt_composition,
    product_price AS price_raw,
    CASE
        WHEN product_price IS NULL
          OR TRIM(product_price) = ''
            THEN NULL
        WHEN clean_price REGEXP '^-?[0-9]+([.][0-9]+)?$'
            THEN CAST(clean_price AS DECIMAL(12,2))
        ELSE NULL
    END AS price,
    NULLIF(TRIM(product_manufactured), '') AS manufacturer,
    NULLIF(TRIM(medicine_desc), '') AS medicine_desc,
    NULLIF(TRIM(side_effects), '') AS side_effects,
    NULLIF(TRIM(drug_interactions), '') AS drug_interactions,
    CASE
        WHEN product_price IS NULL
          OR TRIM(product_price) = ''
            THEN 'MISSING'
        WHEN clean_price NOT REGEXP '^-?[0-9]+([.][0-9]+)?$'
            THEN 'INVALID_FORMAT'
        WHEN CAST(clean_price AS DECIMAL(12,2)) <= 0
            THEN 'NON_POSITIVE'
        ELSE 'VALID'
    END AS price_status
FROM (
    SELECT
        d.*,
        REPLACE(
            REPLACE(
                REPLACE(TRIM(d.product_price), '₹', ''),
                ',',
                ''
            ),
            ' ',
            ''
        ) AS clean_price
    FROM dedup_imr AS d
) AS p;



SELECT
    COUNT(*) AS total_rows,
    SUM(price_status = 'VALID') AS valid_prices,
    SUM(price_status = 'MISSING') AS missing_prices,
    SUM(price_status = 'INVALID_FORMAT') AS invalid_format_prices,
    SUM(price_status = 'NON_POSITIVE') AS nonpositive_prices,
    MIN(CASE
        WHEN price_status = 'VALID' THEN price
    END) AS minimum_valid_price,
    MAX(CASE
        WHEN price_status = 'VALID' THEN price
    END) AS maximum_valid_price
FROM clean_imr;


SELECT
    product_name,
    manufacturer,
    salt_composition,
    sub_category,
    price_raw,
    price_status
FROM clean_imr
WHERE price_status = 'MISSING'
ORDER BY product_name
LIMIT 20;



CREATE TABLE IF NOT EXISTS project_audit_log (
    step_key VARCHAR(20) PRIMARY KEY,
    step_name VARCHAR(100) NOT NULL,
    source_table VARCHAR(64) NOT NULL,
    target_table VARCHAR(64) NOT NULL,
    input_rows BIGINT NOT NULL,
    output_rows BIGINT NOT NULL,
    rows_removed BIGINT NOT NULL,
    details VARCHAR(500),
    logged_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


    
INSERT INTO project_audit_log (
    step_key,
    step_name,
    source_table,
    target_table,
    input_rows,
    output_rows,
    rows_removed,
    details
)
SELECT
    'IMR-01',
    'Full-record grouping',
    'raw_imr',
    'dedup_imr',
    r.row_count,
    d.row_count,
    r.row_count - d.row_count,
    'Grouped using all eight fields; text comparison may depend on collation.'
FROM
    (SELECT COUNT(*) AS row_count FROM raw_imr) AS r
CROSS JOIN
    (SELECT COUNT(*) AS row_count FROM dedup_imr) AS d
WHERE 1 = 1
ON DUPLICATE KEY UPDATE
    input_rows = VALUES(input_rows),
    output_rows = VALUES(output_rows),
    rows_removed = VALUES(rows_removed),
    details = VALUES(details),
    logged_at = CURRENT_TIMESTAMP;
    
    
INSERT INTO project_audit_log (
    step_key,
    step_name,
    source_table,
    target_table,
    input_rows,
    output_rows,
    rows_removed,
    details
)
SELECT
    'IMR-02',
    'Price standardisation and validation',
    'dedup_imr',
    'clean_imr',
    d.row_count,
    c.row_count,
    d.row_count - c.row_count,
    'Standardised price formatting and classified price quality; all records retained.'
FROM
    (SELECT COUNT(*) AS row_count FROM dedup_imr) AS d
CROSS JOIN
    (SELECT COUNT(*) AS row_count FROM clean_imr) AS c
WHERE NOT EXISTS (
    SELECT 1
    FROM project_audit_log
    WHERE step_key = 'IMR-02'
);



SELECT *
FROM project_audit_log
ORDER BY step_key;


WITH record_groups AS (
    SELECT
        COUNT(*) AS occurrences
    FROM raw_az
    GROUP BY
        name,
        price,
        Is_discontinued,
        manufacturer_name,
        type,
        pack_size_label,
        short_composition1,
        short_composition2
)
SELECT
    SUM(occurrences) AS total_rows,
    COUNT(*) AS distinct_record_groups,
    SUM(
        CASE WHEN occurrences > 1 THEN 1 ELSE 0 END
    ) AS repeated_groups,
    SUM(
        CASE WHEN occurrences > 1
             THEN occurrences
             ELSE 0
        END
    ) AS rows_in_repeated_groups,
    SUM(
        CASE WHEN occurrences > 1
             THEN occurrences - 1
             ELSE 0
        END
    ) AS excess_duplicate_rows,
    MAX(occurrences) AS highest_repeat_count
FROM record_groups;



SELECT
    name,
    price,
    Is_discontinued,
    manufacturer_name,
    type,
    pack_size_label,
    short_composition1,
    short_composition2,
    COUNT(*) AS occurrences,
    GROUP_CONCAT(id ORDER BY id) AS record_ids
FROM raw_az
GROUP BY
    name,
    price,
    Is_discontinued,
    manufacturer_name,
    type,
    pack_size_label,
    short_composition1,
    short_composition2
HAVING COUNT(*) > 1
ORDER BY occurrences DESC, name;



DROP TABLE IF EXISTS clean_az;

CREATE TABLE clean_az AS
SELECT
    src_id,
    product_name,
    price,
    price_status,
    discontinued_raw,
    is_discontinued,
    manufacturer,
    product_type,
    pack_size,
    composition1,
    composition2
FROM (
    SELECT
        n.*,
        ROW_NUMBER() OVER (
            PARTITION BY
                LOWER(product_name),
                price,
                LOWER(discontinued_raw),
                LOWER(manufacturer),
                LOWER(product_type),
                LOWER(pack_size),
                LOWER(composition1),
                LOWER(composition2)
            ORDER BY src_id
        ) AS rn
    FROM (
        SELECT
            p.*,
            CASE
                WHEN price IS NULL THEN 'MISSING'
                WHEN price <= 0 THEN 'NON_POSITIVE'
                ELSE 'VALID'
            END AS price_status,
            CASE
                WHEN LOWER(discontinued_raw)
                     IN ('true', '1', 'yes', 'y') THEN 1
                WHEN LOWER(discontinued_raw)
                     IN ('false', '0', 'no', 'n') THEN 0
                ELSE NULL
            END AS is_discontinued
        FROM (
            SELECT
                id AS src_id,

                NULLIF(
                    REGEXP_REPLACE(TRIM(name), '\\s+', ' '),
                    ''
                ) AS product_name,
					price,
                NULLIF(
                    REGEXP_REPLACE(TRIM(Is_discontinued), '\\s+', ' '),
                    ''
                ) AS discontinued_raw,
                NULLIF(
                    REGEXP_REPLACE(TRIM(manufacturer_name), '\\s+', ' '),
                    ''
                ) AS manufacturer,
                NULLIF(
                    REGEXP_REPLACE(TRIM(type), '\\s+', ' '),
                    ''
                ) AS product_type,
                NULLIF(
                    REGEXP_REPLACE(TRIM(pack_size_label), '\\s+', ' '),
                    ''
                ) AS pack_size,
                NULLIF(
                    REGEXP_REPLACE(TRIM(short_composition1), '\\s+', ' '),
                    ''
                ) AS composition1,
                NULLIF(
                    REGEXP_REPLACE(TRIM(short_composition2), '\\s+', ' '),
                    ''
                ) AS composition2
            FROM raw_az
        ) AS p
    ) AS n
) AS ranked
WHERE rn = 1;



SHOW TABLES LIKE 'clean_az';

SELECT COUNT(*) AS total_rows
FROM clean_az;

SELECT
    COUNT(*) AS total_rows,
    SUM(price_status = 'VALID') AS valid_prices,
    SUM(price_status = 'MISSING') AS missing_prices,
    SUM(price_status = 'NON_POSITIVE') AS nonpositive_prices,
    SUM(product_name IS NULL) AS missing_names,
    SUM(manufacturer IS NULL) AS missing_manufacturers,
    SUM(composition1 IS NULL) AS missing_composition1,
    SUM(is_discontinued IS NULL) AS unknown_discontinued_status
FROM clean_az;

INSERT INTO project_audit_log (
    step_key,
    step_name,
    source_table,
    target_table,
    input_rows,
    output_rows,
    rows_removed,
    details
)
SELECT
    'AZ-01',
    'A-Z cleaning and duplicate handling',
    'raw_az',
    'clean_az',
    r.row_count,
    c.row_count,
    r.row_count - c.row_count,
    'Standardised whitespace, grouped cleaned product attributes, retained non-positive prices with validation status.'
FROM
    (SELECT COUNT(*) AS row_count FROM raw_az) AS r
CROSS JOIN
    (SELECT COUNT(*) AS row_count FROM clean_az) AS c
WHERE NOT EXISTS (
    SELECT 1
    FROM project_audit_log AS a
    WHERE a.step_key = 'AZ-01'
);


SELECT *
FROM project_audit_log
ORDER BY step_key;


SELECT
    src_id,
    product_name,
    price,
    price_status,
    manufacturer,
    pack_size,
    composition1,
    composition2,
    discontinued_raw
FROM clean_az
WHERE price_status = 'NON_POSITIVE'
ORDER BY product_name;


WITH ranked_prices AS (
    SELECT
        price,
        ROW_NUMBER() OVER (
            ORDER BY price
        ) AS rn,
        COUNT(*) OVER () AS total_valid_prices
    FROM clean_az
    WHERE price_status = 'VALID'
)
SELECT
    COUNT(*) AS valid_price_records,
    ROUND(MIN(price), 2) AS minimum_price,
    ROUND(AVG(price), 2) AS average_price,
    ROUND(
        AVG(
            CASE
                WHEN rn IN (
                    FLOOR((total_valid_prices + 1) / 2),
                    FLOOR((total_valid_prices + 2) / 2)
                )
                THEN price
            END
        ),
        2
    ) AS median_price,
    ROUND(MAX(price), 2) AS maximum_price
FROM ranked_prices;


WITH price_quartiles AS (
    SELECT
        price,

        NTILE(4) OVER (
            ORDER BY price
        ) AS price_quartile
    FROM clean_az
    WHERE price_status = 'VALID'
)
SELECT
    price_quartile,
    CASE price_quartile
        WHEN 1 THEN 'Q1 - Lowest-price quartile'
        WHEN 2 THEN 'Q2 - Lower-middle quartile'
        WHEN 3 THEN 'Q3 - Upper-middle quartile'
        WHEN 4 THEN 'Q4 - Highest-price quartile'
    END AS price_band,
    COUNT(*) AS product_listings,
    ROUND(MIN(price), 2) AS minimum_price,
    ROUND(MAX(price), 2) AS maximum_price,
    ROUND(AVG(price), 2) AS average_price
FROM price_quartiles
GROUP BY price_quartile
ORDER BY price_quartile;


SELECT
    manufacturer,
    COUNT(*) AS total_catalogue_listings,
    SUM(price_status = 'VALID') AS valid_price_listings,
    COUNT(
        DISTINCT CASE
            WHEN price_status = 'VALID'
            THEN product_name
        END
    ) AS distinct_valid_product_names,
    ROUND(
        AVG(CASE
            WHEN price_status = 'VALID' THEN price
        END),
        2
    ) AS average_valid_price,
    ROUND(
        MIN(CASE
            WHEN price_status = 'VALID' THEN price
        END),
        2
    ) AS minimum_valid_price,
    ROUND(
        MAX(CASE
            WHEN price_status = 'VALID' THEN price
        END),
        2
    ) AS maximum_valid_price,
    SUM(CASE
        WHEN is_discontinued = 1 THEN 1
        ELSE 0
    END) AS discontinued_listings,
    ROUND(
        100.0 * SUM(
            CASE WHEN is_discontinued = 1 THEN 1 ELSE 0 END
        ) / NULLIF(COUNT(*), 0),
        2
    ) AS pct_discontinued_all_listings
FROM clean_az
WHERE manufacturer IS NOT NULL
GROUP BY manufacturer
HAVING COUNT(*) >= 100
ORDER BY total_catalogue_listings DESC
LIMIT 20;


SELECT
    manufacturer,
    product_name,
    price,
    pack_size,
    composition1,
    composition2
FROM clean_az
WHERE price_status = 'VALID'
  AND manufacturer IS NOT NULL
ORDER BY price DESC
LIMIT 20;


WITH unit_prices AS (
    SELECT
        product_name,
        manufacturer,
        composition1,
        price,
        pack_size,
        CAST(
            REGEXP_SUBSTR(pack_size, '[0-9]+')
            AS UNSIGNED
        ) AS unit_count,
        ROUND(
            price / NULLIF(
                CAST(REGEXP_SUBSTR(pack_size, '[0-9]+') AS UNSIGNED),
                0
            ),
            2
        ) AS price_per_unit
    FROM clean_az
    WHERE price_status = 'VALID'
      AND pack_size IS NOT NULL
      AND (
          LOWER(pack_size) LIKE '%tablet%'
          OR LOWER(pack_size) LIKE '%capsule%'
      )
      AND pack_size REGEXP '[0-9]+'
)
SELECT
    product_name, 
    manufacturer,
    composition1,
    COUNT(DISTINCT pack_size) AS pack_variants,
    MIN(unit_count) AS smallest_pack_units,
    MAX(unit_count) AS largest_pack_units,
    ROUND(MIN(price_per_unit), 2) AS lowest_price_per_unit,
    ROUND(MAX(price_per_unit), 2) AS highest_price_per_unit,
    ROUND(
        100 * (
            MAX(price_per_unit) - MIN(price_per_unit)
        ) / NULLIF(MIN(price_per_unit), 0),
        2
    ) AS unit_price_spread_pct
FROM unit_prices
GROUP BY
    product_name,
    manufacturer,
    composition1
HAVING COUNT(DISTINCT pack_size) >= 2
ORDER BY unit_price_spread_pct DESC
LIMIT 20;


SELECT
    src_id,
    product_name,
    manufacturer,
    composition1,
    pack_size,
    price,
    CAST(
        REGEXP_SUBSTR(pack_size, '[0-9]+')
        AS UNSIGNED
    ) AS extracted_units,
    ROUND(
        price / NULLIF(
            CAST(
                REGEXP_SUBSTR(pack_size, '[0-9]+')
                AS UNSIGNED
            ),
            0
        ),
        2
    ) AS calculated_price_per_unit
FROM clean_az
WHERE price_status = 'VALID'
  AND product_name IN (
      'Opitone 30 Tablet',
      'Zenegra Red 100mg Tablet',
      'Itacan 200mg Tablet',
      'Omey 20mg Capsule'
  )
ORDER BY product_name, extracted_units, price;


WITH unit_prices AS (
    SELECT
        src_id,
        product_name,
        manufacturer,
        composition1,
        composition2,
        price,
        pack_size,
        CAST(
            REGEXP_SUBSTR(pack_size, '[0-9]+')
            AS DECIMAL(12,3)
        ) AS unit_count,
        price / NULLIF(
            CAST(
                REGEXP_SUBSTR(pack_size, '[0-9]+')
                AS DECIMAL(12,3)
            ),
            0
        ) AS price_per_unit
    FROM clean_az
    WHERE price_status = 'VALID'
      AND pack_size IS NOT NULL
      AND (
          LOWER(pack_size) LIKE '%tablet%'
          OR LOWER(pack_size) LIKE '%capsule%'
      )
      AND pack_size REGEXP '[0-9]+'
),
pack_comparisons AS (
    SELECT
        product_name,
        manufacturer,
        composition1,
        composition2,
        COUNT(DISTINCT pack_size) AS pack_variants,
        MIN(price_per_unit) AS lowest_unit_price,
        MAX(price_per_unit) AS highest_unit_price
    FROM unit_prices
    GROUP BY
        product_name,
        manufacturer,
        composition1,
        composition2
    HAVING COUNT(DISTINCT pack_size) >= 2
)
SELECT
    product_name,
    manufacturer,
    composition1,
    pack_variants,
    ROUND(lowest_unit_price, 4) AS lowest_unit_price,
    ROUND(highest_unit_price, 4) AS highest_unit_price,
    ROUND(
        highest_unit_price / NULLIF(lowest_unit_price, 0),
        2
    ) AS unit_price_ratio,
    ROUND(
        100 * (
            highest_unit_price - lowest_unit_price
        ) / NULLIF(lowest_unit_price, 0),
        2
    ) AS unit_price_spread_pct
FROM pack_comparisons
WHERE highest_unit_price / NULLIF(lowest_unit_price, 0) >= 2
ORDER BY unit_price_ratio DESC
LIMIT 20;


SELECT
    src_id,
    product_name,
    manufacturer,
    composition1,
    composition2,
    pack_size,
    price,
    CAST(
        REGEXP_SUBSTR(pack_size, '[0-9]+')
        AS UNSIGNED
    ) AS extracted_units,
    ROUND(
        price / NULLIF(
            CAST(
                REGEXP_SUBSTR(pack_size, '[0-9]+')
                AS UNSIGNED
            ),
            0
        ),
        4
    ) AS calculated_price_per_unit
FROM clean_az
WHERE price_status = 'VALID'
  AND product_name IN (
      'Opitone 30 Tablet',
      'Zenegra Red 100mg Tablet',
      'Itacan 200mg Tablet',
      'Omey 20mg Capsule',
      'Isco 12mg Tablet'
  )
ORDER BY
    product_name,
    extracted_units,
    price;
    


CREATE OR REPLACE VIEW vw_price_pack_anomalies AS

WITH unit_prices AS (
    SELECT
        src_id,
        product_name,
        manufacturer,
        composition1,
        composition2,
        pack_size,
        price,
        CAST(
            REGEXP_SUBSTR(pack_size, '[0-9]+')
            AS UNSIGNED
        ) AS extracted_units,
        price / NULLIF(
            CAST(
                REGEXP_SUBSTR(pack_size, '[0-9]+')
                AS UNSIGNED
            ),
            0
        ) AS price_per_unit
    FROM clean_az
    WHERE price_status = 'VALID'
      AND pack_size IS NOT NULL
      AND pack_size REGEXP '[0-9]+'
      AND (
          LOWER(pack_size) LIKE '%tablet%'
          OR LOWER(pack_size) LIKE '%capsule%'
      )
),
group_stats AS (
    SELECT
        product_name,
        manufacturer,
        composition1,
        composition2,
        COUNT(DISTINCT pack_size) AS pack_variants,
        MIN(price_per_unit) AS lowest_unit_price,
        MAX(price_per_unit) AS highest_unit_price,
        MAX(price_per_unit)
            / NULLIF(MIN(price_per_unit), 0)
            AS unit_price_ratio
    FROM unit_prices
    GROUP BY
        product_name,
        manufacturer,
        composition1,
        composition2
    HAVING COUNT(DISTINCT pack_size) >= 2
       AND MAX(price_per_unit)
           / NULLIF(MIN(price_per_unit), 0) >= 2
)
SELECT
    u.src_id,
    u.product_name,
    u.manufacturer,
    u.composition1,
    u.composition2,
    u.pack_size,
    u.price,
    u.extracted_units,
    ROUND(u.price_per_unit, 4)
        AS calculated_price_per_unit,
    s.pack_variants,
    ROUND(s.lowest_unit_price, 4)
        AS lowest_unit_price,
    ROUND(s.highest_unit_price, 4)
        AS highest_unit_price,
    ROUND(s.unit_price_ratio, 2)
        AS unit_price_ratio,
    ROUND(
        100 * (
            s.highest_unit_price - s.lowest_unit_price
        ) / NULLIF(s.lowest_unit_price, 0),
        2
    ) AS unit_price_spread_pct,
    CASE
        WHEN s.unit_price_ratio >= 10
            THEN 'HIGH PRIORITY REVIEW'
        ELSE 'REVIEW'
    END AS review_priority
FROM unit_prices AS u
JOIN group_stats AS s
    ON u.product_name = s.product_name
   AND u.manufacturer <=> s.manufacturer
   AND u.composition1 <=> s.composition1
   AND u.composition2 <=> s.composition2;
   

SELECT *
FROM vw_price_pack_anomalies
ORDER BY unit_price_ratio DESC, product_name
LIMIT 50;



WITH anomaly_groups AS (
    SELECT
        product_name,
        manufacturer,
        composition1,
        composition2,
        MAX(unit_price_ratio) AS unit_price_ratio,
        MAX(unit_price_spread_pct) AS unit_price_spread_pct,
        MAX(review_priority) AS review_priority,
        COUNT(DISTINCT src_id) AS affected_records
    FROM vw_price_pack_anomalies
    GROUP BY
        product_name,
        manufacturer,
        composition1,
        composition2
)
SELECT
    review_priority,
    COUNT(*) AS flagged_product_groups,
    SUM(affected_records) AS affected_pack_records,
    ROUND(MAX(unit_price_ratio), 2) AS highest_unit_price_ratio,
    ROUND(MAX(unit_price_spread_pct), 2) AS highest_spread_pct
FROM anomaly_groups
GROUP BY review_priority
ORDER BY
    CASE review_priority
        WHEN 'HIGH PRIORITY REVIEW' THEN 1
        ELSE 2
    END;
    
-- Five product groups need higher-priority unit-price ratios of at least 10×) investigation 
-- including Opitone, Zenegra Red, Itacan, Isco and Omey.

-- Another 49 product groups need rev iew (unit-price ratio is 6.6×)

-- Flagged 109 pack records across 54 product groups */


CREATE OR REPLACE VIEW vw_price_pack_anomaly_summary AS
SELECT
    review_priority,
    COUNT(*) AS flagged_product_groups,
    SUM(affected_records) AS affected_pack_records,
    ROUND(MAX(unit_price_ratio), 2)
        AS highest_unit_price_ratio,
    ROUND(MAX(unit_price_spread_pct), 2)
        AS highest_spread_pct
FROM (
    SELECT
        composition2,
        MAX(unit_price_ratio) AS unit_price_ratio,
        product_name,
        manufacturer,
        composition1,
        MAX(unit_price_spread_pct) AS unit_price_spread_pct,
        MAX(review_priority) AS review_priority,
        COUNT(DISTINCT src_id) AS affected_records
    FROM vw_price_pack_anomalies
    GROUP BY
        product_name,
        manufacturer,
        composition1,
        composition2
) AS anomaly_groups
GROUP BY review_priority;



SELECT *
FROM vw_price_pack_anomaly_summary
ORDER BY
    CASE review_priority
        WHEN 'HIGH PRIORITY REVIEW' THEN 1
        ELSE 2
    END;
    


SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT name) AS distinct_names,
    SUM(
        name IS NULL OR TRIM(name) = ''
    ) AS missing_names,
    SUM(
        `Chemical Class` IS NULL
        OR TRIM(`Chemical Class`) = ''
    ) AS missing_chemical_class,
    SUM(
        `Therapeutic Class` IS NULL
        OR TRIM(`Therapeutic Class`) = ''
    ) AS missing_therapeutic_class,
    SUM(
        `Action Class` IS NULL
        OR TRIM(`Action Class`) = ''
    ) AS missing_action_class,
    SUM(
        `Habit Forming` IS NULL
        OR TRIM(`Habit Forming`) = ''
    ) AS missing_habit_forming,
    SUM(
        use0 IS NULL OR TRIM(use0) = ''
    ) AS missing_primary_use,
    SUM(
        substitute0 IS NULL
        OR TRIM(substitute0) = ''
    ) AS missing_first_substitute
FROM raw_250k;



SELECT
    COUNT(*) AS total_rows,
    SUM(substitute0 IS NULL OR TRIM(substitute0) = '')
        AS missing_substitute0,
    SUM(substitute1 IS NULL OR TRIM(substitute1) = '')
        AS missing_substitute1,
    SUM(substitute2 IS NULL OR TRIM(substitute2) = '')
        AS missing_substitute2,
    SUM(substitute3 IS NULL OR TRIM(substitute3) = '')
        AS missing_substitute3,
    SUM(substitute4 IS NULL OR TRIM(substitute4) = '')
        AS missing_substitute4,
    SUM(use0 IS NULL OR TRIM(use0) = '')
        AS missing_use0,
    SUM(use1 IS NULL OR TRIM(use1) = '')
        AS missing_use1,
    SUM(use2 IS NULL OR TRIM(use2) = '')
        AS missing_use2,
    SUM(use3 IS NULL OR TRIM(use3) = '')
        AS missing_use3,
    SUM(use4 IS NULL OR TRIM(use4) = '')
        AS missing_use4
FROM raw_250k;    


SELECT
    COUNT(*) AS total_records,
    SUM(
        (substitute0 IS NULL OR TRIM(substitute0) = '')
        AND (substitute1 IS NULL OR TRIM(substitute1) = '')
        AND (substitute2 IS NULL OR TRIM(substitute2) = '')
        AND (substitute3 IS NULL OR TRIM(substitute3) = '')
        AND (substitute4 IS NULL OR TRIM(substitute4) = '')
    ) AS records_without_any_substitute,
    SUM(
        (substitute0 IS NOT NULL AND TRIM(substitute0) <> '')
        OR (substitute1 IS NOT NULL AND TRIM(substitute1) <> '')
        OR (substitute2 IS NOT NULL AND TRIM(substitute2) <> '')
        OR (substitute3 IS NOT NULL AND TRIM(substitute3) <> '')
        OR (substitute4 IS NOT NULL AND TRIM(substitute4) <> '')
    ) AS records_with_at_least_one_substitute
FROM raw_250k;


SELECT
    COUNT(*) AS total_records,
    SUM(has_side_effect IS NULL)
        AS records_without_any_side_effect,
    SUM(has_side_effect IS NOT NULL)
        AS records_with_at_least_one_side_effect,
    ROUND(
        100.0 * SUM(has_side_effect IS NULL) / COUNT(*),
        2
    ) AS pct_without_any_side_effect
FROM (
    SELECT
        COALESCE(
            NULLIF(TRIM(sideEffect0), ''),
            NULLIF(TRIM(sideEffect1), ''),
            NULLIF(TRIM(sideEffect2), ''),
            NULLIF(TRIM(sideEffect3), ''),
            NULLIF(TRIM(sideEffect4), ''),
            NULLIF(TRIM(sideEffect5), ''),
            NULLIF(TRIM(sideEffect6), ''),
            NULLIF(TRIM(sideEffect7), ''),
            NULLIF(TRIM(sideEffect8), ''),
            NULLIF(TRIM(sideEffect9), ''),
            NULLIF(TRIM(sideEffect10), ''),
            NULLIF(TRIM(sideEffect11), ''),
            NULLIF(TRIM(sideEffect12), ''),
            NULLIF(TRIM(sideEffect13), ''),
            NULLIF(TRIM(sideEffect14), ''),
            NULLIF(TRIM(sideEffect15), ''),
            NULLIF(TRIM(sideEffect16), ''),
            NULLIF(TRIM(sideEffect17), ''),
            NULLIF(TRIM(sideEffect18), ''),
            NULLIF(TRIM(sideEffect19), ''),
            NULLIF(TRIM(sideEffect20), ''),
            NULLIF(TRIM(sideEffect21), ''),
            NULLIF(TRIM(sideEffect22), ''),
            NULLIF(TRIM(sideEffect23), ''),
            NULLIF(TRIM(sideEffect24), ''),
            NULLIF(TRIM(sideEffect25), ''),
            NULLIF(TRIM(sideEffect26), ''),
            NULLIF(TRIM(sideEffect27), ''),
            NULLIF(TRIM(sideEffect28), ''),
            NULLIF(TRIM(sideEffect29), ''),
            NULLIF(TRIM(sideEffect30), ''),
            NULLIF(TRIM(sideEffect31), ''),
            NULLIF(TRIM(sideEffect32), ''),
            NULLIF(TRIM(sideEffect33), ''),
            NULLIF(TRIM(sideEffect34), ''),
            NULLIF(TRIM(sideEffect35), ''),
            NULLIF(TRIM(sideEffect36), ''),
            NULLIF(TRIM(sideEffect37), ''),
            NULLIF(TRIM(sideEffect38), ''),
            NULLIF(TRIM(sideEffect39), ''),
            NULLIF(TRIM(sideEffect40), ''),
            NULLIF(TRIM(sideEffect41), '')
        ) AS has_side_effect
    FROM raw_250k
) AS side_effect_profile;

SELECT 'sideEffect0' AS column_name,
       COUNT(*) AS total_rows,
       SUM(sideEffect0 IS NULL OR TRIM(sideEffect0) = '') AS missing_rows,
       ROUND(100.0 * SUM(sideEffect0 IS NULL OR TRIM(sideEffect0) = '') / COUNT(*), 2) AS pct_missing
FROM raw_250k
UNION ALL
SELECT 'sideEffect1', COUNT(*), SUM(sideEffect1 IS NULL OR TRIM(sideEffect1) = ''), ROUND(100.0 * SUM(sideEffect1 IS NULL OR TRIM(sideEffect1) = '') / COUNT(*), 2) FROM raw_250k
UNION ALL
SELECT 'sideEffect2', COUNT(*), SUM(sideEffect2 IS NULL OR TRIM(sideEffect2) = ''), ROUND(100.0 * SUM(sideEffect2 IS NULL OR TRIM(sideEffect2) = '') / COUNT(*), 2) FROM raw_250k
UNION ALL
SELECT 'sideEffect3', COUNT(*), SUM(sideEffect3 IS NULL OR TRIM(sideEffect3) = ''), ROUND(100.0 * SUM(sideEffect3 IS NULL OR TRIM(sideEffect3) = '') / COUNT(*), 2) FROM raw_250k
UNION ALL
SELECT 'sideEffect4', COUNT(*), SUM(sideEffect4 IS NULL OR TRIM(sideEffect4) = ''), ROUND(100.0 * SUM(sideEffect4 IS NULL OR TRIM(sideEffect4) = '') / COUNT(*), 2) FROM raw_250k
UNION ALL
SELECT 'sideEffect5', COUNT(*), SUM(sideEffect5 IS NULL OR TRIM(sideEffect5) = ''), ROUND(100.0 * SUM(sideEffect5 IS NULL OR TRIM(sideEffect5) = '') / COUNT(*), 2) FROM raw_250k
UNION ALL
SELECT 'sideEffect6', COUNT(*), SUM(sideEffect6 IS NULL OR TRIM(sideEffect6) = ''), ROUND(100.0 * SUM(sideEffect6 IS NULL OR TRIM(sideEffect6) = '') / COUNT(*), 2) FROM raw_250k
UNION ALL
SELECT 'sideEffect7', COUNT(*), SUM(sideEffect7 IS NULL OR TRIM(sideEffect7) = ''), ROUND(100.0 * SUM(sideEffect7 IS NULL OR TRIM(sideEffect7) = '') / COUNT(*), 2) FROM raw_250k
UNION ALL
SELECT 'sideEffect8', COUNT(*), SUM(sideEffect8 IS NULL OR TRIM(sideEffect8) = ''), ROUND(100.0 * SUM(sideEffect8 IS NULL OR TRIM(sideEffect8) = '') / COUNT(*), 2) FROM raw_250k
UNION ALL
SELECT 'sideEffect9', COUNT(*), SUM(sideEffect9 IS NULL OR TRIM(sideEffect9) = ''), ROUND(100.0 * SUM(sideEffect9 IS NULL OR TRIM(sideEffect9) = '') / COUNT(*), 2) FROM raw_250k
UNION ALL
SELECT 'sideEffect10', COUNT(*), SUM(sideEffect10 IS NULL OR TRIM(sideEffect10) = ''), ROUND(100.0 * SUM(sideEffect10 IS NULL OR TRIM(sideEffect10) = '') / COUNT(*), 2) FROM raw_250k
UNION ALL
SELECT 'sideEffect11', COUNT(*), SUM(sideEffect11 IS NULL OR TRIM(sideEffect11) = ''), ROUND(100.0 * SUM(sideEffect11 IS NULL OR TRIM(sideEffect11) = '') / COUNT(*), 2) FROM raw_250k
UNION ALL
SELECT 'sideEffect12', COUNT(*), SUM(sideEffect12 IS NULL OR TRIM(sideEffect12) = ''), ROUND(100.0 * SUM(sideEffect12 IS NULL OR TRIM(sideEffect12) = '') / COUNT(*), 2) FROM raw_250k
UNION ALL
SELECT 'sideEffect13', COUNT(*), SUM(sideEffect13 IS NULL OR TRIM(sideEffect13) = ''), ROUND(100.0 * SUM(sideEffect13 IS NULL OR TRIM(sideEffect13) = '') / COUNT(*), 2) FROM raw_250k
UNION ALL
SELECT 'sideEffect14', COUNT(*), SUM(sideEffect14 IS NULL OR TRIM(sideEffect14) = ''), ROUND(100.0 * SUM(sideEffect14 IS NULL OR TRIM(sideEffect14) = '') / COUNT(*), 2) FROM raw_250k
UNION ALL
SELECT 'sideEffect15', COUNT(*), SUM(sideEffect15 IS NULL OR TRIM(sideEffect15) = ''), ROUND(100.0 * SUM(sideEffect15 IS NULL OR TRIM(sideEffect15) = '') / COUNT(*), 2) FROM raw_250k
UNION ALL
SELECT 'sideEffect16', COUNT(*), SUM(sideEffect16 IS NULL OR TRIM(sideEffect16) = ''), ROUND(100.0 * SUM(sideEffect16 IS NULL OR TRIM(sideEffect16) = '') / COUNT(*), 2) FROM raw_250k
UNION ALL
SELECT 'sideEffect17', COUNT(*), SUM(sideEffect17 IS NULL OR TRIM(sideEffect17) = ''), ROUND(100.0 * SUM(sideEffect17 IS NULL OR TRIM(sideEffect17) = '') / COUNT(*), 2) FROM raw_250k
UNION ALL
SELECT 'sideEffect18', COUNT(*), SUM(sideEffect18 IS NULL OR TRIM(sideEffect18) = ''), ROUND(100.0 * SUM(sideEffect18 IS NULL OR TRIM(sideEffect18) = '') / COUNT(*), 2) FROM raw_250k
UNION ALL
SELECT 'sideEffect19', COUNT(*), SUM(sideEffect19 IS NULL OR TRIM(sideEffect19) = ''), ROUND(100.0 * SUM(sideEffect19 IS NULL OR TRIM(sideEffect19) = '') / COUNT(*), 2) FROM raw_250k
UNION ALL
SELECT 'sideEffect20', COUNT(*), SUM(sideEffect20 IS NULL OR TRIM(sideEffect20) = ''), ROUND(100.0 * SUM(sideEffect20 IS NULL OR TRIM(sideEffect20) = '') / COUNT(*), 2) FROM raw_250k
ORDER BY pct_missing DESC, column_name;


SELECT 'sideEffect21' AS column_name,
       COUNT(*) AS total_rows,
       SUM(sideEffect21 IS NULL OR TRIM(sideEffect21) = '') AS missing_rows,
       ROUND(100.0 * SUM(sideEffect21 IS NULL OR TRIM(sideEffect21) = '') / COUNT(*), 2) AS pct_missing
FROM raw_250k
UNION ALL
SELECT 'sideEffect22', COUNT(*), SUM(sideEffect22 IS NULL OR TRIM(sideEffect22) = ''), ROUND(100.0 * SUM(sideEffect22 IS NULL OR TRIM(sideEffect22) = '') / COUNT(*), 2) FROM raw_250k
UNION ALL
SELECT 'sideEffect23', COUNT(*), SUM(sideEffect23 IS NULL OR TRIM(sideEffect23) = ''), ROUND(100.0 * SUM(sideEffect23 IS NULL OR TRIM(sideEffect23) = '') / COUNT(*), 2) FROM raw_250k
UNION ALL
SELECT 'sideEffect24', COUNT(*), SUM(sideEffect24 IS NULL OR TRIM(sideEffect24) = ''), ROUND(100.0 * SUM(sideEffect24 IS NULL OR TRIM(sideEffect24) = '') / COUNT(*), 2) FROM raw_250k
UNION ALL
SELECT 'sideEffect25', COUNT(*), SUM(sideEffect25 IS NULL OR TRIM(sideEffect25) = ''), ROUND(100.0 * SUM(sideEffect25 IS NULL OR TRIM(sideEffect25) = '') / COUNT(*), 2) FROM raw_250k
UNION ALL
SELECT 'sideEffect26', COUNT(*), SUM(sideEffect26 IS NULL OR TRIM(sideEffect26) = ''), ROUND(100.0 * SUM(sideEffect26 IS NULL OR TRIM(sideEffect26) = '') / COUNT(*), 2) FROM raw_250k
UNION ALL
SELECT 'sideEffect27', COUNT(*), SUM(sideEffect27 IS NULL OR TRIM(sideEffect27) = ''), ROUND(100.0 * SUM(sideEffect27 IS NULL OR TRIM(sideEffect27) = '') / COUNT(*), 2) FROM raw_250k
UNION ALL
SELECT 'sideEffect28', COUNT(*), SUM(sideEffect28 IS NULL OR TRIM(sideEffect28) = ''), ROUND(100.0 * SUM(sideEffect28 IS NULL OR TRIM(sideEffect28) = '') / COUNT(*), 2) FROM raw_250k
UNION ALL
SELECT 'sideEffect29', COUNT(*), SUM(sideEffect29 IS NULL OR TRIM(sideEffect29) = ''), ROUND(100.0 * SUM(sideEffect29 IS NULL OR TRIM(sideEffect29) = '') / COUNT(*), 2) FROM raw_250k
UNION ALL
SELECT 'sideEffect30', COUNT(*), SUM(sideEffect30 IS NULL OR TRIM(sideEffect30) = ''), ROUND(100.0 * SUM(sideEffect30 IS NULL OR TRIM(sideEffect30) = '') / COUNT(*), 2) FROM raw_250k
UNION ALL
SELECT 'sideEffect31', COUNT(*), SUM(sideEffect31 IS NULL OR TRIM(sideEffect31) = ''), ROUND(100.0 * SUM(sideEffect31 IS NULL OR TRIM(sideEffect31) = '') / COUNT(*), 2) FROM raw_250k
UNION ALL
SELECT 'sideEffect32', COUNT(*), SUM(sideEffect32 IS NULL OR TRIM(sideEffect32) = ''), ROUND(100.0 * SUM(sideEffect32 IS NULL OR TRIM(sideEffect32) = '') / COUNT(*), 2) FROM raw_250k
UNION ALL
SELECT 'sideEffect33', COUNT(*), SUM(sideEffect33 IS NULL OR TRIM(sideEffect33) = ''), ROUND(100.0 * SUM(sideEffect33 IS NULL OR TRIM(sideEffect33) = '') / COUNT(*), 2) FROM raw_250k
UNION ALL
SELECT 'sideEffect34', COUNT(*), SUM(sideEffect34 IS NULL OR TRIM(sideEffect34) = ''), ROUND(100.0 * SUM(sideEffect34 IS NULL OR TRIM(sideEffect34) = '') / COUNT(*), 2) FROM raw_250k
UNION ALL
SELECT 'sideEffect35', COUNT(*), SUM(sideEffect35 IS NULL OR TRIM(sideEffect35) = ''), ROUND(100.0 * SUM(sideEffect35 IS NULL OR TRIM(sideEffect35) = '') / COUNT(*), 2) FROM raw_250k
UNION ALL
SELECT 'sideEffect36', COUNT(*), SUM(sideEffect36 IS NULL OR TRIM(sideEffect36) = ''), ROUND(100.0 * SUM(sideEffect36 IS NULL OR TRIM(sideEffect36) = '') / COUNT(*), 2) FROM raw_250k
UNION ALL
SELECT 'sideEffect37', COUNT(*), SUM(sideEffect37 IS NULL OR TRIM(sideEffect37) = ''), ROUND(100.0 * SUM(sideEffect37 IS NULL OR TRIM(sideEffect37) = '') / COUNT(*), 2) FROM raw_250k
UNION ALL
SELECT 'sideEffect38', COUNT(*), SUM(sideEffect38 IS NULL OR TRIM(sideEffect38) = ''), ROUND(100.0 * SUM(sideEffect38 IS NULL OR TRIM(sideEffect38) = '') / COUNT(*), 2) FROM raw_250k
UNION ALL
SELECT 'sideEffect39', COUNT(*), SUM(sideEffect39 IS NULL OR TRIM(sideEffect39) = ''), ROUND(100.0 * SUM(sideEffect39 IS NULL OR TRIM(sideEffect39) = '') / COUNT(*), 2) FROM raw_250k
UNION ALL
SELECT 'sideEffect40', COUNT(*), SUM(sideEffect40 IS NULL OR TRIM(sideEffect40) = ''), ROUND(100.0 * SUM(sideEffect40 IS NULL OR TRIM(sideEffect40) = '') / COUNT(*), 2) FROM raw_250k
UNION ALL
SELECT 'sideEffect41', COUNT(*), SUM(sideEffect41 IS NULL OR TRIM(sideEffect41) = ''), ROUND(100.0 * SUM(sideEffect41 IS NULL OR TRIM(sideEffect41) = '') / COUNT(*), 2) FROM raw_250k
ORDER BY pct_missing DESC, column_name;


WITH name_groups AS (
    SELECT
        name,
        COUNT(*) AS occurrences
    FROM raw_250k
    GROUP BY name
)
SELECT
    SUM(occurrences) AS total_rows,
    COUNT(*) AS distinct_name_groups,
    SUM(occurrences > 1) AS repeated_name_groups,
    SUM(
        CASE
            WHEN occurrences > 1 THEN occurrences
            ELSE 0
        END
    ) AS rows_in_repeated_groups,
    SUM(
        CASE
            WHEN occurrences > 1 THEN occurrences - 1
            ELSE 0
        END
    ) AS excess_rows,
    MAX(occurrences) AS highest_repeat_count
FROM name_groups;


SELECT
    name,
    COUNT(*) AS occurrences,
    COUNT(DISTINCT COALESCE(
        NULLIF(TRIM(`Chemical Class`), ''),
        '[MISSING]'
    )) AS chemical_class_variants,
    COUNT(DISTINCT COALESCE(
        NULLIF(TRIM(`Therapeutic Class`), ''),
        '[MISSING]'
    )) AS therapeutic_class_variants,
    COUNT(DISTINCT COALESCE(
        NULLIF(TRIM(`Action Class`), ''),
        '[MISSING]'
    )) AS action_class_variants,
    COUNT(DISTINCT COALESCE(
        NULLIF(TRIM(use0), ''),
        '[MISSING]'
    )) AS primary_use_variants,
    COUNT(DISTINCT COALESCE(
        NULLIF(TRIM(substitute0), ''),
        '[MISSING]'
    )) AS first_substitute_variants
FROM raw_250k
GROUP BY name
HAVING COUNT(*) > 1
ORDER BY occurrences DESC, name
LIMIT 20;



SELECT
    id,
    name,
    `Chemical Class`,
    `Therapeutic Class`,
    `Action Class`,
    `Habit Forming`,
    use0,
    use1,
    substitute0,
    substitute1,
    substitute2,
    substitute3,
    substitute4
FROM raw_250k
WHERE LOWER(TRIM(name)) = 'artee 150mg injection'
ORDER BY id;


SELECT
    id,
    SHA2(
        CAST(
            JSON_ARRAY(
                use1, use2, use3, use4,
                sideEffect0, sideEffect1, sideEffect2,
                sideEffect3, sideEffect4, sideEffect5,
                sideEffect6, sideEffect7, sideEffect8,
                sideEffect9, sideEffect10, sideEffect11,
                sideEffect12, sideEffect13, sideEffect14,
                sideEffect15, sideEffect16, sideEffect17,
                sideEffect18, sideEffect19, sideEffect20,
                sideEffect21, sideEffect22, sideEffect23,
                sideEffect24, sideEffect25, sideEffect26,
                sideEffect27, sideEffect28, sideEffect29,
                sideEffect30, sideEffect31, sideEffect32,
                sideEffect33, sideEffect34, sideEffect35,
                sideEffect36, sideEffect37, sideEffect38,
                sideEffect39, sideEffect40, sideEffect41
            ) AS CHAR
        ),
        256
    ) AS remaining_metadata_hash
FROM raw_250k
WHERE id IN (29955, 29984, 30032)
ORDER BY id;


WITH repeated_names AS (
    SELECT name
    FROM raw_250k
    GROUP BY name
    HAVING COUNT(*) > 1
),
record_fingerprints AS (
    SELECT
        SHA2(
            CAST(
                JSON_ARRAY(
                    r.name,
                    r.substitute0, r.substitute1, r.substitute2,
                    r.substitute3, r.substitute4,

                    r.sideEffect0, r.sideEffect1, r.sideEffect2,
                    r.sideEffect3, r.sideEffect4, r.sideEffect5,
                    r.sideEffect6, r.sideEffect7, r.sideEffect8,
                    r.sideEffect9, r.sideEffect10, r.sideEffect11,
                    r.sideEffect12, r.sideEffect13, r.sideEffect14,
                    r.sideEffect15, r.sideEffect16, r.sideEffect17,
                    r.sideEffect18, r.sideEffect19, r.sideEffect20,
                    r.sideEffect21, r.sideEffect22, r.sideEffect23,
                    r.sideEffect24, r.sideEffect25, r.sideEffect26,
                    r.sideEffect27, r.sideEffect28, r.sideEffect29,
                    r.sideEffect30, r.sideEffect31, r.sideEffect32,
                    r.sideEffect33, r.sideEffect34, r.sideEffect35,
                    r.sideEffect36, r.sideEffect37, r.sideEffect38,
                    r.sideEffect39, r.sideEffect40, r.sideEffect41,

                    r.use0, r.use1, r.use2, r.use3, r.use4,

                    r.`Chemical Class`,
                    r.`Habit Forming`,
                    r.`Therapeutic Class`,
                    r.`Action Class`
                ) AS CHAR
            ),
            256
        ) AS record_hash
    FROM raw_250k AS r
    INNER JOIN repeated_names AS n
        ON r.name = n.name
),
fingerprint_groups AS (
    SELECT
        record_hash,
        COUNT(*) AS occurrences
    FROM record_fingerprints
    GROUP BY record_hash
)
SELECT
    COUNT(*) AS distinct_full_record_groups_among_candidates,
    SUM(occurrences > 1) AS repeated_full_record_groups,
    SUM(
        CASE WHEN occurrences > 1
             THEN occurrences
             ELSE 0
        END
    ) AS rows_in_repeated_full_record_groups,
    SUM(
        CASE WHEN occurrences > 1
             THEN occurrences - 1
             ELSE 0
        END
    ) AS excess_duplicate_rows,
    MAX(occurrences) AS highest_repeat_count
FROM fingerprint_groups;



CREATE TABLE clean_250k AS

WITH repeated_names AS (
    SELECT name
    FROM raw_250k
    GROUP BY name
    HAVING COUNT(*) > 1
),
candidate_fingerprints AS (
    SELECT
        r.id,
        SHA2(
            CAST(
                JSON_ARRAY(
                    r.name,
                    r.substitute0, r.substitute1, r.substitute2,
                    r.substitute3, r.substitute4,

                    r.sideEffect0, r.sideEffect1, r.sideEffect2,
                    r.sideEffect3, r.sideEffect4, r.sideEffect5,
                    r.sideEffect6, r.sideEffect7, r.sideEffect8,
                    r.sideEffect9, r.sideEffect10, r.sideEffect11,
                    r.sideEffect12, r.sideEffect13, r.sideEffect14,
                    r.sideEffect15, r.sideEffect16, r.sideEffect17,
                    r.sideEffect18, r.sideEffect19, r.sideEffect20,
                    r.sideEffect21, r.sideEffect22, r.sideEffect23,
                    r.sideEffect24, r.sideEffect25, r.sideEffect26,
                    r.sideEffect27, r.sideEffect28, r.sideEffect29,
                    r.sideEffect30, r.sideEffect31, r.sideEffect32,
                    r.sideEffect33, r.sideEffect34, r.sideEffect35,
                    r.sideEffect36, r.sideEffect37, r.sideEffect38,
                    r.sideEffect39, r.sideEffect40, r.sideEffect41,

                    r.use0, r.use1, r.use2, r.use3, r.use4,

                    r.`Chemical Class`,
                    r.`Habit Forming`,
                    r.`Therapeutic Class`,
                    r.`Action Class`
                ) AS CHAR
            ),
            256
        ) AS record_hash

    FROM raw_250k AS r
    INNER JOIN repeated_names AS n
        ON r.name = n.name
),
ranked_candidates AS (
    SELECT
        id,
        ROW_NUMBER() OVER (
            PARTITION BY record_hash
            ORDER BY id
        ) AS rn

    FROM candidate_fingerprints
),
keep_ids AS (
    SELECT id
    FROM ranked_candidates
    WHERE rn = 1
    UNION ALL
    SELECT r.id
    FROM raw_250k AS r
    WHERE NOT EXISTS (
        SELECT 1
        FROM repeated_names AS n
        WHERE n.name = r.name
    )
)
SELECT r.*
FROM raw_250k AS r
INNER JOIN keep_ids AS k
    ON r.id = k.id;
    
 
 
SELECT
    'Raw' AS table_name,
    COUNT(*) AS total_rows
FROM raw_250k
UNION ALL
SELECT
    'Cleaned' AS table_name,
    COUNT(*) AS total_rows
FROM clean_250k;



SELECT
    id,
    name,
    `Chemical Class`,
    substitute0,
    substitute1,
    substitute2,
    substitute3,
    substitute4
FROM clean_250k
WHERE LOWER(TRIM(name)) = 'artee 150mg injection'
ORDER BY id;

INSERT INTO project_audit_log (
    step_key,
    step_name,
    source_table,
    target_table,
    input_rows,
    output_rows,
    rows_removed,
    details
)
SELECT
    '250K-01',
    'Full-record duplicate handling',
    'raw_250k',
    'clean_250k',
    r.row_count,
    c.row_count,
    r.row_count - c.row_count,
    'Deduplicated repeated-name candidates using full-record SHA-256 fingerprints; retained the lowest ID per fingerprint.'
FROM
    (SELECT COUNT(*) AS row_count FROM raw_250k) AS r
CROSS JOIN
    (SELECT COUNT(*) AS row_count FROM clean_250k) AS c
WHERE NOT EXISTS (
    SELECT 1
    FROM project_audit_log AS a
    WHERE a.step_key = '250K-01'
);



SELECT *
FROM project_audit_log
ORDER BY step_key;


WITH name_groups AS (
    SELECT
        name,
        COUNT(*) AS occurrences
    FROM clean_250k
    GROUP BY name
)
SELECT
    SUM(occurrences) AS total_rows,
    COUNT(*) AS distinct_name_groups,
    SUM(occurrences > 1) AS repeated_name_groups,
    SUM(
        CASE
            WHEN occurrences > 1 THEN occurrences
            ELSE 0
        END
    ) AS rows_in_repeated_name_groups,
    SUM(
        CASE
            WHEN occurrences > 1 THEN occurrences - 1
            ELSE 0
        END
    ) AS excess_rows_by_name

FROM name_groups;


DROP TABLE IF EXISTS clean_250k_match;

CREATE TABLE clean_250k_match AS
SELECT
    src_id,
    name,
    norm_name,
    chemical_class,
    habit_forming,
    therapeutic_class,
    action_class,
    primary_use,
    top_substitute,
    match_completeness_score
FROM (
    SELECT
        s.*,
        ROW_NUMBER() OVER (
            PARTITION BY norm_name
            ORDER BY match_completeness_score DESC, src_id ASC
        ) AS rn
    FROM (
        SELECT
            id AS src_id,
            name,
            LOWER(
                REGEXP_REPLACE(TRIM(name), '\\s+', ' ')
            ) AS norm_name,
            NULLIF(TRIM(`Chemical Class`), '')
                AS chemical_class,
            NULLIF(TRIM(`Habit Forming`), '')
                AS habit_forming,
            NULLIF(TRIM(`Therapeutic Class`), '')
                AS therapeutic_class,
            NULLIF(TRIM(`Action Class`), '')
                AS action_class,
            NULLIF(TRIM(use0), '')
                AS primary_use,
            NULLIF(TRIM(substitute0), '')
                AS top_substitute,
            (
                (NULLIF(TRIM(`Chemical Class`), '') IS NOT NULL)
              + (NULLIF(TRIM(`Habit Forming`), '') IS NOT NULL)
              + (NULLIF(TRIM(`Therapeutic Class`), '') IS NOT NULL)
              + (NULLIF(TRIM(`Action Class`), '') IS NOT NULL)
              + (NULLIF(TRIM(use0), '') IS NOT NULL)
              + (NULLIF(TRIM(substitute0), '') IS NOT NULL)
            ) AS match_completeness_score
        FROM clean_250k
        WHERE name IS NOT NULL
          AND TRIM(name) <> ''
    ) AS s
) AS ranked
WHERE rn = 1;


SELECT
    COUNT(*) AS matching_rows,
    COUNT(DISTINCT norm_name) AS distinct_normalized_names
FROM clean_250k_match;



WITH normalized_names AS (
    SELECT
        LOWER(
            REGEXP_REPLACE(TRIM(name), '\\s+', ' ')
        ) AS norm_name,
        name AS original_name
    FROM clean_250k
    WHERE name IS NOT NULL
      AND TRIM(name) <> ''
),
collision_keys AS (
    SELECT norm_name
    FROM normalized_names
    GROUP BY norm_name
    HAVING COUNT(DISTINCT BINARY original_name) > 1
)
SELECT DISTINCT
    n.norm_name,
    n.original_name
FROM normalized_names AS n
JOIN collision_keys AS c
    ON n.norm_name = c.norm_name
ORDER BY n.norm_name, n.original_name
LIMIT 100;



WITH az_match_keys AS (
    SELECT
        src_id,
        product_name,
        LOWER(
            REGEXP_REPLACE(TRIM(product_name), '\\s+', ' ')
        ) AS norm_name
    FROM clean_az
)
SELECT
    COUNT(*) AS total_az_records,
    SUM(
        CASE
            WHEN c.norm_name IS NOT NULL THEN 1
            ELSE 0
        END
    ) AS matched_records,
    SUM(
        CASE
            WHEN c.norm_name IS NULL THEN 1
            ELSE 0
        END
    ) AS unmatched_records,
    ROUND(
        100.0 * SUM(
            CASE
                WHEN c.norm_name IS NOT NULL THEN 1
                ELSE 0
            END
        ) / COUNT(*),
        2
    ) AS match_percentage
FROM az_match_keys AS a
LEFT JOIN clean_250k_match AS c
    ON a.norm_name = c.norm_name;
    

CREATE TABLE medicine_master AS
SELECT
    a.src_id,
    a.product_name,
    a.manufacturer,
    a.product_type,
    a.pack_size,
    a.composition1,
    a.composition2,
    a.price,
    a.price_status,
    a.is_discontinued,
    c.src_id AS src_250k_id,
    c.chemical_class,
    c.habit_forming,
    c.therapeutic_class,
    c.action_class,
    c.primary_use,
    c.top_substitute,
    c.match_completeness_score,
    CASE
        WHEN c.norm_name IS NOT NULL THEN 'NAME_MATCH'
        ELSE 'UNMATCHED'
    END AS metadata_match_status
FROM clean_az AS a
LEFT JOIN clean_250k_match AS c
    ON LOWER(
        REGEXP_REPLACE(TRIM(a.product_name), '\\s+', ' ')
    ) = c.norm_name;
    
    
    
SELECT
    COUNT(*) AS total_master_rows,
    COUNT(DISTINCT src_id) AS distinct_az_records,
    SUM(metadata_match_status = 'NAME_MATCH')
        AS matched_records,
    SUM(metadata_match_status = 'UNMATCHED')
        AS unmatched_records
FROM medicine_master;



WITH imr_keyed AS (
    SELECT
        LOWER(
            REGEXP_REPLACE(TRIM(product_name), '\\s+', ' ')
        ) AS norm_name,
        LOWER(
            REGEXP_REPLACE(TRIM(manufacturer), '\\s+', ' ')
        ) AS norm_manufacturer
    FROM clean_imr
    WHERE product_name IS NOT NULL
      AND TRIM(product_name) <> ''
),
key_groups AS (
    SELECT
        norm_name,
        norm_manufacturer,
        COUNT(*) AS occurrences
    FROM imr_keyed
    WHERE norm_manufacturer IS NOT NULL
      AND norm_manufacturer <> ''
    GROUP BY
        norm_name,
        norm_manufacturer
)
SELECT
    (SELECT COUNT(*) FROM clean_imr)
        AS total_imr_rows,

    (SELECT COUNT(*)
     FROM imr_keyed
     WHERE norm_manufacturer IS NOT NULL
       AND norm_manufacturer <> '')
        AS rows_with_name_and_manufacturer,
    COUNT(*) AS distinct_name_manufacturer_keys,
    SUM(occurrences > 1)
        AS repeated_key_groups,
    SUM(
        CASE
            WHEN occurrences > 1 THEN occurrences - 1
            ELSE 0
        END
    ) AS excess_rows_by_key,
    MAX(occurrences) AS highest_records_per_key
FROM key_groups;


WITH imr_keyed AS (
    SELECT
        LOWER(
            REGEXP_REPLACE(TRIM(product_name), '\\s+', ' ')
        ) AS norm_name,
        LOWER(
            REGEXP_REPLACE(TRIM(manufacturer), '\\s+', ' ')
        ) AS norm_manufacturer,
        product_name,
        manufacturer,
        price,
        price_status,
        salt_composition,
        sub_category
    FROM clean_imr
    WHERE product_name IS NOT NULL
      AND TRIM(product_name) <> ''
      AND manufacturer IS NOT NULL
      AND TRIM(manufacturer) <> ''
)
SELECT
    norm_name,
    norm_manufacturer,
    COUNT(*) AS occurrences,
    COUNT(DISTINCT COALESCE(
        CAST(price AS CHAR),
        '[NULL]'
    )) AS distinct_price_values,
    COUNT(DISTINCT COALESCE(
        NULLIF(TRIM(salt_composition), ''),
        '[MISSING]'
    )) AS distinct_compositions,
    COUNT(DISTINCT COALESCE(
        NULLIF(TRIM(sub_category), ''),
        '[MISSING]'
    )) AS distinct_categories,
    GROUP_CONCAT(
        DISTINCT product_name
        ORDER BY product_name
        SEPARATOR ' | '
    ) AS original_names,
    GROUP_CONCAT(
        DISTINCT CAST(price AS CHAR)
        ORDER BY CAST(price AS CHAR)
        SEPARATOR ' | '
    ) AS observed_prices
FROM imr_keyed
GROUP BY
    norm_name,
    norm_manufacturer
HAVING COUNT(*) > 1
ORDER BY occurrences DESC, norm_name
LIMIT 25;


WITH imr_keyed AS (
    SELECT
        LOWER(
            REGEXP_REPLACE(TRIM(product_name), '\\s+', ' ')
        ) AS norm_name,
        LOWER(
            REGEXP_REPLACE(TRIM(manufacturer), '\\s+', ' ')
        ) AS norm_manufacturer,
        price,
        salt_composition,
        sub_category,
        medicine_desc
    FROM clean_imr
    WHERE product_name IS NOT NULL
      AND TRIM(product_name) <> ''
      AND manufacturer IS NOT NULL
      AND TRIM(manufacturer) <> ''
),
key_profile AS (
    SELECT
        norm_name,
        norm_manufacturer,
        COUNT(*) AS occurrences,
        COUNT(DISTINCT COALESCE(
            CAST(price AS CHAR),
            '[NULL]'
        )) AS distinct_price_values,
        COUNT(DISTINCT COALESCE(
            NULLIF(TRIM(salt_composition), ''),
            '[MISSING]'
        )) AS distinct_compositions,
        COUNT(DISTINCT COALESCE(
            NULLIF(TRIM(sub_category), ''),
            '[MISSING]'
        )) AS distinct_categories,
        COUNT(DISTINCT COALESCE(
            NULLIF(TRIM(medicine_desc), ''),
            '[MISSING]'
        )) AS distinct_descriptions
    FROM imr_keyed
    GROUP BY
        norm_name,
        norm_manufacturer
    HAVING COUNT(*) > 1
)
SELECT
    COUNT(*) AS repeated_key_groups,
    SUM(distinct_price_values > 1)
        AS groups_with_different_prices,
    SUM(distinct_compositions > 1)
        AS groups_with_different_compositions,
    SUM(distinct_categories > 1)
        AS groups_with_different_categories,
    SUM(distinct_descriptions > 1)
        AS groups_with_different_descriptions,
    SUM(
        distinct_price_values = 1
        AND distinct_compositions = 1
        AND distinct_categories = 1
        AND distinct_descriptions = 1
    ) AS groups_consistent_on_checked_fields,
    MAX(occurrences) AS highest_records_per_key
FROM key_profile;


WITH imr_keyed AS (
    SELECT
        LOWER(
            REGEXP_REPLACE(TRIM(product_name), '\\s+', ' ')
        ) AS norm_name,
        LOWER(
            REGEXP_REPLACE(TRIM(manufacturer), '\\s+', ' ')
        ) AS norm_manufacturer,
        price,
        NULLIF(
            LOWER(
                REGEXP_REPLACE(TRIM(salt_composition), '\\s+', ' ')
            ),
            ''
        ) AS norm_composition
    FROM clean_imr
    WHERE product_name IS NOT NULL
      AND TRIM(product_name) <> ''
      AND manufacturer IS NOT NULL
      AND TRIM(manufacturer) <> ''
),
key_profile AS (
    SELECT
        norm_name,
        norm_manufacturer,
        COUNT(*) AS occurrences,
        COUNT(DISTINCT COALESCE(
            CAST(price AS CHAR),
            '[NULL]'
        )) AS price_value_count,
        COUNT(DISTINCT COALESCE(
            norm_composition,
            '[MISSING]'
        )) AS composition_value_count,
        MIN(price) AS minimum_price,
        MAX(price) AS maximum_price,
        MAX(norm_composition) AS composition_value
    FROM imr_keyed
    GROUP BY norm_name, norm_manufacturer
)
SELECT
    COUNT(*) AS total_matching_keys,
    SUM(occurrences = 1) AS single_record_keys,
    SUM(occurrences > 1) AS repeated_keys,
    SUM(price_value_count > 1) AS keys_with_price_conflicts,
    SUM(composition_value_count > 1)
        AS keys_with_composition_conflicts,
    SUM(
        price_value_count = 1
        AND minimum_price > 0
        AND minimum_price = maximum_price
        AND composition_value_count = 1
        AND composition_value IS NOT NULL
    ) AS candidates_for_price_matching
FROM key_profile;


CREATE TABLE clean_imr_price_match AS

WITH imr_keyed AS (
    SELECT
        LOWER(
            REGEXP_REPLACE(TRIM(product_name), '\\s+', ' ')
        ) AS norm_name,
        LOWER(
            REGEXP_REPLACE(TRIM(manufacturer), '\\s+', ' ')
        ) AS norm_manufacturer,
        price,
        NULLIF(
            LOWER(
                REGEXP_REPLACE(
                    TRIM(salt_composition),
                    '\\s+',
                    ' '
                )
            ),
            ''
        ) AS norm_composition
    FROM clean_imr
    WHERE product_name IS NOT NULL
      AND TRIM(product_name) <> ''
      AND manufacturer IS NOT NULL
      AND TRIM(manufacturer) <> ''
),
key_profile AS (
    SELECT
        norm_name,
        norm_manufacturer,
        COUNT(*) AS source_record_count,
        COUNT(DISTINCT COALESCE(
            CAST(price AS CHAR),
            '[NULL]'
        )) AS price_value_count,
        COUNT(DISTINCT COALESCE(
            norm_composition,
            '[MISSING]'
        )) AS composition_value_count,
        MIN(price) AS minimum_price,
        MAX(price) AS maximum_price,
        MAX(norm_composition) AS norm_composition
    FROM imr_keyed
    GROUP BY
        norm_name,
        norm_manufacturer
)
SELECT
    norm_name,
    norm_manufacturer,
    minimum_price AS imr_price,
    norm_composition AS imr_salt_composition,
    source_record_count
FROM key_profile
WHERE price_value_count = 1
  AND minimum_price > 0
  AND minimum_price = maximum_price
  AND composition_value_count = 1
  AND norm_composition IS NOT NULL;
  
  
  
SELECT
    COUNT(*) AS candidate_keys,
    COUNT(DISTINCT norm_name, norm_manufacturer)
        AS distinct_matching_keys,
    SUM(source_record_count > 1)
        AS candidates_with_multiple_source_records,
    MIN(imr_price) AS minimum_candidate_price,
    MAX(imr_price) AS maximum_candidate_price
FROM clean_imr_price_match;


WITH master_keys AS (
    SELECT
        src_id,
        product_name,
        manufacturer,
        price,
        price_status,
        LOWER(
            REGEXP_REPLACE(TRIM(product_name), '\\s+', ' ')
        ) AS norm_name,
        LOWER(
            REGEXP_REPLACE(TRIM(manufacturer), '\\s+', ' ')
        ) AS norm_manufacturer
    FROM medicine_master
)
SELECT
    COUNT(*) AS total_master_records,
    SUM(
        CASE
            WHEN i.norm_name IS NOT NULL THEN 1
            ELSE 0
        END
    ) AS matched_records,
    SUM(
        CASE
            WHEN i.norm_name IS NULL THEN 1
            ELSE 0
        END
    ) AS unmatched_records,
    ROUND(
        100.0 * SUM(
            CASE
                WHEN i.norm_name IS NOT NULL THEN 1
                ELSE 0
            END
        ) / COUNT(*),
        2
    ) AS match_percentage,
    SUM(
        CASE
            WHEN i.norm_name IS NOT NULL
             AND m.price_status = 'VALID'
            THEN 1
            ELSE 0
        END
    ) AS matched_records_with_valid_az_price
FROM master_keys AS m
LEFT JOIN clean_imr_price_match AS i
    ON m.norm_name = i.norm_name
   AND m.norm_manufacturer = i.norm_manufacturer;
   

WITH matched_prices AS (
    SELECT
        m.src_id,
        m.product_name,
        m.manufacturer,
        m.price AS price_az,
        i.imr_price,
        ROUND(
            100.0 * ABS(m.price - i.imr_price)
            / NULLIF(i.imr_price, 0),
            2
        ) AS absolute_price_gap_pct
    FROM medicine_master AS m
    INNER JOIN clean_imr_price_match AS i
        ON LOWER(
            REGEXP_REPLACE(TRIM(m.product_name), '\\s+', ' ')
        ) = i.norm_name
       AND LOWER(
            REGEXP_REPLACE(TRIM(m.manufacturer), '\\s+', ' ')
        ) = i.norm_manufacturer
    WHERE m.price_status = 'VALID'
      AND i.imr_price > 0
)
SELECT
    COUNT(*) AS matched_records,
    SUM(price_az = imr_price)
        AS identical_listed_prices,
    SUM(
        price_az <> imr_price
        AND absolute_price_gap_pct <= 10
    ) AS differing_by_up_to_10_pct,
    SUM(absolute_price_gap_pct > 10)
        AS differing_by_more_than_10_pct,
    ROUND(AVG(absolute_price_gap_pct), 2)
        AS average_absolute_price_gap_pct,
    ROUND(MAX(absolute_price_gap_pct), 2)
        AS maximum_absolute_price_gap_pct
FROM matched_prices;


SELECT
    m.src_id,
    m.product_name,
    m.manufacturer,
    m.composition1 AS az_composition1,
    m.composition2 AS az_composition2,
    m.pack_size AS az_pack_size,
    m.price AS price_az,
    i.imr_salt_composition,
    i.imr_price,
    ROUND(
        100.0 * ABS(m.price - i.imr_price)
        / NULLIF(i.imr_price, 0),
        2
    ) AS absolute_price_gap_pct
FROM medicine_master AS m
INNER JOIN clean_imr_price_match AS i
    ON LOWER(
        REGEXP_REPLACE(TRIM(m.product_name), '\\s+', ' ')
    ) = i.norm_name
   AND LOWER(
        REGEXP_REPLACE(TRIM(m.manufacturer), '\\s+', ' ')
    ) = i.norm_manufacturer
WHERE m.price_status = 'VALID'
  AND i.imr_price > 0
ORDER BY absolute_price_gap_pct DESC
LIMIT 20;


WITH composition_check AS (
    SELECT
        m.src_id,
        m.product_name,
        m.manufacturer,
        m.price AS price_az,
        i.imr_price,
        m.pack_size,
        LOWER(
            REGEXP_REPLACE(
                CONCAT(
                    COALESCE(m.composition1, ''),
                    COALESCE(m.composition2, '')
                ),
                '[^a-z0-9]',
                ''
            )
        ) AS az_composition_key,
        LOWER(
            REGEXP_REPLACE(
                COALESCE(i.imr_salt_composition, ''),
                '[^a-z0-9]',
                ''
            )
        ) AS imr_composition_key
    FROM medicine_master AS m
    INNER JOIN clean_imr_price_match AS i
        ON LOWER(
            REGEXP_REPLACE(TRIM(m.product_name), '\\s+', ' ')
        ) = i.norm_name
       AND LOWER(
            REGEXP_REPLACE(TRIM(m.manufacturer), '\\s+', ' ')
        ) = i.norm_manufacturer
    WHERE m.price_status = 'VALID'
      AND i.imr_price > 0
)
SELECT
    COUNT(*) AS matched_records,
    SUM(
        az_composition_key <> ''
        AND imr_composition_key <> ''
        AND az_composition_key = imr_composition_key
    ) AS composition_matches,
    SUM(
        az_composition_key <> ''
        AND imr_composition_key <> ''
        AND az_composition_key <> imr_composition_key
    ) AS composition_mismatches,
    SUM(
        az_composition_key = ''
        OR imr_composition_key = ''
    ) AS missing_composition_for_comparison
FROM composition_check;


SELECT
    m.src_id,
    m.product_name,
    m.manufacturer,
    m.composition1 AS az_composition1,
    m.composition2 AS az_composition2,
    i.imr_salt_composition,
    m.pack_size,
    m.price AS price_az,
    i.imr_price,
    ROUND(
        100.0 * ABS(m.price - i.imr_price)
        / NULLIF(i.imr_price, 0),
        2
    ) AS price_gap_pct
FROM medicine_master AS m
INNER JOIN clean_imr_price_match AS i
    ON LOWER(
        REGEXP_REPLACE(TRIM(m.product_name), '\\s+', ' ')
    ) = i.norm_name
   AND LOWER(
        REGEXP_REPLACE(TRIM(m.manufacturer), '\\s+', ' ')
    ) = i.norm_manufacturer
WHERE m.price_status = 'VALID'
  AND LOWER(
        REGEXP_REPLACE(
            CONCAT(
                COALESCE(m.composition1, ''),
                COALESCE(m.composition2, '')
            ),
            '[^a-z0-9]',
            ''
        )
  ) <> LOWER(
        REGEXP_REPLACE(
            COALESCE(i.imr_salt_composition, ''),
            '[^a-z0-9]',
            ''
        )
  )
ORDER BY price_gap_pct DESC
LIMIT 20;


WITH matched_records AS (
    SELECT
        m.src_id,
        m.price AS price_az,
        i.imr_price,
        LOWER(
            REGEXP_REPLACE(
                CONCAT(
                    COALESCE(m.composition1, ''),
                    COALESCE(m.composition2, '')
                ),
                '[^a-z0-9]',
                ''
            )
        ) AS az_composition_key,
        LOWER(
            REGEXP_REPLACE(
                COALESCE(i.imr_salt_composition, ''),
                '[^a-z0-9]',
                ''
            )
        ) AS imr_composition_key
    FROM medicine_master AS m
    INNER JOIN clean_imr_price_match AS i
        ON LOWER(
            REGEXP_REPLACE(TRIM(m.product_name), '\\s+', ' ')
        ) = i.norm_name
       AND LOWER(
            REGEXP_REPLACE(TRIM(m.manufacturer), '\\s+', ' ')
        ) = i.norm_manufacturer
    WHERE m.price_status = 'VALID'
      AND i.imr_price > 0
),
classified_records AS (
    SELECT
        price_az,
        imr_price,
        CASE
            WHEN az_composition_key = imr_composition_key
                THEN 'COMPOSITION_TEXT_MATCH'
            ELSE 'COMPOSITION_MISMATCH'
        END AS composition_status,
        100.0 * ABS(price_az - imr_price)
            / NULLIF(imr_price, 0) AS price_gap_pct
    FROM matched_records
)
SELECT
    composition_status,
    COUNT(*) AS matched_records,
    SUM(price_az = imr_price)
        AS identical_prices,
    SUM(
        price_az <> imr_price
        AND price_gap_pct <= 10
    ) AS differing_by_up_to_10_pct,
    SUM(price_gap_pct > 10)
        AS differing_by_more_than_10_pct,
    ROUND(AVG(price_gap_pct), 2)
        AS average_absolute_price_gap_pct,
    ROUND(MAX(price_gap_pct), 2)
        AS maximum_absolute_price_gap_pct
FROM classified_records
GROUP BY composition_status
ORDER BY composition_status;


CREATE OR REPLACE VIEW vw_imr_price_reconciliation AS
SELECT
    m.src_id AS az_src_id,
    m.product_name,
    m.manufacturer,
    m.composition1 AS az_composition1,
    m.composition2 AS az_composition2,
    i.imr_salt_composition,
    m.pack_size AS az_pack_size,
    m.price AS az_price,
    i.imr_price,
    ROUND(
        ABS(m.price - i.imr_price),
        2
    ) AS absolute_price_difference,
    ROUND(
        100.0 * ABS(m.price - i.imr_price)
        / NULLIF(i.imr_price, 0),
        2
    ) AS absolute_price_gap_pct,
    CASE
        WHEN LOWER(
            REGEXP_REPLACE(
                CONCAT(
                    COALESCE(m.composition1, ''),
                    COALESCE(m.composition2, '')
                ),
                '[^a-z0-9]',
                ''
            )
        ) =
        LOWER(
            REGEXP_REPLACE(
                COALESCE(i.imr_salt_composition, ''),
                '[^a-z0-9]',
                ''
            )
        )
        THEN 'COMPOSITION_TEXT_MATCH'
        ELSE 'COMPOSITION_MISMATCH'
    END AS composition_status,
    CASE
        WHEN LOWER(
            REGEXP_REPLACE(
                CONCAT(
                    COALESCE(m.composition1, ''),
                    COALESCE(m.composition2, '')
                ),
                '[^a-z0-9]',
                ''
            )
        ) <>
        LOWER(
            REGEXP_REPLACE(
                COALESCE(i.imr_salt_composition, ''),
                '[^a-z0-9]',
                ''
            )
        )
        THEN 'REVIEW_COMPOSITION'
        WHEN ABS(m.price - i.imr_price) / i.imr_price > 0.10
        THEN 'REVIEW_PRICE_GAP'
        ELSE 'LOWER_GAP_STILL_NEEDS_PACK_CHECK'
    END AS review_status
FROM medicine_master AS m
INNER JOIN clean_imr_price_match AS i
    ON LOWER(
        REGEXP_REPLACE(TRIM(m.product_name), '\\s+', ' ')
    ) = i.norm_name
   AND LOWER(
        REGEXP_REPLACE(TRIM(m.manufacturer), '\\s+', ' ')
    ) = i.norm_manufacturer
WHERE m.price_status = 'VALID'
  AND i.imr_price > 0;
  
  
  
SELECT
    COUNT(*) AS reconciliation_records,
    SUM(composition_status = 'COMPOSITION_TEXT_MATCH')
        AS composition_text_matches,
    SUM(composition_status = 'COMPOSITION_MISMATCH')
        AS composition_mismatches
FROM vw_imr_price_reconciliation;


CREATE OR REPLACE VIEW vw_imr_reconciliation_summary AS
SELECT
    composition_status,
    COUNT(*) AS matched_records,
    SUM(az_price = imr_price)
        AS identical_prices,
    SUM(
        az_price <> imr_price
        AND ABS(az_price - imr_price) / imr_price <= 0.10
    ) AS differing_by_up_to_10_pct,
    SUM(
        ABS(az_price - imr_price) / imr_price > 0.10
    ) AS differing_by_more_than_10_pct,
    ROUND(
        AVG(
            ABS(az_price - imr_price) / imr_price * 100
        ),
        2
    ) AS avg_absolute_price_gap_pct,
    ROUND(
        MAX(
            ABS(az_price - imr_price) / imr_price * 100
        ),
        2
    ) AS max_absolute_price_gap_pct
FROM vw_imr_price_reconciliation
GROUP BY composition_status;


SELECT *
FROM vw_imr_reconciliation_summary
ORDER BY composition_status;


CREATE OR REPLACE VIEW vw_catalogue_quality_kpis AS
SELECT
    -- A-Z data quality
    (SELECT COUNT(*)
     FROM raw_az) AS raw_az_rows,

    (SELECT COUNT(*)
     FROM clean_az) AS clean_az_rows,

    (SELECT COUNT(*)
     FROM raw_az)
    -
    (SELECT COUNT(*)
     FROM clean_az) AS az_excess_rows_removed,

    ROUND(
        100.0 *
        (
            (SELECT COUNT(*) FROM raw_az)
            -
            (SELECT COUNT(*) FROM clean_az)
        )
        / NULLIF((SELECT COUNT(*) FROM raw_az), 0),
        2
    ) AS az_pct_removed,

    (SELECT COUNT(*)
     FROM clean_az
     WHERE price_status = 'VALID') AS valid_price_records,

    (SELECT COUNT(*)
     FROM clean_az
     WHERE price_status = 'NON_POSITIVE') AS nonpositive_price_records,

    (SELECT COUNT(DISTINCT manufacturer)
     FROM clean_az) AS distinct_manufacturers,

    (SELECT COUNT(DISTINCT composition1)
     FROM clean_az) AS distinct_primary_compositions,

    -- 250K metadata enrichment
    (SELECT COUNT(*)
     FROM medicine_master
     WHERE metadata_match_status = 'NAME_MATCH')
        AS az_records_matched_to_250k,

    (SELECT COUNT(*)
     FROM medicine_master
     WHERE metadata_match_status = 'UNMATCHED')
        AS az_records_unmatched_to_250k,

    ROUND(
        100.0 *
        (SELECT COUNT(*) FROM medicine_master
         WHERE metadata_match_status = 'NAME_MATCH')
        / NULLIF((SELECT COUNT(*) FROM medicine_master), 0),
        2
    ) AS pct_matched_to_250k,

    -- Indian Medicine Data reconciliation
    (SELECT COUNT(*)
     FROM vw_imr_price_reconciliation)
        AS imr_matched_records,

    (SELECT COUNT(*)
     FROM vw_imr_price_reconciliation
     WHERE composition_status = 'COMPOSITION_TEXT_MATCH')
        AS imr_composition_text_matches,

    (SELECT COUNT(*)
     FROM vw_imr_price_reconciliation
     WHERE composition_status = 'COMPOSITION_MISMATCH')
        AS imr_composition_mismatches,

    (SELECT COUNT(*)
     FROM vw_imr_price_reconciliation
     WHERE absolute_price_gap_pct > 10)
        AS imr_price_gaps_over_10pct,

    (SELECT ROUND(AVG(absolute_price_gap_pct), 2)
     FROM vw_imr_price_reconciliation)
        AS imr_avg_absolute_price_gap_pct;
        
        
SELECT *
FROM vw_catalogue_quality_kpis;


SELECT
    COUNT(*) AS matched_records,
    SUM(
        100.0 * ABS(m.price - i.imr_price)
        / NULLIF(i.imr_price, 0) > 10
    ) AS price_gaps_over_10pct,
    ROUND(
        100.0 * SUM(
            100.0 * ABS(m.price - i.imr_price)
            / NULLIF(i.imr_price, 0) > 10
        ) / COUNT(*),
        2
    ) AS pct_gaps_over_10pct
FROM medicine_master AS m
INNER JOIN clean_imr_price_match AS i
    ON LOWER(
        REGEXP_REPLACE(TRIM(m.product_name), '\\s+', ' ')
    ) = i.norm_name
   AND LOWER(
        REGEXP_REPLACE(TRIM(m.manufacturer), '\\s+', ' ')
    ) = i.norm_manufacturer
WHERE m.price_status = 'VALID'
  AND i.imr_price > 0;
  

CREATE OR REPLACE VIEW vw_imr_price_reconciliation AS
SELECT
    m.src_id AS az_src_id,
    m.product_name,
    m.manufacturer,
    m.composition1 AS az_composition1,
    m.composition2 AS az_composition2,
    i.imr_salt_composition,
    m.pack_size AS az_pack_size,
    m.price AS az_price,
    i.imr_price,
    ROUND(
        ABS(m.price - i.imr_price),
        2
    ) AS absolute_price_difference,
    
    -- Keep full precision for correct classification
    100.0 * ABS(m.price - i.imr_price)
        / NULLIF(i.imr_price, 0)
        AS absolute_price_gap_pct,

    -- Rounded value for display in dashboards
    ROUND(
        100.0 * ABS(m.price - i.imr_price)
        / NULLIF(i.imr_price, 0),
        2
    ) AS price_gap_pct_display,
    CASE
        WHEN LOWER(
            REGEXP_REPLACE(
                CONCAT(
                    COALESCE(m.composition1, ''),
                    COALESCE(m.composition2, '')
                ),
                '[^a-z0-9]',
                ''
            )
        ) =
        LOWER(
            REGEXP_REPLACE(
                COALESCE(i.imr_salt_composition, ''),
                '[^a-z0-9]',
                ''
            )
        )
        THEN 'COMPOSITION_TEXT_MATCH'
        ELSE 'COMPOSITION_MISMATCH'
    END AS composition_status,

    CASE
        WHEN LOWER(
            REGEXP_REPLACE(
                CONCAT(
                    COALESCE(m.composition1, ''),
                    COALESCE(m.composition2, '')
                ),
                '[^a-z0-9]',
                ''
            )
        ) <>
        LOWER(
            REGEXP_REPLACE(
                COALESCE(i.imr_salt_composition, ''),
                '[^a-z0-9]',
                ''
            )
        )
        THEN 'REVIEW_COMPOSITION'

        WHEN ABS(m.price - i.imr_price) / i.imr_price > 0.10
        THEN 'REVIEW_PRICE_GAP'

        ELSE 'LOWER_GAP_STILL_NEEDS_PACK_CHECK'
    END AS review_status

FROM medicine_master AS m
INNER JOIN clean_imr_price_match AS i
    ON LOWER(
        REGEXP_REPLACE(TRIM(m.product_name), '\\s+', ' ')
    ) = i.norm_name
   AND LOWER(
        REGEXP_REPLACE(TRIM(m.manufacturer), '\\s+', ' ')
    ) = i.norm_manufacturer

WHERE m.price_status = 'VALID'
  AND i.imr_price > 0;
  
  
  
SELECT
    COUNT(*) AS matched_records,
    SUM(absolute_price_gap_pct > 10)
        AS price_gaps_over_10pct,
    ROUND(
        AVG(absolute_price_gap_pct),
        2
    ) AS average_absolute_price_gap_pct
FROM vw_imr_price_reconciliation;


SELECT *
FROM vw_imr_reconciliation_summary;


SELECT *
FROM vw_catalogue_quality_kpis;


SHOW CREATE VIEW vw_catalogue_quality_kpis;

DESCRIBE vw_catalogue_quality_kpis;

SELECT VIEW_DEFINITION
FROM INFORMATION_SCHEMA.VIEWS
WHERE TABLE_SCHEMA = 'epharmacy'
  AND TABLE_NAME = 'vw_catalogue_quality_kpis';
  

SELECT
    part,
    sql_part
FROM (
    SELECT 1 AS part, SUBSTRING(VIEW_DEFINITION, 1, 300) AS sql_part
    FROM INFORMATION_SCHEMA.VIEWS
    WHERE TABLE_SCHEMA = 'epharmacy'
      AND TABLE_NAME = 'vw_catalogue_quality_kpis'
    UNION ALL
    SELECT 2, SUBSTRING(VIEW_DEFINITION, 301, 300)
    FROM INFORMATION_SCHEMA.VIEWS
    WHERE TABLE_SCHEMA = 'epharmacy'
      AND TABLE_NAME = 'vw_catalogue_quality_kpis'
    UNION ALL
    SELECT 3, SUBSTRING(VIEW_DEFINITION, 601, 300)
    FROM INFORMATION_SCHEMA.VIEWS
    WHERE TABLE_SCHEMA = 'epharmacy'
      AND TABLE_NAME = 'vw_catalogue_quality_kpis'
    UNION ALL
    SELECT 4, SUBSTRING(VIEW_DEFINITION, 901, 300)
    FROM INFORMATION_SCHEMA.VIEWS
    WHERE TABLE_SCHEMA = 'epharmacy'
      AND TABLE_NAME = 'vw_catalogue_quality_kpis'
    UNION ALL
    SELECT 5, SUBSTRING(VIEW_DEFINITION, 1201, 300)
    FROM INFORMATION_SCHEMA.VIEWS
    WHERE TABLE_SCHEMA = 'epharmacy'
      AND TABLE_NAME = 'vw_catalogue_quality_kpis'
    UNION ALL
    SELECT 6, SUBSTRING(VIEW_DEFINITION, 1501, 300)
    FROM INFORMATION_SCHEMA.VIEWS
    WHERE TABLE_SCHEMA = 'epharmacy'
      AND TABLE_NAME = 'vw_catalogue_quality_kpis'
) AS view_parts
ORDER BY part;


CREATE OR REPLACE VIEW vw_catalogue_quality_kpis_precision AS
SELECT
    raw_az_rows,
    clean_az_rows,
    az_excess_rows_removed,
    ROUND(
        100.0 * az_excess_rows_removed
        / NULLIF(raw_az_rows, 0),
        4
    ) AS az_pct_removed,
    valid_price_records,
    nonpositive_price_records,
    distinct_manufacturers,
    distinct_primary_compositions,
    az_records_matched_to_250k,
    az_records_unmatched_to_250k,
    pct_matched_to_250k,
    imr_matched_records,
    imr_composition_text_matches,
    imr_composition_mismatches,
    imr_price_gaps_over_10pct,
    imr_avg_absolute_price_gap_pct
FROM vw_catalogue_quality_kpis;


SELECT
    raw_az_rows,
    clean_az_rows,
    az_excess_rows_removed,
    az_pct_removed
FROM vw_catalogue_quality_kpis_precision;


SELECT
    step_key,
    step_name,
    input_rows,
    output_rows,
    rows_removed,
    input_rows - output_rows AS calculated_rows_removed,
    CASE
        WHEN input_rows - output_rows = rows_removed
            THEN 'PASS'
        ELSE 'CHECK'
    END AS audit_status
FROM project_audit_log
ORDER BY logged_at;


SELECT 'raw_az' AS object_name, COUNT(*) AS row_count
FROM raw_az
UNION ALL
SELECT 'clean_az', COUNT(*)
FROM clean_az
UNION ALL
SELECT 'clean_250k_match', COUNT(*)
FROM clean_250k_match
UNION ALL
SELECT 'clean_imr', COUNT(*)
FROM clean_imr
UNION ALL
SELECT 'clean_imr_price_match', COUNT(*)
FROM clean_imr_price_match
UNION ALL
SELECT 'medicine_master', COUNT(*)
FROM medicine_master
UNION ALL
SELECT 'vw_imr_price_reconciliation', COUNT(*)
FROM vw_imr_price_reconciliation;


SELECT
    '250K name matching' AS check_area,
    COUNT(*) AS total_records,
    SUM(metadata_match_status = 'NAME_MATCH') AS matched_records,
    SUM(metadata_match_status = 'UNMATCHED') AS unmatched_records,
    SUM(
        metadata_match_status IN ('NAME_MATCH', 'UNMATCHED')
    ) AS classified_records
FROM medicine_master
UNION ALL
SELECT
    'IMR composition comparison',
    COUNT(*),
    SUM(composition_status = 'COMPOSITION_TEXT_MATCH'),
    SUM(composition_status = 'COMPOSITION_MISMATCH'),
    SUM(
        composition_status IN (
            'COMPOSITION_TEXT_MATCH',
            'COMPOSITION_MISMATCH'
        )
    )
FROM vw_imr_price_reconciliation;


SELECT
    COUNT(*) AS matched_records,
    SUM(absolute_price_gap_pct = 0)
        AS identical_prices,
    SUM(
        absolute_price_gap_pct > 0
        AND absolute_price_gap_pct <= 10
    ) AS differing_by_up_to_10_pct,
    SUM(absolute_price_gap_pct > 10)
        AS price_gaps_over_10_pct,
    ROUND(
        100.0 * SUM(absolute_price_gap_pct > 10)
        / COUNT(*),
        2
    ) AS pct_gaps_over_10,
    ROUND(
        AVG(absolute_price_gap_pct),
        2
    ) AS avg_absolute_price_gap_pct
FROM vw_imr_price_reconciliation;


SELECT *
FROM vw_catalogue_quality_kpis_precision;


SELECT *
FROM vw_price_pack_anomaly_summary;


SELECT *
FROM vw_imr_reconciliation_summary;


DESCRIBE vw_price_pack_anomaly_summary;


CREATE OR REPLACE VIEW vw_epharmacy_dashboard_summary AS
SELECT
    k.raw_az_rows,
    k.clean_az_rows,
    k.az_excess_rows_removed,
    k.az_pct_removed,
    k.valid_price_records,
    k.nonpositive_price_records,
    k.distinct_manufacturers,
    k.distinct_primary_compositions,
    k.az_records_matched_to_250k,
    k.az_records_unmatched_to_250k,
    k.pct_matched_to_250k,
    k.imr_matched_records,
    k.imr_composition_text_matches,
    k.imr_composition_mismatches,
    k.imr_price_gaps_over_10pct,
    k.imr_avg_absolute_price_gap_pct,
    (
        SELECT COALESCE(SUM(flagged_product_groups), 0)
        FROM vw_price_pack_anomaly_summary
    ) AS total_pack_anomaly_groups,
    (
        SELECT COALESCE(SUM(affected_pack_records), 0)
        FROM vw_price_pack_anomaly_summary
    ) AS total_affected_pack_records,
    (
        SELECT COALESCE(SUM(flagged_product_groups), 0)
        FROM vw_price_pack_anomaly_summary
        WHERE review_priority = 'HIGH PRIORITY REVIEW'
    ) AS high_priority_anomaly_groups,
    (
        SELECT COALESCE(SUM(affected_pack_records), 0)
        FROM vw_price_pack_anomaly_summary
        WHERE review_priority = 'HIGH PRIORITY REVIEW'
    ) AS high_priority_pack_records,
    (
        SELECT MAX(highest_unit_price_ratio)
        FROM vw_price_pack_anomaly_summary
    ) AS highest_unit_price_ratio,
    (
        SELECT MAX(highest_spread_pct)
        FROM vw_price_pack_anomaly_summary
    ) AS highest_price_spread_pct
FROM vw_catalogue_quality_kpis_precision AS k;


SELECT *
FROM vw_epharmacy_dashboard_summary;

SELECT
    TABLE_NAME AS view_name
FROM INFORMATION_SCHEMA.VIEWS
WHERE TABLE_SCHEMA = 'epharmacy'
ORDER BY TABLE_NAME;


CREATE OR REPLACE VIEW vw_az_price_quartiles AS
SELECT
    CONCAT('Q', quartile) AS price_quartile,
    COUNT(*) AS medicine_records,
    ROUND(MIN(price), 2) AS minimum_price,
    ROUND(MAX(price), 2) AS maximum_price,
    ROUND(AVG(price), 2) AS average_price
FROM (
    SELECT
        price,
        NTILE(4) OVER (ORDER BY price) AS quartile
    FROM clean_az
    WHERE price_status = 'VALID'
      AND price > 0
) AS price_groups
GROUP BY quartile;

SELECT *
FROM vw_az_price_quartiles
ORDER BY price_quartile;


DESCRIBE clean_az;


CREATE OR REPLACE VIEW vw_az_manufacturer_analysis AS
SELECT
    manufacturer,
    COUNT(*) AS valid_price_listings,
    COUNT(DISTINCT product_name) AS distinct_products,
    ROUND(AVG(price), 2) AS average_price,
    ROUND(MIN(price), 2) AS minimum_price,
    ROUND(MAX(price), 2) AS maximum_price,
    SUM(
        CASE
            WHEN is_discontinued = 1 THEN 1
            ELSE 0
        END
    ) AS discontinued_listings,
    ROUND(
        100.0 * SUM(
            CASE
                WHEN is_discontinued = 1 THEN 1
                ELSE 0
            END
        ) / NULLIF(COUNT(*), 0),
        2
    ) AS discontinued_pct
FROM clean_az
WHERE price_status = 'VALID'
  AND price > 0
  AND manufacturer IS NOT NULL
  AND TRIM(manufacturer) <> ''
GROUP BY manufacturer
HAVING COUNT(*) >= 100;


SELECT *
FROM vw_az_manufacturer_analysis
ORDER BY valid_price_listings DESC
LIMIT 20;


DESCRIBE medicine_master;




CREATE OR REPLACE VIEW vw_250k_therapeutic_class_analysis AS
SELECT
    therapeutic_class,
    COUNT(*) AS medicine_records,
    COUNT(DISTINCT product_name) AS distinct_products,
    SUM(
        CASE
            WHEN price_status = 'VALID' AND price > 0
            THEN 1
            ELSE 0
        END
    ) AS valid_price_records,
    ROUND(
        AVG(
            CASE
                WHEN price_status = 'VALID' AND price > 0
                THEN price
            END
        ),
        2
    ) AS average_price,
    SUM(
        CASE
            WHEN is_discontinued = 1 THEN 1
            ELSE 0
        END
    ) AS discontinued_listings,
    ROUND(
        100.0 * SUM(
            CASE
                WHEN is_discontinued = 1 THEN 1
                ELSE 0
            END
        ) / NULLIF(COUNT(*), 0),
        2
    ) AS discontinued_pct
FROM medicine_master
WHERE metadata_match_status = 'NAME_MATCH'
  AND therapeutic_class IS NOT NULL
  AND TRIM(therapeutic_class) <> ''
GROUP BY therapeutic_class;


SELECT *
FROM vw_250k_therapeutic_class_analysis
ORDER BY medicine_records DESC
LIMIT 20;


SELECT
    COUNT(*) AS total_matched_records,
    SUM(
        therapeutic_class IS NOT NULL
        AND TRIM(therapeutic_class) <> ''
    ) AS records_with_therapeutic_class,
    SUM(
        therapeutic_class IS NULL
        OR TRIM(therapeutic_class) = ''
    ) AS records_without_therapeutic_class,
    COUNT(DISTINCT therapeutic_class) AS distinct_therapeutic_classes
FROM medicine_master
WHERE metadata_match_status = 'NAME_MATCH';


SELECT *
FROM vw_epharmacy_dashboard_summary;


SELECT *
FROM vw_az_price_quartiles
ORDER BY price_quartile;


SELECT
    manufacturer,
    valid_price_listings,
    distinct_products,
    average_price,
    minimum_price,
    maximum_price,
    discontinued_listings,
    discontinued_pct
FROM vw_az_manufacturer_analysis
ORDER BY valid_price_listings DESC;


SELECT
    therapeutic_class,
    medicine_records,
    distinct_products,
    valid_price_records,
    average_price,
    discontinued_listings,
    discontinued_pct
FROM vw_250k_therapeutic_class_analysis
ORDER BY medicine_records DESC;

DESCRIBE vw_price_pack_anomalies;


SELECT
    src_id,
    product_name,
    manufacturer,
    composition1,
    composition2,
    pack_size,
    price,
    extracted_units,
    calculated_price_per_unit,
    pack_variants,
    lowest_unit_price,
    highest_unit_price,
    unit_price_ratio,
    unit_price_spread_pct,
    review_priority
FROM vw_price_pack_anomalies
ORDER BY
    CASE
        WHEN review_priority = 'HIGH PRIORITY REVIEW' THEN 1
        ELSE 2
    END,
    unit_price_ratio DESC;
    
    
SELECT
    composition_status,
    matched_records,
    identical_prices,
    differing_by_up_to_10_pct,
    differing_by_more_than_10_pct,
    avg_absolute_price_gap_pct,
    max_absolute_price_gap_pct
FROM vw_imr_reconciliation_summary
ORDER BY matched_records DESC;


SELECT clean_az_rows
FROM vw_epharmacy_dashboard_summary;

SELECT imr_price_gaps_over_10pct
FROM vw_epharmacy_dashboard_summary;

SELECT total_pack_anomaly_groups
FROM vw_epharmacy_dashboard_summary;