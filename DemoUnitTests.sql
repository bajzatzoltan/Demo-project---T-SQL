USE master
CREATE DATABASE FullTutorial
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


---------------------------------------------------------------------------------------------------
--CREATE METHODS TO INVALID PARAMETER ERROR: USP_InvalidParameterError 
---------------------------------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE USP_InvalidParameterError AS
BEGIN;
	THROW 51000, 'Invalid parameter!',1;
END;
----------------
GO;


---------------------------------------------------------------------------------------------------
--CREATE METHODS TO GET COUNT OF ID: SF_CheckIdInPersons 
---------------------------------------------------------------------------------------------------
CREATE OR ALTER FUNCTION SF_CheckIdInPersons (@par_ID INT) RETURNS INT AS
BEGIN
	DECLARE @var_count INT;
	IF @par_ID <= 0
		BEGIN;
			EXEC USP_InvalidParameterError;
		END;

	SELECT @var_count = COUNT(*) FROM Persons WHERE ID_FK = @par_ID;
	RETURN @var_count;
END;
----------------
GO;


---------------------------------------------------------------------------------------------------
--CREATE UNIT TESTS OF SF_CheckIdInPersons 
---------------------------------------------------------------------------------------------------

BEGIN

--DECLARATION (ARRANGE)
	DECLARE 
		@TESTNUMBER NVARCHAR(50) = '001-001-001',
		@METHODNAME NVARCHAR(50) = 'SF_CheckIdInPersons',
		@TESTNAME NVARCHAR(100) = 'Contains ID for parameter',
		@TESTRESULT NVARCHAR(10) = 'False',
		@expectedResult INT = 1,
		@result INT,
		@maxIDinPartners INT,
		@tempID INT;
	SET NOCOUNT ON;

--PRINT TEST IDENTIFYING (ARRANGE)
	PRINT CONCAT(@TESTNUMBER,': ',@METHODNAME, ' - ', @TESTNAME);
		BEGIN TRANSACTION;
			BEGIN TRY

--INITIALIZATION: CREATE START STATE OF TEST (ARRANGE)
					INSERT INTO Partners (InternalTaxNumber) VALUES ('01234567890');
					SELECT @maxIDinPartners = MAX(ID) FROM Partners;
					--PRINT CONCAT('max Partners ID: ' ,@maxIDinPartners);
					INSERT INTO Persons (ID_FK, FirstName, LastName, Gender, Birthday) VALUES (@maxIDinPartners, 'Gubo', 'Pestis', 'Male', '20110303 12:00:00 AM');

--SAVE THE STATE BEFORE THE TEST (SAVE)
					SET @tempID = @maxIDinPartners - 1;

--RUN METHOD (ACT)
					SET @result = DBO.SF_CheckIdInPersons(@maxIDinPartners);

--SET RESULT (ASSERT)
					IF @result = @expectedResult
						BEGIN
							SET @TESTRESULT = 'True';
						END;

--RESTORE THE STATE BEFORE THE TEST(RESTORE)
				ROLLBACK TRANSACTION;
				--ROLLBACK TRANSACTION = DELETE FROM Persons WHERE ID_FK = @maxIDinPartners; AND DELETE FROM Partners WHERE ID = @maxIDinPartners;
			END TRY
			BEGIN CATCH

--PRINT TEST RESULT (ASSERT)
				PRINT( CONCAT('ERROR_NUMBER: ', ERROR_NUMBER()));
				PRINT( CONCAT('ERROR_SEVERITY: ', ERROR_SEVERITY()));
				PRINT( CONCAT('ERROR_STATE: ', ERROR_STATE()));
				--PRINT( CONCAT('ERROR_PROCEDURE: ', ERROR_PROCEDURE()));
				PRINT( CONCAT('ERROR_MESSAGE: ', ERROR_MESSAGE()));
				
--SET RESULT (ASSERT)
				SET @TESTRESULT = 'False'
				
--RESTORE THE STATE BEFORE THE TEST(RESTORE)
				ROLLBACK TRANSACTION;
			END CATCH

--RESTORE THE STATE BEFORE THE TEST (RESTORE)
	DBCC CHECKIDENT (Partners, RESEED, @tempID) WITH NO_INFOMSGS; --RESTORE SEQUENCE OF ID

--PRINT TEST RESULT (ASSERT)
	PRINT CONCAT('TEST RESULT: ', @TESTRESULT);
END;
----------------
GO 
DBCC DROPCLEANBUFFERS WITH NO_INFOMSGS; --JUST IN TEST ENVIROMENT!!!!
GO
----------------
BEGIN

--DECLARATION (ARRANGE)
	DECLARE 
		@TESTNUMBER NVARCHAR(50) = '001-001-002',
		@METHODNAME NVARCHAR(50) = 'SF_CheckIdInPersons',
		@TESTNAME NVARCHAR(100) = 'No contains ID for parameter',
		@TESTRESULT NVARCHAR(10) = 'False',
		@expectedResult INT = 0,
		@result INT,
		@param INT = 10;
	SET NOCOUNT ON;
	
