-- Enable necessary extensions
create extension if not exists "uuid-ossp";

-- 1. Create 'stories' table (Simplified for Anonymous Usage)
-- Note: We are removing the foreign key constraint to users table since we might not have a synced user.
create table if not exists public.stories (
  id uuid default uuid_generate_v4() primary key,
  user_id text not null,  -- Changed from UUID to TEXT to accept Firebase UID directly
  media_url text not null,
  media_type text not null check (media_type in ('image', 'video')),
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  expires_at timestamp with time zone default (timezone('utc'::text, now()) + interval '24 hours')
);

-- Enable RLS for stories
alter table public.stories enable row level security;

-- Policies for stories (ANONYMOUS / PUBLIC ACCESS)
-- Allow anyone to select (view) stories
create policy "Public Stories Access"
  on stories for select
  using ( true );

-- Allow anyone to insert (upload) stories
-- WARN: This is insecure for production but matches user request for "anon policy"
create policy "Anonymous Insert Access"
  on stories for insert
  with check ( true );

-- Allow users to delete their own stories (based on user_id text match)
-- Note: Since we are anon, we can't easily verify 'auth.uid()', so this is tricky.
-- For now, allowing all deletes or we rely on client-side ID match which is insecure but functional for this mode.
create policy "Anonymous Delete Access"
  on stories for delete
  using ( true ); 


-- 2. Storage Setup for 'storyBucket'
insert into storage.buckets (id, name, public)
values ('storyBucket', 'storyBucket', true)
on conflict (id) do nothing;

-- Storage Policies for 'storyBucket'
-- Allow public access to view files
create policy "Public Access View"
  on storage.objects for select
  using ( bucket_id = 'storyBucket' );

-- Allow ANONYMOUS uploads
create policy "Anonymous Upload"
  on storage.objects for insert
  with check ( bucket_id = 'storyBucket' );

-- Allow ANONYMOUS updates/deletes
create policy "Anonymous Update"
  on storage.objects for update
  using ( bucket_id = 'storyBucket' );

create policy "Anonymous Delete"
  on storage.objects for delete
  using ( bucket_id = 'storyBucket' );
