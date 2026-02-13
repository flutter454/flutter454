-- Enable Row Level Security (RLS) on the stories table
alter table public.stories enable row level security;

-- Policy to allow EVERYONE (authenticated or anon) to READ stories
-- This is crucial for users to see each other's stories
create policy "Enable read access for all users"
on public.stories
for select
using (true);

-- Policy to allow Authenticated users to INSERT their own stories
create policy "Enable insert for authenticated users only"
on public.stories
for insert
with check (auth.uid() = user_id);

-- Policy to allow Users to DELETE their own stories
create policy "Enable delete for users based on user_id"
on public.stories
for delete
using (auth.uid() = user_id);

-- STORAGE POLICIES (storyBucket)

-- Allow public read access to the bucket
create policy "Public Access"
on storage.objects for select
using ( bucket_id = 'storyBucket' );

-- Allow authenticated users to upload
create policy "Authenticated Upload"
on storage.objects for insert
with check ( bucket_id = 'storyBucket' and auth.role() = 'authenticated' );

-- Allow users to delete their own files
create policy "Give users access to delete own files"
on storage.objects for delete
using ( bucket_id = 'storyBucket' and auth.uid()::text = (storage.foldername(name))[2] );
