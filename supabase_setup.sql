-- Enable necessary extensions
create extension if not exists "uuid-ossp";

-- 1. Create 'users' table
create table if not exists public.users (
  id uuid references auth.users not null primary key,
  full_name text,
  username text,
  email text,
  avatar_url text,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Enable RLS for users
alter table public.users enable row level security;

-- Policies for users
create policy "Public profiles are viewable by everyone."
  on users for select
  using ( true );

create policy "Users can insert their own profile."
  on users for insert
  with check ( auth.uid() = id );

create policy "Users can update own profile."
  on users for update
  using ( auth.uid() = id );

-- 2. Create 'stories' table
create table if not exists public.stories (
  id uuid default uuid_generate_v4() primary key,
  user_id uuid references public.users(id) not null,
  media_url text not null,
  media_type text not null check (media_type in ('image', 'video')),
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  expires_at timestamp with time zone default (timezone('utc'::text, now()) + interval '24 hours')
);

-- Enable RLS for stories
alter table public.stories enable row level security;

-- Policies for stories
create policy "Stories are viewable by everyone."
  on stories for select
  using ( true );

create policy "Users can insert their own stories."
  on stories for insert
  with check ( auth.uid() = user_id );

create policy "Users can delete their own stories."
  on stories for delete
  using ( auth.uid() = user_id );

-- 3. Storage Setup for 'storyBucket'
-- Note: It is best to create the bucket in the Supabase Dashboard -> Storage -> Create a new bucket named 'storyBucket'.
-- Make sure to toggle "Public bucket" to TRUE.

-- However, we can try to insert it via SQL (requires permissions)
insert into storage.buckets (id, name, public)
values ('storyBucket', 'storyBucket', true)
on conflict (id) do nothing;

-- Storage Policies for 'storyBucket'
-- Allow public access to view files
create policy "Public Access"
  on storage.objects for select
  using ( bucket_id = 'storyBucket' );

-- Allow authenticated users to upload files
create policy "Authenticated users can upload media"
  on storage.objects for insert
  with check (
    bucket_id = 'storyBucket' 
    and auth.role() = 'authenticated'
  );

-- Allow users to update/delete their own files (optional, based on path structure users/USERID/...)
create policy "Users can update/delete their own files"
  on storage.objects for update
  using (
    bucket_id = 'storyBucket' 
    and auth.uid()::text = (storage.foldername(name))[2]
  );

create policy "Users can delete their own files"
  on storage.objects for delete
  using (
    bucket_id = 'storyBucket' 
    and auth.uid()::text = (storage.foldername(name))[2]
  );
