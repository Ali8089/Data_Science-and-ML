##Data_set = https://www.kaggle.com/datasets/ehtishamsadiq/uncleaned-laptop-price-dataset

USE my_db;
SELECT * FROM laptopdata;

# Backup dataset
CREATE TABLE laptop_backup LIKE laptopdata;
INSERT INTO laptop_backup SELECT * FROM laptopdata;

#Change Column name
ALTER TABLE laptopdata 
RENAME COLUMN `Unnamed: 0` TO `index`;

#Drop complete null rows
SET SQL_SAFE_UPDATES = 0;

#Check for null values in specific columns

SELECT * 
FROM laptopdata
WHERE Company IS NULL OR TRIM(Company) = ''
    OR TypeName IS NULL OR TRIM(TypeName) = ''
    OR Inches IS NULL OR Inches = ''
    OR `Cpu` IS NULL OR TRIM(`Cpu`) = ''
    OR ScreenResolution IS NULL OR TRIM(`Cpu`) = ''
    OR `Ram` IS NULL OR `Ram` = ''
    OR `Memory` IS NULL OR TRIM(`Memory`) = ''
    OR `Gpu` IS NULL OR TRIM(`Gpu`) = ''
    OR `OpSys` IS NULL OR TRIM(`OpSys`) = ''
    OR `Price` IS NULL
    OR Weight IS NULL OR Weight = '' ; # FOUND A 0.00 KG!!

#REPLACE WITH MEAN!
UPDATE laptopdata
SET `Weight` = (
	SELECT avg_weight FROM (
		SELECT ROUND(AVG(Weight),2) AS 'avg_weight'
		FROM laptopdata 
        )AS temp
)
WHERE `Weight`  = 0.00;

#Complete NULL Row
DELETE FROM laptopdata
WHERE `index` IN (
    SELECT `index` FROM (
        SELECT `index` FROM laptopdata
        WHERE Company IS NULL
          AND TypeName IS NULL
          AND Inches IS NULL
          AND ScreenResolution IS NULL
          AND Cpu IS NULL
          AND Memory IS NULL
          AND Gpu IS NULL
          AND OpSys IS NULL
          AND Weight IS NULL
          AND Price IS NULL
    ) AS temp
);

#Check for symbols and broken data
SELECT * FROM laptopdata
WHERE  
	Company = REGEXP_SUBSTR(Company,'[^A-Z0-9]+') 
	OR TypeName = REGEXP_SUBSTR(TypeName,'[^A-Z0-9]+') 
    OR Inches = REGEXP_SUBSTR(Inches,'[^A-Z0-9]+') 
	OR ScreenResolution = REGEXP_SUBSTR(ScreenResolution,'[^A-Z0-9]+') 
    OR `Cpu` = REGEXP_SUBSTR(`Cpu`,'[^A-Z0-9]+') 
    OR  `OpSys`  = REGEXP_SUBSTR(`OpSys` ,'[^A-Z0-9]+') 
	OR  `Weight` = REGEXP_SUBSTR(`Weight` ,'[^A-Z0-9]+') #found
    OR `Ram`  = REGEXP_SUBSTR(`Ram` ,'[^A-Z0-9]+') 
    OR `Memory`  = REGEXP_SUBSTR(`Memory` ,'[^A-Za-z0-9]+'); #found
    
DELETE FROM laptopdata 
WHERE `Memory`  = REGEXP_SUBSTR(`Memory` ,'[^A-Za-z0-9]+'); #found

DELETE FROM laptopdata 
WHERE `Weight`  = REGEXP_SUBSTR(`Weight` ,'[^A-Za-z0-9]+'); #found

# Could have also REPLACED  WITH MEAN()
UPDATE laptopdata
SET `Weight` = (
	SELECT avg_weight FROM (
		SELECT AVG(Weight) AS 'avg_weight'
		FROM laptopdata 
        )AS temp
)
WHERE `Weight`  = REGEXP_SUBSTR(`Weight` ,'[^A-Za-z0-9]+'); #found

# Check for Duplicates

SELECT  Company, TypeName, Inches, ScreenResolution, `Cpu`, Ram, 
		`Memory`, Gpu, OpSys, Weight, Price, COUNT(*) AS duplicate_count
FROM laptopdata
GROUP BY Company, TypeName, Inches, ScreenResolution, `Cpu`, Ram,
		`Memory`, Gpu, OpSys, Weight, Price
HAVING duplicate_count > 1;
    
