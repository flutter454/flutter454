-- 1. Enable Row Level Security (RLS) on the stories table
ALTER TABLE stories ENABLE ROW LEVEL SECURITY;

-- 2. ALLOW EVERYONE to SEE all stories (This fixes the "Friend stories not showing" issue)
-- This allows any authenticated user or anonymous user to read the list of stories.
CREATE POLICY "Enable read access for all users" 
ON "public"."stories" 
FOR SELECT 
USING (true); 

-- 3. ALLOW USERS to UPLOAD their own stories
-- Only authenticated users can insert, and they can only insert rows where user_id matches their own ID.
CREATE POLICY "Enable insert for authenticated users only" 
ON "public"."stories" 
FOR INSERT 
WITH CHECK (auth.uid() = user_id);

-- 4. ALLOW USERS to DELETE their own stories
-- Users can only delete rows where user_id matches their own ID.
CREATE POLICY "Enable delete for users based on user_id" 
ON "public"."stories" 
FOR DELETE 
USING (auth.uid() = user_id);

-- 5. ALLOW USERS to UPDATE their own stories (Optional, for edits)
CREATE POLICY "Enable update for users based on user_id" 
ON "public"."stories" 
FOR UPDATE 
USING (auth.uid() = user_id);
