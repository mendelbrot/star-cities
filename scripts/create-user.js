require('dotenv').config();
const { createClient } = require('@supabase/supabase-js');

const supabaseUrl = process.env.SUPABASE_URL;
const supabaseSecretKey = process.env.SUPABASE_SECRET_KEY;

if (!supabaseUrl || !supabaseSecretKey) {
  console.error('Error: SUPABASE_URL and SUPABASE_SECRET_KEY are required.');
  console.log('Ensure you have a .env file with these values or pass them as environment variables.');
  process.exit(1);
}

const supabase = createClient(supabaseUrl, supabaseSecretKey);

const email = process.argv[2];

if (!email) {
  console.error('Usage: node scripts/create-user.js <email>');
  process.exit(1);
}

async function createUser() {
  console.log(`Creating user with email: ${email}...`);
  
  const { data, error } = await supabase.auth.admin.createUser({
    email: email,
    email_confirm: true, // Auto-confirm the user so they can login immediately
  });

  if (error) {
    console.error('Error creating user:', error.message);
    return;
  }

  console.log('User created successfully!');
  console.log('User ID:', data.user.id);
  console.log('Email:', data.user.email);
}

createUser();
