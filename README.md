# Iris Digital College Application System

A web application for managing student applications and admin dashboard for Iris Digital College.

## Features

- Student application form with file upload
- Secure admin dashboard
- Role-based access control
- Docker containerization

## Prerequisites

- Node.js 18 or higher
- Docker and Docker Compose
- Supabase account

## Environment Variables

Create a `.env` file in the root directory with:

```env
SUPABASE_URL=your_supabase_url
SUPABASE_ANON_KEY=your_supabase_anon_key
```

## Local Development

```bash
# Install dependencies
npm install

# Start development server
npm run dev
```

## Docker Deployment

```bash
# Build and run with Docker Compose
docker-compose up -d
```

## Render Deployment

1. Create a new Web Service in Render
2. Connect your GitHub repository
3. Set environment variables in Render dashboard
4. Use the following build command:
   ```bash
   docker build -t iris-college .
   ```
5. Use the following start command:
   ```bash
   docker run -p 3000:3000 iris-college
   ```

## Security

- Admin panel is protected with authentication
- Static admin files are not publicly accessible
- All API routes are secured with proper authorization

## License

ISC