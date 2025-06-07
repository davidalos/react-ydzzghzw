# Incident Logging App

This project is a simple incident logging application built with **React** and **Supabase**. Users can submit incident reports, track progress toward goals and, if authorized as managers, view a dashboard of all activity. Cloudflare Turnstile is used on sign up to prevent spam registrations.

## Getting Started

Install dependencies:

```bash
npm install
```

### Development Server

Run the Vite development server with hot reloading:

```bash
npm run dev
```

The app will be available at `http://localhost:5173` by default.

### Running on StackBlitz

When using StackBlitz, first install dependencies and then start the development server:

```bash
npm install
npm start
```

`npm start` launches Vite in development mode. Environment variables can be provided in a `.env` file or set through the StackBlitz UI.

### Running Tests

Unit tests are written with [Vitest](https://vitest.dev/). To execute the test suite once, run:

```bash
npx vitest run
```

Or start Vitest in watch mode with:

```bash
npm test
```

## Project Structure

- `src/` – React components and hooks
- `api/` – Serverless functions used in development and on Vercel
- `supabase/` – Supabase migrations and seed scripts

## Deployment

The project is configured for deployment on Vercel. Environment variables for Supabase and Turnstile should be set in the Vercel dashboard.

### Required Environment Variables

| Name | Purpose | Example Value |
| --- | --- | --- |
| `VITE_SUPABASE_URL` | Supabase project URL (client) | `https://kybhregztorltmcltjra.supabase.co` |
| `VITE_SUPABASE_ANON_KEY` | Supabase anon key (client) | `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...` |
| `SUPABASE_URL` | Supabase project URL for serverless functions | `https://kybhregztorltmcltjra.supabase.co` |
| `SUPABASE_SERVICE_ROLE_KEY` | Service role key used by the signup API | `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...` |
| `VITE_TURNSTILE_SITE_KEY` | Cloudflare Turnstile site key | `0x4AAAAAABf8GGR3DrgJYy7g` |
| `TURNSTILE_SECRET_KEY` | Cloudflare Turnstile secret key | `0x4AAAAAABf8GBb27IJHtqpE9FfZdp-DRNU` |

Both Vite (`VITE_`) and Next.js (`NEXT_PUBLIC_`) prefixes are supported for the
Supabase credentials. Pick the prefix that matches your build tooling and keep
the same values across environments.

When running on StackBlitz or locally, place these values in a `.env` file. On Vercel set them in your project settings.

### Setting up Supabase CLI

To work with migrations and database schema:

1. **Install Supabase CLI** (if not already installed):
   ```bash
   npm install -g supabase
   ```

2. **Login to Supabase**:
   ```bash
   supabase login
   ```

3. **Link your project**:
   ```bash
   supabase link --project-ref kybhregztorltmcltjra
   ```

4. **Push migrations to database**:
   ```bash
   supabase db push
   ```

5. **Generate TypeScript types**:
   ```bash
   supabase gen types typescript --local > src/types/database.ts
   ```

## License

MIT