USE master
CREATE DATABASE FullTutorial
----------------
GO
----------------
---------------------------------------------------------------------------------------------------
--CREATE LOGIN WITH SYSADMIN ROLE
---------------------------------------------------------------------------------------------------
USE master
GO
CREATE LOGIN tester WITH PASSWORD = 'Jelszo123';
GO
EXEC sp_addsrvrolemember @loginame = 'tester', @rolename = 'sysadmin';
----------------
GO
----------------
---------------------------------------------------------------------------------------------------
--CREATE USER TO tester LOGIN IN A DB
---------------------------------------------------------------------------------------------------
USE [FullTutorial]
BEGIN;
CREATE USER [tester] FOR LOGIN [tester];
EXEC sp_addrolemember N'db_owner', N'tester';
END;
----------------
GO
----------------
USE master
GO
GRANT VIEW SERVER STATE TO tester;
----------------
GO
----------------



USE FullTutorial;

---------------------------------------------------------------------------------------------------
--CREATE DEMO DB STURCTURE
---------------------------------------------------------------------------------------------------
CREATE TABLE Partners (
	ID INT PRIMARY KEY IDENTITY NOT NULL,
	InternalTaxNumber CHAR(11));

CREATE TABLE Persons (
	ID_FK INT PRIMARY KEY NOT NULL,
	FirstName NVARCHAR(50) NOT NULL,
	LastName NVARCHAR(50) NOT NULL,
	Gender NVARCHAR(6),
	BirthDay DATETIMEOFFSET);

CREATE TABLE Companies(
	ID_FK INT PRIMARY KEY NOT NULL,
	CompanyName NVARCHAR(100) NOT NULL,
	OrganizationTypes_ID_FK INT NOT NULL
	);

CREATE TABLE OrganizationTypes (
	ID INT PRIMARY KEY IDENTITY NOT NULL,
	OrganizationTypeName NVARCHAR(100));

CREATE TABLE PartnerAnaliticsTypes(
	ID INT PRIMARY KEY IDENTITY NOT NULL,
	TypeOfAnalitic NVARCHAR(30) NOT NULL,
	Code NVARCHAR(10) NOT NULL);

CREATE TABLE PartnerAnalyticsUnits(
	ID INT PRIMARY KEY IDENTITY NOT NULL,
	UnitName NVARCHAR(20),
	Code NVARCHAR(10) NOT NULL,
	PartnerAnaliticsTypes_ID_FK INT);

CREATE TABLE PartnerAnalyticsUnitsXPartners(
	PartnerAnalyticsUnits_ID_FK INT NOT NULL,
	Partners_ID_FK INT NOT NULL);
ALTER TABLE PartnerAnalyticsUnitsXPartners ADD CONSTRAINT PK_PartnerAnalyticsUnitsXPartners PRIMARY KEY (PartnerAnalyticsUnits_ID_FK, Partners_ID_FK);

ALTER TABLE Persons ADD CONSTRAINT FK_ID01 FOREIGN KEY (ID_FK) REFERENCES Partners(ID); 
ALTER TABLE Companies ADD CONSTRAINT FK_ID02 FOREIGN KEY (ID_FK) REFERENCES Partners(ID);
ALTER TABLE Companies ADD CONSTRAINT FK_Companies01 FOREIGN KEY (OrganizationTypes_ID_FK) REFERENCES OrganizationTypes(ID);
ALTER TABLE PartnerAnalyticsUnitsXPartners ADD CONSTRAINT FK_PartnerAnalyticsUnitsXPartners01 FOREIGN KEY (PartnerAnalyticsUnits_ID_FK) REFERENCES PartnerAnalyticsUnits(ID);
ALTER TABLE PartnerAnalyticsUnitsXPartners ADD CONSTRAINT FK_PartnerAnalyticsUnitsXPartners02 FOREIGN KEY (Partners_ID_FK) REFERENCES Partners(ID);
ALTER TABLE PartnerAnalyticsUnits ADD CONSTRAINT FK_PartnerAnalyticsUnits01 FOREIGN KEY (PartnerAnaliticsTypes_ID_FK) REFERENCES PartnerAnaliticsTypes(ID);
ALTER TABLE Persons ADD CONSTRAINT CHK_Persons01 CHECK (UPPER(Gender) = 'MALE' OR UPPER(Gender) = 'FEMALE' OR Gender IS NULL);
ALTER TABLE OrganizationTypes ADD CONSTRAINT UQ_OrganizationTypes01 UNIQUE (OrganizationTypeName);
ALTER TABLE PartnerAnaliticsTypes ADD CONSTRAINT UQ_PartnerAnaliticsTypes01 UNIQUE (Code);
ALTER TABLE PartnerAnalyticsUnits ADD CONSTRAINT UQ_PartnerAnalyticsUnits01 UNIQUE (Code);
ALTER TABLE PartnerAnalyticsUnits ADD CONSTRAINT UQ_PartnerAnalyticsUnits02 UNIQUE (UnitName);
----------------
GO

----------------CREATE METHODS TO CHECK CONSTRAINTS: SF_CheckIdInPersons ----------------
CREATE OR ALTER FUNCTION SF_CheckIdInPersons (@par_ID AS INT) RETURNS INT AS
BEGIN
	DECLARE @var_count INT;
	SELECT @var_count = COUNT(*) FROM Persons WHERE ID_FK = @par_ID;
	RETURN @var_count;
END;
----------------
GO

----------------CREATE UNIT TESTS OF SF_CheckIdInPersons ----------------
BEGIN
	DECLARE 
		@TESTNUMBER NVARCHAR(50) = '001-001-001',
		@METHODNAME NVARCHAR(50) = 'SF_CheckIdInPersons',
		@TESTNAME NVARCHAR(100) = 'Contains instance with params',
		@TESTRESULT NVARCHAR(10) = 'False',
		@expectedResult INT = 1,
		@result INT,
		@maxIDinPartners INT,
		@tempID INT;
	SET NOCOUNT ON;
	PRINT CONCAT(@TESTNUMBER,': ',@METHODNAME, ' - ', @TESTNAME);
		BEGIN TRANSACTION;
			BEGIN TRY
					INSERT INTO Partners (InternalTaxNumber) VALUES ('01234567890');
					SELECT @maxIDinPartners = MAX(ID) FROM Partners;
					--PRINT CONCAT('max Partners ID: ' ,@maxIDinPartners);
					INSERT INTO Persons (ID_FK, FirstName, LastName, Gender, Birthday) VALUES (@maxIDinPartners, 'Gubo', 'Pestis', 'Male', '20110303 12:00:00 AM');
					SET @result = DBO.SF_CheckIdInPersons(@maxIDinPartners);
					DELETE FROM Persons WHERE ID_FK = @maxIDinPartners;
					DELETE FROM Partners WHERE ID = @maxIDinPartners;
					IF @result = @expectedResult
						BEGIN
							SET @TESTRESULT = 'True';
						END;
				ROLLBACK TRANSACTION;
			END TRY
			BEGIN CATCH
				PRINT( CONCAT('ERROR_NUMBER: ', ERROR_NUMBER()));
				PRINT( CONCAT('ERROR_SEVERITY: ', ERROR_SEVERITY()));
				PRINT( CONCAT('ERROR_STATE: ', ERROR_STATE()));
				--PRINT( CONCAT('ERROR_PROCEDURE: ', ERROR_PROCEDURE()));
				PRINT( CONCAT('ERROR_MESSAGE: ', ERROR_MESSAGE()));
				SET @TESTRESULT = 'False'
				ROLLBACK TRANSACTION;
			END CATCH
	SET @tempID = @maxIDinPartners - 1;
	DBCC CHECKIDENT (Partners, RESEED, @tempID) WITH NO_INFOMSGS; 
	PRINT CONCAT('TEST RESULT: ', @TESTRESULT);
END;
----------------
GO 
----------------
BEGIN
	DECLARE 
		@TESTNUMBER NVARCHAR(50) = '001-001-002',
		@METHODNAME NVARCHAR(50) = 'SF_CheckIdInPersons',
		@TESTNAME NVARCHAR(100) = 'No instance with params',
		@TESTRESULT NVARCHAR(10) = 'False',
		@expectedResult INT = 0,
		@result INT,
		@param INT = 10;
	SET NOCOUNT ON;
	PRINT CONCAT(@TESTNUMBER,': ',@METHODNAME, ' - ', @TESTNAME);
		BEGIN TRANSACTION
			BEGIN TRY
				SET @result = DBO.SF_CheckIdInPersons(@param);
				IF @result = @expectedResult
					BEGIN
						SET @TESTRESULT = 'True';
					END;
				ROLLBACK TRANSACTION;
			END TRY
			BEGIN CATCH
				PRINT( CONCAT('ERROR_NUMBER: ', ERROR_NUMBER()));
				PRINT( CONCAT('ERROR_SEVERITY: ', ERROR_SEVERITY()));
				PRINT( CONCAT('ERROR_STATE: ', ERROR_STATE()));
				--PRINT( CONCAT('ERROR_PROCEDURE: ', ERROR_PROCEDURE()));
				PRINT( CONCAT('ERROR_MESSAGE: ', ERROR_MESSAGE()));
				SET @TESTRESULT = 'False'
				ROLLBACK TRANSACTION;
			END CATCH
	PRINT CONCAT('TEST RESULT: ', @TESTRESULT);
END;
----------------
GO

----------------CREATE METHODS TO CHECK CONSTRAINTS: SF_CheckIdInCompanies ----------------
CREATE OR ALTER FUNCTION SF_CheckIdInCompanies(@par_ID AS INT) RETURNS INT AS
BEGIN 
	DECLARE @var_count INT;
	SELECT @var_count = COUNT(*) FROM Companies WHERE ID_FK = @par_ID;
	RETURN  @var_count;
END;
----------------
GO

----------------CREATE UNIT TESTS OF SF_CheckIdInCompanies ----------------
BEGIN
	DECLARE 
		@TESTNUMBER NVARCHAR(50) = '001-002-001',
		@METHODNAME NVARCHAR(50) = 'SF_CheckIdInCompanies',
		@TESTNAME NVARCHAR(100) = 'Contains instance with params',
		@TESTRESULT NVARCHAR(10) = 'False',
		@expectedResult INT = 1,
		@result INT,
		@maxIDinPartners INT,
		@maxIDinOrganizationTypes INT,
		@tempID INT,
		@tempIDofOrganizationTypes INT;
	SET NOCOUNT ON;
	PRINT CONCAT(@TESTNUMBER,': ',@METHODNAME, ' - ', @TESTNAME);
	BEGIN TRANSACTION;
		BEGIN TRY
			INSERT INTO Partners (InternalTaxNumber) VALUES ('01234567890');
			SELECT @maxIDinPartners = MAX(ID) FROM Partners;
			--PRINT CONCAT('max Partners ID: ' ,@maxIDinPartners);
			INSERT INTO OrganizationTypes (OrganizationTypeName) VALUES ('TESTOrganizationType');
			SELECT @maxIDinOrganizationTypes = MAX(ID) FROM OrganizationTypes;
			--PRINT CONCAT('max OrganizationTypes ID: ' ,@maxIDinOrganizationTypes);
			INSERT INTO Companies(ID_FK, CompanyName, OrganizationTypes_ID_FK) VALUES (@maxIDinPartners, 'TestCooporation', @maxIDinOrganizationTypes);
			SET @result = DBO.SF_CheckIdInCompanies(@maxIDinPartners);
			--PRINT CONCAT('RESULT: ' ,@result);
			DELETE FROM Companies WHERE ID_FK = @maxIDinPartners;
			DELETE FROM Partners WHERE ID = @maxIDinPartners;
			DELETE FROM OrganizationTypes WHERE ID = @maxIDinOrganizationTypes;
			IF @result = @expectedResult
				BEGIN
					SET @TESTRESULT = 'True';
				END;
			ROLLBACK TRANSACTION;
		END TRY
		BEGIN CATCH
			PRINT( CONCAT('ERROR_NUMBER: ', ERROR_NUMBER()));
			PRINT( CONCAT('ERROR_SEVERITY: ', ERROR_SEVERITY()));
			PRINT( CONCAT('ERROR_STATE: ', ERROR_STATE()));
			--PRINT( CONCAT('ERROR_PROCEDURE: ', ERROR_PROCEDURE()));
			PRINT( CONCAT('ERROR_MESSAGE: ', ERROR_MESSAGE()));
			SET @TESTRESULT = 'False'
			ROLLBACK TRANSACTION;
		END CATCH
	SET @tempID = @maxIDinPartners - 1;
	SET @tempIDofOrganizationTypes = @maxIDinOrganizationTypes - 1;
	DBCC CHECKIDENT (OrganizationTypes, RESEED, @tempIDofOrganizationTypes) WITH NO_INFOMSGS;
	DBCC CHECKIDENT (Partners, RESEED, @tempID) WITH NO_INFOMSGS;--RESTORE SEQUENCE OF ID
	PRINT CONCAT('TEST RESULT: ', @TESTRESULT);