--PRINT TEST IDENTIFYING (ARRANGE)
	PRINT CONCAT(@TESTNUMBER,': ',@METHODNAME, ' - ', @TESTNAME);
		BEGIN TRANSACTION
			BEGIN TRY
				
--RUN METHOD (ACT)				
				SET @result = DBO.SF_CheckIdInPersons(@param);
				
--SET RESULT (ASSERT)
				IF @result = @expectedResult
					BEGIN
						SET @TESTRESULT = 'True';
					END;
				
--RESTORE THE STATE BEFORE THE TEST(RESTORE)
				ROLLBACK TRANSACTION;
			END TRY
			BEGIN CATCH
				
--PRINT TEST RESULT (ASSERT)
				PRINT( CONCAT('ERROR_NUMBER: ', ERROR_NUMBER()));
				PRINT( CONCAT('ERROR_SEVERITY: ', ERROR_SEVERITY()));
				PRINT( CONCAT('ERROR_STATE: ', ERROR_STATE()));
				--PRINT( CONCAT('ERROR_PROCEDURE: ', ERROR_PROCEDURE()));
				PRINT( CONCAT('ERROR_MESSAGE: ', ERROR_MESSAGE()));
				
--SET RESULT (ASSERT)
				SET @TESTRESULT = 'False'
				
--RESTORE THE STATE BEFORE THE TEST(RESTORE)
				ROLLBACK TRANSACTION;
			END CATCH
	
--PRINT TEST RESULT (ASSERT)	
	PRINT CONCAT('TEST RESULT: ', @TESTRESULT);
END;
----------------
GO 
DBCC DROPCLEANBUFFERS WITH NO_INFOMSGS; --JUST IN TEST ENVIROMENT!!!!
GO
----------------

BEGIN

--DECLARATION (ARRANGE)
	DECLARE 
		@TESTNUMBER NVARCHAR(50) = '001-001-003',
		@METHODNAME NVARCHAR(50) = 'SF_CheckIdInPersons',
		@TESTNAME NVARCHAR(100) = 'Invalid parameter - parameter = 0',
		@TESTRESULT NVARCHAR(10) = 'False',
		@expectedResult INT = 0,
		@result INT,
		@param INT = 0;
	SET NOCOUNT ON;
	
--PRINT TEST IDENTIFYING (ARRANGE)
	PRINT CONCAT(@TESTNUMBER,': ',@METHODNAME, ' - ', @TESTNAME);
		BEGIN TRANSACTION
			BEGIN TRY
				
--RUN METHOD (ACT)				
				SET @result = DBO.SF_CheckIdInPersons(@param);
				
--SET RESULT (ASSERT)
				SET @TESTRESULT = 'False';
				
--RESTORE THE STATE BEFORE THE TEST(RESTORE)
				ROLLBACK TRANSACTION;
			END TRY
			BEGIN CATCH
				
--PRINT TEST RESULT (ASSERT)
				IF ERROR_NUMBER() = 557 AND ERROR_STATE() = 2
				BEGIN;
					SET @TESTRESULT = 'True';
				END;
				
--RESTORE THE STATE BEFORE THE TEST(RESTORE)
				ROLLBACK TRANSACTION;
			END CATCH
	--FINALLY: (MINDENKÉPPEN LEFUT)
	
--PRINT TEST RESULT (ASSERT)	
	PRINT CONCAT('TEST RESULT: ', @TESTRESULT);
END;
----------------
GO 
DBCC DROPCLEANBUFFERS WITH NO_INFOMSGS; --JUST IN TEST ENVIROMENT!!!!
GO
----------------

BEGIN

--DECLARATION (ARRANGE)
	DECLARE 
		@TESTNUMBER NVARCHAR(50) = '001-001-004',
		@METHODNAME NVARCHAR(50) = 'SF_CheckIdInPersons',
		@TESTNAME NVARCHAR(100) = 'Invalid parameter - parameter is negative number',
		@TESTRESULT NVARCHAR(10) = 'False',
		@expectedResult INT = 0,
		@result INT,
		@param INT = -1;
	SET NOCOUNT ON;
	
--PRINT TEST IDENTIFYING (ARRANGE)
	PRINT CONCAT(@TESTNUMBER,': ',@METHODNAME, ' - ', @TESTNAME);
		BEGIN TRANSACTION
			BEGIN TRY
				
--RUN METHOD (ACT)				
				SET @result = DBO.SF_CheckIdInPersons(@param);
				
--SET RESULT (ASSERT)
				SET @TESTRESULT = 'False';
				
--RESTORE THE STATE BEFORE THE TEST(RESTORE)
				ROLLBACK TRANSACTION;
			END TRY
			BEGIN CATCH
				
--PRINT TEST RESULT (ASSERT)
				IF ERROR_NUMBER() = 557 AND ERROR_STATE() = 2
				BEGIN;
					SET @TESTRESULT = 'True';
				END;
				
--RESTORE THE STATE BEFORE THE TEST(RESTORE)
				ROLLBACK TRANSACTION;
			END CATCH
	
--PRINT TEST RESULT (ASSERT)	
	PRINT CONCAT('TEST RESULT: ', @TESTRESULT);
END;
----------------
GO

