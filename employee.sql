# +----------+--------+--------------------------------------------------------------+
# | Date     | Author | Details                                                      |
# +----------+--------+--------------------------------------------------------------+
# | 04-03-06 | A.McC. | Original version. Create employee table.                     |
# +----------+--------+--------------------------------------------------------------+
#
# Synopsis
# --------
# the EMPLOYEE table holds the employee master data

# Use '/' as a delimiter when running as 'mysql> SOURCE server/path/<filename>.sql'.

# change DELIMITER because triggers use BEGIN END blocks

DELIMITER $$

# USE lots;$$

DROP TABLE IF EXISTS employee;$$

CREATE TABLE IF NOT EXISTS employee(
	employee_id 	INT NOT NULL AUTO_INCREMENT,
	employee_number	VARCHAR(255),
	forename	VARCHAR(255),
	surname		VARCHAR(255),
	gender		ENUM("F","M"),
	date_of_birth	DATETIME,
	date_hired	DATETIME,
	department_id	INT,
	shift_name	ENUM("Day","Evening","Night"),
        role            VARCHAR(255),
	created_by 	VARCHAR(255),
	created_on 	DATETIME,
	updated_by 	VARCHAR(255),
	updated_on 	DATETIME,
	PRIMARY KEY (employee_id),
	UNIQUE KEY (employee_number)
);$$

CREATE TRIGGER create_employee BEFORE INSERT ON employee 
FOR EACH ROW
BEGIN
	SET 	
		NEW.created_by 	= USER(),
		NEW.created_on	= NOW();
END;$$

DROP TRIGGER IF EXISTS update_employee;$$

CREATE TRIGGER update_employee BEFORE UPDATE ON employee 
FOR EACH ROW
BEGIN
	SET 	
		NEW.updated_by	= USER(),
		NEW.updated_on	= NOW();
END;$$

# don't forget to change the delimiter back to ';' otherwise the command line won't work

DELIMITER ;

# do some quick tests just to be sure it all works

#INSERT INTO employee (employee_number, forename, surname, gender, date_of_birth, date_hired) VALUES("0000000001", "Robert", "McCune", "M", "1968-12-03", "1998-04-21");

SELECT * FROM employee;

#UPDATE employee SET created_by = USER() WHERE employee_id = 1;

SELECT * FROM employee;

# oldest employee
SELECT * FROM employee ORDER BY date_of_birth ASC LIMIT 1;

# oldest employee ever hired
SELECT * FROM employee ORDER BY date_hired - date_of_birth DESC LIMIT 1;

# longest served employee
SELECT * FROM employee ORDER BY date_hired ASC LIMIT 1;

# longest served employee