END;
----------------
GO 
----------------
BEGIN
	DECLARE 
		@TESTNUMBER NVARCHAR(50) = '001-002-002',
		@METHODNAME NVARCHAR(50) = 'SF_CheckIdInCompanies',
		@TESTNAME NVARCHAR(100) = 'No instance with params',
		@TESTRESULT NVARCHAR(10) = 'False',
		@expectedResult INT = 0,
		@result INT,
		@param INT = 10;
	SET NOCOUNT ON;
	PRINT CONCAT(@TESTNUMBER,': ',@METHODNAME, ' - ', @TESTNAME);
	BEGIN TRANSACTION
		BEGIN TRY
			SET @result = DBO.SF_CheckIdInCompanies(@param);
			IF @result = @expectedResult
				BEGIN
					SET @TESTRESULT = 'True';
				END;
			ROLLBACK TRANSACTION;
		END TRY
		BEGIN CATCH
			PRINT( CONCAT('ERROR_NUMBER: ', ERROR_NUMBER()));
			PRINT( CONCAT('ERROR_SEVERITY: ', ERROR_SEVERITY()));
			PRINT( CONCAT('ERROR_STATE: ', ERROR_STATE()));
			--PRINT( CONCAT('ERROR_PROCEDURE: ', ERROR_PROCEDURE()));
			PRINT( CONCAT('ERROR_MESSAGE: ', ERROR_MESSAGE()));
			SET @TESTRESULT = 'False'
			ROLLBACK TRANSACTION;
		END CATCH
	PRINT CONCAT('TEST RESULT: ', @TESTRESULT);
END;
----------------
GO

----------------ADD CHECK CONSTRAINTS WITH SF_CheckIdInPersons, SF_CheckIdInCompanies ----------------
ALTER TABLE Companies ADD CONSTRAINT CHK_Companies01 CHECK (DBO.SF_CheckIdInPersons(ID_FK) < 1);
ALTER TABLE Persons ADD CONSTRAINT CHK_Persons02 CHECK (DBO.SF_CheckIdInCompanies(ID_FK) < 1);
----------------
GO

---------------------------------------------------------------------------------------------------
--INSERT DATA INTO TABLES
---------------------------------------------------------------------------------------------------

INSERT INTO OrganizationTypes (OrganizationTypeName) VALUES ('LTD');
INSERT INTO OrganizationTypes (OrganizationTypeName) VALUES ('PLC');
INSERT INTO OrganizationTypes (OrganizationTypeName) VALUES ('PHC');
INSERT INTO OrganizationTypes (OrganizationTypeName) VALUES ('FUND');
SELECT * FROM OrganizationTypes ORDER BY ID;

INSERT INTO PartnerAnaliticsTypes (TypeOfAnalitic, Code) VALUES ('Levels of quality', 'LEVEL');
INSERT INTO PartnerAnaliticsTypes (TypeOfAnalitic, Code) VALUES ('Financial solvency', 'SOLVENCY');
SELECT * FROM PartnerAnaliticsTypes ORDER BY ID;

INSERT INTO PartnerAnalyticsUnits (UnitName, Code, PartnerAnaliticsTypes_ID_FK) VALUES ('Lowest level', 'LOWEST', 1);
INSERT INTO PartnerAnalyticsUnits (UnitName, Code, PartnerAnaliticsTypes_ID_FK) VALUES ('Low level', 'LOW', 1);
INSERT INTO PartnerAnalyticsUnits (UnitName, Code, PartnerAnaliticsTypes_ID_FK) VALUES ('Middle level', 'MID', 1);
INSERT INTO PartnerAnalyticsUnits (UnitName, Code, PartnerAnaliticsTypes_ID_FK) VALUES ('High level', 'HIGH', 1);
INSERT INTO PartnerAnalyticsUnits (UnitName, Code, PartnerAnaliticsTypes_ID_FK) VALUES ('Highest level', 'HIGHEST', 1);
INSERT INTO PartnerAnalyticsUnits (UnitName, Code, PartnerAnaliticsTypes_ID_FK) VALUES ('Risky solvency', 'RISKY', 2);
INSERT INTO PartnerAnalyticsUnits (UnitName, Code, PartnerAnaliticsTypes_ID_FK) VALUES ('Not risky solvency', 'NRISKY', 2);
INSERT INTO PartnerAnalyticsUnits (UnitName, Code, PartnerAnaliticsTypes_ID_FK) VALUES ('Safe solvency', 'SAFE', 2);
SELECT * FROM PartnerAnalyticsUnits ORDER BY ID;


INSERT INTO Partners (InternalTaxNumber) VALUES ('01234567890');
INSERT INTO PartnerAnalyticsUnitsXPartners (PartnerAnalyticsUnits_ID_FK, Partners_ID_FK) VALUES (1,1);
INSERT INTO PartnerAnalyticsUnitsXPartners (PartnerAnalyticsUnits_ID_FK, Partners_ID_FK) VALUES (7,1);
INSERT INTO Partners (InternalTaxNumber) VALUES ('11234567890');
INSERT INTO PartnerAnalyticsUnitsXPartners (PartnerAnalyticsUnits_ID_FK, Partners_ID_FK) VALUES (2,2);
INSERT INTO PartnerAnalyticsUnitsXPartners (PartnerAnalyticsUnits_ID_FK, Partners_ID_FK) VALUES (6,2);
----------------
GO 
----------------
--CREATE INSERT SCRIPTS OF Partners, PartnerAnalyticsUnitsXPartners, PartnerAnalyticsUnitsXPartners
BEGIN
	DECLARE
		@counter INT,
		@tempInternalTaxNumber BIGINT,
		@PartnerAnalyticsUnits_ID_FK INT,
		@tempMaxPartnersID INT,
		@startMaxPartnersID INT;
		SET @counter = 1;
	BEGIN TRANSACTION
		BEGIN TRY
			SELECT @startMaxPartnersID = MAX(ID) FROM Partners
			WHILE (@counter < 500000)
			BEGIN
				SET @tempInternalTaxNumber  = 11234567890 + @counter
			--PRINT @tempInternalTaxNumber
				INSERT INTO Partners (InternalTaxNumber) VALUES ((CONVERT(CHAR(11), @tempInternalTaxNumber)))
				SELECT @tempMaxPartnersID = MAX(ID) FROM Partners
			--PRINT CONCAT('MAXPARTNERID: ',@tempMaxPartnersID)
				SET @PartnerAnalyticsUnits_ID_FK = FLOOR(RAND()*(5-1+1)+1)
			--PRINT CONCAT('@PartnerAnalyticsUnits_ID_FK 01: ',@PartnerAnalyticsUnits_ID_FK)
				INSERT INTO PartnerAnalyticsUnitsXPartners (PartnerAnalyticsUnits_ID_FK, Partners_ID_FK) VALUES (@PartnerAnalyticsUnits_ID_FK, @tempMaxPartnersID)
				SET @PartnerAnalyticsUnits_ID_FK = FLOOR(RAND()*(8-6+1)+6)
			--PRINT CONCAT('@PartnerAnalyticsUnits_ID_FK 02: ',@PartnerAnalyticsUnits_ID_FK)
				INSERT INTO PartnerAnalyticsUnitsXPartners (PartnerAnalyticsUnits_ID_FK, Partners_ID_FK) VALUES (@PartnerAnalyticsUnits_ID_FK, @tempMaxPartnersID)
				SET @counter = @counter + 1
			END;
			COMMIT TRANSACTION;
		END TRY
		BEGIN CATCH
			PRINT( CONCAT('ERROR_NUMBER: ', ERROR_NUMBER()));
			PRINT( CONCAT('ERROR_SEVERITY: ', ERROR_SEVERITY()));
			PRINT( CONCAT('ERROR_STATE: ', ERROR_STATE()));
			--PRINT( CONCAT('ERROR_PROCEDURE: ', ERROR_PROCEDURE()));
			PRINT( CONCAT('ERROR_MESSAGE: ', ERROR_MESSAGE()));
			ROLLBACK TRANSACTION;
			DBCC CHECKIDENT (Partners, RESEED, @startMaxPartnersID) WITH NO_INFOMSGS;
		END CATCH;
END;
----------------
GO
----------------
SELECT * FROM Partners ORDER BY ID;
SELECT * FROM PartnerAnalyticsUnitsXPartners ORDER BY Partners_ID_FK;

----------------
GO 
----------------



---------------------------------------------------------------------------------------------------
--CREATE SCRIPTS OF INSERTS OF COMPANIES AND PERSONS (SLOW SOLUTION) - VERSION 1
---------------------------------------------------------------------------------------------------
--CREATE VIEW OF RANDOM VALUE BECAUSE I CANNOT CALL A NON-DETERMINISTIC FUNCTION FROM INSIDE A USER-DEFINIED FUNCTION
CREATE OR ALTER VIEW VW_Rand AS SELECT RAND() AS RANDOM
----------------
GO
----------------

--CREATE USER STORED FUNCTIONS OF CREATE COMPANY
CREATE OR ALTER FUNCTION USF_CreateRandomCompany (@parID INT) 
RETURNS @resultTable TABLE (
	ID_FK INT NOT NULL,
	CompanyName NVARCHAR(100) NOT NULL,
	OrganizationTypes_ID_FK INT NOT NULL)
AS
BEGIN
	DECLARE @CompanyName NVARCHAR(100),
			@OrganizationTypes_ID_FK INT
	SET @OrganizationTypes_ID_FK = FLOOR((SELECT RANDOM FROM VW_Rand)*(4-1+1)+1)
	SET @CompanyName = CONCAT('COMPANYNAME', @parID)
	INSERT INTO @resultTable (ID_FK, CompanyName, OrganizationTypes_ID_FK) VALUES (@parID,@CompanyName,@OrganizationTypes_ID_FK)
	RETURN
END
----------------
GO 
----------------

--CREATE USER STORED FUNCTIONS OF CREATE PERSON
CREATE OR ALTER FUNCTION USF_CreateRandomPerson (@parID INT) 
RETURNS @resultTable TABLE (	
	ID_FK INT PRIMARY KEY NOT NULL,
	FirstName NVARCHAR(50) NOT NULL,
	LastName NVARCHAR(50) NOT NULL,
	Gender NVARCHAR(6),
	BirthDay DATETIMEOFFSET)
AS
BEGIN
	DECLARE @firstName NVARCHAR(50),
			@lastName NVARCHAR(50),
			@gender NVARCHAR(6),
			@birthDay DATETIMEOFFSET,
			@rndGender INT
	SET @firstName = CONCAT('FIRSTNAME', @parID);
	SET @lastName = CONCAT('LASTNAME', @parID);
	SET @birthDay = DATEADD(YEAR, CAST(FLOOR((SELECT RANDOM FROM VW_Rand)*(71-0+1)) AS INT) , '19500303 00:00:00 AM')
	SET @rndGender = FLOOR((SELECT RANDOM FROM VW_Rand)*(3-1+1)+1);
	IF (@rndGender = 1)
		BEGIN
			SET @gender = 'MALE';
		END;
	ELSE IF (@rndGender = 2)
		BEGIN
			SET @gender = 'FEMALE';
		END;
	ELSE
		BEGIN
			SET @gender = NULL;
		END;
	INSERT INTO @resultTable (ID_FK, FirstName, LastName, Gender, BirthDay) VALUES (@parID, @firstName, @lastName, @gender, @birthDay);
	RETURN
