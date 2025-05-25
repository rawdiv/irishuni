-- Create admin role if it doesn't exist
CREATE ROLE admin;

-- Create admin user profile table
CREATE TABLE admin_profiles (
    id UUID REFERENCES auth.users PRIMARY KEY,
    email TEXT UNIQUE NOT NULL,
    full_name TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Enable RLS
ALTER TABLE admin_profiles ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Admin profiles are viewable by admin users only" 
ON admin_profiles FOR SELECT 
TO authenticated
USING (auth.role() = 'admin');

CREATE POLICY "Admin profiles are editable by admin users only" 
ON admin_profiles FOR ALL 
TO authenticated
USING (auth.role() = 'admin');

-- Create your first admin user (replace with your email)
INSERT INTO auth.users (email, encrypted_password, email_confirmed_at, role)
VALUES ('admin@iris.edu', crypt('admin123', gen_salt('bf')), now(), 'admin');

-- Add user to admin_profiles
INSERT INTO admin_profiles (id, email, full_name)
SELECT id, email, 'Admin User'
FROM auth.users
WHERE email = 'admin@iris.edu';