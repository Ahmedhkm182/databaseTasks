CREATE TABLE Department (
    DNUM INT IDENTITY(1,1) PRIMARY KEY,
    DName VARCHAR(100) UNIQUE NOT NULL,
    MgrSSN CHAR(9) UNIQUE NOT NULL,
    MgrStartDate DATE NOT NULL
);
CREATE TABLE Employee (
    SSN CHAR(9) PRIMARY KEY,
    FName VARCHAR(50) NOT NULL,
    LName VARCHAR(50) NOT NULL,
    BirthDate DATE NOT NULL,
    Gender CHAR(10),
    DNO INT NOT NULL,
    SupervisorSSN CHAR(9),
    FOREIGN KEY (DNO) REFERENCES Department(DNUM),
    FOREIGN KEY (SupervisorSSN) REFERENCES Employee(SSN)
);
CREATE TABLE Project (
    PNumber INT IDENTITY(1,1) PRIMARY KEY,
    PName VARCHAR(100) NOT NULL,
    Location VARCHAR(100) NOT NULL,
    DNUM INT NOT NULL,
    FOREIGN KEY (DNUM) REFERENCES Department(DNUM)
);
CREATE TABLE Works_On (
    ESSN CHAR(9) NOT NULL,
    PNumber INT NOT NULL,
    Hours DECIMAL(5,2),
    PRIMARY KEY (ESSN, PNumber),
    FOREIGN KEY (ESSN) REFERENCES Employee(SSN),
    FOREIGN KEY (PNumber) REFERENCES Project(PNumber)
);
CREATE TABLE Dependent (
    ESSN CHAR(9) NOT NULL,
    Dependent_Name VARCHAR(50) NOT NULL,
    Gender CHAR(10),
    BirthDate DATE NOT NULL,
    PRIMARY KEY (ESSN, Dependent_Name),
    FOREIGN KEY (ESSN) REFERENCES Employee(SSN) ON DELETE CASCADE
);
INSERT INTO Department (DName, MgrSSN, MgrStartDate) VALUES
('HR', '111223333', '2025-01-10'),
('IT', '222334444', '2025-03-01'),
('Finance', '333445555', '2025-04-15');


INSERT INTO Employee (SSN, FName, LName, BirthDate, Gender, DNO, SupervisorSSN) VALUES
('111223333', 'Ali', 'Hassan', '1985-05-12', 'Male', 1, NULL),
('222334444', 'Sara', 'Mohamed', '1990-09-20', 'Female', 2, '111223333'),
('333445555', 'Khaled', 'Youssef', '1988-01-30', 'Male', 3, '111223333'),
('444556666', 'Laila', 'Omar', '1995-04-18', 'Female', 2, '222334444'),
('555667777', 'Omar', 'Ali', '1992-12-10', 'Male', 2, '222334444');


INSERT INTO Project (PName, Location, DNUM) VALUES
('Payroll System', 'Cairo', 1),
('Web Portal', 'Alex', 2),
('ERP Software', 'Cairo', 3);


INSERT INTO Works_On (ESSN, PNumber, Hours) VALUES
('222334444', 1, 10.5),
('333445555', 2, 12.0),
('444556666', 2, 8.0),
('555667777', 2, 6.5),
('555667777', 3, 9.0);

INSERT INTO Dependent (ESSN, Dependent_Name, Gender, BirthDate) VALUES
('222334444', 'Mona', 'Female', '2015-03-10'),
('333445555', 'Tarek', 'Male', '2014-08-22'),
('444556666', 'Nada', 'Female', '2018-12-05');


UPDATE Employee
SET DNO = 3
WHERE SSN = '555667777';


DELETE FROM Dependent
WHERE ESSN = '222334444' AND Dependent_Name = 'Mona';


SELECT E.SSN, E.FName, E.LName, D.DName
FROM Employee E
JOIN Department D ON E.DNO = D.DNUM
WHERE D.DName = 'IT';


SELECT 
    E.FName, 
    E.LName, 
    P.PName AS ProjectName, 
    W.Hours
FROM Works_On W
JOIN Employee E ON E.SSN = W.ESSN
JOIN Project P ON P.PNumber = W.PNumber;


