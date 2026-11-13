# Smart Todos Backend

Express starter backend for the Smart Todos application. It currently provides a Hello World endpoint and a health check. SQL Server connection settings and a reusable `mssql` connection pool are prepared for the next API step.

## Requirements

- Node.js 18 or newer
- SQL Server is only needed when database-backed endpoints are added

## Setup

```bash
npm install
```

Copy `.env.example` to `.env` and update values as needed. The Hello World server does not require a running SQL Server.

## Run

```bash
npm run dev
```

Or run the server without automatic restarts:

```bash
npm start
```

Try `GET http://localhost:3000/` or `GET http://localhost:3000/health`.
