
-- 1. Add missing columns to 'chats' if table exists
-- We use a DO block to safely add columns only if they don't exist
DO $$
BEGIN
    -- Check for 'last_message_at' in chats
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'chats' AND column_name = 'last_message_at') THEN
        ALTER TABLE public.chats ADD COLUMN last_message_at timestamp with time zone default timezone('utc'::text, now()) not null;
    END IF;
    
    -- Check for 'user1_id' (just in case)
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'chats' AND column_name = 'user1_id') THEN
        ALTER TABLE public.chats ADD COLUMN user1_id uuid references auth.users not null;
    END IF;

    -- Check for 'user2_id'
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'chats' AND column_name = 'user2_id') THEN
        ALTER TABLE public.chats ADD COLUMN user2_id uuid references auth.users not null;
    END IF;
END $$;

-- 2. Add missing columns to 'messages'
DO $$
BEGIN
    -- Check for 'is_seen'
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'messages' AND column_name = 'is_seen') THEN
        ALTER TABLE public.messages ADD COLUMN is_seen boolean default false not null;
    END IF;

    -- Check for 'text' (assuming it exists, but good to be safe if it was named 'content' before)
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'messages' AND column_name = 'text') THEN
        ALTER TABLE public.messages ADD COLUMN text text;
    END IF;
    
    -- Check for 'chat_id'
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'messages' AND column_name = 'chat_id') THEN
         ALTER TABLE public.messages ADD COLUMN chat_id uuid references public.chats on delete cascade;
    END IF;
END $$;

-- 3. Update/Reset RLS Policies (Safe to drop and recreate)
-- chats policies
DROP POLICY IF EXISTS "Users can view their own chats" ON public.chats;
DROP POLICY IF EXISTS "Users can create chats" ON public.chats;

CREATE POLICY "Users can view their own chats"
ON public.chats FOR SELECT
USING (auth.uid() = user1_id OR auth.uid() = user2_id);

CREATE POLICY "Users can create chats"
ON public.chats FOR INSERT
WITH CHECK (auth.uid() = user1_id OR auth.uid() = user2_id);

-- messages policies
DROP POLICY IF EXISTS "Users can view messages in their chats" ON public.messages;
DROP POLICY IF EXISTS "Users can send messages" ON public.messages;
DROP POLICY IF EXISTS "Users can update 'is_seen' status" ON public.messages;

CREATE POLICY "Users can view messages in their chats"
ON public.messages FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM public.chats
    WHERE id = messages.chat_id
    AND (user1_id = auth.uid() OR user2_id = auth.uid())
  )
);

CREATE POLICY "Users can send messages"
ON public.messages FOR INSERT
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.chats
    WHERE id = chat_id
    AND (user1_id = auth.uid() OR user2_id = auth.uid())
  )
);

CREATE POLICY "Users can update 'is_seen' status"
ON public.messages FOR UPDATE
USING (
   EXISTS (
    SELECT 1 FROM public.chats
    WHERE id = messages.chat_id
    AND (user1_id = auth.uid() OR user2_id = auth.uid())
  )
)
WITH CHECK (
   EXISTS (
    SELECT 1 FROM public.chats
    WHERE id = messages.chat_id
    AND (user1_id = auth.uid() OR user2_id = auth.uid())
  )
);

-- 4. Recreate/Ensure Trigger for last_message_at
CREATE OR REPLACE FUNCTION public.update_chat_last_message()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE public.chats
  SET last_message_at = new.created_at
  WHERE id = new.chat_id;
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_message_sent ON public.messages;
CREATE TRIGGER on_message_sent
AFTER INSERT ON public.messages
FOR EACH ROW EXECUTE PROCEDURE public.update_chat_last_message();

-- 5. Enable RLS (idempotent)
ALTER TABLE public.chats ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;
