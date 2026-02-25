CREATE DATABASE alma
  WITH ENCODING 'UTF8'
  LC_COLLATE='es_CO.UTF-8'
  LC_CTYPE='es_CO.UTF-8';

-- Conectarse a la base de datos alma antes de ejecutar el resto
-- \c alma

-- Crear el schema
CREATE SCHEMA alma;

-- Usar el schema por defecto para la sesión
SET search_path TO alma;

-- Extensiones recomendadas
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TABLE alma.users (
  id UUID PRIMARY KEY DEFAULT public.uuid_generate_v4(),

  -- Datos personales
  first_name VARCHAR(150) NOT NULL,
  last_name VARCHAR(150) NOT NULL,

  -- Identificación legal (Colombia)
  document_type VARCHAR(20) NOT NULL,   -- CC, TI, CE, PAS, NIT, etc.
  document_number VARCHAR(50) NOT NULL,
  CONSTRAINT unique_document UNIQUE (document_type, document_number),

  -- Contacto
  email VARCHAR(320) UNIQUE,
  phone VARCHAR(20),
  address TEXT,

  -- Perfil
  photo_url TEXT,
  gender VARCHAR(50),
  birthdate DATE,
  is_active BOOLEAN DEFAULT TRUE,

  -- Autenticación externa
  auth_provider VARCHAR(50),       -- 'google', 'microsoft', 'facebook', etc.
  external_id VARCHAR(150),        -- id que devuelve el proveedor externo
  CONSTRAINT unique_auth_provider UNIQUE (auth_provider, external_id),

  -- Consentimientos y políticas
  accepted_data_policy BOOLEAN DEFAULT FALSE,
  accepted_image_policy BOOLEAN DEFAULT FALSE,
  accepted_policy_date TIMESTAMP WITH TIME ZONE,

  -- Auditoría y control
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  deleted_at TIMESTAMP WITH TIME ZONE,

  created_by UUID NULL REFERENCES users(id),
  updated_by UUID NULL REFERENCES users(id)
);

