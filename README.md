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

## License

MIT
