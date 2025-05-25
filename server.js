require('dotenv').config();
const express = require('express');
const cors = require('cors');
const multer = require('multer');
const { createClient } = require('@supabase/supabase-js');
const path = require('path');

const app = express();
const port = process.env.PORT || 3000;

// Initialize Supabase client
const supabaseUrl = process.env.SUPABASE_URL;
const supabaseKey = process.env.SUPABASE_ANON_KEY;
const supabase = createClient(supabaseUrl, supabaseKey);

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.static(path.join(__dirname)));

// Configure multer for file uploads
const upload = multer({
    storage: multer.memoryStorage(),
    limits: {
        fileSize: 5 * 1024 * 1024 // 5MB limit
    }
});

// Routes
app.get('/api/health', (req, res) => {
    res.json({ status: 'ok' });
});

// Submit application
app.post('/api/applications', upload.single('photo'), async (req, res) => {
    try {
        const applicationData = req.body;
        let photoUrl = null;

        // Handle photo upload if provided
        if (req.file) {
            const { data, error: uploadError } = await supabase.storage
                .from('applicant-photos')
                .upload(
                    `${Date.now()}-${req.file.originalname}`,
                    req.file.buffer,
                    { contentType: req.file.mimetype }
                );

            if (uploadError) throw uploadError;
            photoUrl = data.path;
        }

        // Save application data
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

        res.status(201).json({
            message: 'Application submitted successfully',
            data
        });

    } catch (error) {
        console.error('Error submitting application:', error);
        res.status(500).json({
            error: 'Failed to submit application',
            details: error.message
        });
    }
});

// Get all applications (admin only)
app.get('/api/applications', async (req, res) => {
    try {
        const { data, error } = await supabase
            .from('applications')
            .select('*')
            .order('created_at', { ascending: false });

        if (error) throw error;

        res.json(data);
    } catch (error) {
        console.error('Error fetching applications:', error);
        res.status(500).json({
            error: 'Failed to fetch applications',
            details: error.message
        });
    }
});

// Update application status (admin only)
app.patch('/api/applications/:id', async (req, res) => {
    try {
        const { id } = req.params;
        const { status } = req.body;

        const { data, error } = await supabase
            .from('applications')
            .update({ status })
            .eq('id', id);

        if (error) throw error;

        res.json({
            message: 'Application status updated successfully',
            data
        });
    } catch (error) {
        console.error('Error updating application:', error);
        res.status(500).json({
            error: 'Failed to update application',
            details: error.message
        });
    }
});

// Delete application (admin only)
app.delete('/api/applications/:id', async (req, res) => {
    try {
        const { id } = req.params;

        const { error } = await supabase
            .from('applications')
            .delete()
            .eq('id', id);

        if (error) throw error;

        res.json({
            message: 'Application deleted successfully'
        });
    } catch (error) {
        console.error('Error deleting application:', error);
        res.status(500).json({
            error: 'Failed to delete application',
            details: error.message
        });
    }
});

// Start server
app.listen(port, () => {
    console.log(`Server running at http://localhost:${port}`);
});