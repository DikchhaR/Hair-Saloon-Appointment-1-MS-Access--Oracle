CREATE TABLESPACE assignment2
  DATAFILE 'assignment2.dat' SIZE 40M 
  ONLINE; 
  
-- Create Users
CREATE USER dikchhaAdmin IDENTIFIED BY dikchhaPassword ACCOUNT UNLOCK
	DEFAULT TABLESPACE assignment2
	QUOTA 20M ON assignment2;
	
CREATE USER testUser IDENTIFIED BY testPassword ACCOUNT UNLOCK
	DEFAULT TABLESPACE assignment2
	QUOTA 5M ON assignment2;
	
-- Create ROLES
CREATE ROLE applicationAdmin;
CREATE ROLE applicationUser;

-- Grant PRIVILEGES
GRANT CONNECT, RESOURCE, CREATE VIEW, CREATE TRIGGER, CREATE PROCEDURE TO applicationAdmin;
GRANT CONNECT, RESOURCE TO applicationUser;

GRANT applicationAdmin TO dikchhaAdmin;
GRANT applicationUser TO testUser;

-- NOW we can connect as the applicationAdmin and create the stored procedures, tables, and triggers

CONNECT dikchhaAdmin/dikchhaPassword;


--creating table Clients---
CREATE TABLE Clients (
  ClientID int NOT NULL,
  FirstName varchar(45) NOT NULL,
   LastName varchar(45) NOT NULL,
   Phone   varchar(45) NOT NULL,
   Email   varchar(45) NULL,
PRIMARY KEY (ClientID)
);

INSERT INTO Clients VALUES (1,'Jenn','Clarke','159-231-3821','jennc@gmail.com'); 
INSERT INTO Clients VALUES (2,'Kay','Allen','218-328-2861','kaya@gmail.com'); 
INSERT INTO Clients VALUES (3,'Lena','Thang','516-215-2465','lena@gmail.com'); 
INSERT INTO Clients VALUES (4,'Linh','Nguyen','836-197-3021','linhn@gmail.com'); 
COMMIT;


--creating table employees----
CREATE TABLE Employees(
   EmployeeID int NOT NULL,
   FirstName varchar(45) NOT NULL,
   LastName varchar(45) NOT NULL,
   Phone   varchar(45) NOT NULL,
   Email   varchar(45) NULL,
   PRIMARY KEY (EmployeeID)
);


INSERT INTO Employees VALUES (1,'Lynn','Tran','675-676-7871','lynnt@dhair.com'); 
INSERT INTO Employees VALUES (2,'Dikchha','Rijal','675-668-8976','dikchhar@gmail.com'); 
INSERT INTO Employees VALUES (3,'Tania','Maijo','675-687-9911','taniam@dhair.com');
INSERT INTO Employees VALUES (4,'Mandy','Dhanoa','675-687-9911','mandyd@dhair.com'); 
INSERT INTO Employees VALUES (5,'Raisha','Rasaili','897-123-0987','rrasaili@dhair.com'); 
COMMIT;

---creating table services---
CREATE TABLE Services(
   ServiceID int NOT NULL,
   Services varchar(45) NOT NULL,
   Price number NOT NULL,
   Duration number NOT NULL,
   PRIMARY KEY (ServiceID)
   );

INSERT INTO Services VALUES (1,'Women cut','80.00','60'); 
INSERT INTO Services VALUES (2,'Men cut','50.00','45'); 
INSERT INTO Services VALUES (3,'Colour','90.00','30'); 
INSERT INTO Services VALUES (4,'FullHighlights ','150.00','120'); 
INSERT INTO Services VALUES (5,'Blowdry','50.00','45'); 
INSERT INTO Services VALUES (6,'Manicure','40.00','30'); 
COMMIT;

