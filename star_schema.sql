
-- date dimention table to store date information
CREATE TABLE dim_date (
    date_key INT PRIMARY KEY,
    calendar_date DATE NOT NULL UNIQUE,
    year INT NOT NULL,
    quarter INT NOT NULL,
    month INT NOT NULL,
    month_name VARCHAR(20) NOT NULL,
    day VARCHAR(20) NOT NULL,
    week INT NOT NULL
);


-- patient dimension table to store patient information
CREATE TABLE dim_patient (
    patient_key INT PRIMARY KEY AUTO_INCREMENT,
    patient_id INT NOT NULL,
    mrn VARCHAR(20) NOT NULL,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    full_name VARCHAR(200),
    date_of_birth DATE NOT NULL,
    age INT,
    age_group VARCHAR(20),
    gender CHAR(10),
    is_active TINYINT NOT NULL DEFAULT 1,
    INDEX idx_patient_id (patient_id)
);

-- specialty dimension table to store specialty information
CREATE TABLE dim_specialty (
    specialty_key INT PRIMARY KEY AUTO_INCREMENT,
    specialty_id INT NOT NULL UNIQUE,
    specialty_name VARCHAR(100) NOT NULL,
    specialty_code VARCHAR(10) NOT NULL,
    INDEX idx_specialty_id (specialty_id),
    INDEX idx_specialty_name (specialty_name)
);


-- hospital department dimension table to store department information
CREATE TABLE dim_department (
    department_key INT PRIMARY KEY AUTO_INCREMENT,
    department_id INT NOT NULL UNIQUE,
    department_name VARCHAR(100) NOT NULL,
    department_code VARCHAR(20),
    floor INT,
    capacity INT,
    INDEX idx_department_id (department_id),
    INDEX idx_department_name (department_name)
);


-- provider dimension table to store hospital service provider information
CREATE TABLE dim_provider (
    provider_key INT PRIMARY KEY AUTO_INCREMENT,
    provider_id INT NOT NULL UNIQUE,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    full_name VARCHAR(200),
    credential VARCHAR(20),
    specialty_name VARCHAR(100),
    specialty_code VARCHAR(10),
    specialty_key INT,
    department_name VARCHAR(100),
    department_floor INT,
    department_key INT,
    is_active TINYINT NOT NULL DEFAULT 1,
    hire_date DATE,
    years_of_service INT,
    FOREIGN KEY (specialty_key) REFERENCES dim_specialty(specialty_key),
    FOREIGN KEY (department_key) REFERENCES dim_department(department_key),
    INDEX idx_provider_id (provider_id),
    INDEX idx_specialty_name (specialty_name),
    INDEX idx_department_name (department_name)
);


-- encounter type dimension table to store encounter type information
CREATE TABLE dim_encounter_type (
    encounter_type_key INT PRIMARY KEY AUTO_INCREMENT,
    encounter_type VARCHAR(50) NOT NULL UNIQUE,
    INDEX idx_encounter_type (encounter_type)
);

-- diagnosis dimension table to store encounter diagnosis information
CREATE TABLE dim_diagnosis (
    diagnosis_key INT PRIMARY KEY AUTO_INCREMENT,
    diagnosis_id INT NOT NULL UNIQUE,
    icd10_code VARCHAR(10) NOT NULL,
    icd10_description VARCHAR(200) NOT NULL,
    INDEX idx_diagnosis_id (diagnosis_id),
    INDEX idx_icd10_code (icd10_code)
);

-- procedure dimension table to store procedure information
CREATE TABLE dim_procedure (
    procedure_key INT PRIMARY KEY AUTO_INCREMENT,
    procedure_id INT NOT NULL UNIQUE,
    cpt_code VARCHAR(10) NOT NULL,
    cpt_description VARCHAR(200) NOT NULL,
    INDEX idx_procedure_id (procedure_id),
    INDEX idx_cpt_code (cpt_code)
);


-- fact_encounters table to store core health care encounter information
CREATE TABLE fact_encounters (
    fact_encounter_id INT PRIMARY KEY AUTO_INCREMENT,
    encounter_id INT NOT NULL UNIQUE,

    -- Foreign keys to dimensions
    encounter_date_key INT NOT NULL,
    discharge_date_key INT,
    patient_key INT NOT NULL,
    provider_key INT NOT NULL,
    specialty_key INT NOT NULL,
    department_key INT NOT NULL,
    encounter_type_key INT NOT NULL,
    
    -- attributes stored directly in fact
    encounter_datetime DATETIME NOT NULL,
    discharge_datetime DATETIME,
    
    -- Pre-aggregated metrics
    diagnosis_count INT NOT NULL DEFAULT 0,
    procedure_count INT NOT NULL DEFAULT 0,
    allowed_amount DECIMAL(12,2),
    payment_amount DECIMAL(12,2),    
    length_of_stay_hours DECIMAL(10,2),
    length_of_stay_days INT,
    
    -- Foreign key constraints
    FOREIGN KEY (encounter_date_key) REFERENCES dim_date(date_key),
    FOREIGN KEY (discharge_date_key) REFERENCES dim_date(date_key),
    FOREIGN KEY (patient_key) REFERENCES dim_patient(patient_key),
    FOREIGN KEY (provider_key) REFERENCES dim_provider(provider_key),
    FOREIGN KEY (specialty_key) REFERENCES dim_specialty(specialty_key),
    FOREIGN KEY (department_key) REFERENCES dim_department(department_key),
    FOREIGN KEY (encounter_type_key) REFERENCES dim_encounter_type(encounter_type_key),
    
    -- Indexes for common query patterns
    INDEX idx_encounter_id (encounter_id),
    INDEX idx_encounter_date_key (encounter_date_key),
    INDEX idx_discharge_date_key (discharge_date_key),
    INDEX idx_patient_key (patient_key),
    INDEX idx_provider_key (provider_key),
    INDEX idx_specialty_key (specialty_key),
    INDEX idx_department_key (department_key),
    INDEX idx_encounter_type_key (encounter_type_key),
    
    INDEX idx_date_specialty (encounter_date_key, specialty_key),
    INDEX idx_specialty_type (specialty_key, encounter_type_key),
    INDEX idx_patient_discharge_datetime (patient_key, discharge_datetime)
    
);


CREATE TABLE bridge_encounter_diagnoses (
    fact_encounter_id INT NOT NULL,
    diagnosis_key INT NOT NULL,
    diagnosis_sequence INT NOT NULL,
    
    PRIMARY KEY (fact_encounter_id, diagnosis_key, diagnosis_sequence),
    FOREIGN KEY (fact_encounter_id) REFERENCES fact_encounters(fact_encounter_id),
    FOREIGN KEY (diagnosis_key) REFERENCES dim_diagnosis(diagnosis_key)
);

CREATE TABLE bridge_encounter_procedures (
    fact_encounter_id INT NOT NULL,
    procedure_key INT NOT NULL,
    procedure_date DATE NOT NULL,
    procedure_sequence INT NOT NULL,
    
    PRIMARY KEY (fact_encounter_id, procedure_key, procedure_sequence),
    FOREIGN KEY (fact_encounter_id) REFERENCES fact_encounters(fact_encounter_id),
    FOREIGN KEY (procedure_key) REFERENCES dim_procedure(procedure_key)
);