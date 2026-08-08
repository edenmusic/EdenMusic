import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const supabaseUrl = "https://kokjxhgnguskgioeqhul.supabase.co"
const supabaseKey = "sb_publishable_zoBChaJuIHnR0ArIGK4MKA_B9XBi3PN"

export const supabase = createClient(supabaseUrl, supabaseKey);

