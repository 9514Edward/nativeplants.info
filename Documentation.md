
**Get Source Data**
From https://bonap.net/TDC/#
select Nativity>Continental>Native
Hide: Infraspecific Taxa
Unhide: Common Name
10000 taxa per page
Run query,
Copy results to Excel, export to tab delimited txt.
Approx 19565 plants.

**Python Script to load to mysql**

```sql
# Create the table:
CREATE TABLE `bonap_all_natives` (
  `scientific_name` VARCHAR(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `common_name`     VARCHAR(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `usda_code`       VARCHAR(45)  CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `needs_review`    TINYINT(1) DEFAULT 0,
  KEY `idx_bonap_scientific_name` (`scientific_name`),
  KEY `idx_bonap_common_name` (`common_name`)
) ENGINE=InnoDB
  DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

```python
import mysql.connector
import csv


# Database connection configuration
db_config = {
    'host': 'rizz2.cyax1patkaio.us-east-1.rds.amazonaws.com',
    'user': 'xxxxxx',
    'password': 'xxxxxx',  # <-- replace with actual password
    'database': 'nativeplants',  # <-- replace with your database name
}

# Path to the input file
file_path = r"C:\Users\User\Documents\USANativePlantFinder\FullNativebonap.txt"

# Connect to MySQL
conn = mysql.connector.connect(**db_config)
cursor = conn.cursor()

# Prepare INSERT query
insert_query = """
INSERT IGNORE INTO bonap_all_natives (scientific_name, common_name)
VALUES (%s, %s)
"""

# Read the file and insert data
with open(file_path, 'r', encoding='cp1252', errors='replace') as f:
    reader = csv.reader(f, delimiter='\t')
    count = 0
    for row in reader:
        scientific_name = row[0].strip()
        common_name = row[1].strip()
        cursor.execute(insert_query, (scientific_name, common_name))
        count += cursor.rowcount


# Commit and close
conn.commit()
cursor.close()
conn.close()

