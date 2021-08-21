
CREATE DATABASE Union_Bank;
GO

USE Union_Bank;
GO

---Create Table Calender in DBO
CREATE TABLE dbo.Calender 
	( CalendarDate datetime NULL);

---Create Table US_Zipcodes in DBO
CREATE TABLE dbo.US_Zipcodes
	(  IsSurrogateKey int NOT NULL
	 , ZIP varchar (5) NOT NULL
	 , Latitude float NULL
	 , Longitude float NULL
	 , City varchar (255) NULL
	 , StateID char (2) NULL
	 , [Population] int NULL
	 , Density decimal (18,0) NULL   --- DECIMAL (P, S) where P= Preciion total number of digits wanted within that column; annd S = Scale how many decimal points are wanted 
	 , County_Fips varchar (10) NULL
	 , County_Name varchar (255) NULL
	 , County_Names_all varchar (255) NULL
	 , County_Fips_all varchar (50) NULL
	 , TimeZone varchar (255) NULL
	 , CreateDate datetime NOT NULL
	);

	ALTER TABLE dbo.US_Zipcodes
	ADD CONSTRAINT PK_US_Zipcodes_ZIP_ PRIMARY KEY (ZIP)
	, CONSTRAINT FK_US_Zipcodes_StateID FOREIGN KEY (StateID) References dbo.State (StateID);


---Create Table  State in DBO
CREATE TABLE dbo.State
	( StateID char(2) NOT NULL
	 , StateName varchar (255) NOT NULL
	 , CreateDate datetime NOT NULL
	);
	
ALTER TABLE dbo.State
	ADD CONSTRAINT PK_State_StateID PRIMARY KEY (StateID)
	, CONSTRAINT DF_State_CreateDate DEFAULT (GETDATE ()) FOR CreateDate
	, CONSTRAINT UNQ_State_StateName UNIQUE (StateName); 


 ---Create 2nd Schema for Borrower with 2 Tables, Borrower and BorrowerAddress
CREATE SCHEMA BORROWER;

	CREATE TABLE BORROWER.Borrower 
		( BorrowerID int NOT NULL
		 , BorrowerFirstName varchar (255) NOT NULL
		 , BorrowerMiddleInitial char (1) NOT NULL
		 , BorrowerLastName varchar (255) NOT NULL
		 , DoB datetime NOT NULL
		 , Gender char (1) NULL
		 , TaxPayerID_SSN varchar (9) NOT NULL
		 , PhoneNumber varchar (10) NOT NULL
		 , Email varchar (255) NULL 
		 , Citizenship  varchar (255) NULL 
		 , BeneficiaryName  varchar (255) NULL 
		 , IsUScitizen bit NULL
		 , CreateDate datetime NOT NULL 
		);

	ALTER TABLE BORROWER.Borrower
	ADD CONSTRAINT CHK_Borrower_DOB CHECK(DOB<= DATEADD(YEAR, -18, GETDATE()))
	   , CONSTRAINT CHK_Borrower_Email CHECK (Email like '%@%')
	   , CONSTRAINT CHK_Borrower_Phone CHECK(LEN(PhoneNUmber)=10 )
	   , CONSTRAINT CHK_Borrower_TaxPayerID_SSN CHECK(LEN(TaxPayerID_SSN) = 9)
	   , CONSTRAINT DF_Borrower_CreateDate DEFAULT(GETDATE()) FOR CreateDate 
	   , CONSTRAINT PK_Borrower_BorrowerID PRIMARY KEY (BorrowerID);

	CREATE TABLE BORROWER.BorrowerAddress
		( AddressID int NOT NULL 
		 , BorrowerID int NOT NULL 
		 , StreetAddress varchar (255) NOT NULL 
		 , ZIP varchar (5) NOT NULL 
		 , CreateDate datetime NOT NULL 
		);

	ALTER TABLE BORROWER.BorrowerAddress
	ADD CONSTRAINT DF_BorrowerAddress_CreateDate DEFAULT(GETDATE()) FOR CreateDate 
	   , CONSTRAINT FK_BorrowerAddress_BorrowerID FOREIGN KEY (BorrowerID) REFERENCES BORROWER.Borrower (BorrowerID) ON DELETE CASCADE
	   , CONSTRAINT FK_BorrowerAddress_ZIP FOREIGN KEY (ZIP) REFERENCES dbo.US_Zipcodes (ZIP) ON DELETE CASCADE
	   , CONSTRAINT PK_BorrowerAddress_AddressID_BorrowerID PRIMARY KEY (AddressID, BorrowerID) ; 
	 
	 