#Drop Duplicates 
DELETE FROM laptopdata
WHERE `index` NOT IN (
SELECT minindex FROM (
SELECT  MIN(`index`) AS `minindex`
FROM laptopdata
GROUP BY Company, TypeName, Inches, ScreenResolution, `Cpu`, Ram,
		`Memory`, Gpu, OpSys, Weight, Price ) AS temp);  

#check for size
SELECT DATA_LENGTH/1024 FROM information_schema.TABLES
WHERE TABLE_SCHEMA = 'campusx'
AND TABLE_NAME = 'laptopdata';

#Clean columns
#Clean Ram column

UPDATE laptopdata t1
SET Ram = REPLACE(Ram,'GB','');
# Change DataType
ALTER TABLE laptopdata
MODIFY COLUMN Ram INT;
    
#Weight Column
UPDATE laptopdata
SET Weight = REPLACE(Weight,'kg','');

ALTER TABLE laptopdata
MODIFY COLUMN Weight DECIMAL(10,2);

#Price Column

SELECT Price FROM laptopdata;
#Round the price
UPDATE laptopdata
SET Price = ROUND(Price);

ALTER TABLE laptopdata
MODIFY COLUMN Price INT;

#OpSys Column
SELECT * FROM laptopdata;

UPDATE laptopdata
SET OpSys = CASE 
		WHEN OpSys LIKE '%mac%' THEN 'MAC'
		WHEN OpSys LIKE 'Windows%' THEN 'WINDOWS'
		WHEN OpSys LIKE '%Linux%' THEN 'LINUX'
		WHEN OpSys LIKE 'No OS' THEN 'N/A'
		ELSE 'OTHER'
END;

#Gpu Column

SELECT Gpu FROM laptopdata;


ALTER TABLE laptopdata
ADD COLUMN  Gpu_brand VARCHAR(255) AFTER Gpu;

UPDATE laptopdata t1
SET Gpu_brand =( SELECT Gpu_brand FROM  (SELECT SUBSTRING_INDEX(Gpu,' ',1) AS 'Gpu_brand'
				 FROM laptopdata t2 
                 WHERE t1.index = t2.index) AS temp);


ALTER TABLE laptopdata
ADD COLUMN  Gpu_name VARCHAR(255) AFTER Gpu_brand;

UPDATE laptopdata t1
SET Gpu_name = (SELECT Gpu_Name FROM  (SELECT REPLACE(Gpu,Gpu_brand,'') AS Gpu_Name 
				FROM laptopdata t2
                WHERE t1.index = t2.index) AS temp);
 
ALTER TABLE laptopdata
DROP COLUMN Gpu;

#Cpu Column

ALTER TABLE laptopdata
ADD COLUMN Cpu_brand VARCHAR(255) AFTER Cpu,
ADD COLUMN Cpu_model VARCHAR(255) AFTER Cpu_brand,
ADD COLUMN Cpu_speed VARCHAR(255) AFTER Cpu_model;


UPDATE  laptopdata t1
SET Cpu_brand = (SELECT Cpu_brand 
					FROM(
					SELECT SUBSTRING_INDEX(Cpu,' ',1) AS 'Cpu_brand' 
                    FROM laptopdata t2
					WHERE t1.index = t2.index) AS temp);



SELECT * FROM laptopdata;
UPDATE  laptopdata t1
SET Cpu_Speed = (SELECT Cpu_speed 
					FROM(
					SELECT REPLACE(SUBSTRING_INDEX(Cpu,' ',-1),'GHz','') AS 'Cpu_speed'
                    FROM laptopdata t2
					WHERE t1.index = t2.index) AS temp);
                    
                    
                    
UPDATE  laptopdata t1
SET Cpu_model = (SELECT Cpu_brand
					FROM(
					SELECT REPLACE(REPLACE(Cpu,SUBSTRING_INDEX(Cpu,' ',1),''),SUBSTRING_INDEX(Cpu,' ',-1),'')  AS 'Cpu_brand'
                    FROM laptopdata t2
					WHERE t1.index = t2.index) AS temp);  
                    
#Can do further cleaining to sperate Cores from the model
UPDATE laptopdata
SET  Cpu_model = SUBSTRING_INDEX(TRIM(Cpu_model),' ',2);                   
                    
ALTER TABLE laptopdata
MODIFY COLUMN Cpu_speed DECIMAL(10,2);

ALTER TABLE laptopdata
DROP COLUMN Cpu;



#Screen Resolution column
#1.Extract TouchScreen Feature
#2. Extract Screen_Resolution and Seperate width and height

