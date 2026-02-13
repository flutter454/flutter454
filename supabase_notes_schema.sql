-- 1. Create the notes table
-- This table stores one active note per user. 
-- We use user_id as the primary key to ensure one note per user.
CREATE TABLE public.notes (
    user_id UUID REFERENCES auth.users NOT NULL PRIMARY KEY,
    note_text TEXT,
    song_title TEXT,
    song_artist TEXT,
    song_url TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    expires_at TIMESTAMPTZ DEFAULT (NOW() + INTERVAL '24 hours')
);

-- 2. Enable RLS on notes
ALTER TABLE public.notes ENABLE ROW LEVEL SECURITY;

-- 3. Policy: Anyone can view UNEXPIRED notes
CREATE POLICY "Anyone can view active notes"
ON public.notes
FOR SELECT
USING (expires_at > NOW());

-- 4. Policy: Users can Insert/Update their own note
-- logic: matching triggers on the user_id column
CREATE POLICY "Users can manage their own note"
ON public.notes
FOR ALL
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);


-- 5. Create the reactions table (Likes and Comments)
CREATE TABLE public.note_reactions (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    -- referencing notes(user_id) because that is the PK of notes
    note_id UUID REFERENCES public.notes(user_id) ON DELETE CASCADE NOT NULL, 
    user_id UUID REFERENCES auth.users NOT NULL,
    reaction_type TEXT CHECK (reaction_type IN ('like', 'comment')),
    content TEXT, -- content is NULL for likes, textual for comments
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 6. Enable RLS on reactions
ALTER TABLE public.note_reactions ENABLE ROW LEVEL SECURITY;

-- 7. Policy: Anyone can view reactions
CREATE POLICY "Anyone can view reactions"
ON public.note_reactions
FOR SELECT
USING (true);

-- 8. Policy: Users can insert their own reactions
CREATE POLICY "Users can insert their own reactions"
ON public.note_reactions
FOR INSERT
WITH CHECK (auth.uid() = user_id);

-- 9. (Optional) Policy: Users can delete their own reactions (unlike)
CREATE POLICY "Users can delete their own reactions"
ON public.note_reactions
FOR DELETE
USING (auth.uid() = user_id);
