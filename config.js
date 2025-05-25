// Supabase configuration
const SUPABASE_URL = 'https://yoarpzplrajhzsfwesyg.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlvYXJwenBscmFqaHpzZndlc3lnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDgwNzc2NDEsImV4cCI6MjA2MzY1MzY0MX0.VaGJ6l5y2rFEkoe_1RelVr-wngaIOr4WZ5Qtnp34v4s';

// Initialize Supabase client
const supabase = supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

// Handle form submission
document.getElementById('applicationForm').addEventListener('submit', async (e) => {
    e.preventDefault();
    
    try {
        const formData = new FormData(e.target);
        const applicationData = {};
        
        // Convert FormData to JSON
        for (let [key, value] of formData.entries()) {
            if (key !== 'photo') {
                applicationData[key] = value;
            }
        }

        // Handle photo upload
        const photoFile = formData.get('photo');
        let photoUrl = null;

        if (photoFile.size > 0) {
            const { data, error: uploadError } = await supabase.storage
                .from('applicant-photos')
                .upload(`${Date.now()}-${photoFile.name}`, photoFile);

            if (uploadError) throw uploadError;
            photoUrl = data.path;
        }

        // Submit application data
        const { data, error } = await supabase
            .from('applications')
            .insert([
                {
                    ...applicationData,
                    photo_url: photoUrl,
                    status: 'pending',
                    created_at: new Date().toISOString()
                }
            ]);

        if (error) throw error;

        // Show success message
        alert('Application submitted successfully!');
        window.location.href = '/index.html';

    } catch (error) {
        console.error('Error submitting application:', error);
        alert('Failed to submit application. Please try again.');
    }
});