END
----------------
GO
----------------

--CREATE SCRIPTS OF INSERTS OF COMPANIES AND PERSONS
BEGIN
	DECLARE @varPartnersTbl TABLE (ID INT, InternalTaxNumber CHAR(11))
	DECLARE @varPersonsTbl TABLE (	
		ID_FK INT NOT NULL,
		FirstName NVARCHAR(50) NOT NULL,
		LastName NVARCHAR(50) NOT NULL,
		Gender NVARCHAR(6),
		BirthDay DATETIMEOFFSET)
	DECLARE @varCompaniesTbl TABLE (
		ID_FK INT NOT NULL,
		CompanyName NVARCHAR(100) NOT NULL,
		OrganizationTypes_ID_FK INT NOT NULL)
	DECLARE @varPartnersTblCount INT,
			@counter INT,
			@tempID INT
	INSERT INTO @varPartnersTbl (ID, InternalTaxNumber) SELECT ID, InternalTaxNumber FROM Partners ORDER BY ID
	SELECT @varPartnersTblCount = MAX(ID) FROM @varPartnersTbl
	SELECT @counter = MIN(ID) FROM @varPartnersTbl
--SET @varPartnersTblCount = 1000;
	WHILE (@counter <= @varPartnersTblCount) 
		BEGIN
			SELECT @tempID = ID FROM @varPartnersTbl WHERE ID = @counter
			--PRINT (CONCAT('COUNTER: ', @counter, ' - ', 'TEMPID: ', @tempID))
			IF (@tempID IS NULL)
				BEGIN
					CONTINUE
				END
			ELSE IF (@tempID % 2 = 0)
				BEGIN
					INSERT INTO @varCompaniesTbl SELECT * FROM USF_CreateRandomCompany(@tempID)
				END
			ELSE
				BEGIN
					INSERT INTO @varPersonsTbl SELECT * FROM USF_CreateRandomPerson(@tempID)
				END;
			SET @counter = @counter + 1
		END;
	--PRINT ('START INSERT')
	INSERT INTO Companies SELECT * FROM @varCompaniesTbl
	INSERT INTO Persons SELECT * FROM @varPersonsTbl
	--PRINT ('READY')
END;
GO

----------------
GO
----------------


---------------------------------------------------------------------------------------------------
--CREATE SCRIPTS OF INSERTS OF COMPANIES AND PERSONS (SLOW SOLUTION) - VERSION 2
---------------------------------------------------------------------------------------------------
--CREATE SCRIPTS OF INSERTS OF COMPANIES AND PERSONS
BEGIN
	DECLARE @varPartnersTbl TABLE (ID INT, InternalTaxNumber CHAR(11))
	DECLARE @varPersonsTbl TABLE (	
		ID_FK INT NOT NULL,
		FirstName NVARCHAR(50) NOT NULL,
		LastName NVARCHAR(50) NOT NULL,
		Gender NVARCHAR(6),
		BirthDay DATETIMEOFFSET)
	DECLARE @varCompaniesTbl TABLE (
		ID_FK INT NOT NULL,
		CompanyName NVARCHAR(100) NOT NULL,
		OrganizationTypes_ID_FK INT NOT NULL)
	DECLARE @varPartnersTblCount INT,
			@counter INT,
			@tempID INT
	DECLARE @CompanyName NVARCHAR(100),
		@OrganizationTypes_ID_FK INT
	DECLARE @firstName NVARCHAR(50),
		@lastName NVARCHAR(50),
		@gender NVARCHAR(6),
		@birthDay DATETIMEOFFSET,
		@rndGender INT
	INSERT INTO @varPartnersTbl (ID, InternalTaxNumber) SELECT ID, InternalTaxNumber FROM Partners ORDER BY ID
	SELECT @varPartnersTblCount = MAX(ID) FROM @varPartnersTbl
	SELECT @counter = MIN(ID) FROM @varPartnersTbl
	WHILE (@counter <= @varPartnersTblCount) 
		BEGIN
			SELECT @tempID = ID FROM @varPartnersTbl WHERE ID = @counter
			--PRINT (CONCAT('COUNTER: ', @counter, ' - ', 'TEMPID: ', @tempID))
			IF (@tempID IS NULL)
				BEGIN
					CONTINUE
				END
			ELSE IF (@tempID % 2 = 0)
				BEGIN
					SET @OrganizationTypes_ID_FK = FLOOR(RAND()*(4-1+1)+1)
					SET @CompanyName = CONCAT('COMPANYNAME', @tempID)
					INSERT INTO @varCompaniesTbl (ID_FK, CompanyName, OrganizationTypes_ID_FK) VALUES (@tempID, @CompanyName,@OrganizationTypes_ID_FK)
				END
			ELSE
				BEGIN
					SET @firstName = CONCAT('FIRSTNAME', @tempID);
					SET @lastName = CONCAT('LASTNAME', @tempID);
					SET @birthDay = DATEADD(YEAR, CAST(FLOOR(RAND()*(71-0+1)) AS INT) , '19500303 00:00:00 AM')
					SET @rndGender = FLOOR(RAND()*(3-1+1)+1);
					IF (@rndGender = 1)
						BEGIN
							SET @gender = 'MALE';
						END;
					ELSE IF (@rndGender = 2)
						BEGIN
							SET @gender = 'FEMALE';
						END;
					ELSE
						BEGIN
							SET @gender = NULL;
						END;
					INSERT INTO @varPersonsTbl (ID_FK, FirstName, LastName, Gender, BirthDay) VALUES (@tempID, @firstName, @lastName, @gender, @birthDay);
				END;
			--DELETE FROM @varPartnersTbl WHERE ID = @tempID
			SET @counter = @counter + 1
		END;
	--PRINT ('START INSERT')
	INSERT INTO Companies SELECT * FROM @varCompaniesTbl
	INSERT INTO Persons SELECT * FROM @varPersonsTbl
	--PRINT ('READY')
END;
----------------
GO
----------------

---------------------------------------------------------------------------------------------------
--CREATE SCRIPTS OF INSERTS OF COMPANIES AND PERSONS (IN-MEMORY SOLUTION - FASTEST WAY) - VERSION 3
---------------------------------------------------------------------------------------------------
USE MASTER;
----------------
GO
----------------
-- ADD MEMORY OPTIMIZED FILEGROUP TO DATABASE
ALTER DATABASE FullTutorial ADD FILEGROUP FULLTUTORIAL_INMEMORY_001_FILEGROUP CONTAINS memory_optimized_data; 
----------------
GO
----------------
-- ADD MEMORY OPTIMIZED FILE TO FILEGROUP
SELECT physical_name FROM sys.database_files --GET DATABASE PATH (AND PHYSICAL_NAME)

ALTER DATABASE FullTutorial ADD FILE 
	(NAME = 'FULLTUTORIAL_INMEMORY_001_FILE', 
	FILENAME = N'c:\Program Files\Microsoft SQL Server\MSSQL15.SQLDEVELOPER\MSSQL\DATA\FULLTUTORIAL_INMEMORY_001_FILENAME') -- NEED VALID DIRECTORY, (HELP: 575. ROW)
	TO FILEGROUP FULLTUTORIAL_INMEMORY_001_FILEGROUP; 
----------------
GO
USE FullTutorial;
GO
----------------
--CREATE IN-MEMORY USER-DEFINED TABLE TYPES
CREATE TYPE UT_InMem_Companies AS TABLE(
	ID_FK INT PRIMARY KEY NONCLUSTERED NOT NULL,
	CompanyName NVARCHAR(100) NOT NULL,
	OrganizationTypes_ID_FK INT NOT NULL)
	WITH (MEMORY_OPTIMIZED = ON)

CREATE TYPE UT_InMem_Persons AS TABLE (
	ID_FK INT PRIMARY KEY NONCLUSTERED NOT NULL,
	FirstName NVARCHAR(50) NOT NULL,
	LastName NVARCHAR(50) NOT NULL,
	Gender NVARCHAR(6),
	BirthDay DATETIME2)
	WITH (MEMORY_OPTIMIZED = ON)

CREATE TYPE UT_InMem_Partners AS TABLE (
	ID INT PRIMARY KEY NONCLUSTERED NOT NULL,
	InternalTaxNumber CHAR(11))
	WITH (MEMORY_OPTIMIZED = ON)
----------------
GO
----------------

--CREATE SCRIPTS OF INSERTS OF COMPANIES AND PERSONS 
BEGIN
	DECLARE @varPartnersTbl UT_InMem_Partners
	DECLARE @varCompaniesTbl UT_InMem_Companies
	DECLARE @varPersonsTbl UT_InMem_Persons
	DECLARE @varPartnersTblCount INT
	DECLARE @counter INT
	DECLARE @tempID INT
	DECLARE @CompanyName NVARCHAR(100)
	DECLARE	@OrganizationTypes_ID_FK INT
	DECLARE @firstName NVARCHAR(50)
	DECLARE @lastName NVARCHAR(50)
	DECLARE @gender NVARCHAR(6)
	DECLARE @birthDay DATETIME2
	DECLARE @rndGender INT
	INSERT INTO @varPartnersTbl (ID, InternalTaxNumber) SELECT ID, InternalTaxNumber FROM Partners
	SELECT @varPartnersTblCount = COUNT(*) FROM Partners
	SET @counter = 1;
	WHILE (@counter <= @varPartnersTblCount)
		BEGIN
			SELECT TOP (1) @tempID = ID FROM @varPartnersTbl;
			--PRINT (CONCAT('COUNTER: ', @counter, ' - ', 'TEMPID: ', @tempID))
			IF (@tempID % 2 = 0)
				BEGIN
					SET @OrganizationTypes_ID_FK = FLOOR(RAND()*(4-1+1)+1)
					SET @CompanyName = CONCAT('COMPANYNAME', @tempID)
					INSERT INTO @varCompaniesTbl (ID_FK, CompanyName, OrganizationTypes_ID_FK) VALUES (@tempID, @CompanyName,@OrganizationTypes_ID_FK)
				END
			ELSE
				BEGIN
					SET @firstName = CONCAT('FIRSTNAME', @tempID);
					SET @lastName = CONCAT('LASTNAME', @tempID);
					SET @birthDay = DATEADD(YEAR, CAST(FLOOR(RAND()*(71-0+1)) AS INT) , '19500303 00:00:00 AM')
					SET @rndGender = FLOOR(RAND()*(3-1+1)+1);
					IF (@rndGender = 1)
						BEGIN
							SET @gender = 'MALE';
						END;
					ELSE IF (@rndGender = 2)
						BEGIN
							SET @gender = 'FEMALE';
						END;
					ELSE
						BEGIN
							SET @gender = NULL;
						END;
					INSERT INTO @varPersonsTbl (ID_FK, FirstName, LastName, Gender, BirthDay) VALUES (@tempID, @firstName, @lastName, @gender, @birthDay);
				END
			DELETE FROM @varPartnersTbl WHERE ID = @tempID;
			SET @counter = @counter + 1;
		END
	--PRINT ('START INSERT')
	INSERT INTO Companies SELECT ID_FK, CompanyName, OrganizationTypes_ID_FK FROM @varCompaniesTbl ORDER BY ID_FK;
	INSERT INTO Persons SELECT ID_FK, FirstName, LastName, Gender, BirthDay FROM @varPersonsTbl ORDER BY ID_FK;
	--PRINT ('READY')
END;

GO
SELECT * FROM Persons ORDER BY ID_FK
SELECT * FROM Companies ORDER BY ID_FK
----------------
GO
----------------


---------------------------------------------------------------------------------------------------
--CREATE XML FROM QUERY (FOR XML AUTO) 
---------------------------------------------------------------------------------------------------

--https://www.sqlshack.com/working-with-xml-data-in-sql-server/

