-- Jalankan di Supabase SQL Editor setelah membuat project.
-- Database untuk daftar video Wijaya. RLS wajib tetap aktif.
create table if not exists public.admin_access (
  user_id uuid primary key references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);

create table if not exists public.videos (
  id uuid primary key default gen_random_uuid(),
  category text not null check (category in ('youtube','tiktok')),
  title text not null check (char_length(title) between 1 and 120),
  url text not null,
  is_published boolean not null default true,
  sort_order integer not null default 0,
  created_at timestamptz not null default now()
);


-- Data YouTube yang sudah ada pada website sebelumnya dipertahankan sebagai data awal.
insert into public.videos (category, title, url, is_published, sort_order) values
  ('youtube', 'Project Wijaya #01', 'https://youtu.be/GTI3I7Ia_3M', true, 1),
  ('youtube', 'Project Wijaya #02', 'https://youtu.be/sYbB5Gur4g0', true, 2),
  ('youtube', 'Project Wijaya #03', 'https://youtu.be/AWBHED1D_SU', true, 3),
  ('youtube', 'Project Wijaya #04', 'https://youtu.be/6j_cH2C2Jtk', true, 4)
on conflict do nothing;

alter table public.admin_access enable row level security;
alter table public.videos enable row level security;

create or replace function public.is_wijaya_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.admin_access
    where user_id = auth.uid()
  );
$$;

revoke all on function public.is_wijaya_admin() from public;
grant execute on function public.is_wijaya_admin() to authenticated;

drop policy if exists "Public can read published videos" on public.videos;
create policy "Public can read published videos"
on public.videos for select
to anon, authenticated
using (is_published = true or public.is_wijaya_admin());

drop policy if exists "Only admin can add videos" on public.videos;
create policy "Only admin can add videos"
on public.videos for insert
to authenticated
with check (public.is_wijaya_admin());

drop policy if exists "Only admin can update videos" on public.videos;
create policy "Only admin can update videos"
on public.videos for update
to authenticated
using (public.is_wijaya_admin())
with check (public.is_wijaya_admin());

drop policy if exists "Only admin can delete videos" on public.videos;
create policy "Only admin can delete videos"
on public.videos for delete
to authenticated
using (public.is_wijaya_admin());

-- PENTING:
-- Setelah membuat satu user admin di Authentication > Users,
-- salin UUID user tersebut dan jalankan perintah berikut di SQL Editor:
-- insert into public.admin_access (user_id) values ('UUID-USER-ADMIN');
-- Jangan membuat policy insert/update/delete untuk tabel admin_access.