SELECT ScreenResolution,
	CASE 
		WHEN ScreenResolution LIKE '%Touch%' THEN 1 
		ELSE 0
    END AS 'TouchScreen'
FROM laptopdata;

SELECT 
	ScreenResolution,
    SUBSTRING_INDEX(ScreenResolution,' ',-1),
    SUBSTRING_INDEX(SUBSTRING_INDEX(ScreenResolution,' ',-1),'x',1),
	SUBSTRING_INDEX(SUBSTRING_INDEX(ScreenResolution,' ',-1),'x',-1)
FROM laptopdata;


ALTER TABLE laptopdata
ADD COLUMN TouchScreen INT AFTER ScreenResolution,
ADD COLUMN Resolution_width INT AFTER TouchScreen,
ADD COLUMN Resolution_height INT AFTER Resolution_width;


UPDATE laptopdata
SET TouchScreen = CASE 
		WHEN ScreenResolution LIKE '%Touch%' THEN 1 
		ELSE 0
	END,
	Resolution_width = SUBSTRING_INDEX(SUBSTRING_INDEX(ScreenResolution,' ',-1),'x',1),
    Resolution_height = SUBSTRING_INDEX(SUBSTRING_INDEX(ScreenResolution,' ',-1),'x',-1);
    
ALTER TABLE laptopdata
DROP COLUMN ScreenResolution;


#Memory Column
SELECT Memory FROM laptopdata;

# 1. Set three Type(SSD/HDD/Hybrid/Flash) 
# 2. Remove GB 
# 3. Set Secondary and Primary Storage 

    
SELECT Memory,
CASE 
	WHEN Memory LIKE '%SSD%' AND Memory LIKE '%HDD%' THEN 'Hybrid'
	WHEN Memory LIKE '%Flash%' AND Memory LIKE '%HDD%' THEN 'Hybrid'
	WHEN Memory LIKE '%SSD%' THEN 'SSD'
	WHEN Memory LIKE '%HDD%' THEN 'HDD'
	WHEN Memory LIKE '%Flash%' THEN 'Flash'
	WHEN Memory LIKE '%Hybrid%' THEN 'Hybrid'

END AS 'Memory_Type'
FROM laptopdata;


SELECT Memory,
REGEXP_SUBSTR(SUBSTRING_INDEX(Memory,'+',1),'[0-9]+'),
CASE 
	WHEN Memory LIKE '%+%' THEN REGEXP_SUBSTR(SUBSTRING_INDEX(Memory,'+',-1),'[0-9]+')
    ELSE 0
END
FROM laptopdata;


ALTER TABLE laptopdata
ADD COLUMN Memory_Type VARCHAR(255) AFTER Memory,
ADD COLUMN Primary_Storage VARCHAR(255) AFTER Memory,
ADD COLUMN Secondary_Storage VARCHAR(255) AFTER Memory;

UPDATE laptopdata
SET Memory_Type = CASE 
						WHEN Memory LIKE '%SSD%' AND Memory LIKE '%HDD%' THEN 'Hybrid'
						WHEN Memory LIKE '%Flash%' AND Memory LIKE '%HDD%' THEN 'Hybrid'
						WHEN Memory LIKE '%SSD%' THEN 'SSD'
						WHEN Memory LIKE '%HDD%' THEN 'HDD'
						WHEN Memory LIKE '%Flash%' THEN 'Flash'
						WHEN Memory LIKE '%Hybrid%' THEN 'Hybrid'

				  END,
Primary_Storage = REGEXP_SUBSTR(SUBSTRING_INDEX(Memory,'+',1),'[0-9]+'),
Secondary_Storage = CASE 
						WHEN Memory LIKE '%+%' THEN REGEXP_SUBSTR(SUBSTRING_INDEX(Memory,'+',-1),'[0-9]+')
						ELSE 0
					END;
 
 
 UPDATE laptopdata
 SET Primary_Storage = 
		CASE 
			WHEN Primary_Storage <=2 THEN Primary_Storage * 1024 
            ELSE Primary_Storage
        END,
Secondary_Storage = 
		CASE 
			WHEN Secondary_Storage <=2 THEN Secondary_Storage * 1024 
            ELSE Secondary_Storage
        END 
;


ALTER TABLE laptopdata
DROP COLUMN Memory;

ALTER TABLE laptopdata
MODIFY COLUMN Primary_Storage INT,
MODIFY COLUMN Secondary_Storage INT;

