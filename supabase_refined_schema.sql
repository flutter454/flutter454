-- 1. Create the notes table
-- Ensures one active note per user via UNIQUE(user_id) and RLS.
CREATE TABLE public.notes (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users NOT NULL UNIQUE,
    note_text TEXT,
    song_title TEXT, -- Kept for UI consistency
    song_artist TEXT,
    song_url TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    expire_at TIMESTAMPTZ DEFAULT (NOW() + INTERVAL '24 hours'),
    
    -- Constraint: Prevent empty notes (must have text OR song)
    CONSTRAINT check_content_exists CHECK (
        (note_text IS NOT NULL AND length(trim(note_text)) > 0) OR 
        (song_url IS NOT NULL AND length(trim(song_url)) > 0)
    )
);

-- 2. Enable RLS on notes
ALTER TABLE public.notes ENABLE ROW LEVEL SECURITY;

-- 3. Policy: Anyone can view ACTIVE notes
CREATE POLICY "Anyone can view active notes"
ON public.notes
FOR SELECT
USING (expire_at > NOW());

-- 4. Policy: Users can Insert/Update their own note
CREATE POLICY "Users can manage their own note"
ON public.notes
FOR ALL
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);


-- 5. Create the note_reactions table
CREATE TABLE public.note_reactions (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    note_id UUID REFERENCES public.notes(id) ON DELETE CASCADE NOT NULL,
    user_id UUID REFERENCES auth.users NOT NULL,
    type TEXT CHECK (type IN ('like', 'comment')),
    comment_text TEXT, -- Null for likes
    created_at TIMESTAMPTZ DEFAULT NOW(),

    -- Constraint: Comments must have text
    CONSTRAINT check_comment_content CHECK (
        type = 'like' OR (type = 'comment' AND comment_text IS NOT NULL AND length(trim(comment_text)) > 0)
    ),
    -- Constraint: One like per user per note
    CONSTRAINT unique_like_per_user UNIQUE (note_id, user_id, type)
        DEFERRABLE INITIALLY DEFERRED 
        -- Only applies if type is 'like'. Since standard SQL unique handles nulls poorly or strictly, 
        -- we rely on application logic or valid partial index. 
        -- A partial index is better for "One like per user":
);

-- Better Unique Like Constraint using Index
CREATE UNIQUE INDEX unique_likes ON public.note_reactions(note_id, user_id) WHERE type = 'like';

-- 6. Enable RLS on note_reactions
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

-- 9. Policy: Users can delete their own reactions
CREATE POLICY "Users can delete their own reactions"
ON public.note_reactions
FOR DELETE
USING (auth.uid() = user_id);
