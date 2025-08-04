
**Get Source Data**
From https://bonap.net/TDC/#
select Nativity>Continental>Native
Hide: Infraspecific Taxa
Unhide: Common Name
10000 taxa per page
Run query,
Copy results to Excel, export to txt.
Approx 19565 plants.

**Python Script to load to mysql**
```python
import mysql.connector
import csv

# Create the table:
CREATE TABLE `bonap_all_natives` (
   `scientific_name` varchar(255) CHARACTER SET utf8 NOT NULL,
   `common_name` varchar(255) CHARACTER SET utf8 DEFAULT NULL,
   `usda_code` varchar(45) DEFAULT NULL,
   PRIMARY KEY (`scientific_name`)
 ) ENGINE=InnoDB DEFAULT CHARSET=latin1

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
CREATE TABLE usda_plantlist (
    symbol VARCHAR(20) NOT NULL PRIMARY KEY,
    synonym_symbol VARCHAR(20),
    scientific_name_with_author VARCHAR(255) NOT NULL,
    common_name VARCHAR(255),
    family VARCHAR(100)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

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