---creating table appointments---
 CREATE TABLE Appointments(
   AppointmentID int NOT NULL,
   AppointmentDate Date NOT NULL,
   AppointmentTime Varchar2(25) NOT NULL,
   Clients_ClientID int NOT NULL,
   Services_ServiceID int NOT NULL,
   Employees_EmployeeID int NOT NULL,
   PRIMARY KEY (AppointmentID),
   CONSTRAINT fk_ClientID FOREIGN KEY (Clients_ClientID) REFERENCES Clients (ClientID),
   CONSTRAINT fk_ServiceID FOREIGN KEY (Services_ServiceID) REFERENCES Services (ServiceID),
   CONSTRAINT fk_EmployeeID FOREIGN KEY (Employees_EmployeeID) REFERENCES Employees (EmployeeID)
);
INSERT INTO Appointments VALUES (1, TO_DATE('2024-02-06', 'YYYY-MM-DD'),'9:00','2','1','2'); 
INSERT INTO Appointments VALUES (2, TO_DATE('2024-02-07', 'YYYY-MM-DD'),'10:00','1','1','1');
INSERT INTO Appointments VALUES (3, TO_DATE('2024-02-10', 'YYYY-MM-DD'),'10:15','3','2','2'); 
INSERT INTO Appointments VALUES (4, TO_DATE('2024-02-09', 'YYYY-MM-DD'),'11:00','4','1','3');
COMMIT;


----creating view for clients table---
CREATE VIEW Clients_View AS
SELECT 
    Clients.ClientID, 
    Clients.FirstName,
    Clients.LastName,
    Clients.Phone,
    Clients.Email
FROM Clients;

---creating view for employees table---
CREATE VIEW Employees_View AS
SELECT 
    Employees.EmployeeID, 
    Employees.FirstName,
    Employees.LastName,
    Employees.Phone,
    Employees.Email
FROM Employees;

---creating histological table for clients multivalue field-email----
CREATE TABLE Clients_Email_History (
    ClientID INT,
    Email VARCHAR(45),
    StartTime TIMESTAMP,
    EndTime TIMESTAMP,
    Notes VARCHAR(100)
);

----creating an assiciation table between clients and email----
CREATE TABLE Clients_Email_Association (
    ClientID INT,
    Email VARCHAR(45),
    StartTime TIMESTAMP,
    EndTime TIMESTAMP,
    Notes VARCHAR(100),
    CONSTRAINT fk_ClientID_Email FOREIGN KEY (ClientID) REFERENCES Clients(ClientID)
);

----creating view to show clients email----
CREATE VIEW Clients_Email_View AS 
SELECT 
    c.ClientID,
    c.FirstName,
    c.LastName,
    cea.Email
FROM 
    Clients c
LEFT JOIN 
    Clients_Email_Association cea ON c.ClientID = cea.ClientID
WHERE 
    cea.EndTime IS NULL;



-----creating trigger for after delete on table clients---
create or replace TRIGGER trg_clients_email_del
BEFORE DELETE ON Clients
FOR EACH ROW
BEGIN
    IF :OLD.Email IS NOT NULL THEN
        -- Update association table
        UPDATE Clients_Email_Association
        SET EndTime = SYSTIMESTAMP
        WHERE ClientID = :OLD.ClientID
        AND EndTime IS NULL;

        -- Insert deleted email into history table
        INSERT INTO Clients_Email_History (ClientID, Email, StartTime, EndTime)
        VALUES (:OLD.ClientID, :OLD.Email, SYSTIMESTAMP, SYSTIMESTAMP);
    END IF;
END;

-----creating trigger for after insert on clients table----
create or replace TRIGGER trg_clients_email_ins
AFTER INSERT ON Clients
FOR EACH ROW
BEGIN
    IF :NEW.Email IS NOT NULL THEN
        -- Insert new email into association table
        INSERT INTO Clients_Email_Association (ClientID, Email, StartTime)
        VALUES (:NEW.ClientID, :NEW.Email, SYSTIMESTAMP);

        -- Insert new email into history table
        INSERT INTO Clients_Email_History (ClientID, Email, StartTime, EndTime)
        VALUES (:NEW.ClientID, :NEW.Email, SYSTIMESTAMP, NULL);
    END IF;
END;

----creating trigger for after insert on clients table---
create or replace TRIGGER trg_clients_email_ins_history
AFTER INSERT ON Clients
FOR EACH ROW
BEGIN
    IF :NEW.Email IS NOT NULL THEN
        INSERT INTO Clients_Email_History (ClientID, Email, StartTime, EndTime)
        VALUES (:NEW.ClientID, :NEW.Email, SYSTIMESTAMP, NULL);
    END IF;
