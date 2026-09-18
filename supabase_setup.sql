-- PROOF OF LIFE - SUPABASE SETUP
-- Run this script in the Supabase SQL Editor.
-- Enable Email Sign-In under Authentication > Providers first.
-- Configure the deployed GitHub Pages and Vercel URLs under Authentication > URL Configuration.

create or replace function public.is_proof_owner()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
    select lower(coalesce(auth.jwt() ->> 'email', '')) =
        lower('swettadafelizarda.sf@gmail.com');
$$;

grant execute on function public.is_proof_owner() to authenticated;

create table if not exists public.checkins (
    id uuid primary key default gen_random_uuid(),
    checked_at timestamptz not null default now()
);

create table if not exists public.contacts (
    id uuid primary key default gen_random_uuid(),
    name text not null,
    phone text,
    email text,
    created_at timestamptz not null default now()
);

create table if not exists public.daily_status (
    day date primary key,
    pain integer not null default 1 check (pain between 1 and 5),
    hunger integer not null default 1 check (hunger between 1 and 5),
    energy integer not null default 1 check (energy between 1 and 5),
    mood text not null default 'Okay',
    note text not null default '',
    updated_at timestamptz not null default now()
);

create table if not exists public.memories (
    id uuid primary key default gen_random_uuid(),
    storage_path text not null unique,
    original_name text not null default 'memory',
    created_at timestamptz not null default now()
);

-- Compatibility for tables created by the earlier setup script.
alter table public.checkins
    add column if not exists checked_at timestamptz;

alter table public.checkins
    alter column checked_at set default now();

alter table public.daily_status
    add column if not exists day date;

update public.daily_status
set day = coalesce(day, updated_at::date, current_date)
where day is null;

delete from public.daily_status older
using public.daily_status newer
where older.day = newer.day
  and older.ctid < newer.ctid;

create unique index if not exists daily_status_day_key
on public.daily_status (day);

alter table public.memories
    add column if not exists original_name text;

update public.memories
set original_name = 'memory'
where original_name is null;

alter table public.memories
    alter column original_name set default 'memory';

alter table public.memories
    alter column original_name set not null;

alter table public.checkins enable row level security;
alter table public.contacts enable row level security;
alter table public.daily_status enable row level security;
alter table public.memories enable row level security;

-- Drop both the current setup names and names from the older owner script.
drop policy if exists "Anyone can view checkins" on public.checkins;
drop policy if exists "Authenticated users can read checkins" on public.checkins;
drop policy if exists "Owner can create checkins" on public.checkins;
drop policy if exists "Authenticated users can add checkins" on public.checkins;

create policy "Anyone can view checkins"
on public.checkins for select to anon, authenticated using (true);

create policy "Authenticated users can add checkins"
on public.checkins for insert to authenticated
with check (public.is_proof_owner());


drop policy if exists "Anyone can view contacts" on public.contacts;
drop policy if exists "Owner can view contacts" on public.contacts;
drop policy if exists "Owner can create contacts" on public.contacts;
drop policy if exists "Authenticated users can read contacts" on public.contacts;
drop policy if exists "Authenticated users can add contacts" on public.contacts;
drop policy if exists "Authenticated users can delete contacts" on public.contacts;
drop policy if exists "Owner can update contacts" on public.contacts;
drop policy if exists "Owner can delete contacts" on public.contacts;

create policy "Anyone can view contacts"
on public.contacts for select to anon, authenticated using (true);

create policy "Authenticated users can add contacts"
on public.contacts for insert to authenticated
with check (public.is_proof_owner());

create policy "Authenticated users can delete contacts"
on public.contacts for delete to authenticated
using (public.is_proof_owner());


-- Remove legacy daily_status policies before recreating the compatible ones.
drop policy if exists "Anyone can view status" on public.daily_status;
drop policy if exists "Owner can create status" on public.daily_status;
drop policy if exists "Owner can update status" on public.daily_status;
drop policy if exists "Owner can delete status" on public.daily_status;
drop policy if exists "Authenticated users can read daily status" on public.daily_status;
drop policy if exists "Authenticated users can save daily status" on public.daily_status;
drop policy if exists "Authenticated users can update daily status" on public.daily_status;

create policy "Anyone can view status"
on public.daily_status for select to anon, authenticated using (true);

create policy "Authenticated users can save daily status"
on public.daily_status for insert to authenticated
with check (public.is_proof_owner());

create policy "Authenticated users can update daily status"
on public.daily_status for update to authenticated
using (public.is_proof_owner())
with check (public.is_proof_owner());


-- Remove legacy memory policies before recreating them.
drop policy if exists "Anyone can view memories" on public.memories;
drop policy if exists "Owner can add memories" on public.memories;
drop policy if exists "Owner can delete memories" on public.memories;
drop policy if exists "Authenticated users can read memories" on public.memories;
drop policy if exists "Authenticated users can add memories" on public.memories;
drop policy if exists "Authenticated users can delete memories" on public.memories;

create policy "Anyone can view memories"
on public.memories for select to anon, authenticated using (true);

create policy "Authenticated users can add memories"
on public.memories for insert to authenticated
with check (public.is_proof_owner());

create policy "Authenticated users can delete memories"
on public.memories for delete to authenticated
using (public.is_proof_owner());


insert into storage.buckets (id, name, public)
values ('memories', 'memories', true)
on conflict (id) do update set public = true;


drop policy if exists "Proof owner can upload memories" on storage.objects;
drop policy if exists "Authenticated users can upload memories" on storage.objects;
create policy "Authenticated users can upload memories"
on storage.objects for insert to authenticated
with check (
    bucket_id = 'memories'
    and public.is_proof_owner()
);


drop policy if exists "Proof owner can delete memories" on storage.objects;
drop policy if exists "Authenticated users can delete memory objects" on storage.objects;
create policy "Authenticated users can delete memory objects"
on storage.objects for delete to authenticated
using (
    bucket_id = 'memories'
    and public.is_proof_owner()
);


drop policy if exists "Anyone can view storage memories" on storage.objects;
drop policy if exists "Authenticated users can read memory objects" on storage.objects;
create policy "Anyone can view storage memories"
on storage.objects for select to anon, authenticated
using (bucket_id = 'memories');


grant usage on schema public to anon, authenticated;
grant select, insert on public.checkins to authenticated;
grant select on public.checkins to anon;
grant select, insert on public.contacts to authenticated;
grant delete on public.contacts to authenticated;
grant select on public.contacts to anon;
grant select, insert, update on public.daily_status to authenticated;
grant select on public.daily_status to anon;
grant select, insert on public.memories to authenticated;
grant delete on public.memories to authenticated;
grant select on public.memories to anon;
