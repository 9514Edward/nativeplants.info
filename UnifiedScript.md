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
We are going to use this download for the basis if all new records to be added to my database.  We will infer the soil and climate from the geolocation coordinates.  Plus get other data as available.
Download the file.  Extract the files.  Upload only occurrences file to S3.

Soil datasource 2: TRY traits: 602, 600, 593, 761, 3410, 1138, 1140, 825, 1144, 30, 603, 1041, 229, 61

Soil datasource 3: https://bien.nceas.ucsb.edu/bien/

Run script IntegrateSoilMoistureData.py

Bien data for future use.:
                         whole plant height 10167913
                    whole plant growth form   330047
          whole plant growth form diversity    67413
                      whole plant woodiness    49060
                 maximum whole plant height     3722
              maximum whole plant longevity     1065
              longest whole plant longevity      730
                 minimum whole plant height      658
 whole plant primary juvenile period length      375
