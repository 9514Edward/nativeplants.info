THIS WILL BE THE SCRIPT FOR ALL COUNTRIES.  
THE BASIC IDEA IS WE WILL NEED SOME COUNTRY SPECIFIC SOURCES, BUT WE WILL BRING THIS COUNTRY SPECIFIC DATASOURCE INTO COMMON STAGING TABLES AS SOON AS POSSIBLE IN THE PROCESS
STARTING WITH MEXICO

Images:
These 4 scripts need to be combined into one.

run_wikipedia_top_images_RETRY.py
resize_images.py
plant_images_cleanup.py
run_make_lant_images_in_batches.py

However we actually will start with U.S. Soil and Moisture data.

Soil datasource 1: https://www.gbif.org/occurrence/download?basis_of_record=HUMAN_OBSERVATION&basis_of_record=PRESERVED_SPECIMEN&has_coordinate=true&has_geospatial_issue=false&taxon_key=7707728&year=1954,2025&advanced=1&coordinate_uncertainty_in_meters=0,9040&occurrence_status=present
We are going to infer the soil and climate from the geolocation coordinates.
Download the file.  Extract the files.  Upload only occurrences file to S3.

Soil datasource 2: TRY traits: 602, 600, 593, 761, 3410, 1138, 1140, 825, 1144, 30, 603, 1041, 229, 61

Soil datasource 3: https://bien.nceas.ucsb.edu/bien/

Run script IntegrateSoilMoistureData.py
