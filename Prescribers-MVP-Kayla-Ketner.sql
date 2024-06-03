--Prescriber with highest total number of claims
--1a:
SELECT npi, SUM(total_claim_count) AS max_claim_total
FROM prescription 
GROUP BY npi
ORDER BY max_claim_total DESC
LIMIT 1;


--1b:
SELECT npi, nppes_provider_first_name, nppes_provider_last_org_name, specialty_description, SUM(total_claim_count) AS max_claim_total
FROM prescription INNER JOIN prescriber USING(npi)
GROUP BY npi, nppes_provider_first_name, nppes_provider_last_org_name, specialty_description
ORDER BY max_claim_total DESC
LIMIT 1;


--Specialty with most total number of claims
--2a: Family Practice
SELECT DISTINCT specialty_description, SUM(total_claim_count)AS total_claims
FROM prescriber INNER JOIN prescription USING(npi)
GROUP BY specialty_description
ORDER BY total_claims DESC
LIMIT 1;


--Specialty with most opioid claims
--2b: Nurse Practitioner
SELECT DISTINCT specialty_description, SUM(total_claim_count)AS total_claims
FROM prescriber INNER JOIN prescription USING(npi) INNER JOIN drug USING (drug_name)
WHERE opioid_drug_flag='Y'
GROUP BY specialty_description
ORDER BY total_claims DESC
LIMIT 1;


--Yes, there are 15 specialty decriptions that have no associated prescriptions.
--2c: 
SELECT specialty_description, COUNT (total_claim_count)AS claim_count
FROM prescriber LEFT JOIN prescription USING(npi)
GROUP BY specialty_description
HAVING COUNT(total_claim_count)='0';


--Care Coordinator, Orthopaedic Surgery, and Pain Management specialties have the highest percentage of opioids.
--2d:difficult
SELECT DISTINCT specialty_description, ROUND(((SUM(opioid_claims))/(SUM(total_claims))*100),2)AS percentage_opioid
FROM (SELECT DISTINCT specialty_description, SUM(total_claim_count)AS opioid_claims
	FROM prescriber INNER JOIN prescription USING(npi) INNER JOIN drug USING (drug_name)
	WHERE opioid_drug_flag='Y'
	GROUP BY specialty_description) AS otable 
	INNER JOIN (SELECT DISTINCT specialty_description, SUM (total_claim_count)AS total_claims
	FROM prescriber INNER JOIN prescription USING(npi) 
	GROUP BY specialty_description)AS ttable USING (specialty_description)
GROUP BY specialty_description
ORDER BY percentage_opioid DESC;


--Which generic drug had the highest total cost?
--3a: Insulin
SELECT generic_name, SUM(total_drug_cost)AS total_cost
FROM drug INNER JOIN prescription USING(drug_name)
GROUP BY generic_name
ORDER BY total_cost DESC
LIMIT 1;


--3b:
--Which generic drug has the highest total cost per day?
SELECT generic_name, 										ROUND(MAX(total_drug_cost/total_day_supply),2)AS max_per_day
FROM drug INNER JOIN prescription USING(drug_name)
GROUP BY generic_name
ORDER BY max_per_day DESC
LIMIT 1;


--4a:
SELECT DISTINCT drug_name, 
	CASE WHEN opioid_drug_flag ='Y'THEN 'opioid'
	WHEN antibiotic_drug_flag='Y'THEN 'antibiotic'
	ELSE 'neither' END AS drug_type
FROM drug;


--4b: More money was spent on opioids.
WITH drug_type AS (SELECT DISTINCT drug_name, 
	CASE WHEN opioid_drug_flag ='Y'THEN 'opioid'
	WHEN antibiotic_drug_flag='Y'THEN 'antibiotic'
	ELSE 'neither' END AS drug_type
	FROM drug) 

SELECT SUM(CASE WHEN drug_type='opioid'THEN total_drug_cost::money END) AS sum_opioid,
	SUM (CASE WHEN drug_type='antibiotic'THEN total_drug_cost::money END)AS sum_anti
FROM drug_type INNER JOIN prescription USING(drug_name)
WHERE drug_type='opioid' OR drug_type='antibiotic';


--How many CBSAs in TN?
--5a: 10
SELECT COUNT(DISTINCT cbsa)
FROM cbsa LEFT JOIN fips_county USING(fipscounty)
WHERE state='TN';


--WHICH CBSA has the largest pop and the smallest pop?
--5b: largest pop=Nashville-Davidson-Murfreesboro-Franklin, TN & smallest pop=Morristown, TN
SELECT cbsaname, SUM(population)AS total_pop
FROM cbsa INNER JOIN population USING(fipscounty)
GROUP BY cbsaname
ORDER BY total_pop;


--largest county not included in a CBSA
--5c: Sevier with population of 95,523
SELECT SUM(population)AS total_pop, county
FROM cbsa RIGHT JOIN population USING(fipscounty) INNER JOIN fips_county USING (fipscounty)
WHERE cbsaname IS NULL 
GROUP BY cbsaname, county
ORDER BY total_pop DESC
LIMIT 1;


--6a:
SELECT drug_name, total_claim_count 
FROM prescription
WHERE total_claim_count>=3000
ORDER BY total_claim_count;


--6b:
SELECT drug_name, total_claim_count,
	CASE WHEN opioid_drug_flag='Y'THEN 'Opioid' 
		WHEN opioid_drug_flag<>'Y' THEN 'N/A'END AS opioid_label
FROM prescription LEFT JOIN drug USING (drug_name)
WHERE total_claim_count>=3000
ORDER BY total_claim_count;


--6c:
SELECT drug_name, nppes_provider_first_name, nppes_provider_last_org_name, total_claim_count,
	CASE WHEN opioid_drug_flag='Y'THEN 'Opioid' 
		WHEN opioid_drug_flag<>'Y' THEN 'N/A'END AS opioid_label
FROM prescription LEFT JOIN drug USING (drug_name)
	LEFT JOIN prescriber USING(npi)
WHERE total_claim_count>=3000
ORDER BY total_claim_count;


--7
--7a:
SELECT npi, drug_name
FROM prescriber CROSS JOIN drug 
WHERE specialty_description='Pain Management' AND nppes_provider_city='NASHVILLE' AND opioid_drug_flag='Y';


--7b:
SELECT prescriber.npi, drug.drug_name, total_claim_count
FROM prescriber CROSS JOIN drug LEFT JOIN prescription USING (npi,drug_name)
WHERE specialty_description='Pain Management' AND nppes_provider_city='NASHVILLE' AND opioid_drug_flag='Y'
GROUP BY prescriber.npi, drug.drug_name, total_claim_count;


--7c:
SELECT prescriber.npi, drug.drug_name, COALESCE(total_claim_count, 0)
FROM prescriber CROSS JOIN drug LEFT JOIN prescription USING (npi,drug_name)
WHERE specialty_description='Pain Management' AND nppes_provider_city='NASHVILLE' AND opioid_drug_flag='Y'
GROUP BY prescriber.npi, drug.drug_name,total_claim_count;