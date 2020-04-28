DELIMITER $$

DROP PROCEDURE IF EXISTS populateDepartment;

# @user_defined_variable

CREATE PROCEDURE populateDepartment(departmentID INTEGER, population INTEGER)
BEGIN

    SELECT CONCAT("Populating department ", departmentID, " with ", population, " employees.") AS message;

    WHILE population > 0 do
    
        # select a random departmentless employee and assign them to this department
        SELECT employee_id INTO @employeeID FROM employee WHERE department_id = 0 ORDER BY RAND() LIMIT 1;
        
        IF population % 50 = 0 THEN 
            # make every fiftieth employee a supervisor
            SELECT CONCAT("Assigning ", @employeeID, " to ", departmentID, " as skilled employee.") AS message;
            UPDATE employee SET department_id = departmentID, role = "Supervisor" WHERE employee_id = @employeeID;
        ELSEIF population % 10 = 0 THEN 
            # make every tenth employee skilled
            SELECT CONCAT("Assigning ", @employeeID, " to ", departmentID, " as skilled employee.") AS message;
            UPDATE employee SET department_id = departmentID, role = "Skilled" WHERE employee_id = @employeeID;
        ELSE
            SELECT CONCAT("Assigning ", @employeeID, " to ", departmentID, " as unskilled employee.") AS message;
            UPDATE employee SET department_id = departmentID WHERE employee_id = @employeeID;
        END IF;
        
        SET population = population - 1;
        
    END WHILE;

    # make the longest served employee in each department the manager of that department
    SELECT employee_id INTO @managerID FROM employee WHERE department_id = departmentID ORDER BY date_hired ASC LIMIT 1;
    UPDATE employee SET role = "Manager" WHERE employee_id = @managerID;

END;

DROP PROCEDURE IF EXISTS createOrganisationStructure;

CREATE PROCEDURE createOrganisationStructure()
BEGIN

    # be default all employees are created as role = "Unskilled", department = "Production", shift = "Day"
    # for testing we need to randomly assign between 20 and 30 employees to each of the other departments
    # and make the longest served employee in each department the manager of that department then make the
    # longest served employee (regardless of department) the director of the entire organisation overall

    DECLARE departmentID INTEGER DEFAULT 0;
    DECLARE endOfRecordset INTEGER DEFAULT 0;

    # declare these after any variables otherwise you get Error Code: 1337
    # Variable or condition declaration after cursor or handler declaration
 
    DECLARE departmentCursor CURSOR FOR SELECT department_id FROM department WHERE department_id <> 3;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET endOfRecordset = 1;

    # !!!!! LOAD DATA can't be used in stored proc but I'm keeping SQl here for reference because here'll raise the errors !!!!!
    # !!!!! to be albe to use the LOAD DATA command from the prompt you need to mysql --local-infile -u root -p !!!!!

    #DROP TEMPORARY TABLE IF EXISTS surnames;
    #CREATE TEMPORARY TABLE surnames(surname VARCHAR(255));
    #LOAD DATA LOCAL INFILE "C:/Development/live order tracking system/surnames.txt" INTO TABLE surnames LINES TERMINATED BY "\r\n";
    
    #DROP TEMPORARY TABLE IF EXISTS male_forenames;
    #CREATE TEMPORARY TABLE male_forenames(forename VARCHAR(255));
    #LOAD DATA LOCAL INFILE "C:/Development/live order tracking system/forenames_male.txt" INTO TABLE male_forenames LINES TERMINATED BY "\r\n";

    #DROP TEMPORARY TABLE IF EXISTS female_forenames;
    #CREATE TEMPORARY TABLE female_forenames(forename VARCHAR(255));
    #LOAD DATA LOCAL INFILE "C:/Development/live order tracking system/forenames_female.txt" INTO TABLE female_forenames LINES TERMINATED BY "\r\n";

    # delete all employee records and reset the employee_id to auto increment from 1
    DELETE FROM employee;
    ALTER TABLE employee AUTO_INCREMENT = 1;

    # create 1000 employee records
    SET @employeeCount = 0;
    WHILE @employeeCount < 1000 do
        # random surname
        SELECT surname INTO @surname FROM surnames ORDER BY RAND() LIMIT 1;
        # random gender
        SELECT ELT(FLOOR(RAND()*(2-1+1)) + 1, "M","F") INTO @gender;
        # random forename depending on gender
        IF @gender = "M" THEN
            SELECT forename INTO @forename FROM male_forenames ORDER BY RAND() LIMIT 1;
        ELSE
            SELECT forename INTO @forename FROM female_forenames ORDER BY RAND() LIMIT 1;
        END IF;
        # to select a random number in a range the formula is FLOOR( RAND() * ( upper_bound - lower_bound + 1 ) ) + lower_bound
        # random date of birth, ensuring employees are aged between sixteen and sixty five years old
        SELECT TIMESTAMP(NOW()) - INTERVAL ( FLOOR( RAND() * ( 65 - 16 + 1 ) ) + 16 ) * 365 DAY INTO @dob;
        # random date of hire between employees sixteenth birthday and today
        SELECT TIMESTAMP(@dob) + INTERVAL ( FLOOR( RAND() * ( DATEDIFF(NOW(), @dob) - ( 16 * 365 ) + 1 ) ) + ( 16 * 365 ) ) DAY INTO @doh;
        INSERT INTO employee(
            employee_number, forename, surname, gender, date_of_birth, date_hired, department_id , shift_name , role
        ) VALUES(
            CONCAT("K", LPAD(@employeeCount + 1, 7, "0")),
            @forename,
            @surname,
            @gender,
            @dob,
            @doh,
            0,
            "Day",
            "Unskilled"
        );
        SET @employeeCount = @employeeCount + 1;
    END WHILE;

    # make the longest overall served employee the director of the organisation entire
    SELECT employee_id INTO @directorID FROM employee ORDER BY date_hired ASC LIMIT 1;
    UPDATE employee SET role = "Director", department_id = 15 WHERE employee_id = @directorID;

    SET endOfRecordset = 0;

    OPEN departmentCursor;

    fetchDepartment: LOOP

        FETCH departmentCursor INTO departmentID;

        SELECT CONCAT("Populating department ", departmentID) AS message;

        IF endOfRecordset = 1 THEN
            LEAVE fetchDepartment;
        END IF;

        # assign a random number (between eleven and thirty) of employees to work in each department        
        SELECT FLOOR(RAND()*(30-11+1)+11) INTO @population;

        CALL populateDepartment(departmentID, @population);

    END LOOP fetchDepartment;

    CLOSE departmentCursor;

    # make all the remaining departmentless employees production (department_id=3) employees
    SELECT COUNT(1) INTO @population FROM employee WHERE department_id = 0;
    CALL populateDepartment(3, @population);

    # check it all worked as expected

    # there should be no employees assigned to department 0
    SELECT COUNT(1) AS departmentless FROM employee WHERE department_id = 0;

    # there should be between eleven and thirty employees assigned to each department, with the balance assigned to department 3
    SELECT COUNT(1) AS employees, department_id FROM employee GROUP BY department_id ORDER BY department_id ASC;

    # there should be some employees assigned to each role
    SELECT COUNT(1) AS employees, role FROM employee GROUP BY role;

END$$

DELIMITER ;

CALL createOrganisationStructure();
