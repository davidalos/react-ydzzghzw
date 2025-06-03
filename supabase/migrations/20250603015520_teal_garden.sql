/*
  # Add initial test data
  
  1. Test Data
    - Add sample clients for testing
    
  2. Purpose
    - Provide initial data for testing the application
    - Allow immediate testing of features without manual data entry
*/

-- Insert test clients
INSERT INTO clients (label) VALUES
  ('John Doe'),
  ('Jane Smith'),
  ('Robert Johnson'),
  ('Maria Garcia')
ON CONFLICT (id) DO NOTHING;