END;
----creating trigger for before update on table clients--
create or replace TRIGGER trg_clients_email_upd
BEFORE UPDATE OF Email ON Clients
FOR EACH ROW
BEGIN
    IF :OLD.Email <> :NEW.Email THEN
        -- Update association table
        UPDATE Clients_Email_Association
        SET EndTime = SYSTIMESTAMP
        WHERE ClientID = :OLD.ClientID
        AND EndTime IS NULL;

        -- Insert updated email into association table
        INSERT INTO Clients_Email_Association (ClientID, Email, StartTime)
        VALUES (:OLD.ClientID, :NEW.Email, SYSTIMESTAMP);

        -- Insert old email into history table
        INSERT INTO Clients_Email_History (ClientID, Email, StartTime, EndTime)
        VALUES (:OLD.ClientID, :OLD.Email, SYSTIMESTAMP, SYSTIMESTAMP);
    END IF;
END;

---creating trigger on before update of email on clients table---
create or replace TRIGGER trg_clients_email_upd_history
BEFORE UPDATE OF Email ON Clients
FOR EACH ROW
BEGIN
    IF :OLD.Email <> :NEW.Email THEN
        UPDATE Clients_Email_History
        SET EndTime = SYSTIMESTAMP
        WHERE ClientID = :OLD.ClientID
        AND EndTime IS NULL;

        INSERT INTO Clients_Email_History (ClientID, Email, StartTime, EndTime)
        VALUES (:OLD.ClientID, :NEW.Email, SYSTIMESTAMP, NULL);
    END IF;
END;

---creating INSTEAD OF trigger on insert on clients_view---
CREATE OR REPLACE TRIGGER trg_clients_ins
INSTEAD OF INSERT ON Clients_View
FOR EACH ROW
BEGIN
    -- Insert into Clients table
    INSERT INTO Clients (ClientID, FirstName, LastName, Phone, Email)
    VALUES (:NEW.ClientID, :NEW.FirstName, :NEW.LastName, :NEW.Phone, :NEW.Email);
END;

----creating INSTEAD OF trigger on update on clients_view
create or replace TRIGGER trg_clients_upd
INSTEAD OF UPDATE ON Clients_View
BEGIN
    -- Update Clients table
    UPDATE Clients
    SET FirstName = :NEW.FirstName,
        LastName = :NEW.LastName,
        Phone = :NEW.Phone,
        Email = :NEW.Email
    WHERE ClientID = :OLD.ClientID;
END;

-----creating INSTEAD OF trigger for delete on clients_view---
create or replace TRIGGER trg_clients_del
INSTEAD OF DELETE ON Clients_View
BEGIN
    -- Delete from Clients table
    DELETE FROM Clients WHERE ClientID = :OLD.ClientID;
END;

CREATE SEQUENCE SEQ_APPOINTMENTS
START WITH 100
INCREMENT BY 1
NOCACHE
NOCYCLE;

CREATE SEQUENCE SEQ_CLIENTS
START WITH 100
INCREMENT BY 1
NOCACHE
NOCYCLE;

CREATE SEQUENCE SEQ_EMPLOYEES
START WITH 100
INCREMENT BY 1
NOCACHE
NOCYCLE;

CREATE SEQUENCE SEQ_SERVICES
START WITH 100
INCREMENT BY 1
NOCACHE
NOCYCLE;

ALTER TABLE appointments
  MODIFY appointmentid DEFAULT SEQ_APPOINTMENTS.NEXTVAL;
  
ALTER TABLE clients
  MODIFY clientid DEFAULT SEQ_CLIENTS.NEXTVAL;
  
ALTER TABLE EMPLOYEES
  MODIFY employeeid DEFAULT SEQ_EMPLOYEES.NEXTVAL;
  
ALTER TABLE SERVICES
  MODIFY serviceid DEFAULT SEQ_SERVICES.NEXTVAL;

SELECT DIKCHHAADMIN_EMPLOYEES_VIEW.FIRSTNAME
FROM DIKCHHAADMIN_EMPLOYEES_VIEW INNER JOIN DIKCHHAADMIN_APPOINTMENTS ON DIKCHHAADMIN_EMPLOYEES_VIEW.EMPLOYEEID = DIKCHHAADMIN_APPOINTMENTS.EMPLOYEES_EMPLOYEEID
ORDER BY DIKCHHAADMIN_EMPLOYEES_VIEW.FIRSTNAME;

CREATE OR REPLACE TRIGGER instead_of_insert_trigger
INSTEAD OF INSERT ON employee_view
FOR EACH ROW
DECLARE
BEGIN
    -- Insert into the employees table
    INSERT INTO employees (employee_id, employee_name, department_id)
    VALUES (:NEW.employee_id, :NEW.employee_name, 
            (SELECT department_id FROM departments WHERE department_name = :NEW.department_name));
END;
/