print(f"Inserted {count} records into bonap_all_natives.")
```

**Download USDA file (need to apply the USDA code to the BONAP data)**
https://plants.usda.gov/downloads
click on Download Complete Plants Checklist (includes subspecies and non natives)
Right click and select Save As.


**Create the table **

```sql
CREATE TABLE `usda_plantlist` (
  `symbol`                       VARCHAR(20)  CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `synonym_symbol`                VARCHAR(20)  CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `scientific_name_with_author`   VARCHAR(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `common_name`                   VARCHAR(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `family`                        VARCHAR(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `author`                        VARCHAR(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `scientific_name`               VARCHAR(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  KEY `scientific_name` (`scientific_name`),
  KEY `symbol` (`symbol`),
  KEY `x_common_name` (`common_name`),
  KEY `x_name_author` (`scientific_name_with_author`)
) ENGINE=InnoDB
  DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

```

**Python Script to upload USDA data**
```python
import mysql.connector
import csv

# Database connection config
db_config = {
    'host': 'rizz2.cyax1patkaio.us-east-1.rds.amazonaws.com',
    'user': 'xxxxxx',
    'password': 'xxxxxxx',  # <-- replace with actual password
    'database': 'nativeplants',  # <-- replace with your database name
    'charset': 'utf8mb4'
}

file_path = r"C:\Users\User\Documents\USANativePlantFinder\plantlst.txt"

conn = mysql.connector.connect(**db_config)
cursor = conn.cursor()

insert_query = """
INSERT INTO usda_plantlist
(symbol, synonym_symbol, scientific_name_with_author, common_name, family)
VALUES (%s, %s, %s, %s, %s)
ON DUPLICATE KEY UPDATE
  synonym_symbol = VALUES(synonym_symbol),
  scientific_name_with_author = VALUES(scientific_name_with_author),
  common_name = VALUES(common_name),
  family = VALUES(family)
"""

batch_size = 1000
batch = []
total_inserted = 0

with open(file_path, newline='', encoding='utf-8') as csvfile:
    reader = csv.DictReader(csvfile, delimiter=',', quotechar='"')
    for row in reader:
        batch.append((
            row['Symbol'].strip(),
            row['Synonym Symbol'].strip() if row['Synonym Symbol'] else None,
            row['Scientific Name with Author'].strip(),
            row['Common Name'].strip() if row['Common Name'] else None,
            row['Family'].strip() if row['Family'] else None
        ))

        if len(batch) == batch_size:
            cursor.executemany(insert_query, batch)
            conn.commit()
            total_inserted += len(batch)
            print(f"Inserted {total_inserted} records...")
            batch = []

    # Insert remaining rows
    if batch:
        cursor.executemany(insert_query, batch)
        conn.commit()
        total_inserted += len(batch)
        print(f"Inserted {total_inserted} records...")

cursor.close()
conn.close()

print(f"Done. Inserted/Updated {total_inserted} records into usda_plantlist.")
```
Add columns scientific_name and author to usda_plantlist and populate them.

```sql
ALTER TABLE usda_plantlist

use nativeplants;
-- Corrected SQL UPDATE statement to populate the 'scientific_name' and 'author' columns
-- based on the 'scientific_name_with_author' column.
--
-- Logic:
-- 1. The first word is always part of the scientific name.
-- 2. The second word is added to the scientific name under two conditions:
--    a. It starts with a lowercase character.
--    b. It starts with the '×' character.
-- 3. The '×' character is removed from the final scientific name string.
-- 4. The remaining words are assigned to the 'author' column.

UPDATE usda_plantlist
SET
    -- First, we determine the 'scientific_name'.
    -- The CASE statement checks for two conditions to determine if the second word
    -- should be included. Then, the REPLACE function removes all '×' characters.
    scientific_name = REPLACE(
        TRIM(
            CASE
                -- Check if a second word exists and if it starts with '×' or a lowercase character.
                WHEN
                    LOCATE(' ', scientific_name_with_author) > 0 AND
                    (SUBSTRING(scientific_name_with_author, LOCATE(' ', scientific_name_with_author) + 1, 1) = '×' OR
                     ASCII(SUBSTRING(scientific_name_with_author, LOCATE(' ', scientific_name_with_author) + 1, 1)) BETWEEN 97 AND 122)
                THEN
                    -- If so, concatenate the first two words.
                    SUBSTRING_INDEX(scientific_name_with_author, ' ', 2)
                ELSE
                    -- Otherwise, only use the first word as the scientific name.
                    SUBSTRING_INDEX(scientific_name_with_author, ' ', 1)
            END
        ),
        '×',
        ''
    ),
    -- Next, we determine the 'author' based on the same conditions as the scientific name.
    author = TRIM(
        CASE
            -- Check if the second word starts with '×' or a lowercase character.
            WHEN
                LOCATE(' ', scientific_name_with_author) > 0 AND
                (SUBSTRING(scientific_name_with_author, LOCATE(' ', scientific_name_with_author) + 1, 1) = '×' OR
                 ASCII(SUBSTRING(scientific_name_with_author, LOCATE(' ', scientific_name_with_author) + 1, 1)) BETWEEN 97 AND 122)
            THEN
                -- If the second word is part of the scientific name, the author starts after the second space.
                SUBSTRING(scientific_name_with_author,
                    LOCATE(' ', scientific_name_with_author, LOCATE(' ', scientific_name_with_author) + 1) + 1)
            ELSE
                -- Otherwise, if only the first word is the scientific name, the author starts after the first space.
                SUBSTRING(scientific_name_with_author,
                    LOCATE(' ', scientific_name_with_author) + 1)
        END
    );


```
**Link the two tables
```sql
use nativeplants;

SET SESSION innodb_lock_wait_timeout = 6000;

UPDATE bonap_all_natives
SET usda_code = NULL, needs_review = NULL;

commit;

update bonap_all_natives set scientific_name = replace(scientific_name,'×','');
commit;
UPDATE bonap_all_natives bonap
JOIN usda_plantlist usda
  ON usda.scientific_name = bonap.scientific_name
SET bonap.usda_code = usda.symbol;



commit;
UPDATE bonap_all_natives bonap
JOIN usda_plantlist usda
  ON usda.common_name = bonap.common_name
SET bonap.usda_code = usda.symbol
WHERE bonap.usda_code IS NULL;
commit;
```

**Get a default image from mediapedia and scrape data from USDA**

```python
import os
import json
import time
import glob
import csv
import requests
import mysql.connector
from selenium import webdriver
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC

# ---- CONFIGURATION ----
download_dir = r"C:\Users\User\Documents\USANativePlantFinder\distribution"
csv_file_path = os.path.join(download_dir, "plant_data.csv")
image_cache_path = r"C:\Users\User\Documents\USANativePlantFinder\image_cache.json"
usda_cache_path = r"C:\Users\User\Documents\USANativePlantFinder\usda_cache.json"

MYSQL_CONFIG = {
    "host": "rizz2.cyax1patkaio.us-east-1.rds.amazonaws.com",
    "user": "c6xvsSTa",
    "password": "dhqDjL,vw7t!y%RY",
    "database": "nativeplants",
}

# Load caches or initialize empty
if os.path.exists(usda_cache_path):
    with open(usda_cache_path, 'r', encoding='utf-8') as f:
        usda_cache = json.load(f)
else:
    usda_cache = {}

if os.path.exists(image_cache_path):
    with open(image_cache_path, 'r', encoding='utf-8') as f:
        image_cache = json.load(f)
else:
    image_cache = {}

# Selenium setup
options = Options()
options.add_argument("--headless")
options.add_argument("--disable-gpu")
prefs = {
    "download.default_directory": download_dir,
    "download.prompt_for_download": False,
    "download.directory_upgrade": True,
    "safebrowsing.enabled": True
}
options.add_experimental_option("prefs", prefs)
driver = webdriver.Chrome(options=options)

def insert_ignore(cursor, query, params):
    try:
        cursor.execute(query, params)
    except mysql.connector.Error as err:
        print(f"MySQL Error: {err}")

def get_commons_thumbnail_cached(search_term, width=200):
    if search_term in image_cache:
        return image_cache[search_term]
    print(f"Searching image for: {search_term}")
    search_url = "https://commons.wikimedia.org/w/api.php"
    params = {
        "action": "query",
        "format": "json",
        "prop": "pageimages",
        "generator": "search",
        "gsrsearch": f'intitle:"{search_term}"',
        "gsrlimit": 5,  # get a few results to check titles explicitly
        "piprop": "thumbnail",
        "pithumbsize": width,
    }
    try:
        response = requests.get(search_url, params=params, timeout=10)
        data = response.json()
        pages = data.get("query", {}).get("pages", {})
        
        # Filter pages to those with exact term in title (case insensitive)
        for page in pages.values():
            title = page.get("title", "")
            if search_term.lower() in title.lower():
                thumbnail = page.get("thumbnail", {}).get("source")
                if thumbnail:
                    image_cache[search_term] = thumbnail
                    return thumbnail
    except Exception as e:
        print(f"Error fetching image for {search_term}: {e}")

    image_cache[search_term] = ""
    return None


def download_distribution_csv(symbol, scientific_name, common_name):
    """
    Scrapes USDA metadata tables and distribution CSV from the plant profile page.
    Returns metadata dict on success or None on failure.
    """
    url = f"https://plants.sc.egov.usda.gov/plant-profile/{symbol}"
    driver.get(url)

    try:
        # Wait for the metadata section to load
        WebDriverWait(driver, 10).until(
            EC.presence_of_element_located((By.CLASS_NAME, "general-info"))
        )

        metadata = {}

        # Scrape main metadata table
        table = driver.find_element(By.CSS_SELECTOR, "table.usa-table.margin-top-0")
        rows = table.find_elements(By.TAG_NAME, "tr")
        for row in rows:
            th = row.find_element(By.TAG_NAME, "th")
            td = row.find_element(By.TAG_NAME, "td")
            key = th.find_element(By.TAG_NAME, "h3").text.strip().lower().replace(" ", "_")
            spans = td.find_elements(By.TAG_NAME, "span")
            if spans:
                value = " | ".join(span.text.strip() for span in spans if span.text.strip())
            else:
                value = td.text.strip()
            metadata[key] = value

        # Scrape classification table
        classification_table = driver.find_element(By.CSS_SELECTOR, "table.classification-table")
        rows = classification_table.find_elements(By.TAG_NAME, "tr")
        for row in rows:
            th = row.find_element(By.TAG_NAME, "th")
            td = row.find_element(By.TAG_NAME, "td")
            key = th.find_element(By.TAG_NAME, "h3").text.strip().lower().replace(" ", "_")
            spans = td.find_elements(By.TAG_NAME, "span")
            texts = [span.text.strip() for span in spans if span.text.strip()]
            metadata[key] = " | ".join(texts)

        # Add scientific_name and common_name from params (not scraped)
        metadata["scientific_name"] = scientific_name
        metadata["common_name"] = common_name

        print(f"Scraped metadata for {symbol}: {metadata}")

        # Download distribution CSV
        first_button = WebDriverWait(driver, 10).until(
            EC.presence_of_element_located((By.LINK_TEXT, "Download Distribution Data"))
        )
        driver.execute_script("arguments[0].scrollIntoView({block: 'center'});", first_button)
        time.sleep(0.5)
        driver.execute_script("arguments[0].click();", first_button)
        print(f"📥 Opened download panel for {symbol}")

        second_link = WebDriverWait(driver, 10).until(
            EC.presence_of_element_located((By.XPATH, "//a[@download='DistributionData.csv']"))
        )
        blob_url = second_link.get_attribute("href")

        csv_data = driver.execute_async_script("""
            const url = arguments[0];
            const callback = arguments[1];
            fetch(url)
                .then(r => r.blob())
                .then(blob => blob.text())
                .then(text => callback(text))
                .catch(err => callback(null));
        """, blob_url)

        if not csv_data:
            raise Exception("Failed to retrieve CSV from blob URL.")

        csv_text = csv_data.lstrip("\ufeff")
        lines = csv_text.splitlines()
        if lines and lines[0].strip().lower().startswith("distribution data"):
            lines = lines[1:]

        csv_reader = csv.DictReader(lines)
        dist_rows = [
            (
                row.get("Symbol", ""),
                row.get("Country", ""),
                row.get("State", ""),
                row.get("State FIP", ""),
                row.get("County", ""),
                row.get("County FIP", "")
            )
            for row in csv_reader
        ]

        # Add distribution rows to metadata so caller can insert them later
        metadata["distribution_rows"] = dist_rows

        return metadata

    except Exception as e:
        print(f"⚠️ Failed to load data for {symbol}: {e}")
        return None

def main():
    # DB connection
    conn = mysql.connector.connect(**MYSQL_CONFIG)
    cursor = conn.cursor(dictionary=True)

    try:
        cursor.execute("SELECT * FROM bonap_all_natives WHERE usda_code IS NOT NULL  ORDER BY usda_code")
        plants = cursor.fetchall()

        for plant in plants:
            symbol = plant.get("usda_code")
            scientific_name = plant.get("scientific_name")
            common_name = plant.get("common_name")

            # Get cached or fetch Wikimedia image
            image_url = plant.get("image", "").strip()
            if not image_url:
                image_url = get_commons_thumbnail_cached(scientific_name)

            # Insert basic plant info
            insert_ignore(cursor,
                """
                INSERT IGNORE INTO plants (usda_symbol, scientific_name, common_name)
                VALUES (%s, %s, %s)
                """,
                (symbol, scientific_name, common_name)
            )

            # Get plant_id from usda_plantlist for linking
            cursor.execute("SELECT DISTINCT symbol FROM usda_plantlist WHERE symbol = %s", (symbol,))
            row = cursor.fetchone()
            plant_id = row["symbol"] if row else None

            if plant_id and image_url:
                insert_ignore(cursor,
                    """
                    INSERT IGNORE INTO plant_images (plant_id, image_url, source)
                    VALUES (%s, %s, %s)
                    """,
                    (plant_id, image_url, "wikimedia")
                )

            # Scrape USDA metadata + distribution CSV
            metadata = download_distribution_csv(symbol, scientific_name, common_name)
            if metadata:
                # Insert/update plants table with USDA metadata
                try:
                    cursor.execute("""
                        INSERT INTO plants (
                            usda_symbol, scientific_name, common_name,
                            usda_group, usda_duration, usda_growth_habit, usda_native_status,
                            usda_kingdom, usda_subkingdom, usda_superdivision, usda_division,
                            usda_class, usda_subclass, usda_order, usda_family, usda_genus, usda_species
                        ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
                        ON DUPLICATE KEY UPDATE
                            scientific_name=VALUES(scientific_name),
                            common_name=VALUES(common_name),
                            usda_group=VALUES(usda_group),
                            usda_duration=VALUES(usda_duration),
                            usda_growth_habit=VALUES(usda_growth_habit),
                            usda_native_status=VALUES(usda_native_status),
                            usda_kingdom=VALUES(usda_kingdom),
                            usda_subkingdom=VALUES(usda_subkingdom),
                            usda_superdivision=VALUES(usda_superdivision),
                            usda_division=VALUES(usda_division),
                            usda_class=VALUES(usda_class),
                            usda_subclass=VALUES(usda_subclass),
                            usda_order=VALUES(usda_order),
                            usda_family=VALUES(usda_family),
                            usda_genus=VALUES(usda_genus),
                            usda_species=VALUES(usda_species)
                    """, (
                        symbol,
                        metadata.get("scientific_name"),
                        metadata.get("common_name"),
                        metadata.get("group"),
                        metadata.get("duration"),
                        metadata.get("growth_habits") or metadata.get("growth_habit"),  # fix key name
                        metadata.get("native_status"),
                        metadata.get("kingdom"),
                        metadata.get("subkingdom"),
                        metadata.get("superdivision"),
                        metadata.get("division"),
                        metadata.get("class"),
                        metadata.get("subclass"),
                        metadata.get("order"),
                        metadata.get("family"),
                        metadata.get("genus"),
                        metadata.get("species")
                    ))
                except mysql.connector.Error as err:
                    print(f"❌ DB error for {symbol}: {err}")

                # Remove old distribution data
                cursor.execute("DELETE FROM usda_distribution WHERE `Symbol` = %s", (symbol,))
                # Insert new distribution data rows
                dist_rows = metadata.get("distribution_rows", [])
                if dist_rows:
                    cursor.executemany("""
                        INSERT INTO usda_distribution
                            (`Symbol`, `Country`, `State`, `State FIP`, `County`, `County FIP`)
                        VALUES (%s, %s, %s, %s, %s, %s)
                    """, dist_rows)

            conn.commit()

    finally:
        cursor.close()
        conn.close()
        driver.quit()

    # Save caches
    with open(image_cache_path, 'w', encoding='utf-8') as f:
        json.dump(image_cache, f, indent=2, ensure_ascii=False)
    with open(usda_cache_path, 'w', encoding='utf-8') as f:
        json.dump(usda_cache, f, indent=2, ensure_ascii=False)

    print("✅ Plants inserted with image and USDA data.")

if __name__ == "__main__":
    main()


```

**Populate state_region and other data fixes/initializations**

```sql
INSERT IGNORE INTO state_region (state_name, state_code, country_code)
SELECT DISTINCT 
    state,
    CASE 
        WHEN state = 'Alabama' THEN 'AL'
        WHEN state = 'Alaska' THEN 'AK'
        WHEN state = 'Arizona' THEN 'AZ'
        WHEN state = 'Arkansas' THEN 'AR'
        WHEN state = 'California' THEN 'CA'
        WHEN state = 'Colorado' THEN 'CO'
        WHEN state = 'Connecticut' THEN 'CT'
        WHEN state = 'Delaware' THEN 'DE'
        WHEN state = 'District of Columbia' THEN 'DC'
        WHEN state = 'Florida' THEN 'FL'
        WHEN state = 'Georgia' THEN 'GA'
        WHEN state = 'Hawaii' THEN 'HI'
        WHEN state = 'Idaho' THEN 'ID'
        WHEN state = 'Illinois' THEN 'IL'
        WHEN state = 'Indiana' THEN 'IN'
        WHEN state = 'Iowa' THEN 'IA'
        WHEN state = 'Kansas' THEN 'KS'
        WHEN state = 'Kentucky' THEN 'KY'
        WHEN state = 'Louisiana' THEN 'LA'
        WHEN state = 'Maine' THEN 'ME'
        WHEN state = 'Maryland' THEN 'MD'
        WHEN state = 'Massachusetts' THEN 'MA'
        WHEN state = 'Michigan' THEN 'MI'
        WHEN state = 'Minnesota' THEN 'MN'
        WHEN state = 'Mississippi' THEN 'MS'
        WHEN state = 'Missouri' THEN 'MO'
        WHEN state = 'Montana' THEN 'MT'
        WHEN state = 'Nebraska' THEN 'NE'
        WHEN state = 'Nevada' THEN 'NV'
        WHEN state = 'New Hampshire' THEN 'NH'
        WHEN state = 'New Jersey' THEN 'NJ'
        WHEN state = 'New Mexico' THEN 'NM'
        WHEN state = 'New York' THEN 'NY'
        WHEN state = 'North Carolina' THEN 'NC'
        WHEN state = 'North Dakota' THEN 'ND'
        WHEN state = 'Ohio' THEN 'OH'
        WHEN state = 'Oklahoma' THEN 'OK'
        WHEN state = 'Oregon' THEN 'OR'
        WHEN state = 'Pennsylvania' THEN 'PA'
        WHEN state = 'Rhode Island' THEN 'RI'
        WHEN state = 'South Carolina' THEN 'SC'
        WHEN state = 'South Dakota' THEN 'SD'
        WHEN state = 'Tennessee' THEN 'TN'
        WHEN state = 'Texas' THEN 'TX'
        WHEN state = 'Utah' THEN 'UT'
        WHEN state = 'Vermont' THEN 'VT'
        WHEN state = 'Virginia' THEN 'VA'
        WHEN state = 'Washington' THEN 'WA'
        WHEN state = 'West Virginia' THEN 'WV'
        WHEN state = 'Wisconsin' THEN 'WI'
        WHEN state = 'Wyoming' THEN 'WY'
        WHEN state = 'Alberta' THEN 'AB'
        WHEN state = 'British Columbia' THEN 'BC'
        WHEN state = 'Manitoba' THEN 'MB'
        WHEN state = 'New Brunswick' THEN 'NB'
        WHEN state = 'Newfoundland and Labrador' THEN 'NL'
        WHEN state = 'Northwest Territories' THEN 'NT'
        WHEN state = 'Nova Scotia' THEN 'NS'
        WHEN state = 'Nunavut' THEN 'NU'
        WHEN state = 'Ontario' THEN 'ON'
        WHEN state = 'Prince Edward Island' THEN 'PE'
        WHEN state = 'Quebec' THEN 'QC'
        WHEN state = 'Saskatchewan' THEN 'SK'
        WHEN state = 'Yukon' THEN 'YT'
        WHEN state = 'Aguascalientes' THEN 'AGU'
        WHEN state = 'Baja California' THEN 'BCN'
        WHEN state = 'Baja California Sur' THEN 'BCS'
        WHEN state = 'Campeche' THEN 'CAM'
        WHEN state = 'Chiapas' THEN 'CHP'
        WHEN state = 'Chihuahua' THEN 'CHH'
        WHEN state = 'Coahuila' THEN 'COA'
        WHEN state = 'Colima' THEN 'COL'
        WHEN state = 'Durango' THEN 'DUR'
        WHEN state = 'Guanajuato' THEN 'GUA'
        WHEN state = 'Guerrero' THEN 'GRO'
        WHEN state = 'Hidalgo' THEN 'HID'
        WHEN state = 'Jalisco' THEN 'JAL'
        WHEN state = 'Mexico State' THEN 'MEX'
        WHEN state = 'Michoacán' THEN 'MIC'
        WHEN state = 'Morelos' THEN 'MOR'
        WHEN state = 'Nayarit' THEN 'NAY'
        WHEN state = 'Nuevo León' THEN 'NLE'
        WHEN state = 'Oaxaca' THEN 'OAX'
        WHEN state = 'Puebla' THEN 'PUE'
        WHEN state = 'Querétaro' THEN 'QUE'
        WHEN state = 'Quintana Roo' THEN 'ROO'
        WHEN state = 'San Luis Potosí' THEN 'SLP'
        WHEN state = 'Sinaloa' THEN 'SIN'
        WHEN state = 'Sonora' THEN 'SON'
        WHEN state = 'Tabasco' THEN 'TAB'
        WHEN state = 'Tamaulipas' THEN 'TAM'
        WHEN state = 'Tlaxcala' THEN 'TLA'
        WHEN state = 'Veracruz' THEN 'VER'
        WHEN state = 'Yucatán' THEN 'YUC'
        WHEN state = 'Zacatecas' THEN 'ZAC'
    END AS state_code,
    CASE 
        WHEN country = 'United States' THEN 'USA'
        WHEN country = 'Canada' THEN 'CAN'
        WHEN country = 'Mexico' THEN 'MEX'
    END AS country_code
FROM usda_distribution;

INSERT IGNORE INTO county (country_code, state_code, county_name)
SELECT DISTINCT 
    country.country_code,
    state_region.state_code,
    usda_distribution.County
FROM usda_distribution
JOIN state_region 
    ON state_region.state_name = usda_distribution.state
    AND state_region.country_code = 
        CASE 
            WHEN usda_distribution.country = 'United States' THEN 'USA'
            WHEN usda_distribution.country = 'Canada' THEN 'CAN'
            WHEN usda_distribution.country = 'Mexico' THEN 'MEX'
        END
JOIN country 
    ON country.country_name = usda_distribution.country
WHERE COALESCE(usda_distribution.County, '') <> '';

INSERT IGNORE INTO state_plant (state_code, plant_id)
SELECT DISTINCT
    sr.state_code,
    p.plant_id
FROM usda_distribution ud
JOIN state_region sr
    ON sr.state_name = ud.state
    AND sr.country_code = CASE
        WHEN ud.country = 'United States' THEN 'USA'
        WHEN ud.country = 'Canada' THEN 'CAN'
        WHEN ud.country = 'Mexico' THEN 'MEX'
    END
JOIN plants p
    ON p.usda_symbol = ud.symbol
WHERE COALESCE(ud.state, '') <> ''
  AND COALESCE(ud.symbol, '') <> '';


INSERT IGNORE INTO county_plant (county_id, plant_id)
SELECT DISTINCT
    c.county_id,
    p.plant_id
FROM usda_distribution ud
JOIN state_region sr
    ON sr.state_name = ud.state
    AND sr.country_code = CASE
        WHEN ud.country = 'United States' THEN 'USA'
        WHEN ud.country = 'Canada' THEN 'CAN'
        WHEN ud.country = 'Mexico' THEN 'MEX'
    END
JOIN county c
    ON c.county_name = ud.county
    AND c.state_code = sr.state_code
JOIN plants p
    ON p.usda_symbol = ud.symbol
WHERE COALESCE(ud.county, '') <> ''
  AND COALESCE(ud.symbol, '') <> '';



```
