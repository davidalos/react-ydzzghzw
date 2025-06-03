/*
  # Insert Test Data
  
  Adds initial test data for development and testing purposes.
*/

-- Insert test clients
INSERT INTO clients (label) VALUES
  ('John Doe'),
  ('Jane Smith'),
  ('Robert Johnson'),
  ('Maria Garcia')
ON CONFLICT (id) DO NOTHING;