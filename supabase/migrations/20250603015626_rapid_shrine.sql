/*
  # Insert Test Data
  
  1. Creates test clients for development
*/

-- Insert test clients
INSERT INTO clients (label) VALUES
  ('John Doe'),
  ('Jane Smith'),
  ('Robert Johnson'),
  ('Maria Garcia')
ON CONFLICT (id) DO NOTHING;