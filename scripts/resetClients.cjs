// scripts/resetClients.cjs

const { createClient } = require('@supabase/supabase-js');
require('dotenv').config();

// ✅ Initialize Supabase client
const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY
);

// ✅ Default Íbúar
const defaultClients = [
  { label: 'Íbúi 1' },
  { label: 'Íbúi 2' },
  { label: 'Íbúi 3' },
  { label: 'Íbúi 4' },
  { label: 'Íbúi 5' },
  { label: 'Íbúi 6' }
];

// ✅ Reset function
async function resetClients() {
  console.log('\n🔄 Resetting clients...');

  // 1. Delete all existing clients (UUID-safe)
  const { error: deleteError } = await supabase
    .from('clients')
    .delete()
    .not('id', 'is', null);

  if (deleteError) {
    console.error('❌ Error deleting clients:', deleteError.message);
    process.exit(1);
  }

  // 2. Insert default Íbúar
  const { error: insertError } = await supabase
    .from('clients')
    .insert(defaultClients);

  if (insertError) {
    console.error('❌ Error inserting clients:', insertError.message);
    process.exit(1);
  }

  console.log('✅ Clients reset successfully!\n');
  process.exit(0);
}

// 🚀 Run it
resetClients();
