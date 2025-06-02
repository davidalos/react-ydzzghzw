/*
  # Initial Schema Setup

  1. New Tables
    - `clients`
      - `id` (uuid, primary key)
      - `label` (text, client name/identifier)
      - `created_at` (timestamp)
    
    - `incidents`
      - `id` (uuid, primary key)
      - `client_id` (uuid, foreign key to clients)
      - `category` (text)
      - `description` (text)
      - `reflection` (text)
      - `serious` (boolean)
      - `co_staff` (text array)
      - `submitted_by` (uuid, references auth.users)
      - `created_at` (timestamp)
    
    - `goals`
      - `id` (uuid, primary key)
      - `client_id` (uuid, foreign key to clients)
      - `title` (text)
      - `description` (text)
      - `status` (text)
      - `created_by` (uuid, references auth.users)
      - `created_at` (timestamp)
    
    - `goal_updates`
      - `id` (uuid, primary key)
      - `goal_id` (uuid, foreign key to goals)
      - `update_text` (text)
      - `progress_type` (text)
      - `created_by` (uuid, references auth.users)
      - `created_at` (timestamp)

  2. Security
    - Enable RLS on all tables
    - Add policies for authenticated users
*/

-- Create clients table
CREATE TABLE IF NOT EXISTS clients (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  label text NOT NULL,
  created_at timestamptz DEFAULT now()
);

-- Create incidents table
CREATE TABLE IF NOT EXISTS incidents (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  client_id uuid REFERENCES clients(id),
  category text NOT NULL,
  description text NOT NULL,
  reflection text,
  serious boolean DEFAULT false,
  co_staff text[],
  submitted_by uuid REFERENCES auth.users(id),
  created_at timestamptz DEFAULT now()
);

-- Create goals table
CREATE TABLE IF NOT EXISTS goals (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  client_id uuid REFERENCES clients(id),
  title text NOT NULL,
  description text,
  status text DEFAULT 'active',
  created_by uuid REFERENCES auth.users(id),
  created_at timestamptz DEFAULT now()
);

-- Create goal_updates table
CREATE TABLE IF NOT EXISTS goal_updates (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  goal_id uuid REFERENCES goals(id),
  update_text text NOT NULL,
  progress_type text NOT NULL,
  created_by uuid REFERENCES auth.users(id),
  created_at timestamptz DEFAULT now()
);

-- Enable Row Level Security
ALTER TABLE clients ENABLE ROW LEVEL SECURITY;
ALTER TABLE incidents ENABLE ROW LEVEL SECURITY;
ALTER TABLE goals ENABLE ROW LEVEL SECURITY;
ALTER TABLE goal_updates ENABLE ROW LEVEL SECURITY;

-- Create security policies
CREATE POLICY "Allow authenticated users to read clients"
  ON clients FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Allow authenticated users to read incidents"
  ON incidents FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Allow users to create incidents"
  ON incidents FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = submitted_by);

CREATE POLICY "Allow authenticated users to read goals"
  ON goals FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Allow users to create goals"
  ON goals FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Allow users to update their goals"
  ON goals FOR UPDATE
  TO authenticated
  USING (auth.uid() = created_by);

CREATE POLICY "Allow authenticated users to read goal updates"
  ON goal_updates FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Allow users to create goal updates"
  ON goal_updates FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = created_by);