---Create 3rd Schema for Loan with 5 Tables, LoanSetupInformation, LoanPeriodic, LU_Delinquency, LU_PaymentFrequency, Underwriter
 CREATE SCHEMA LOAN; 

	CREATE TABLE LOAN.LoanSetupInformation
		( IsSurrogateKey int NOT NULL
		 , LoanNumber varchar (10)  NOT NULL
		 , PurchaseAmount numeric  NOT NULL
		 , PurchaseDate datetime  NOT NULL
		 , LoanTerm int  NOT NULL
		 , BorrowerID int  NOT NULL
		 , UnderwriterID int  NOT NULL
		 , ProductID char (2)  NOT NULL
		 , InterestRate decimal (3,3)  NOT NULL
		 , PaymentFrequency int  NOT NULL
		 , AppraisalValue numeric (18,2) NOT NULL
		 , CreateDate datetime  NOT NULL
		 , LTV decimal (4,2) NOT NULL
		 , FirstInterestPaymentDate datetime NULL
		 , MaturityDate datetime  NOT NULL
		);

	ALTER TABLE LOAN.LoanSetupInformation
	ADD CONSTRAINT PK_LoanSetupInformation_LoanNumber PRIMARY KEY (LoanNumber)
	, CONSTRAINT CHK_LoanSetupInformationc_LoanTerm CHECK (LoanTerm=35 OR LoanTerm=30 OR LoanTerm=15 OR LoanTerm=10)
	, CONSTRAINT CHK_LoanSetupInformation_InterestRate CHECK (InterestRate !< 0.01 and InterestRate !> 0.30)
	, CONSTRAINT DF_LoanSetupInformation_CreateDate DEFAULT (GETDATE()) FOR CreateDate
	, CONSTRAINT FK_LoanSetupInformation_BorrowerID FOREIGN KEY (BorrowerID) References BORROWER.Borrower (BorrowerID) ON DELETE CASCADE
	, CONSTRAINT FK_LoanSetupInformation_PaymentFrequency FOREIGN KEY (PaymentFrequency) References LOAN.LU_PaymentFrequency (PaymentFrequency) ON DELETE CASCADE
	, CONSTRAINT FK_LoanSetupInformation_UnderwriterID FOREIGN KEY (UnderwriterID) References LOAN.Underwriter (UnderwriterID) ON DELETE CASCADE;
	   
	CREATE TABLE LOAN.LoanPeriodic
		( IsSurrogateKey  int NOT NULL
		 , LoanNumber varchar (10) NOT NULL
		 , CycleDate datetime NOT NULL
		 , ExtraMonthlyPayment numeric (18,2) NOT NULL
		 , UnpaidPrincipalBalance numeric (18,2)  NOT NULL
		 , BeginningScheduleBalance  numeric (18,2)  NOT NULL
		 , PaidInstallment numeric (18,2)  NOT NULL
		 , InterestPortion numeric (18,2)  NOT NULL
		 , PrincipalPortion numeric (18,2)  NOT NULL
		 , EndscheduleBalance numeric (18,2)  NOT NULL
		 , ActualendScheduleBalance numeric (18,2)  NOT NULL
		 , TotalInterestAccrued numeric (18,2)  NOT NULL
		 , TotalPrincipalAccrued numeric (18,2)  NOT NULL
		 , DefaultPenalty numeric (18,2)  NOT NULL
		 , DelinquencyCode int NOT NULL
		 , CreateDate datetime NOT NULL
		);

	ALTER TABLE LOAN.LoanPeriodic
	ADD CONSTRAINT CHK_LoanPeriodic_PaidInstallment CHECK (InterestPortion + PrincipalPortion = PaidInstallment)
	, CONSTRAINT DF_LoanPeriodic_ExtraMonthlyPayment DEFAULT ('0') FOR ExtraMonthlyPayment
	, CONSTRAINT DF_LoanPeriodic_CreateDate DEFAULT (GETDATE()) FOR  CreateDate
	, CONSTRAINT FK_LoanPeriodic_LoanNumber FOREIGN KEY (LoanNumber) References LOAN.LoanSetupInformation (LoanNUmber) ON DELETE CASCADE
	, CONSTRAINT FK_LoanPeriodic_DelinquencyCode FOREIGN KEY (DelinquencyCode) References LOAN.LU_Delinquency (DelinquencyCode) ON DELETE CASCADE
	, CONSTRAINT PK_LoanPeriodic_LoanNUmber_CycleDate PRIMARY KEY (LoanNUmber, CycleDate);
	   	  
	CREATE TABLE LOAN.LU_Delinquency
		( DelinquencyCode int NOT NULL
		 , Delinquency varchar (255) NOT NULL
		);

	ALTER TABLE LOAN.LU_Delinquency
	ADD CONSTRAINT PK_LU_Delinquency_DelinquencyCode PRIMARY KEY (DelinquencyCode);

	CREATE TABLE LOAN.LU_PaymentFrequency 
		( PaymentFrequency int NOT NULL
		 , PaymentIsMadeEvery int NOT NULL
		 , PaymentFrequency_Description varchar (255) NOT NULL
		);

	ALTER TABLE LOAN.LU_PaymentFrequency
	ADD CONSTRAINT PK_LU_PaymentFrequency_PaymentFrequency PRIMARY KEY (PaymentFrequency);

	CREATE TABLE LOAN.Underwriter
		( UnderwriterID int NOT NULL
		 , UnderwriterFirstName varchar (255) NULL
		 , UnderwriterMiddleInitial char (1) NULL
		 , UnderwriterLastName varchar (255) NOT NULL
		 , PhoneNumber varchar (14) NULL
		 , Email varchar (255) NOT NULL
		 , CreateDate datetime NOT NULL
		);
		
	ALTER TABLE LOAN.Underwriter
	ADD CONSTRAINT PK_Underwriter_UnderwriterID PRIMARY KEY (UnderwriterID)
	, CONSTRAINT CHK_Underwriter_Email CHECK (Email like '%@%')
	, CONSTRAINT DF_Underwriter_CreateDate DEFAULT (GETDATE()) FOR  CreateDate ; 

	