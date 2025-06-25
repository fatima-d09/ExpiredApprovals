# ExpiredApprovals
An analysis on direct mail campaigns targeting expired approvals. It calculates how often leads have been mailed in the past 6 months, filters campaigns based on specific criteria, and summarizes campaign performance metrics such as response rate, recency, and revenue segmentation.

# 📂 Data Sources
<li> dms_lead: Contains lead-level mailing data. </li>
<li>dms_campaign_member: Links leads to campaigns.</li>
<li>campaign: Contains campaign metadata from Salesforce.</li>

# 🧮 Key Metrics
<li>Times Mailed (last 6 months): How many times a lead has been mailed in the past 6 months.</li>
<li>Mails: Number of leads mailed in a campaign.</li>
<li>Responses: Number of leads that responded (i.e., is_available = 0).</li>
<li>Response Rate: Percentage of responses over total mails.</li>
<li>Recency: Campaign targeting window (e.g., 1–12 months).</li>
<li>Revenue: Revenue tier based on campaign notes.</li>
<li>Business vs Home: Type of revenue source.</li>
  
# 🧠 Explanation of the Code
CTE: TIMES_MAILED_CTE Calculates how many times each lead has been mailed in the last 6 months before the current mail date:
   <li> Filters out mailings before 2023-11-27.</li>
   <li> Ensures only previous mailings are counted (C.mail_date < L.mail_date).c</li><br>
Main Query
<li>Joins campaign, lead, and mailing data to compute campaign-level metrics.v

# 🔗 Joins:
dms_lead → dms_campaign_member → campaign<br>
Left join to TIMES_MAILED_CTE to bring in mailing frequency.

# 📊 Aggregations:
COUNT(*): Total leads in the campaign.<br>
SUM(CASE WHEN is_mailed = 1 THEN 1 ELSE 0 END): Total mailed.<br>
SUM(CASE WHEN is_mailed = 1 AND is_available = 0 THEN 1 ELSE 0 END): Total responses.

# 📈 Derived Columns:
Recency: Extracted from CAMPAIGN_NOTES__C using LIKE patterns.<br>
Revenue: Categorized into tiers like "Under $500k" or "500k+ Rev".<br>
Business vs Home: Based on revenue source keywords.<br>
Response Rate: Calculated as: (Response / Mails) * 100

# 📋 Filters:
Campaigns must be:
<li>Type: direct mail</li>
<li>Date range: 2024-11-27 to 2025-05-07</li><br>
<em>*Notes must include “expired approvals” but exclude “2nd home”, “3rd home”, and “$400k-$499k”.*</em>

# 📤 Output Columns
Column	Description<br>
NAME	Campaign name<br>
NUMBERSENT	Number of leads mailed<br>
STARTDATE	Campaign start date<br>
CAMPAIGN_NOTES__C	Notes describing the campaign<br>
ARTWORK__C, ENVELOPE_ARTWORK__C	Creative assets used<br>
NROW	Number of leads in the campaign<br>
TIMES_MAILED	Times each lead was mailed in the last 6 months<br>
MAILS	Total mailings<br>
RESP	Total responses<br>
RECENCY, REVENUE, BUSINESS_VS_HOME	Categorized campaign attributes<br>
RESPONSE_RATE	% of responses


