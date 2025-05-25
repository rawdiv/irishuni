# Iris Institute of Technology - Application System

## Overview
This is the application management system for Iris Institute of Technology, featuring a student application form, admin dashboard, and Supabase backend integration.

## Features
- Student Application Form
- Admin Dashboard
- Supabase Database Integration
- File Upload Support
- Real-time Updates

## Prerequisites
- Node.js (v14 or higher)
- npm (v6 or higher)
- Supabase Account

## Setup Instructions

1. **Install Dependencies**
   ```bash
   npm install
   ```

2. **Configure Environment Variables**
   Create a `.env` file in the root directory with the following variables:
   ```env
   SUPABASE_URL=your_supabase_url
   SUPABASE_ANON_KEY=your_supabase_anon_key
   SUPABASE_SERVICE_ROLE_KEY=your_supabase_service_role_key
   PORT=3000
   ```

3. **Initialize Database**
   - Create a new Supabase project
   - Run the SQL commands from `schema.sql` in the Supabase SQL editor
   - Create a storage bucket named 'applicant-photos'

4. **Start the Server**
   ```bash
   # Development mode
   npm run dev

   # Production mode
   npm start
   ```

## API Endpoints

### Applications

#### Submit Application
- **POST** `/api/applications`
- Multipart form data for application details and photo

#### Get All Applications (Admin)
- **GET** `/api/applications`
- Requires admin authentication

#### Update Application Status (Admin)
- **PATCH** `/api/applications/:id`
- Requires admin authentication
- Body: `{ "status": "approved" | "rejected" | "pending" }`

#### Delete Application (Admin)
- **DELETE** `/api/applications/:id`
- Requires admin authentication

## File Structure
```
├── .env                 # Environment variables
├── package.json         # Project dependencies
├── server.js           # Express server setup
├── schema.sql          # Database schema
├── README.md           # Project documentation
├── admin.html          # Admin dashboard
├── application.html    # Application form
└── config.js           # Supabase configuration
```

## Security
- Row Level Security (RLS) enabled
- Admin-only access to sensitive operations
- File upload size limits
- CORS protection

## Contributing
Please follow the existing code style and add unit tests for any new features.

## License
MIT