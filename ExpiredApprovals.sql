WITH TIMES_MAILED_CTE AS (
    SELECT
        L."company_primary_id",
        L."lead_id_pk",
        L."mail_date",
        COUNT(DISTINCT C."mail_date") AS times_mailed_last_12mo
    FROM ANALYTICS_DATA.RAW_DMS_AWS_DATA_SQLSERVER."dms_lead" L
    JOIN ANALYTICS_DATA.RAW_DMS_AWS_DATA_SQLSERVER."dms_lead" C
        ON L."company_primary_id" = C."company_primary_id"
        AND C."mail_date" < L."mail_date"
        AND C."mail_date" >= DATEADD(month, -6, L."mail_date")
        AND C."mail_date" >= DATE '2023-11-27'
    WHERE C."is_mailed" = 1
    GROUP BY
        L."company_primary_id",
        L."lead_id_pk",
        L."mail_date"
)

SELECT
    X.NAME,
    X.NUMBERSENT,
    X.STARTDATE,
    X.CAMPAIGN_NOTES__C,
    X.ARTWORK__C,
    X.ENVELOPE_ARTWORK__C,
    COUNT(*) AS NROW,
    COALESCE(TM.times_mailed_last_12mo, 0) AS TIMES_MAILED,
    SUM(CASE WHEN L."is_mailed" = 1 THEN 1 ELSE 0 END) AS MAILS,
    SUM(CASE WHEN L."is_mailed" = 1 AND L."is_available" = 0 THEN 1 ELSE 0 END) AS RESP,
    

    -- new column
CASE
    WHEN LOWER(X."CAMPAIGN_NOTES__C") LIKE '%1-12 month%' THEN '1-12 Mo'
    WHEN LOWER(X."CAMPAIGN_NOTES__C") LIKE '%13-24 month%' THEN '13-24 Mo'
    WHEN LOWER(X."CAMPAIGN_NOTES__C") LIKE '%1-24 month%' THEN '1-24 Mo'
    WHEN LOWER(X."CAMPAIGN_NOTES__C") LIKE '%25-36 month%' THEN '25-36 Mo'
    WHEN LOWER(X."CAMPAIGN_NOTES__C") LIKE '%25-48 month%' THEN '25-48 Mo'
    WHEN LOWER(X."CAMPAIGN_NOTES__C") LIKE '%37-48 month%' THEN '37-48 Mo'
        ELSE 'Null'
    END AS recency,  

CASE
    WHEN LOWER(X."CAMPAIGN_NOTES__C") LIKE '%under $500k%' THEN 'Under $500k'
    WHEN LOWER(X."CAMPAIGN_NOTES__C") LIKE '%low rev%' THEN 'Under $500k'
    WHEN LOWER(X."CAMPAIGN_NOTES__C") LIKE '%500k%' THEN '500k+ Rev'
        ELSE 'Other Rev'
    END AS revenue,
    
Case
    When lower(X."CAMPAIGN_NOTES__C") LIKE '%rev: business' THEN 'Business'
    When lower(X."CAMPAIGN_NOTES__C") LIKE '%rev: top home' THEN 'Home'
    WHEN lower(X."CAMPAIGN_NOTES__C") LIKE '%rev: home' THEN 'Home'
        Else 'Other'
    End AS business_vs_home,

-- response rate
TO_CHAR(
    Round(
        CASE
            WHEN SUM (CASE WHEN L."is_mailed" = 1 THEN 1 ELSE 0 END) > 0 THEN (SUM(CASE WHEN L."is_mailed" = 1 AND L."is_available" = 0 THEN 1 ELSE 0 END):: FLOAT / SUM(CASE WHEN L."is_mailed" = 1 THEN 1 ELSE 0 END)) *100
            ELSE 0
        END
    ,2), 'FM999.00'
) || '%' AS RESPONSE_RATE   
    
FROM ANALYTICS_DATA.RAW_DMS_AWS_DATA_SQLSERVER."dms_lead" L

INNER JOIN ANALYTICS_DATA.RAW_DMS_AWS_DATA_SQLSERVER."dms_campaign_member" CM 
    ON CM."lead_id_fk" = L."lead_id_pk"

LEFT JOIN TIMES_MAILED_CTE TM
    ON TM."company_primary_id" = L."company_primary_id"
    AND TM."lead_id_pk" = L."lead_id_pk"
    AND TM."mail_date" = L."mail_date"

RIGHT JOIN (
    SELECT
        CAMPAIGN_ID_18C__C,
        NAME,
        STARTDATE,
        CAMPAIGN_NOTES__C,
        NUMBERSENT,
        NUMBEROFRESPONSES,
        ARTWORK__C,
        ENVELOPE_ARTWORK__C
    FROM ANALYTICS_DATA.RAW_DATA_SALESFORCE.CAMPAIGN
    WHERE LOWER(TYPE) = 'direct mail'
      AND STARTDATE BETWEEN DATE '2024-11-27' AND DATE '2025-05-07'
      AND CAMPAIGN_NOTES__C IS NOT NULL
      AND LOWER(CAMPAIGN_NOTES__C) LIKE '%expired approvals%'
      AND LOWER(CAMPAIGN_NOTES__C) NOT LIKE '%2nd home%'
      AND LOWER(CAMPAIGN_NOTES__C) NOT LIKE '%3rd home%'
      AND LOWER(CAMPAIGN_NOTES__C) NOT LIKE '%$400k-$499k%'
) X ON X.CAMPAIGN_ID_18C__C = CM."campaign_id"

GROUP BY 
    X.NAME,
    X.NUMBERSENT,
    X.STARTDATE,
    X.CAMPAIGN_NOTES__C,
    X.ARTWORK__C,
    X.ENVELOPE_ARTWORK__C,
    TM.times_mailed_last_12mo

ORDER BY X.NAME;
