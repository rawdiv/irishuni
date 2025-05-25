-- Create applications table
CREATE TABLE applications (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    full_name TEXT NOT NULL,
    dob DATE NOT NULL,
    gender TEXT NOT NULL,
    nationality TEXT NOT NULL,
    category TEXT NOT NULL,
    photo_url TEXT,
    email TEXT NOT NULL,
    mobile TEXT NOT NULL,
    alternate_mobile TEXT,
    qualification TEXT NOT NULL,
    institution TEXT NOT NULL,
    board TEXT NOT NULL,
    passing_year INTEGER NOT NULL,
    percentage DECIMAL(5,2) NOT NULL,
    program_type TEXT NOT NULL,
    course TEXT NOT NULL,
    specialization TEXT,
    batch INTEGER NOT NULL,
    study_mode TEXT NOT NULL,
    scholarship BOOLEAN DEFAULT false,
    referral_source TEXT NOT NULL,
    referral_code TEXT,
    portfolio_link TEXT,
    declaration BOOLEAN NOT NULL,
    terms_accepted BOOLEAN NOT NULL,
    signature TEXT NOT NULL,
    status TEXT DEFAULT 'pending',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create storage bucket for applicant photos
INSERT INTO storage.buckets (id, name, public) 
VALUES ('applicant-photos', 'applicant-photos', true);

-- Enable Row Level Security (RLS)
ALTER TABLE applications ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Applications are viewable by admin users only" 
ON applications FOR SELECT 
TO authenticated
USING (auth.role() = 'admin');

CREATE POLICY "Applications are insertable by anyone" 
ON applications FOR INSERT 
TO anon
WITH CHECK (true);

CREATE POLICY "Applications are updatable by admin users only" 
ON applications FOR UPDATE 
TO authenticated
USING (auth.role() = 'admin');

CREATE POLICY "Applications are deletable by admin users only" 
ON applications FOR DELETE 
TO authenticated
USING (auth.role() = 'admin');

-- Create function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create trigger for updating updated_at
CREATE TRIGGER update_applications_updated_at
    BEFORE UPDATE ON applications
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();