-- Each column is an attribute
CREATE OR ALTER FUNCTION UDF_CreateXmlAuto (@par_fromID INT, @par_untilID INT) RETURNS XML AS
BEGIN
	 DECLARE @resultXml XML
	 SET  @resultXml = (SELECT 
			Partners.ID, Partners.InternalTaxNumber, Persons.FirstName, Persons.LastName, Persons.Gender, Persons.BirthDay
			FROM Persons INNER JOIN Partners ON Persons.ID_FK = Partners.ID WHERE Partners.ID BETWEEN @par_fromID AND @par_untilID 
			FOR XML AUTO)
	IF(@resultXml IS NULL)
		BEGIN
			DECLARE @error INT = CONVERT(INT, 'ROWS OF QUERY EQUELS 0!') -- CAN NOT USE RAISERROR IN UDF :(
		END
	 RETURN @resultXml
END
----------------
GO
----------------
BEGIN 
	DECLARE @resultXML XML
	SET @resultXML = dbo.UDF_CreateXmlAuto(1,5)
	PRINT (CONVERT(NVARCHAR(MAX), @resultXML))
END
----------------
GO
----------------

---------------------------------------------------------------------------------------------------
--CREATE XML FROM QUERY (FOR XML PATH('xy')) 
---------------------------------------------------------------------------------------------------
-- Each record is an element and each column is a nested element
CREATE OR ALTER FUNCTION UDF_CreateXmlPath (@par_fromID INT, @par_untilID INT) RETURNS XML AS
BEGIN 
	DECLARE @resultXml XML
	SET  @resultXml = (SELECT 
			Partners.ID, Partners.InternalTaxNumber, Persons.FirstName, Persons.LastName, Persons.Gender, Persons.BirthDay
			FROM Persons INNER JOIN Partners ON Persons.ID_FK = Partners.ID WHERE Partners.ID BETWEEN @par_fromID AND @par_untilID 
			FOR XML PATH ('PersonElement'))
	IF(@resultXml IS NULL)
		BEGIN
			DECLARE @error INT = CONVERT(INT, 'ROWS OF QUERY EQUELS 0!') -- CAN NOT USE RAISERROR IN UDF :(
		END
	RETURN @resultXml
END
----------------
GO
----------------
BEGIN 
	DECLARE @resultXML XML
	SET @resultXML = dbo.UDF_CreateXmlPath(2,5)
	PRINT (CONVERT(NVARCHAR(MAX), @resultXML))
END
----------------
GO
----------------


---------------------------------------------------------------------------------------------------
--CREATE XML FROM QUERY (FOR XML PATH('xy'), Root('z')) 
---------------------------------------------------------------------------------------------------
-- Each record is an element and each column is a nested element with Root element
CREATE OR ALTER FUNCTION UDF_CreateXmlPathRoot (@par_fromID INT, @par_untilID INT) RETURNS XML AS
BEGIN 
	DECLARE @resultXml XML
	SET  @resultXml = (SELECT 
			Partners.ID, Partners.InternalTaxNumber, Persons.FirstName, Persons.LastName, Persons.Gender, Persons.BirthDay
			FROM Persons INNER JOIN Partners ON Persons.ID_FK = Partners.ID WHERE Partners.ID BETWEEN @par_fromID AND @par_untilID 
			FOR XML PATH ('PersonElement'), ROOT ('PersonsRoot'))
	IF(@resultXml IS NULL)
		BEGIN
			DECLARE @error INT = CONVERT(INT, 'ROWS OF QUERY EQUELS 0!') -- CAN NOT USE RAISERROR IN UDF :(
		END
	RETURN @resultXml
END
----------------
GO
----------------
BEGIN 
	DECLARE @resultXML XML
	SET @resultXML = dbo.UDF_CreateXmlPathRoot(2,5)
	PRINT (CONVERT(NVARCHAR(MAX), @resultXML))
END
----------------
GO
----------------


---------------------------------------------------------------------------------------------------
--CREATE XML FROM QUERY (FOR XML PATH('xy'), Root('z')) 
---------------------------------------------------------------------------------------------------
-- Each record is an element and each column is a nested element with Root element. 
-- ID is attribute of PersonElement.
CREATE OR ALTER FUNCTION UDF_CreateXmlPathRootAttributeID (@par_fromID INT, @par_untilID INT) RETURNS XML AS
BEGIN 
	DECLARE @resultXml XML
	SET  @resultXml = (SELECT 
			Partners.ID [@PersonElementID], Partners.InternalTaxNumber, Persons.FirstName, Persons.LastName, Persons.Gender, Persons.BirthDay
			FROM Persons INNER JOIN Partners ON Persons.ID_FK = Partners.ID WHERE Partners.ID BETWEEN @par_fromID AND @par_untilID 
			FOR XML PATH ('PersonElement'), ROOT ('PersonsRoot'))
	IF(@resultXml IS NULL)
		BEGIN
			DECLARE @error INT = CONVERT(INT, 'ROWS OF QUERY EQUELS 0!') -- CAN NOT USE RAISERROR IN UDF :(
		END
	RETURN @resultXml
END
----------------
GO
----------------
BEGIN 
	DECLARE @resultXML XML
	SET @resultXML = dbo.UDF_CreateXmlPathRootAttributeID(2,5)
	PRINT (CONVERT(NVARCHAR(MAX), @resultXML))
END
----------------
GO
----------------


---------------------------------------------------------------------------------------------------
--CREATE XML FROM QUERY (FOR XML PATH('xy'), Root('z')) 
---------------------------------------------------------------------------------------------------
-- Each record is an element and each column is a nested element with Root element. 
-- ID is attribute of PersonElement. 
-- FirstName and LastName are nested level of FullName
CREATE OR ALTER FUNCTION UDF_CreateXmlPathRootAttributeIDNestedLevel (@par_fromID INT, @par_untilID INT) RETURNS XML AS
BEGIN 
	DECLARE @resultXml XML
	SET  @resultXml = (SELECT 
			Partners.ID [@PersonElementID], Partners.InternalTaxNumber, Persons.FirstName[FullName/FirstName], Persons.LastName [FullName/LastName], Persons.Gender, Persons.BirthDay
			FROM Persons INNER JOIN Partners ON Persons.ID_FK = Partners.ID WHERE Partners.ID BETWEEN @par_fromID AND @par_untilID 
			FOR XML PATH ('PersonElement'), ROOT ('PersonsRoot'))
	IF(@resultXml IS NULL)
		BEGIN
			DECLARE @error INT = CONVERT(INT, 'ROWS OF QUERY EQUELS 0!') -- CAN NOT USE RAISERROR IN UDF :(
		END
	RETURN @resultXml
END
----------------
GO
----------------
BEGIN 
	DECLARE @resultXML XML
	BEGIN TRY
		SET @resultXML = dbo.UDF_CreateXmlPathRootAttributeIDNestedLevel(2,5)
		PRINT (CONVERT(NVARCHAR(MAX), @resultXML))
	END TRY
		BEGIN CATCH
			DECLARE @fullStrint NVARCHAR(MAX) = ERROR_MESSAGE();
			DECLARE @errorMsg NVARCHAR(MAX) = 
				left(right(@fullStrint, len(@fullStrint)- CHARINDEX('''', @fullStrint)), charindex('''',right(@fullStrint, len(@fullStrint)- CHARINDEX('''', @fullStrint)))-1)
			RAISERROR(@errorMsg,1,1)
	END CATCH
END
----------------
GO
----------------


---------------------------------------------------------------------------------------------------
--CREATE XML FROM QUERY (FOR XML PATH('xy'), Root('z')) 
---------------------------------------------------------------------------------------------------
-- Each record is an element and each column is a nested element with Root element. 
-- ID is attribute of PersonElement. 
-- FirstName and LastName are nested level of FullName
-- LastName is attribute of Fullname
CREATE OR ALTER FUNCTION UDF_CreateXmlPathRootAttributeIDNestedLevelAttribute (@par_fromID INT, @par_untilID INT) RETURNS XML AS
BEGIN 
	DECLARE @resultXml XML
	SET  @resultXml = (SELECT 
			Partners.ID [@PersonElementID], Partners.InternalTaxNumber, Persons.LastName [FullName/@LastName], Persons.FirstName[FullName/FirstName], Persons.Gender, Persons.BirthDay
			FROM Persons INNER JOIN Partners ON Persons.ID_FK = Partners.ID WHERE Partners.ID BETWEEN @par_fromID AND @par_untilID 
			FOR XML PATH ('PersonElement'), ROOT ('PersonsRoot'))
	IF(@resultXml IS NULL)
		BEGIN
			DECLARE @error INT = CONVERT(INT, 'ROWS OF QUERY EQUELS 0!') -- CAN NOT USE RAISERROR IN UDF :(
		END
	RETURN @resultXml
END
----------------
GO
----------------
--WITH EXCEPTION HANDLING
BEGIN 
	DECLARE @resultXML XML 
		BEGIN TRY
			SET @resultXML = dbo.UDF_CreateXmlPathRootAttributeIDNestedLevelAttribute(1,5)
			PRINT (CONVERT(NVARCHAR(MAX), @resultXML))
		END TRY
		BEGIN CATCH
			DECLARE @fullStrint NVARCHAR(MAX) = ERROR_MESSAGE()
			DECLARE @errorMsg NVARCHAR(MAX) = 
				left(right(@fullStrint, len(@fullStrint)- CHARINDEX('''', @fullStrint)), charindex('''',right(@fullStrint, len(@fullStrint)- CHARINDEX('''', @fullStrint)))-1)
			RAISERROR(@errorMsg,1,1)
		END CATCH
END
----------------
GO
----------------
---------------------------------------------------------------------------------------------------
--CREATE XML FROM QUERY (FOR XML PATH('xy'), Root('z')) IN PROCEDURE
---------------------------------------------------------------------------------------------------
-- Each record is an element and each column is a nested element with Root element. 
-- ID is attribute of PersonElement. 
-- FirstName and LastName are nested level of FullName
-- LastName is attribute of Fullname
CREATE OR ALTER PROCEDURE USP_CreateXmlPathRootAttributeIDNestedLevelAttribute (@par_fromID INT, @par_untilID INT, @par_resultXML XML OUTPUT) AS
BEGIN 
	SET  @par_resultXML = (SELECT 
			Partners.ID [@PersonElementID], Partners.InternalTaxNumber, Persons.LastName [FullName/@LastName], Persons.FirstName[FullName/FirstName], Persons.Gender, Persons.BirthDay
			FROM Persons INNER JOIN Partners ON Persons.ID_FK = Partners.ID WHERE Partners.ID BETWEEN @par_fromID AND @par_untilID 
			FOR XML PATH ('PersonElement'), ROOT ('PersonsRoot'))
	IF(@par_resultXML IS NULL)
		BEGIN
			RAISERROR('ROWS OF QUERY EQUELS 0!',1,1)
		END
END
----------------
GO
----------------
BEGIN 
	DECLARE @resultXML XML 
		BEGIN TRY
			EXEC USP_CreateXmlPathRootAttributeIDNestedLevelAttribute @par_fromID = 1, @par_untilID= 5, @par_resultXML = @resultXML OUTPUT
			PRINT (CONVERT(NVARCHAR(MAX), @resultXML))
		END TRY
		BEGIN CATCH
			PRINT('ERROR:')
			PRINT(ERROR_MESSAGE())
		END CATCH
END
----------------
GO
----------------




---------------------------------------------------------------------------------------------------
-- EXPORT TO XML FILE
---------------------------------------------------------------------------------------------------
--ENABLE xp_cmdshell -- FIRST STEP
EXEC sp_configure 'show advanced options', 1;
RECONFIGURE;
EXEC sp_configure 'xp_cmdshell', 1;
RECONFIGURE;
----------------
GO
----------------

---------------------------------------------------------------------------------------------------
	--EXPORT TO XML FILE FROM QUERY OF VIEW
---------------------------------------------------------------------------------------------------
--CREATE VIEW
CREATE OR ALTER VIEW QeryTable AS SELECT 
			Partners.ID ID, 
			Partners.InternalTaxNumber InternalTaxNumber, 
			Persons.LastName LastName, 
			Persons.FirstName FirstName,
			Persons.Gender,
			Persons.BirthDay
		FROM Persons INNER JOIN Partners ON Persons.ID_FK = Partners.ID 
----------------
GO
----------------
--CREATE EXPORT PROCEDURE
CREATE OR ALTER PROCEDURE USP_ExportToXml (@par_fileNameAndPath NVARCHAR(250), @par_fromID INT, @par_untilID INT) AS
BEGIN

	DECLARE @cmd  NVARCHAR(500) = 'bcp  "SELECT ID[@PersonElementID], InternalTaxNumber, LastName[FullName/@LastName], FirstName[FullName/FirstName], Gender,  BirthDay'+ 
										' FROM FullTutorial.dbo.QeryTable WHERE ID BETWEEN ' +
										CONVERT(NVARCHAR(16), @par_fromID) + ' AND ' + CONVERT(NVARCHAR(16), @par_untilID)  + 
										'FOR XML PATH (''PersonElement''),ROOT (''PersonsRoot'')" ' + 'queryout "' +  
			@par_fileNameAndPath + '" -c -t, -T -S' + @@SERVERNAME
	PRINT (@cmd)
	EXEC master..XP_CMDSHELL @cmd;
END
----------------
GO
----------------
EXEC dbo.USP_ExportToXml @par_fileNameAndPath = 'C:\Temp\TESTFILE.xml', @par_fromID = 1, @par_untilID = 10
----------------
GO
----------------


---------------------------------------------------------------------------------------------------
	--IMPORT TO XML VARIABLE FROM XML FILE
---------------------------------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE USP_ImportToXmlVarFromXmlFile (@par_fileNameAndPath NVARCHAR(250), @par_resultXML XML OUTPUT) AS
BEGIN
	SELECT @par_resultXML = resultXML
			FROM OPENROWSET (BULK 'c:\temp\TESTFILE.xml', SINGLE_BLOB) AS PersonElement(resultXML) 
END
----------------
GO
----------------
BEGIN
	DECLARE @resultXML XML
	EXEC dbo.USP_ImportToXmlVarFromXmlFile @par_fileNameAndPath = 'C:\Temp\TESTFILE.xml', @par_resultXML = @resultXML OUTPUT
	PRINT (CONVERT(NVARCHAR(MAX), @resultXML))
END
----------------
GO
----------------

---------------------------------------------------------------------------------------------------
	--IMPORT DATA TO TABLE FROM XML VARIABLE USING XML ATTRIBUTES
---------------------------------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE USP_ImportToTableFromXmlVarUsingAttributes (@par_xml XML) AS
BEGIN
	DECLARE @handleDoc INT
	DECLARE @resultTable TABLE (LastName NVARCHAR(50))
	DECLARE @resultCount INT
	BEGIN TRY
		EXEC sp_xml_preparedocument @handleDoc OUTPUT, @par_xml
		INSERT INTO @resultTable SELECT * FROM OPENXML(@handleDoc, '/PersonsRoot/PersonElement/FullName', 1)
			WITH (LastName NVARCHAR(50))
		SELECT @resultCount = COUNT(*) FROM @resultTable
		IF (@resultCount <> 0)
			BEGIN
				SELECT * FROM @resultTable
				RETURN 0
			END
		ELSE
			BEGIN 
				RETURN 1
			END 
		EXEC sp_xml_removedocument @handleDoc
	END TRY
	BEGIN CATCH
		EXEC sp_xml_removedocument @handleDoc
		RETURN 2
	END CATCH
END
----------------
GO
----------------
BEGIN
	DECLARE @varXml XML
	DECLARE @resultINT INT
	EXEC USP_CreateXmlPathRootAttributeIDNestedLevelAttribute @par_fromID = 1, @par_untilID= 5, @par_resultXML = @varXml OUTPUT
	EXEC @resultINT = USP_ImportToTableFromXmlVarUsingAttributes @par_xml = @varXml
	PRINT (@resultINT)
END
----------------
GO
----------------
---------------------------------------------------------------------------------------------------
	--IMPORT DATA TO TABLE FROM XML VARIABLE USING XML ELEMENTS
---------------------------------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE USP_ImportToTableFromXmlVarUsingElements (@par_xml XML) AS
BEGIN
	DECLARE @handleDoc INT
	DECLARE @resultTable TABLE (	
				InternalTaxNumber CHAR(11),
				Gender NVARCHAR(7),
				BirthDay DATETIMEOFFSET
				)
	DECLARE @resultCount INT
	BEGIN TRY
		EXEC sp_xml_preparedocument @handleDoc OUTPUT,  @par_xml
		INSERT INTO @resultTable SELECT * FROM OPENXML(@handleDoc, '/PersonsRoot/PersonElement', 2) 
			WITH (	InternalTaxNumber CHAR(11),
					Gender NVARCHAR(7),
					BirthDay DATETIMEOFFSET
					)
		SELECT @resultCount = COUNT(*) FROM @resultTable
		IF (@resultCount <> 0)
			BEGIN
				SELECT * FROM @resultTable
				RETURN 0
			END
		ELSE
			BEGIN 
				RETURN 1
			END 
		EXEC sp_xml_removedocument  @handleDoc
	END TRY
	BEGIN CATCH
		EXEC sp_xml_removedocument @handleDoc
		RETURN 2
	END CATCH
END
----------------
GO
----------------
BEGIN
	DECLARE @varXml XML
	DECLARE @resultINT INT
	EXEC USP_CreateXmlPathRootAttributeIDNestedLevelAttribute @par_fromID = 1, @par_untilID= 5, @par_resultXML = @varXml OUTPUT
	EXEC @resultINT = USP_ImportToTableFromXmlVarUsingElements @par_xml = @varXml
	PRINT (@resultINT)
END
----------------
GO
----------------



---------------------------------------------------------------------------------------------------
	--IMPORT FULLDATA TO TABLE FROM XML VARIABLE 
---------------------------------------------------------------------------------------------------
--(I THINK IT IS NOT A BEST CHOICE, BUT IF TABLE VARIABLES HAVE MADE WITH IN-MEMORY USER-DEFINED TABLE TYPES, IT BECOME VERY FAST SOLUTION)
CREATE OR ALTER PROCEDURE USP_ImportFullDataToTableFromXmlVarTwoStep (@par_xml XML) AS
BEGIN
	DECLARE @handleDoc INT
	DECLARE @firstLevelElementTable TABLE (	
				ID INT PRIMARY KEY IDENTITY NOT NULL,
				InternalTaxNumber CHAR(11),
				Gender NVARCHAR(7),
				BirthDay DATETIMEOFFSET)
	DECLARE @firstLevelAttributeTable TABLE (	
				ID INT PRIMARY KEY IDENTITY NOT NULL,
				PersonElementID INT NOT NULL)
	DECLARE @secondLevelElementTable TABLE(
				ID INT PRIMARY KEY IDENTITY NOT NULL,
				FirstName NVARCHAR(50))
	DECLARE @secondLevelAttributeTable TABLE(
				ID INT PRIMARY KEY IDENTITY NOT NULL,
				LastName NVARCHAR(50))
	DECLARE @resultTable TABLE (	
				PersonElementID INT NOT NULL,
				InternalTaxNumber CHAR(11),
				Gender NVARCHAR(7),
				BirthDay DATETIMEOFFSET,
				FirstName NVARCHAR(50),
				LastName NVARCHAR(50)
				)
	DECLARE @resultCount INT
	BEGIN TRY
		EXEC sp_xml_preparedocument @handleDoc OUTPUT,  @par_xml
		INSERT INTO @firstLevelElementTable (InternalTaxNumber, Gender, BirthDay)
			SELECT * FROM OPENXML(@handleDoc, '/PersonsRoot/PersonElement', 2) 
			WITH (	InternalTaxNumber CHAR(11),
					Gender NVARCHAR(7),
					BirthDay DATETIMEOFFSET)
		INSERT INTO @firstLevelAttributeTable (PersonElementID)
			SELECT * FROM OPENXML(@handleDoc, '/PersonsRoot/PersonElement', 1) 
			WITH (	PersonElementID INT)	
		
		INSERT INTO @secondLevelElementTable (FirstName)
			SELECT * FROM OPENXML(@handleDoc, '/PersonsRoot/PersonElement/FullName', 2) 
			WITH (	FirstName NVARCHAR(50))
		INSERT INTO @secondLevelAttributeTable (LastName)
			SELECT * FROM OPENXML(@handleDoc, '/PersonsRoot/PersonElement/FullName', 1) 
			WITH (	LastName NVARCHAR(50))
		INSERT INTO @resultTable 
			SELECT	FLAT.PersonElementID, 
					FLET.InternalTaxNumber,
					FLET.Gender,
					FLET.BirthDay,
					SLET.FirstName,
					SLAT.LastName
				FROM @firstLevelAttributeTable AS FLAT
				INNER JOIN @firstLevelElementTable AS FLET ON FLAT.ID = FLET.ID
				INNER JOIN @secondLevelElementTable AS SLET ON FLAT.ID = SLET.ID 
				INNER JOIN @secondLevelAttributeTable AS SLAT ON FLAT.ID = SLAT.ID
		SELECT @resultCount = COUNT(*) FROM @resultTable
		IF (@resultCount <> 0)
			BEGIN
				SELECT * FROM @resultTable ORDER BY PersonElementID
				RETURN 0
			END
		ELSE
			BEGIN 
				RETURN 1
			END 
		EXEC sp_xml_removedocument  @handleDoc
	END TRY
	BEGIN CATCH
		EXEC sp_xml_removedocument @handleDoc
		RETURN 2
	END CATCH
END
----------------
GO
----------------
BEGIN
	DECLARE @varXml XML
	DECLARE @resultINT INT
	EXEC USP_CreateXmlPathRootAttributeIDNestedLevelAttribute @par_fromID = 1, @par_untilID= 10, @par_resultXML = @varXml OUTPUT
	EXEC @resultINT = USP_ImportFullDataToTableFromXmlVarTwoStep @par_xml = @varXml
	PRINT (@resultINT)
END
----------------
GO
----------------



---------------------------------------------------------------------------------------------------
	--IMPORT FULLDATA TO TABLE FROM XML VARIABLE -- DYNAMIC SQL VERSION
---------------------------------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE USP_ImportFullDataToTableFromXmlVarDinSql (@par_xml XML) AS
BEGIN
	--DECLARE @handleDoc INT
	CREATE TABLE #resultTable (	
				PersonElementID INT NOT NULL,
				InternalTaxNumber CHAR(11),
				Gender NVARCHAR(7),
				BirthDay DATETIMEOFFSET,
				FirstName NVARCHAR(50),
				LastName NVARCHAR(50)
				)
	DECLARE @resultCount INT
	DECLARE @dynstring NVARCHAR(2000)
	DECLARE @checkPersonElementID INT
	DECLARE @counter INT
	BEGIN TRY
		SET @checkPersonElementID = @par_xml.value ('count(/PersonsRoot/PersonElement/@PersonElementID)', 'INT')
		PRINT (CONCAT('@checkPersonElementID: ',@checkPersonElementID))
		SET @counter = 1
		WHILE (@counter <= @checkPersonElementID)
			BEGIN

				SET @dynstring = 	N'INSERT INTO #resultTable (PersonElementID, InternalTaxNumber, Gender, BirthDay, FirstName, LastName) ' +
									'SELECT	@par_xml.value (' + '''(/PersonsRoot/PersonElement/@PersonElementID)' + '[' +CONVERT(NVARCHAR(10),@counter)+ ']''' + ',''INT'') AS PersonElementID, ' +
											'@par_xml.value (' + '''(/PersonsRoot/PersonElement/InternalTaxNumber)' + '[' +CONVERT(NVARCHAR(10),@counter)+ ']''' + ',''CHAR(11)'') AS InternalTaxNumber, ' +
											'@par_xml.value (' + '''(/PersonsRoot/PersonElement/Gender)' + '[' +CONVERT(NVARCHAR(10),@counter)+ ']''' + ',''NVARCHAR(7)'') AS Gender, ' +
											'@par_xml.value (' + '''(/PersonsRoot/PersonElement/BirthDay)' + '[' +CONVERT(NVARCHAR(10),@counter)+ ']''' + ',''DATETIMEOFFSET'') AS BirthDay, ' +
											'@par_xml.value (' + '''(/PersonsRoot/PersonElement/FullName/FirstName)' + '[' +CONVERT(NVARCHAR(50),@counter)+ ']''' + ',''NVARCHAR(50)'') AS FirstName, '+
											'@par_xml.value (' + '''(/PersonsRoot/PersonElement/FullName/@LastName)' + '[' +CONVERT(NVARCHAR(50),@counter)+ ']''' + ',''NVARCHAR(50)'') AS LastName'
				EXECUTE sp_executesql @dynstring, N'@par_xml XML', @par_xml = @par_xml
				SET @counter = @counter + 1
			END
		SELECT @resultCount = COUNT(*) FROM #resultTable
		IF (@resultCount <> 0)
			BEGIN
				SELECT * FROM #resultTable
				RETURN 0
			END
		ELSE
			BEGIN 
				RETURN 1
			END 
	END TRY
	BEGIN CATCH
			PRINT( CONCAT('ERROR_NUMBER: ', ERROR_NUMBER()));
			PRINT( CONCAT('ERROR_SEVERITY: ', ERROR_SEVERITY()));
			PRINT( CONCAT('ERROR_STATE: ', ERROR_STATE()));
			PRINT( CONCAT('ERROR_PROCEDURE: ', ERROR_PROCEDURE()));
			PRINT( CONCAT('ERROR_MESSAGE: ', ERROR_MESSAGE()));
		RETURN 2
	END CATCH
END
----------------
GO
----------------
BEGIN
	DECLARE @varXml XML
	DECLARE @resultINT INT
	EXEC USP_CreateXmlPathRootAttributeIDNestedLevelAttribute @par_fromID = 1, @par_untilID= 10, @par_resultXML = @varXml OUTPUT
	SELECT @varXml
	EXEC @resultINT = USP_ImportFullDataToTableFromXmlVarDinSql @par_xml = @varXml
	PRINT (@resultINT)
END
----------------
GO
----------------



---------------------------------------------------------------------------------------------------
	--CREATE A TABLE WITH XML TYPE AND DO DML-S 
---------------------------------------------------------------------------------------------------
--https://docs.microsoft.com/en-us/sql/xquery/xquery-language-reference-sql-server?view=sql-server-2017

CREATE TABLE TableOfXML 
	(	ID INT PRIMARY KEY NOT NULL,
		XMLS XML NOT NULL,
		InsertTime DATETIMEOFFSET DEFAULT SYSDATETIMEOFFSET())
----------------
GO
----------------
--INSERT XML DATA
BEGIN 
	DECLARE @counter INT = 1
	DECLARE @varXml XML
	DECLARE @ID INT = 1
	WHILE @counter <= 100
		BEGIN 
			BEGIN TRY
				EXEC USP_CreateXmlPathRootAttributeIDNestedLevelAttribute @par_fromID = @counter, @par_untilID= @counter, @par_resultXML = @varXml OUTPUT
				INSERT INTO TableOfXML (ID, XMLS) VALUES (@ID, @varXml);
				SET @ID = @ID + 1
			END TRY
			BEGIN CATCH
				PRINT CONCAT('ERROR IN ', @counter, '. ITERATION!')
			END CATCH
			SET @counter = @counter +1
		END 
END

--DELETE FROM TableOfXML
----------------
GO
----------------
SELECT * FROM TableOfXML
----------------
GO
----------------

-- SELECT ALL XMLS AND VALUES
SELECT	XMLS,
		TableOfXML.XMLS.value('(/PersonsRoot/PersonElement/@PersonElementID)[1]', 'INT') AS PersonElementID,
		TableOfXML.XMLS.value('(/PersonsRoot/PersonElement/InternalTaxNumber)[1]', 'CHAR(11)') AS InternalTaxNumber,
		TableOfXML.XMLS.value('(/PersonsRoot/PersonElement/Gender)[1]', 'NVARCHAR(10)') AS Gender,
		TableOfXML.XMLS.value('(/PersonsRoot/PersonElement/BirthDay)[1]', 'DATETIMEOFFSET') AS BirthDay,
		TableOfXML.XMLS.value('(/PersonsRoot/PersonElement/FullName/FirstName)[1]', 'NVARCHAR(50)') AS FirstName,
		TableOfXML.XMLS.value('(/PersonsRoot/PersonElement/FullName/@LastName)[1]', 'NVARCHAR(50)') AS LastName
	FROM dbo.TableOfXML 
	WHERE 1 = 1 ORDER BY PersonElementID

-- SELECT WITH WHERE CLAUSE
SELECT	XMLS,
		TableOfXML.XMLS.value('(/PersonsRoot/PersonElement/@PersonElementID)[1]', 'INT') AS PersonElementID,
		TableOfXML.XMLS.value('(/PersonsRoot/PersonElement/InternalTaxNumber)[1]', 'CHAR(11)') AS InternalTaxNumber,
		TableOfXML.XMLS.value('(/PersonsRoot/PersonElement/Gender)[1]', 'NVARCHAR(10)') AS Gender,
		TableOfXML.XMLS.value('(/PersonsRoot/PersonElement/BirthDay)[1]', 'DATETIMEOFFSET') AS BirthDay,
		TableOfXML.XMLS.value('(/PersonsRoot/PersonElement/FullName/FirstName)[1]', 'NVARCHAR(50)') AS FirstName,
		TableOfXML.XMLS.value('(/PersonsRoot/PersonElement/FullName/@LastName)[1]', 'NVARCHAR(50)') AS LastName
	FROM dbo.TableOfXML 
	WHERE TableOfXML.XMLS.value('(/PersonsRoot/PersonElement/@PersonElementID)[1]', 'INT') = 3
	
--SELECT AND COUNT THE NUMBER OF A NODE										
SELECT TableOfXML.XMLS.value ('count(/PersonsRoot/PersonElement/Gender)', 'INT') AS GenderCount
	FROM TableOfXML

SELECT TableOfXML.XMLS.value ('count(/PersonsRoot/PersonElement/Gender)', 'INT') AS GenderCount
	FROM TableOfXML WHERE TableOfXML.XMLS.value('(/PersonsRoot/PersonElement/@PersonElementID)[1]', 'INT') = 3

--SELECT AND COUNT THE NUMBER OF ROWS IN A NODE
SELECT TableOfXML.XMLS.value ('count(/PersonsRoot/PersonElement/*)', 'INT') AS GenderCount
	FROM TableOfXML 

----------------
GO
----------------

--ENABLE xp_cmdshell -- LAST STEP
EXEC sp_configure 'show advanced options', 1;
RECONFIGURE;
EXEC sp_configure 'xp_cmdshell', 0;
RECONFIGURE;
----------------
GO
---------------





---------------------------------------------------------------------------------------------------
--JSONS HANDLE
---------------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------------------
	--EXPORT TO JSONS FILE FROM QUERY OF VIEW WITH AUTO FORMAT
---------------------------------------------------------------------------------------------------
--CREATE EXPORT PROCEDURE
CREATE OR ALTER FUNCTION UDF_CreateJsonAuto (@par_fromID INT, @par_untilID INT) RETURNS NVARCHAR(MAX) AS
BEGIN 
	DECLARE @resultJson NVARCHAR(MAX)
	SET  @resultJson = (SELECT 
						Partners.ID, Partners.InternalTaxNumber, Persons.LastName, Persons.FirstName, Persons.Gender, Persons.BirthDay
						FROM Persons INNER JOIN Partners ON Persons.ID_FK = Partners.ID WHERE Partners.ID BETWEEN @par_fromID AND @par_untilID 
						ORDER BY Partners.ID
						FOR JSON AUTO
						--, INCLUDE_NULL_VALUES
						)
	IF(@resultJson IS NULL)
		BEGIN
			DECLARE @error INT = CONVERT(INT, 'ROWS OF QUERY EQUELS 0!') -- CAN NOT USE RAISERROR IN UDF :(
		END
	RETURN @resultJson
END
----------------
GO
----------------
--WITH EXCEPTION HANDLING
BEGIN 
	DECLARE @resultJson NVARCHAR(MAX) 
		BEGIN TRY
			SET @resultJson = dbo.UDF_CreateJsonAuto(1,5)
			PRINT (@resultJson)
			SELECT * FROM OpenJson(@resultJson)
		END TRY
		BEGIN CATCH
			DECLARE @fullString NVARCHAR(MAX) = ERROR_MESSAGE()
			PRINT @fullString
			DECLARE @errorMsg NVARCHAR(MAX) = 
				left(right(@fullString, len(@fullString)- CHARINDEX('''', @fullString)), charindex('''',right(@fullString, len(@fullString)- CHARINDEX('''', @fullString)))-1)
			RAISERROR(@errorMsg,1,1)
		END CATCH
END 
----------------
GO
----------------

---------------------------------------------------------------------------------------------------
	--EXPORT TO JSONS FILE FROM QUERY OF VIEW WITH PATH
---------------------------------------------------------------------------------------------------
--CREATE EXPORT PROCEDURE
CREATE OR ALTER FUNCTION UDF_CreateJsonPath (@par_fromID INT, @par_untilID INT) RETURNS NVARCHAR(MAX) AS
BEGIN 
	DECLARE @resultJson NVARCHAR(MAX)
	SET  @resultJson = (SELECT 
						Partners.ID [Partner.ID], Partners.InternalTaxNumber[Partner.InternalTaxNumber]
						, Persons.LastName[Partner.FullName.LastName], Persons.FirstName[Partner.FullName.FirstName], Persons.Gender[Partner.Gender], Persons.BirthDay[Partner.BirthDay]
						FROM Persons INNER JOIN Partners ON Persons.ID_FK = Partners.ID WHERE Partners.ID BETWEEN @par_fromID AND @par_untilID 
						ORDER BY Partners.ID
						FOR JSON PATH
						--, INCLUDE_NULL_VALUES
						)
	IF(@resultJson IS NULL)
		BEGIN
			DECLARE @error INT = CONVERT(INT, 'ROWS OF QUERY EQUELS 0!') -- CAN NOT USE RAISERROR IN UDF :(
		END
	RETURN @resultJson
END
----------------
GO
----------------
--WITH EXCEPTION HANDLING
BEGIN 
	DECLARE @resultJson NVARCHAR(MAX) 
		BEGIN TRY
			SET @resultJson = dbo.UDF_CreateJsonPath(1,5)
			PRINT (@resultJson)
			SELECT * FROM OpenJson(@resultJson)
		END TRY
		BEGIN CATCH
			DECLARE @fullString NVARCHAR(MAX) = ERROR_MESSAGE()
			PRINT @fullString
			DECLARE @errorMsg NVARCHAR(MAX) = 
				left(right(@fullString, len(@fullString)- CHARINDEX('''', @fullString)), charindex('''',right(@fullString, len(@fullString)- CHARINDEX('''', @fullString)))-1)
			RAISERROR(@errorMsg,1,1)
		END CATCH
END 


----------------
GO
----------------

---------------------------------------------------------------------------------------------------
	--EXPORT TO JSONS FILE FROM QUERY OF VIEW WITH PATH, ROOT
---------------------------------------------------------------------------------------------------
--CREATE EXPORT PROCEDURE
CREATE OR ALTER FUNCTION UDF_CreateJsonPathRoot (@par_fromID INT, @par_untilID INT) RETURNS NVARCHAR(MAX) AS
BEGIN 
	DECLARE @resultJson NVARCHAR(MAX)
	SET  @resultJson = (SELECT 
						Partners.ID [Partner.ID], Partners.InternalTaxNumber[Partner.InternalTaxNumber]
						, Persons.LastName[Partner.FullName.LastName], Persons.FirstName[Partner.FullName.FirstName], Persons.Gender[Partner.Gender], Persons.BirthDay[Partner.BirthDay]
						FROM Persons INNER JOIN Partners ON Persons.ID_FK = Partners.ID WHERE Partners.ID BETWEEN @par_fromID AND @par_untilID 
						ORDER BY Partners.ID
						FOR JSON PATH
						--, INCLUDE_NULL_VALUES
						,ROOT ('Partners')
						)
	IF(@resultJson IS NULL)
		BEGIN
			DECLARE @error INT = CONVERT(INT, 'ROWS OF QUERY EQUELS 0!') -- CAN NOT USE RAISERROR IN UDF :(
		END
	RETURN @resultJson
END
----------------
GO
----------------
--WITH EXCEPTION HANDLING
BEGIN 
	DECLARE @resultJson NVARCHAR(MAX) 
		BEGIN TRY
			SET @resultJson = dbo.UDF_CreateJsonPathRoot(1,5)
			PRINT (@resultJson)
			SELECT * FROM OpenJson(@resultJson)
		END TRY
		BEGIN CATCH
			DECLARE @fullString NVARCHAR(MAX) = ERROR_MESSAGE()
			PRINT @fullString
			DECLARE @errorMsg NVARCHAR(MAX) = 
				left(right(@fullString, len(@fullString)- CHARINDEX('''', @fullString)), charindex('''',right(@fullString, len(@fullString)- CHARINDEX('''', @fullString)))-1)
			RAISERROR(@errorMsg,1,1)
		END CATCH
END 
----------------
GO
--------------

---------------------------------------------------------------------------------------------------
	--EXPORT TO JSON FILE FROM QUERY OF VIEW
---------------------------------------------------------------------------------------------------

--CREATE EXPORT PROCEDURE
CREATE OR ALTER PROCEDURE USP_ExportToJson (@par_fileNameAndPath NVARCHAR(250), @par_fromID INT, @par_untilID INT) AS
BEGIN

	DECLARE @cmd  NVARCHAR(1000) = 'bcp  "SELECT ID [Partner.ID], InternalTaxNumber[Partner.InternalTaxNumber], LastName[Person.FullName.LastName], FirstName[Person.FullName.FirstName], Gender[Person.Gender], BirthDay[Person.BirthDay]' + 
										' FROM FullTutorial.dbo.QeryTable WHERE ID BETWEEN ' +
										CONVERT(NVARCHAR(16), @par_fromID) + ' AND ' + CONVERT(NVARCHAR(16), @par_untilID)  + 
										'FOR JSON PATH, ROOT (''Persons'')" ' + 'queryout "' +  
										@par_fileNameAndPath + '" -c -t, -T -S' + @@SERVERNAME
	PRINT (@cmd)
	EXEC master..XP_CMDSHELL @cmd;
END
----------------
GO
----------------
EXEC dbo.USP_ExportToJson @par_fileNameAndPath = 'C:\Temp\TESTFILE.json', @par_fromID = 1, @par_untilID = 10
----------------
GO
----------------


---------------------------------------------------------------------------------------------------
	--IMPORT TO JSON VARIABLE FROM JSON FILE
---------------------------------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE USP_ImportToJsonVarFromXmlFile (@par_fileNameAndPath NVARCHAR(250), @par_resultJson VARCHAR(MAX) OUTPUT) AS
BEGIN
	SELECT @par_resultJson = BulkColumn
			FROM OPENROWSET (BULK 'c:\temp\TESTFILE.json', SINGLE_BLOB) import
	IF (ISJSON(@par_resultJson) <> 1)
		BEGIN
			RAISERROR ('ERROR IN JSON FORMAT!',1,1)
		END
END
----------------
GO
----------------
BEGIN
	DECLARE @resultJson NVARCHAR(MAX)
	EXEC dbo.USP_ImportToJsonVarFromXmlFile @par_fileNameAndPath = 'C:\Temp\TESTFILE.json', @par_resultJson = @resultJson OUTPUT
	PRINT (@resultJson)
	SELECT * FROM OpenJson(@resultJson)
END
----------------
GO
----------------



---------------------------------------------------------------------------------------------------
	--IMPORT FULLDATA TO TABLE FROM JSON VARIABLE 
---------------------------------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE USP_ImportFullDataToTableFromJsonVar (@par_json NVARCHAR(MAX)) AS
BEGIN
	CREATE TABLE #resultTable (	
				PersonElementID INT NOT NULL,
				InternalTaxNumber CHAR(11),
				Gender NVARCHAR(7),
				BirthDay DATETIMEOFFSET,
				FirstName NVARCHAR(50),
				LastName NVARCHAR(50)
				)
	DECLARE @resultCount INT
	BEGIN TRY
		INSERT INTO #resultTable (PersonElementID, InternalTaxNumber, Gender, BirthDay, FirstName, LastName)
			SELECT * FROM OPENJSON (@par_json) 
				WITH(
					[PersonElementID] INT N'$.Partner.ID', 
					[InternalTaxNumber] CHAR(11) N'$.Partner.InternalTaxNumber',
					[Gender] NVARCHAR(7) N'$.Partner.Gender',
					[BirthDay] DATETIMEOFFSET N'$.Partner.BirthDay', 
					[FullName.LastName] NVARCHAR(50) N'$.Partner.FullName.LastName', 
					[FullName.FirstName] NVARCHAR(50) N'$.Partner.FullName.FirstName'
					)
		SELECT @resultCount = COUNT(*) FROM #resultTable
		IF (@resultCount <> 0)
			BEGIN
				SELECT * FROM #resultTable
				RETURN 0
			END
		ELSE
			BEGIN 
				RETURN 1
			END 
	END TRY
	BEGIN CATCH
			PRINT( CONCAT('ERROR_NUMBER: ', ERROR_NUMBER()));
			PRINT( CONCAT('ERROR_SEVERITY: ', ERROR_SEVERITY()));
			PRINT( CONCAT('ERROR_STATE: ', ERROR_STATE()));
			PRINT( CONCAT('ERROR_PROCEDURE: ', ERROR_PROCEDURE()));
			PRINT( CONCAT('ERROR_MESSAGE: ', ERROR_MESSAGE()));
		RETURN 2
	END CATCH
END
----------------
GO
----------------
BEGIN
	DECLARE @varJson NVARCHAR(MAX)
	DECLARE @resultINT INT
	SET @varJson = dbo.UDF_CreateJsonPath(1,5)
	SELECT @varJson
	EXEC @resultINT = USP_ImportFullDataToTableFromJsonVar @par_json = @varJson
	PRINT (@resultINT)
END
----------------
GO
----------------


---------------------------------------------------------------------------------------------------
	--CREATE A TABLE WITH JSON TYPE AND DO DML-S 
---------------------------------------------------------------------------------------------------
CREATE TABLE TableOfJson 
	(	ID INT PRIMARY KEY NOT NULL,
		Jsons NVARCHAR(MAX) NOT NULL,
		InsertTime DATETIMEOFFSET DEFAULT SYSDATETIMEOFFSET())
----------------
GO
----------------
--INSERT JSON DATA
BEGIN ;
	DECLARE @counter INT = 1;
	DECLARE @varJson NVARCHAR(MAX);
	DECLARE @ID INT = 1;
	WHILE @counter <= 100
		BEGIN ;
			BEGIN TRY;
				SET @varJson =  dbo.UDF_CreateJsonPath(@counter, @counter);
				PRINT (@varJson);
				INSERT INTO dbo.TableOfJson (ID, Jsons) VALUES (@ID, @varJson);
				SET @ID = @ID + 1;
			END TRY
			BEGIN CATCH;
				IF ERROR_NUMBER() = 245
					BEGIN
						PRINT ('NOT FOUND ID IN Partner TABLE');
					END;
				ELSE
					BEGIN;
						PRINT( CONCAT('ERROR_NUMBER: ', ERROR_NUMBER()));
						PRINT( CONCAT('ERROR_SEVERITY: ', ERROR_SEVERITY()));
						PRINT( CONCAT('ERROR_STATE: ', ERROR_STATE()));
						PRINT( CONCAT('ERROR_PROCEDURE: ', ERROR_PROCEDURE()));
						PRINT( CONCAT('ERROR_MESSAGE: ', ERROR_MESSAGE()));
					END;
			END CATCH;
			SET @counter = @counter +1;
		END;
END;
----------------
GO
----------------
SELECT * FROM TableOfJson


--SELECT WITH SQL_VALUE (RESULT ALWAYS IS A SCALAR VARIABLE)
SELECT  Jsons,
		JSON_VALUE(Jsons, N'strict$[0].Partner.ID') AS ID, --strict: IT GIVES AN ERROR IN  CASE THE KEY DOES NOT EXIST
		JSON_VALUE(Jsons, N'$[0].Partner.InternalTaxNumber') AS InternalTaxNumber, --[0] SHOW ELEMENTS OF ARRAY
		JSON_VALUE(Jsons, N'$[0].Partner.FullName.LastName') AS LastName, 
		JSON_VALUE(Jsons, N'$[0].Partner.FullName.FirstName') AS FirstName,
		JSON_VALUE(Jsons, N'$[0].Partner.Gender') AS Gender 
	FROM TableOfJson WHERE JSON_VALUE(Jsons, N'strict$[0].Partner.ID') = 5


--SELECT WITH SQL_QUERY: GET THE FIRST ELEMENT OF ARRAY (RESULT NEVER IS A SCALAR VARIABLE)
SELECT Jsons,
		JSON_QUERY(Jsons, N'$[0]') AS PartnerJsonWithoutArray
	FROM TableOfJson WHERE JSON_VALUE(Jsons, N'strict$[0].Partner.ID') = 5

--SELECT WITH SQL_QUERY: GET ALL STRING OF JSON (RESULT NEVER IS A SCALAR VARIABLE)
SELECT Jsons,
		JSON_QUERY(Jsons, N'$') AS FullPartnerJson
	FROM TableOfJson WHERE JSON_VALUE(Jsons, N'strict$[0].Partner.ID') = 5


--SELECT WITH SQL_QUERY: GET STRUCTURE OF ELEMENT (RESULT NEVER IS A SCALAR VARIABLE)
SELECT 
		JSON_VALUE(Jsons, N'strict$[0].Partner.ID') AS ID,
		JSON_QUERY(Jsons, N'$[0].Partner.FullName') AS FullName
	FROM TableOfJson

----------------
GO
----------------


-----------------------------------------------------------------------------------------------------
--CONNECT ANOTHER MSSQL SERVER (LINKED SERVER)
-----------------------------------------------------------------------------------------------------
--1. CREATE LINKED SERVER
USE master;
EXEC master.dbo.sp_addlinkedserver 
    @server = N'10.31.12.100',
    @srvproduct=N'SQL Server';
GO

--2. DELETE LINKED SERVER
EXEC master.dbo.sp_dropserver '10.31.12.100';
GO

--3. CREATE LINKEDSERVERLOGIN
EXEC master.dbo.sp_addlinkedsrvlogin   
    @rmtsrvname = N'10.31.12.100',   
    @locallogin = NULL ,   
    @useself = N'FALSE' ,
	@rmtuser = N'Sa' ,
	@rmtpassword  = N'password'
	;  
GO 

--4. DELETE LINKEDSERVERLOGIN 
EXEC sp_droplinkedsrvlogin '10.31.12.100', NULL; 
GO
EXEC sp_droplinkedsrvlogin '10.31.12.100', 'sa'; 
GO

--5. TEST OF LINKEDSERVER (GET DATABASE NAME FROM SOURCE INSTANCE)
SELECT name FROM [10.31.12.100].master.sys.databases ;  
GO  

--6. SELECT A TABLE FROM SOURCE SERVER
	--CREATE TABLE IN SOURCE SERVER
		CREATE TABLE Person (PersonID INT PRIMARY KEY IDENTITY (1,1) NOT NULL, MRN INT, FirstName NVARCHAR(128), LastName NVARCHAR(128))
	--RUN QUERY FROM SOURCE SERVER
		SELECT * FROM [10.31.12.100].[ZRTDATABASE_TEST_733].[dbo].[Person] WHERE PersonID = 1697282;

--7. EXECUTE STORED PROCEDURE FROM SOURCE SERVER
	--CREATE STORED PROCEDURE IN SOURCE SERVER
		GO
		CREATE OR ALTER PROCEDURE TestForLinkedServer_proc @PersonID_par INT AS 
		BEGIN
			SELECT MRN, FirstName, LastName FROM Person WHERE PersonID = @PersonID_par;
		END;
		GO
	--EXECUTE STORED PROCEDURE 
		EXEC [10.31.12.100].[ZRTDATABASE_TEST_733].[dbo].TestForLinkedServer_proc @PersonID_par = 1697282;

--8. RUN QUERY IN LOCAL STORED PROCEDURE AND STORED RESULT FROM SOURCE SERVER
	--CREATE TABLE IN SOURCE SERVER
		CREATE TABLE Person (PersonID INT PRIMARY KEY IDENTITY (1,1) NOT NULL, MRN INT, FirstName NVARCHAR(128), LastName NVARCHAR(128))
	--CREATE TABLE IN LOCAL SERVER
		CREATE TABLE Person (PersonID INT PRIMARY KEY IDENTITY (1,1) NOT NULL, MRN INT, FirstName NVARCHAR(128), LastName NVARCHAR(128))
	--CREATE STORED PROCEDURE  IN LOCAL SERVER
		GO
		CREATE OR ALTER PROCEDURE TestInsertFromLinkedServerQuery @PersonLocalID_par INT AS 
		BEGIN
		INSERT INTO dbo.Person (MRN, FirstName , LastName) SELECT MRN, FirstName , LastName FROM [10.31.12.100].[ZRTDATABASE_TEST_733].[dbo].[Person] 
			WHERE PersonID =  @PersonLocalID_par;
		END;
		GO
	--EXECUTE STORED PROCEDURE IN LOCAL SERVER
		EXEC TestInsertFromLinkedServerQuery @PersonLocalID_par = 1697282;
		SELECT * FROM Person;



---------------------------------------------------------------------------------------------------
--CREATE LINKEDSERVER SOLUTION TO ORACLE - V19
---------------------------------------------------------------------------------------------------

--CREATE LOGIN IN ORACLE RDBMS
	--alter profile "DEFAULT" limit password_life_time unlimited; 
	--create user MSSQLUSER identified by Jelszojelszo1 container = current;
	--grant all privileges to MSSQLUSER;
	--grant select any dictionary to MSSQLUSER;
	--grant create any table to MSSQLUSER;

--CREATE LINKED SERVER IN LOCAL SERVER
	USE master;
	EXEC master.dbo.sp_addlinkedserver 
		@server = N'127.0.0.1',
		@srvproduct = N'127.0.0.1:1521/XEPDB1', --IP:PORT/DATA_SOURCE (portableDB)
		@provider = 'OraOLEDB.Oracle',
		@datasrc = N'127.0.0.1:1521/XEPDB1'; --IP:PORT/DATA_SOURCE (portableDB)
	GO

	sp_addlinkedsrvlogin @rmtsrvname = '127.0.0.1', @useself = 'False', @locallogin = null, 
		   @rmtuser = 'DEMOUSER', @rmtpassword ='jelszo';

	GO

-- RUN QUERY
	USE FullTutorial;
	SELECT * FROM OPENQUERY([127.0.0.1],'SELECT * FROM DEMOUSER.USERS');
	--OR
	SELECT * FROM [127.0.0.1]..DEMOUSER.USERS;



------------------------------------------------------
-- CREATE DATABASE MAIL
------------------------------------------------------
--You must set options of gmail settings. You need enabled IMAP, turn off 2-step Verification and turn on Allow less secure apps. 
--Configure server
GO
sp_configure 'show advanced options', 1;
GO
RECONFIGURE;
GO
 
sp_configure 'Database Mail XPs', 1;
GO
RECONFIGURE
GO

-- Create a Database Mail profile  
EXECUTE msdb.dbo.sysmail_add_profile_sp  
    @profile_name = 'ErrorLog_test_profile',  
    @description = 'First profile for error log using Gmail.' ;  
GO

-- Grant access to the profile to the DBMailUsers role  
EXECUTE msdb.dbo.sysmail_add_principalprofile_sp  
    @profile_name = 'ErrorLog_test_profile',  
    @principal_name = 'public',  
    @is_default = 1 ;
GO

-- Create a Database Mail account  
EXECUTE msdb.dbo.sysmail_add_account_sp  
    @account_name = 'ErrorLog_test_Gmail_account',  
    @description = 'Mail account for sending outgoing ErrorLog_test mails.',  
    @email_address = 'xy@gmail.com',  
    @display_name = 'Automated ErrorLog_test Mailer',  
    @mailserver_name = 'smtp.gmail.com',
    @port = 587,
    @enable_ssl = 1,
    @username = 'xy@gmail.com', -- NEED VALID EMAIL
    @password = '******'; --NEED VALID PASSWORD  
GO

-- Add the account to the profile  
EXECUTE msdb.dbo.sysmail_add_profileaccount_sp  
    @profile_name = 'ErrorLog_test_profile',  
    @account_name = 'ErrorLog_test_Gmail_account',  
    @sequence_number =1 ;  
GO

--Test database mail 
EXEC msdb.dbo.sp_send_dbmail
     @profile_name = 'ErrorLog_test_profile',
     @recipients = 'jk@gmail.com',-- NEED VALID EMAIL
     @body = 'The database mail configuration was completed successfully.',
     @subject = 'Automated Success Test Message';
GO

-- Delete full database mail 
--EXECUTE msdb.dbo.sysmail_delete_profileaccount_sp @profile_name = 'ErrorLog_test_profile'
--EXECUTE msdb.dbo.sysmail_delete_principalprofile_sp @profile_name = 'ErrorLog_test_profile'
--EXECUTE msdb.dbo.sysmail_delete_account_sp @account_name = 'ErrorLog_test_Gmail_account'
--EXECUTE msdb.dbo.sysmail_delete_profile_sp @profile_name = 'ErrorLog_test_profile'


------------------------------------------------------
-- CREATE DATABASE MAIL TRIGGER
------------------------------------------------------
--Create log table
CREATE TABLE dbo.DbErrorLog 
    (
     ID INTEGER IDENTITY(1,1) NOT NULL , 
     ErrorDateTime DATETIME2 NOT NULL , 
     ErrorNumber INTEGER NOT NULL , 
	 ErrorState INT ,
	 ErrorSeverity INT ,
	 ErrorLine INT ,
     ErrorMessage NVARCHAR (MAX) NOT NULL , 
     ErrorProcedure NVARCHAR (128) , 
     ProcedureState NVARCHAR (MAX) , 
	 UserName NVARCHAR(80)
    )
GO 
ALTER TABLE dbo.DbErrorLog ADD CONSTRAINT DbErrorLog_PK PRIMARY KEY CLUSTERED (ID)
     WITH (
     ALLOW_PAGE_LOCKS = ON , 
     ALLOW_ROW_LOCKS = ON )
GO
 
 --Create database mail sender procedure
 CREATE OR ALTER PROCEDURE DbMailSenderLinkedServer_usp @par_body NVARCHAR(MAX)
 AS
 BEGIN;
	DECLARE	@mailRecipients VARCHAR(50) = 'jk@gmail.com',-- NEED VALID EMAIL
			@mailProfileName VARCHAR(50) = 'ErrorLog_test_profile',
			@mailSubject VARCHAR(50) = 'Linked server error';
	EXEC msdb.dbo.sp_send_dbmail
	   @profile_name = @mailProfileName,
	   @recipients = @mailRecipients,
	   @body = @par_body,
	   @subject = @mailSubject
END;
GO

--DbMailSenderLinkedServer_usp test
BEGIN
	DECLARE 
		@TESTNUMBER NVARCHAR(50) = '001-001-001',
		@METHODNAME NVARCHAR(50) = 'DbMailSenderLinkedServer_usp',
		@TESTNAME NVARCHAR(100) = 'Check e-mail have been sent',
		@TESTRESULT NVARCHAR(10) = 'False';
	SET NOCOUNT ON;
	PRINT CONCAT(@TESTNUMBER,': ',@METHODNAME, ' - ', @TESTNAME);
		BEGIN TRANSACTION;
			BEGIN TRY;
				EXEC DbMailSenderLinkedServer_usp @par_body = 'Test body of email';
				SET @TESTRESULT = 'True';
				COMMIT;
			END TRY
			BEGIN CATCH;
				PRINT( CONCAT('ERROR_NUMBER: ', ERROR_NUMBER()));
				PRINT( CONCAT('ERROR_SEVERITY: ', ERROR_SEVERITY()));
				PRINT( CONCAT('ERROR_STATE: ', ERROR_STATE()));
				PRINT( CONCAT('ERROR_PROCEDURE: ', ERROR_PROCEDURE()));
				PRINT( CONCAT('ERROR_MESSAGE: ', ERROR_MESSAGE()));
				SET @TESTRESULT = 'False'
				ROLLBACK TRANSACTION;
			END CATCH;
	PRINT CONCAT('TEST RESULT: ', @TESTRESULT);
END;
GO

--Create trigger
CREATE OR ALTER TRIGGER DbErrorLog_trg ON dbo.DbErrorLog
    FOR INSERT
AS
BEGIN;
    DECLARE @errorMailBody NVARCHAR(MAX),
			@errorProcedure NVARCHAR(128);
	SELECT @errorProcedure = ErrorProcedure FROM INSERTED i;

    IF @errorProcedure = 'LinkedServerProcedure_usp' --check procedure name of error
		BEGIN;
			SELECT @errorMailBody =  CONCAT('ERROR DATE TIME: ', ErrorDateTime, ', ',
											'ERROR MESSAGE: ' ,ErrorMessage)
				FROM INSERTED i;
			EXEC DbMailSenderLinkedServer_usp @par_body = @errorMailBody;
		END;
END;
GO

--Trigger test
BEGIN
	DECLARE 
		@TESTNUMBER NVARCHAR(50) = '001-001-001',
		@METHODNAME NVARCHAR(50) = 'DbErrorLog_trg',
		@TESTNAME NVARCHAR(100) = 'Check e-mail have been sent',
		@TESTRESULT NVARCHAR(10) = 'False',
		@tempID INT;
	SET NOCOUNT ON;
	PRINT CONCAT(@TESTNUMBER,': ',@METHODNAME, ' - ', @TESTNAME);
		BEGIN TRANSACTION;
			BEGIN TRY;
				SELECT @tempID = MAX(ID) FROM [dbo].[DbLinkedServerErrorLog];
				IF (@tempID IS NULL)
					BEGIN
						SET @tempID = 0;
					END;
				INSERT INTO [dbo].[DbLinkedServerErrorLog]
				   ([ErrorDateTime]
				   ,[ErrorNumber]
				   ,[ErrorState]
				   ,[ErrorSeverity]
				   ,[ErrorLine]
				   ,[ErrorMessage]
				   ,[ErrorProcedure]
				   ,[UserName])
				VALUES
				   (GETDate()
				   ,5000
				   ,1
				   ,1
				   ,16
				   ,'Test of linked server error'
				   ,'LinkedServerProcedure_usp'
				   ,SUSER_SNAME());
				 SET @TESTRESULT = 'True';
				 COMMIT;
			END TRY
			BEGIN CATCH;
				PRINT( CONCAT('ERROR_NUMBER: ', ERROR_NUMBER()));
				PRINT( CONCAT('ERROR_SEVERITY: ', ERROR_SEVERITY()));
				PRINT( CONCAT('ERROR_STATE: ', ERROR_STATE()));
				PRINT( CONCAT('ERROR_PROCEDURE: ', ERROR_PROCEDURE()));
				PRINT( CONCAT('ERROR_MESSAGE: ', ERROR_MESSAGE()));
				SET @TESTRESULT = 'False'
				ROLLBACK TRANSACTION;
			END CATCH;
	DELETE FROM dbo.DbLinkedServerErrorLog WHERE ID > @tempID;
	DBCC CHECKIDENT (DbLinkedServerErrorLog, RESEED, @tempID) WITH NO_INFOMSGS;
	PRINT CONCAT('TEST RESULT: ', @TESTRESULT);
END;
GO
