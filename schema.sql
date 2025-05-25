-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create admin_roles table
CREATE TABLE admin_roles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    role_name VARCHAR(50) NOT NULL UNIQUE,
    permissions JSONB NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create admin_profiles table
CREATE TABLE admin_profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    full_name VARCHAR(100) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    role_id UUID REFERENCES admin_roles(id),
    active BOOLEAN DEFAULT true,
    last_login TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create applications table
CREATE TABLE applications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    full_name VARCHAR(100) NOT NULL,
    email VARCHAR(255) NOT NULL,
    phone VARCHAR(20) NOT NULL,
    program_type VARCHAR(50) NOT NULL,
    course VARCHAR(100) NOT NULL,
    photo_url TEXT,
    status VARCHAR(20) DEFAULT 'pending',
    reviewed_by UUID REFERENCES admin_profiles(id),
    review_date TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create application_history table for tracking changes
CREATE TABLE application_history (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    application_id UUID REFERENCES applications(id) ON DELETE CASCADE,
    changed_by UUID REFERENCES admin_profiles(id),
    old_status VARCHAR(20),
    new_status VARCHAR(20),
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create storage bucket for applicant photos
INSERT INTO storage.buckets (id, name, public) VALUES ('applicant-photos', 'applicant-photos', false);

-- Create function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create function to update last login timestamp
CREATE OR REPLACE FUNCTION update_last_login(user_id UUID)
RETURNS VOID AS $$
BEGIN
    UPDATE admin_profiles
    SET last_login = NOW()
    WHERE id = user_id;
END;
$$ LANGUAGE plpgsql;

-- Create function to check admin permissions
CREATE OR REPLACE FUNCTION check_admin_permission(admin_id UUID, required_permission TEXT)
RETURNS BOOLEAN AS $$
DECLARE
    admin_permissions JSONB;
BEGIN
    SELECT ar.permissions INTO admin_permissions
    FROM admin_profiles ap
    JOIN admin_roles ar ON ap.role_id = ar.id
    WHERE ap.id = admin_id;

    RETURN (admin_permissions->required_permission)::boolean;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to track application status changes
CREATE OR REPLACE FUNCTION track_application_status_change()
RETURNS TRIGGER AS $$
BEGIN
    IF (TG_OP = 'UPDATE' AND OLD.status IS DISTINCT FROM NEW.status) THEN
        INSERT INTO application_history
            (application_id, changed_by, old_status, new_status)
        VALUES
            (NEW.id, NEW.reviewed_by, OLD.status, NEW.status);
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create triggers
CREATE TRIGGER update_admin_roles_updated_at
    BEFORE UPDATE ON admin_roles
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_admin_profiles_updated_at
    BEFORE UPDATE ON admin_profiles
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_applications_updated_at
    BEFORE UPDATE ON applications
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER track_application_status_changes
    AFTER UPDATE ON applications
    FOR EACH ROW
    EXECUTE FUNCTION track_application_status_change();

-- Enable Row Level Security
ALTER TABLE admin_roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE admin_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE applications ENABLE ROW LEVEL SECURITY;
ALTER TABLE application_history ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Super admins can manage roles"
    ON admin_roles
    USING (check_admin_permission(auth.uid(), 'manage_roles'));

CREATE POLICY "Super admins can manage admin profiles"
    ON admin_profiles
    USING (check_admin_permission(auth.uid(), 'manage_admins'));

CREATE POLICY "Admins can view all applications"
    ON applications
    FOR SELECT
    USING (EXISTS (
        SELECT 1 FROM admin_profiles WHERE id = auth.uid() AND active = true
    ));

CREATE POLICY "Super admins and admins can update applications"
    ON applications
    FOR UPDATE
    USING (check_admin_permission(auth.uid(), 'manage_applications'));

CREATE POLICY "Admins can view application history"
    ON application_history
    FOR SELECT
    USING (EXISTS (
        SELECT 1 FROM admin_profiles WHERE id = auth.uid() AND active = true
    ));