CREATE TABLE roles (
  id BIGSERIAL PRIMARY KEY,
  code VARCHAR(50) NOT NULL UNIQUE,      -- ejemplo: 'admin', 'student', 'teacher', 'pastoral'
  display_name VARCHAR(100) NOT NULL,    -- nombre visible
  description TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Ejemplo de seed inicial
INSERT INTO roles (code, display_name, description) VALUES
('admin', 'Administrador', 'Control total del sistema'),
('director', 'Director', 'Supervisa programas y usuarios'),
('teacher', 'Maestro/Titular', 'Imparte clases o talleres'),
('monitor', 'Monitor', 'Apoya al maestro o grupo'),
('student', 'Alumno', 'Participante académico o formativo'),
('pastoral', 'Servidor Pastoral', 'Acompaña procesos de pastoral'),
('guardian', 'Acudiente/Tutor', 'Padre o responsable de un menor'),
('member', 'Miembro', 'Usuario general sin rol específico');

CREATE TABLE user_roles (
  id UUID PRIMARY KEY DEFAULT public.uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  role_id BIGINT NOT NULL REFERENCES roles(id) ON DELETE CASCADE,

  assigned_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  assigned_by UUID NULL REFERENCES users(id),

  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  deleted_at TIMESTAMP WITH TIME ZONE,

  is_active BOOLEAN DEFAULT TRUE,

  UNIQUE(user_id, role_id)
);

CREATE TABLE branches (
  id UUID PRIMARY KEY DEFAULT public.uuid_generate_v4(),

  -- Basic info
  name VARCHAR(150) NOT NULL,
  description TEXT,

  -- Location
  address TEXT,
  city VARCHAR(100),
  state VARCHAR(100),
  country VARCHAR(100) DEFAULT 'Colombia',
  phone VARCHAR(50),
  email VARCHAR(150),

  -- Management
  manager_id UUID NULL REFERENCES users(id),    -- branch director or manager
  total_capacity INTEGER,
  notes TEXT,

  -- Control
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  deleted_at TIMESTAMPTZ,

  created_by UUID NULL REFERENCES users(id),
  updated_by UUID NULL REFERENCES users(id)
);

CREATE TABLE spaces (
    id UUID PRIMARY KEY DEFAULT public.uuid_generate_v4(),
    branch_id UUID NOT NULL REFERENCES branches(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    type TEXT NOT NULL CHECK (type IN ('Salon', 'Auditorio', 'Sala multiple', 'Cubiculo')),
    capacity INTEGER,
    description TEXT,
    location TEXT, -- optional: "2nd floor, left wing"
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE space_reservations (
    id UUID PRIMARY KEY DEFAULT public.uuid_generate_v4(),
    space_id UUID NOT NULL REFERENCES spaces(id) ON DELETE CASCADE,
    reserved_by UUID NOT NULL REFERENCES users(id), -- who created the reservation

    purpose TEXT NOT NULL, -- e.g. "Grupo de jóvenes", "Reunión", "Clase"
     -- optional, e.g. "Event", "Prayer Group", "Academic"
    start_time TIMESTAMP NOT NULL,
    end_time TIMESTAMP NOT NULL,
    is_recurring BOOLEAN DEFAULT FALSE,
    recurrence_rule TEXT, -- e.g., "WEEKLY", "MONTHLY" (optional)
    status TEXT DEFAULT 'Pending' CHECK (status IN ('Pending', 'Approved', 'Rejected', 'Cancelled')),
    observations TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_by UUID NULL REFERENCES users(id)
);

CREATE TABLE prayer_group_types (
    id UUID PRIMARY KEY DEFAULT public.uuid_generate_v4(),
    name TEXT NOT NULL UNIQUE, -- e.g., "Juvenil", "Oracion", "Infantil"
    description TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO prayer_group_types (name, description) VALUES
('Oracion', 'Grupo general de oración'),
('Juvenil', 'Grupo dirigido a jóvenes'),
('Infantil', 'Grupo para niños'),
('Ayuno', 'Sesión de oración y ayuno'),
('Vigilia', 'Encuentro nocturno de oración'),
('Concierto', 'Evento musical de alabanza'),
('Ados', 'Grupo de adolescentes y jóvenes');



CREATE TABLE prayer_groups (
    id UUID PRIMARY KEY DEFAULT public.uuid_generate_v4(),
    name TEXT NOT NULL UNIQUE, -- e.g. "Noches de Bendiciones"
    description TEXT,
    type_id UUID REFERENCES prayer_group_types(id) ON DELETE SET NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);



CREATE TABLE prayer_attendance_records (
    id UUID PRIMARY KEY DEFAULT public.uuid_generate_v4(),
    prayer_group_id UUID NOT NULL REFERENCES prayer_groups(id) ON DELETE CASCADE,
    branch_id UUID REFERENCES branches(id), -- sede donde se realizó
    space_id UUID REFERENCES spaces(id), -- espacio asignado
    date DATE NOT NULL,
    male_count INTEGER DEFAULT 0 CHECK (male_count >= 0),
    female_count INTEGER DEFAULT 0 CHECK (female_count >= 0),
    total_count INTEGER GENERATED ALWAYS AS (male_count + female_count) STORED,
    recorded_by UUID REFERENCES users(id), -- quién registró la asistencia
    observations TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


CREATE TABLE academic_programs (
  id UUID PRIMARY KEY DEFAULT public.uuid_generate_v4(),

  name VARCHAR(150) NOT NULL,
  code VARCHAR(50) UNIQUE,
  description TEXT,

  coordinator_id UUID REFERENCES users(id),

  is_active BOOLEAN DEFAULT TRUE,

  created_at TIMESTAMPTZ DEFAULT now(),
  update_at TIMESTAMPTZ DEFAULT now(),
  deleted_at TIMESTAMPTZ
);

CREATE TABLE subjects (
  id BIGSERIAL PRIMARY KEY,

  program_id UUID NOT NULL REFERENCES academic_programs(id) ON DELETE CASCADE,

  name VARCHAR(150) NOT NULL,
  description TEXT,

  duration_classes INTEGER,
  is_active BOOLEAN DEFAULT TRUE,

  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMP DEFAULT now(),
  updated_by UUID NULL REFERENCES users(id),
  deleted_at TIMESTAMPTZ
);

CREATE TABLE academic_groups (
  id BIGSERIAL PRIMARY KEY,

  subject_id BIGINT NOT NULL REFERENCES subjects(id) ON DELETE CASCADE,
  branch_id UUID NOT NULL REFERENCES branches(id) ON DELETE CASCADE,

  name VARCHAR(150) NOT NULL,
  term VARCHAR(50),
  status VARCHAR(30) DEFAULT 'active' CHECK (status IN ('active', 'finished', 'cancelled')),
  capacity INTEGER,

  professor_id UUID NOT NULL REFERENCES users(id),
  monitor_id UUID REFERENCES users(id),
  assistant_id UUID REFERENCES users(id),

  general_schedule TEXT,
  general_link TEXT,

  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  updated_by UUID NULL REFERENCES users(id)
);

CREATE TABLE classes (
  id BIGSERIAL PRIMARY KEY,

  group_id BIGINT NOT NULL REFERENCES academic_groups(id) ON DELETE CASCADE,
  space_id UUID REFERENCES spaces(id),

  status VARCHAR(30) DEFAULT 'scheduled' CHECK (status IN ('scheduled', 'completed', 'cancelled')),
  title VARCHAR(200),
  recording_link TEXT,

  start_class TIMESTAMPTZ,
  end_class TIMESTAMPTZ,
  modality VARCHAR(20) CHECK (modality IN ('in_person', 'virtual', 'hybrid')) DEFAULT 'in_person',

  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  updated_by UUID NULL REFERENCES users(id)
);

CREATE TABLE enrollments (
  id BIGSERIAL PRIMARY KEY,

  group_id BIGINT NOT NULL REFERENCES academic_groups(id) ON DELETE CASCADE,
  student_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

  enrollment_date DATE DEFAULT CURRENT_DATE,
  status VARCHAR(30) DEFAULT 'active' CHECK (status IN ('active', 'withdrawn', 'completed')),
  approved BOOLEAN,

  UNIQUE (group_id, student_id)
);

CREATE TABLE attendance_records (
  id BIGSERIAL PRIMARY KEY,

  class_id BIGINT NOT NULL REFERENCES classes(id) ON DELETE CASCADE,
  student_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

  status VARCHAR(20) NOT NULL CHECK (status IN ('present', 'absent', 'late', 'excused')),
  attendance_type VARCHAR(20) CHECK (attendance_type IN ('in_person', 'virtual', 'makeup')),

  recorded_by UUID REFERENCES users(id),
  notes TEXT,

  created_at TIMESTAMPTZ DEFAULT now(),

  UNIQUE (class_id, student_id)
);

CREATE TABLE education_levels (
  id BIGSERIAL PRIMARY KEY,
  name VARCHAR(100) NOT NULL UNIQUE,
  description TEXT
);

CREATE TABLE user_education_history (
  id UUID PRIMARY KEY DEFAULT public.uuid_generate_v4(),

  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  education_level_id BIGINT REFERENCES education_levels(id),

  institution_name VARCHAR(200) NOT NULL,
  degree_name VARCHAR(150),
  field_of_study VARCHAR(150),
  graduation_year INTEGER CHECK (graduation_year >= 1900 AND graduation_year <= EXTRACT(YEAR FROM now()) + 1),

  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE user_work_history (
  id UUID PRIMARY KEY DEFAULT public.uuid_generate_v4(),

  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

  company_name VARCHAR(200) NOT NULL,
  position_title VARCHAR(150),
  start_date DATE,
  end_date DATE,
  is_current BOOLEAN DEFAULT FALSE,

  description TEXT,

  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),

  CONSTRAINT one_current_work_per_user
    EXCLUDE USING gist (user_id WITH =)
    WHERE (is_current)
);

CREATE TABLE service_areas (
  id UUID PRIMARY KEY DEFAULT public.uuid_generate_v4(),

  name VARCHAR(150) NOT NULL,
  description TEXT,

  director_id UUID REFERENCES users(id) ON DELETE SET NULL,

  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE user_service_assignments (
  id UUID PRIMARY KEY DEFAULT public.uuid_generate_v4(),

  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  service_area_id UUID NOT NULL REFERENCES service_areas(id) ON DELETE CASCADE,

  status VARCHAR(20) NOT NULL DEFAULT 'active'
    CHECK (status IN ('active', 'interested', 'retired')),

  functions TEXT,
  observations TEXT,
  dedication_hours_per_month INTEGER,
  start_date DATE,
  end_date DATE,

  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),

  UNIQUE (user_id, service_area_id)
);

CREATE TABLE user_socioeconomic_info (
  id UUID PRIMARY KEY DEFAULT public.uuid_generate_v4(),
  user_id UUID NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,

  -- 🏠 Datos familiares y económicos
  income_level VARCHAR(50), -- e.g. Low, Medium, High
  housing_type VARCHAR(100), -- e.g. Own, Rent, Family, Other
  household_size INTEGER CHECK (household_size >= 1),
  socioeconomic_stratum INTEGER CHECK (socioeconomic_stratum BETWEEN 1 AND 6),
  current_economic_situation TEXT,

  -- ❤️ Estado personal
  marital_status VARCHAR(30), -- e.g. Single, Married, Divorced, Widowed
  transportation_means VARCHAR(100), -- e.g. Public, Private, Bicycle, Walking
  health_insurance VARCHAR(150), -- EPS
  prepaid_medicine VARCHAR(150),
  disability TEXT,
  blood_type VARCHAR(5) CHECK (blood_type ~ '^(A|B|AB|O)[+-]$'),
  diseases TEXT,
  special_group VARCHAR(100), -- e.g. Displaced, Immigrant, None

  -- 💼 Emprendimiento
  has_enterprise BOOLEAN DEFAULT FALSE,
  enterprise_name VARCHAR(200),
  enterprise_contact VARCHAR(150),
  enterprise_description TEXT,

  -- ⚠️ Antecedentes personales
  major_accidents TEXT,

  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  created_by UUID REFERENCES users(id),
  updated_by UUID REFERENCES users(id)
);

CREATE TABLE user_personal_area_info (
  id UUID PRIMARY KEY DEFAULT public.uuid_generate_v4(),
  user_id UUID NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,

  -- 💭 Desarrollo personal y espiritual
  interests TEXT,
  group_participation TEXT,
  dreams_and_aspirations TEXT,
  personal_life_project TEXT,
  family_life_project TEXT,
  strengths TEXT,
  improvement_opportunities TEXT,

  -- 🕒 Auditoría
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  created_by UUID REFERENCES users(id),
  updated_by UUID REFERENCES users(id)
);

CREATE TABLE user_family_members (
  id UUID PRIMARY KEY DEFAULT public.uuid_generate_v4(),

  -- Relación principal con el usuario del ERP
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

  -- Información del familiar (no necesariamente registrado)
  full_name VARCHAR(200) NOT NULL,
  relationship VARCHAR(100),          -- e.g. Mother, Father, Spouse, Friend
  phone_number VARCHAR(50),
  email VARCHAR(150),
  address TEXT,
  occupation VARCHAR(150),

  -- Si este familiar también existe como usuario, lo relacionamos opcionalmente
  related_user_id UUID REFERENCES users(id) ON DELETE SET NULL,

  lives_with_user BOOLEAN,
  is_emergency_contact BOOLEAN DEFAULT FALSE,

  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE pastoral_session_types (
  id SERIAL PRIMARY KEY,
  name VARCHAR(50) UNIQUE NOT NULL,
  description TEXT,
  is_active BOOLEAN DEFAULT TRUE,

  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

INSERT INTO pastoral_session_types (name, description) VALUES
('diagnosis', 'Initial evaluation or spiritual diagnosis'),
('follow_up', 'Regular accompaniment or follow-up session'),
('evaluation', 'Intermediate or final evaluation'),
('closure', 'Final session to close the process'),
('other', 'Other type of session');


CREATE TABLE pastoral_processes (
  id UUID PRIMARY KEY DEFAULT  public.uuid_generate_v4(),

  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,      -- Accompanied person
  companion_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE, -- Companion / pastoral guide

  start_date DATE NOT NULL,
  end_date DATE,
  status VARCHAR(20) NOT NULL DEFAULT 'active'
    CHECK (status IN ('active', 'closed', 'paused')),

  observations TEXT,

  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  created_by UUID REFERENCES users(id),
  updated_by UUID REFERENCES users(id)
);


CREATE TABLE pastoral_sessions (
  id UUID PRIMARY KEY DEFAULT public.uuid_generate_v4(),

  process_id UUID NOT NULL REFERENCES pastoral_processes(id) ON DELETE CASCADE,
  session_type_id INT NOT NULL REFERENCES pastoral_session_types(id) ON DELETE RESTRICT,

  session_datetime TIMESTAMPTZ NOT NULL,
  duration_minutes INTEGER,

  status VARCHAR(20) NOT NULL DEFAULT 'completed'
    CHECK (status IN ('scheduled', 'completed', 'cancelled')),

  notes TEXT,
  commitments TEXT,

  attended_by UUID REFERENCES users(id),  -- Companion who attended
  next_session_date TIMESTAMPTZ,

  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE event_types (
  id SERIAL PRIMARY KEY,
  name VARCHAR(100) UNIQUE NOT NULL,
  description TEXT,
  is_active BOOLEAN DEFAULT TRUE,

  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

INSERT INTO event_types (name, description) VALUES
('retreat', 'Spiritual retreat'),
('conference', 'Congreso o conferencia'),
('meeting', 'General meeting or encounter'),
('workshop', 'Workshop or formation session'),
('celebration', 'Community celebration');

CREATE TABLE services (
  id BIGINT PRIMARY KEY,
  name VARCHAR(100) UNIQUE NOT NULL,
  description TEXT,
  is_active BOOLEAN DEFAULT TRUE,
  director_id UUID NOT NULL REFERENCES users(id),

  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE events (
  id BIGSERIAL PRIMARY KEY,

  branch_id UUID NOT NULL REFERENCES branches(id) ON DELETE RESTRICT,   -- Branch / sede
  event_type_id INT NOT NULL REFERENCES event_types(id) ON DELETE RESTRICT,
  area_id BIGINT REFERENCES services(id),   -- Responsible area (optional)
  coordinator_id UUID REFERENCES users(id), -- Event coordinator (optional)

  name VARCHAR(150) NOT NULL,
  description TEXT,
  start_datetime TIMESTAMPTZ NOT NULL,
  end_datetime TIMESTAMPTZ NOT NULL,

  capacity INT,                               -- NULL = unlimited
  location VARCHAR(255),
  space_id BIGINT REFERENCES spaces(id),      -- Physical space reserved

  cost NUMERIC(10,2) DEFAULT 0,               -- Donation or entry fee
  status VARCHAR(20) NOT NULL DEFAULT 'scheduled'
    CHECK (status IN ('scheduled', 'ongoing', 'completed', 'cancelled')),

  image_url TEXT,                             -- ✅ Image or poster of the event

  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  created_by UUID REFERENCES users(id),
  updated_by UUID REFERENCES users(id)
);

CREATE TABLE event_participants (
  id UUID PRIMARY KEY DEFAULT public.uuid_generate_v4(),

  event_id BIGINT NOT NULL REFERENCES events(id) ON DELETE CASCADE,
  user_id UUID REFERENCES users(id),   -- NULL si es externo

  full_name VARCHAR(150) NOT NULL,     -- obligatorio para externos
  document_type VARCHAR(20),
  document_number VARCHAR(50),
  email VARCHAR(100),
  phone VARCHAR(50),

  participant_type VARCHAR(10) NOT NULL
    CHECK (participant_type IN ('internal', 'external')),

  registered_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE event_attendance (
  id UUID PRIMARY KEY DEFAULT public.uuid_generate_v4(),

  participant_id UUID NOT NULL REFERENCES event_participants(id) ON DELETE CASCADE,
  event_id BIGINT NOT NULL REFERENCES events(id) ON DELETE CASCADE,

  attendance_date DATE NOT NULL,
  attended BOOLEAN DEFAULT FALSE,

  UNIQUE (participant_id, attendance_date)
);

CREATE TABLE event_payments (
  id BIGSERIAL PRIMARY KEY,

  event_id BIGINT NOT NULL REFERENCES events(id) ON DELETE CASCADE,
  participant_id BIGINT REFERENCES event_participants(id) ON DELETE SET NULL,

  payment_date TIMESTAMPTZ DEFAULT now(),
  amount NUMERIC(10,2) NOT NULL,
  method VARCHAR(30),          -- cash, transfer, credit, donation
  reference_code VARCHAR(100),
  confirmed BOOLEAN DEFAULT FALSE,

  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE guardian_children (
    id UUID PRIMARY KEY DEFAULT public.uuid_generate_v4(),
    guardian_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    child_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    relationship TEXT, -- e.g., 'Father', 'Mother', 'Uncle', 'Guardian'
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (child_id) -- A child can have only one authorized guardian
);

CREATE TABLE guardian_events (
    id UUID PRIMARY KEY DEFAULT public.uuid_generate_v4(),
    name TEXT NOT NULL,
    branch_id UUID REFERENCES branches(id),
    event_date DATE NOT NULL,
    created_by UUID REFERENCES users(id), -- user who created the event
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE guardian_event_codes (
    id UUID PRIMARY KEY DEFAULT public.uuid_generate_v4(),
    event_id UUID NOT NULL REFERENCES guardian_events(id) ON DELETE CASCADE,
    child_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    secret_code VARCHAR(10) NOT NULL, -- auto-generated (e.g., random alphanumeric)
    is_active BOOLEAN DEFAULT TRUE,
    generated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (event_id, child_id)
);

CREATE TABLE guardian_checkins (
    id UUID PRIMARY KEY DEFAULT public.uuid_generate_v4(),
    event_id UUID NOT NULL REFERENCES guardian_events(id) ON DELETE CASCADE,
    child_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    guardian_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    checkin_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    checked_in_by UUID REFERENCES users(id), -- staff/líder que registró entrada
    checkout_time TIMESTAMP, -- optional, when child leaves
    checked_out_by UUID REFERENCES users(id), -- who delivered the child
    secret_code_used VARCHAR(10) NOT NULL,
    observations TEXT,
    CONSTRAINT fk_event_child FOREIGN KEY (event_id, child_id)
        REFERENCES guardian_event_codes(event_id, child_id)
);


