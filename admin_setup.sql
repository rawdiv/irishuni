-- Insert default admin roles
INSERT INTO admin_roles (role_name, permissions) VALUES
('super_admin', '{
    "manage_roles": true,
    "manage_admins": true,
    "manage_applications": true,
    "view_analytics": true,
    "delete_applications": true
}'::jsonb),
('admin', '{
    "manage_roles": false,
    "manage_admins": false,
    "manage_applications": true,
    "view_analytics": true,
    "delete_applications": false
}'::jsonb),
('viewer', '{
    "manage_roles": false,
    "manage_admins": false,
    "manage_applications": false,
    "view_analytics": true,
    "delete_applications": false
}'::jsonb);

-- Function to create admin user
CREATE OR REPLACE FUNCTION create_admin_user(
    email TEXT,
    password TEXT,
    full_name TEXT,
    role_name TEXT
) RETURNS UUID AS $$
DECLARE
    user_id UUID;
    role_id UUID;
BEGIN
    -- Create user in auth.users
    user_id := (SELECT id FROM auth.users WHERE auth.users.email = create_admin_user.email);
    
    IF user_id IS NULL THEN
        user_id := (SELECT id FROM auth.users WHERE auth.users.email = create_admin_user.email);
        IF user_id IS NULL THEN
            RAISE EXCEPTION 'Failed to create user';
        END IF;
    END IF;

    -- Get role ID
    SELECT id INTO role_id FROM admin_roles WHERE admin_roles.role_name = create_admin_user.role_name;
    IF role_id IS NULL THEN
        RAISE EXCEPTION 'Invalid role name';
    END IF;

    -- Create admin profile
    INSERT INTO admin_profiles (id, email, full_name, role_id)
    VALUES (user_id, email, full_name, role_id);

    RETURN user_id;
END;
$$ LANGUAGE plpgsql;

-- Create initial super admin
SELECT create_admin_user(
    'super.admin@iris.edu',
    'admin123',
    'Super Admin',
    'super_admin'
);

-- Create regular admin
SELECT create_admin_user(
    'admin@iris.edu',
    'admin123',
    'Regular Admin',
    'admin'
);

-- Function to update last login
CREATE OR REPLACE FUNCTION update_last_login()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE admin_profiles
    SET last_login = NOW()
    WHERE id = NEW.id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for last login update
CREATE TRIGGER update_admin_last_login
    AFTER INSERT OR UPDATE ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION update_last_login();

-- Function to check admin permission
CREATE OR REPLACE FUNCTION check_admin_permission(permission TEXT)
RETURNS BOOLEAN AS $$
DECLARE
    user_permissions JSONB;
BEGIN
    SELECT ar.permissions INTO user_permissions
    FROM admin_profiles ap
    JOIN admin_roles ar ON ap.role_id = ar.id
    WHERE ap.id = auth.uid();

    RETURN COALESCE((user_permissions->permission)::boolean, false);
END;
$$ LANGUAGE plpgsql;