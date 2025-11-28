# Backend API Setup Guide

This backend API handles MongoDB operations for the MLWIO coin and premium system.

## Prerequisites

- Node.js (v16 or higher)
- MongoDB Atlas account (already configured)
- npm or yarn

## Installation

1. Navigate to the backend directory:
```bash
cd backend
```

2. Install dependencies:
```bash
npm install
```

3. Create environment file:
```bash
cp .env.example .env
```

## Configuration

The `.env` file should contain your MongoDB credentials:
```
PORT=3000
MONGODB_URI=mongodb+srv://<your_username>:<your_password>@<your_cluster>.mongodb.net/?appName=MLWIO-User-Coin
NODE_ENV=production
```

**IMPORTANT**: Replace `<your_username>`, `<your_password>`, and `<your_cluster>` with your actual MongoDB Atlas credentials. Never commit real credentials to version control.

## Running the Server

### Development Mode (with auto-reload):
```bash
npm run dev
```

### Production Mode:
```bash
npm start
```

The server will run on `http://localhost:3000`

## API Endpoints

### Users

#### Get User by Gmail
```
GET /api/users/:gmail
```

#### Create User
```
POST /api/users
Body: {
  "gmail": "user@example.com"
}
```

### Coins Management

#### Update Coins (Set)
```
PATCH /api/users/:gmail/coins
Body: {
  "coins": 100
}
```

#### Add Coins
```
POST /api/users/:gmail/coins/add
Body: {
  "amount": 5
}
```

#### Deduct Coins
```
POST /api/users/:gmail/coins/deduct
Body: {
  "amount": 15
}
```

### Premium Management

#### Activate Premium
```
POST /api/users/:gmail/premium/activate
Body: {
  "days": 7,
  "coinCost": 70,
  "expiryDate": "2025-11-15T10:00:00.000Z"
}
```

#### Downgrade Premium
```
POST /api/users/:gmail/premium/downgrade
```

#### Check and Downgrade Expired Premiums
```
POST /api/users/check-expired
```

### Health Check
```
GET /health
```

## Deployment Options

### 1. Replit Deployment
1. Create a new Node.js Repl
2. Copy all backend files to the Repl
3. Run `npm install`
4. Set environment variables in Secrets
5. Run with `npm start`
6. Update Flutter app's `mongodb_api_service.dart` baseUrl to your Repl URL

### 2. Heroku Deployment
```bash
# Login to Heroku
heroku login

# Create new app
heroku create mlwio-api

# Set environment variables
heroku config:set MONGODB_URI="your_mongodb_uri"

# Deploy
git push heroku main
```

### 3. Railway Deployment
1. Go to https://railway.app
2. Create new project
3. Connect GitHub repository
4. Select the `backend` directory
5. Add environment variables
6. Deploy

### 4. Vercel Deployment (Serverless)
1. Install Vercel CLI: `npm i -g vercel`
2. Run `vercel` in backend directory
3. Follow prompts
4. Add environment variables in Vercel dashboard

## Flutter App Configuration

After deploying the backend, configure the API URL in your Flutter app using environment variables:

### Development (localhost)
The app defaults to `http://localhost:3000/api` for local development.

### Production Deployment
Build the Flutter web app with the production API URL:

```bash
flutter build web --dart-define=API_BASE_URL=https://your-deployed-api-url.com/api
```

**Examples**:
- Replit: `flutter build web --dart-define=API_BASE_URL=https://your-repl-name.your-username.repl.co/api`
- Heroku: `flutter build web --dart-define=API_BASE_URL=https://mlwio-api.herokuapp.com/api`
- Railway: `flutter build web --dart-define=API_BASE_URL=https://mlwio-api.up.railway.app/api`

The `MongoDBApiService` automatically uses the configured URL via `String.fromEnvironment('API_BASE_URL')`.

## Testing the API

You can test the API using curl or Postman:

```bash
# Health check
curl http://localhost:3000/health

# Create a user
curl -X POST http://localhost:3000/api/users \
  -H "Content-Type: application/json" \
  -d '{"gmail":"test@example.com"}'

# Get user
curl http://localhost:3000/api/users/test@example.com

# Add coins
curl -X POST http://localhost:3000/api/users/test@example.com/coins/add \
  -H "Content-Type: application/json" \
  -d '{"amount":50}'
```

## Database Schema

### User Document
```json
{
  "_id": "ObjectId",
  "gmail": "user@example.com",
  "coins": 0,
  "isPremium": false,
  "premiumExpiryDate": null,
  "createdAt": "2025-11-08T00:00:00.000Z",
  "updatedAt": "2025-11-08T00:00:00.000Z"
}
```

## CORS Configuration

The API is configured to accept requests from any origin (`*`). For production, update the CORS origin in `server.js`:

```javascript
app.use(cors({
  origin: 'https://your-flutter-web-app-url.com',
  methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization']
}));
```

## Security Notes

1. **Never commit** `.env` file to Git
2. For production, restrict CORS to your app's domain
3. Consider adding API authentication (JWT tokens)
4. Implement rate limiting for production
5. Add input validation and sanitization

## Troubleshooting

### Connection Issues
- Verify MongoDB URI is correct
- Check MongoDB Atlas IP whitelist (allow 0.0.0.0/0 for development)
- Ensure database user has correct permissions

### Port Already in Use
```bash
# Change PORT in .env file or kill the process
lsof -ti:3000 | xargs kill -9
```

## Support

For issues or questions, check:
- MongoDB Atlas documentation: https://www.mongodb.com/docs/atlas/
- Express.js documentation: https://expressjs.com/
- Node.js documentation: https://nodejs.org/docs/
