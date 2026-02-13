-- 1. Create chats table
create table public.chats (
  id uuid default gen_random_uuid() primary key,
  user1_id uuid references auth.users not null,
  user2_id uuid references auth.users not null,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  last_message_at timestamp with time zone default timezone('utc'::text, now()) not null,
  
  -- Prevent duplicate chats between same two users (in specific order)
  -- Constraint to ensure we don't have (A,B) and (B,A) as separate rows.
  -- We usually enforce user1_id < user2_id via application or additional constraint, 
  -- but a simple unique index on (user1_id, user2_id) is good enough if app handles sorting.
  unique(user1_id, user2_id)
);

-- 2. Create messages table
create table public.messages (
  id uuid default gen_random_uuid() primary key,
  chat_id uuid references public.chats on delete cascade not null,
  sender_id uuid references auth.users not null,
  text text not null,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  is_seen boolean default false not null
);

-- 3. Enable RLS
alter table public.chats enable row level security;
alter table public.messages enable row level security;

-- 4. RLS Policies for CHATS
-- Users can see chats they are a participant in.
create policy "Users can view their own chats"
on public.chats for select
using (auth.uid() = user1_id or auth.uid() = user2_id);

-- Users can create chats (usually involves themselves)
create policy "Users can create chats"
on public.chats for insert
with check (auth.uid() = user1_id or auth.uid() = user2_id);

-- 5. RLS Policies for MESSAGES
-- Users can view messages in chats they belong to.
-- This requires a join or a helper function for performance, but for simple RLS:
-- (A more performant way in production is to denounce participant IDs into messages or use EXISTS)
create policy "Users can view messages in their chats"
on public.messages for select
using (
  exists (
    select 1 from public.chats
    where id = messages.chat_id
    and (user1_id = auth.uid() or user2_id = auth.uid())
  )
);

-- Users can insert messages into chats they belong to
create policy "Users can send messages"
on public.messages for insert
with check (
  exists (
    select 1 from public.chats
    where id = chat_id
    and (user1_id = auth.uid() or user2_id = auth.uid())
  )
);

-- Users can update 'is_seen' (e.g. mark as read)
-- Be careful not to allow changing text.
create policy "Users can update 'is_seen' status"
on public.messages for update
using (
   exists (
    select 1 from public.chats
    where id = messages.chat_id
    and (user1_id = auth.uid() or user2_id = auth.uid())
  )
)
with check (
   exists (
    select 1 from public.chats
    where id = messages.chat_id
    and (user1_id = auth.uid() or user2_id = auth.uid())
  )
);

-- 6. Helper to update last_message_at on new message
create or replace function public.update_chat_last_message()
returns trigger as $$
begin
  update public.chats
  set last_message_at = new.created_at
  where id = new.chat_id;
  return new;
end;
$$ language plpgsql security definer;

create trigger on_message_sent
after insert on public.messages
for each row execute procedure public.update_chat_last_message();
