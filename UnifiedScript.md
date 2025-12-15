THIS WILL BE THE SCRIPT FOR ALL COUNTRIES.  
THE BASIC IDEA IS WE WILL NEED SOME COUNTRY SPECIFIC SOURCES, BUT WE WILL BRING THIS COUNTRY SPECIFIC DATASOURCE INTO COMMON STAGING TABLES AS SOON AS POSSIBLE IN THE PROCESS
STARTING WITH MEXICO

However we actually will start with U.S. Soil and Moisture data.
First we need the U.S. plants as a cross reference file to load into GBIF:

use nativeplants;
SELECT
    scientific_name_no_hybrid             AS gbif_scientific_name
FROM powo_staging
join plants on plants.powo_id = powo_staging.powo_id
WHERE taxon_rank = 'Species'
  AND taxon_status = 'Accepted'
  AND scientific_name_no_hybrid IS NOT NULL;
