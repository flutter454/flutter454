-- Create a table for public profiles if it doesn't exist
CREATE TABLE IF NOT EXISTS public.profiles (
  id uuid REFERENCES auth.users ON DELETE CASCADE NOT NULL PRIMARY KEY,
  updated_at TIMESTAMP WITH TIME ZONE,
  username TEXT UNIQUE,
  full_name TEXT,
  avatar_url TEXT,
  
  -- Add standard constraints
  CONSTRAINT username_length CHECK (char_length(username) >= 3)
);

-- Set up Row Level Security (RLS)
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Create policies for profiles
-- 1. Public profiles are viewable by everyone
CREATE POLICY "Public profiles are viewable by everyone." ON public.profiles
  FOR SELECT USING (true);

-- 2. Users can insert their own profile
CREATE POLICY "Users can insert their own profile." ON public.profiles
  FOR INSERT WITH CHECK (auth.uid() = id);

-- 3. Users can update own profile
CREATE POLICY "Users can update own profile." ON public.profiles
  FOR UPDATE USING (auth.uid() = id);

-- Function to handle new user signup
CREATE OR REPLACE FUNCTION public.handle_new_user() 
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, full_name, avatar_url, username)
  VALUES (
    new.id, 
    new.raw_user_meta_data->>'full_name', 
    new.raw_user_meta_data->>'avatar_url',
    new.raw_user_meta_data->>'username' -- Assumes 'username' is in metadata
  );
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger the function every time a user is created
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();

-- Optional: Manual Sync Script (Run this ONCE manually in SQL Editor to backfill existing users)
-- Optional: Manual Sync Script (Run this ONCE manually in SQL Editor to backfill existing users)
-- INSERT INTO public.profiles (id, full_name, avatar_url, username)
-- SELECT 
--   id, 
--   COALESCE(raw_user_meta_data->>'full_name', raw_user_meta_data->>'name', 'User'), -- Check full_name, then name
--   COALESCE(raw_user_meta_data->>'avatar_url', raw_user_meta_data->>'picture'),   -- Check avatar_url, then picture
--   COALESCE(raw_user_meta_data->>'username', email)                                 -- Check username, then email
-- FROM auth.users
-- ON CONFLICT (id) DO NOTHING;
