-- SkillBridge auth + profiles. Run in Supabase Dashboard > SQL Editor.
create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null check (char_length(full_name) between 2 and 80),
  email text not null,
  college_name text not null check (char_length(college_name) between 2 and 120),
  department text not null default 'Other' check (department in ('Computer Science','Information Technology','Electronics','Mechanical','Civil','Other')),
  academic_year text not null default 'First Year' check (academic_year in ('First Year','Second Year','Third Year','Fourth Year')),
  avatar_url text check (avatar_url is null or char_length(avatar_url) < 60000),
  bio text not null default '' check (char_length(bio) <= 280),
  skills text[] not null default '{}',
  skill_levels jsonb not null default '{}',
  interests text[] not null default '{}',
  availability text not null default 'evening' check (availability in ('now','evening','weekend')),
  karma_points integer not null default 0,
  profile_completed boolean not null default false,
  created_at timestamptz not null default now()
);
alter table public.profiles enable row level security;

-- Owners read their full row (including email). Other students see only the public view below.
create policy "own profile read" on public.profiles for select to authenticated using (auth.uid() = id);
create policy "own profile update" on public.profiles for update to authenticated using (auth.uid() = id) with check (auth.uid() = id);
-- No insert/delete policies: rows are created only by the trigger below.

-- Students may change only these columns; karma_points, email, id stay server-controlled.
revoke update on public.profiles from authenticated, anon;
grant update (full_name, college_name, department, academic_year, avatar_url, bio, skills, skill_levels, interests, availability, profile_completed)
  on public.profiles to authenticated;

create view public.public_profiles as
  select id, full_name, college_name, department, academic_year, avatar_url, bio, skills, skill_levels, interests, availability, karma_points, profile_completed
  from public.profiles;
grant select on public.public_profiles to authenticated;

-- Create the profile when an auth user signs up (works before email verification).
create or replace function public.handle_new_user() returns trigger
language plpgsql security definer set search_path = public as $$
declare m jsonb := coalesce(new.raw_user_meta_data, '{}'::jsonb);
begin
  insert into public.profiles (id, email, full_name, college_name, department, academic_year, bio, interests, avatar_url)
  values (new.id, new.email,
    left(coalesce(nullif(trim(m->>'full_name'),''), split_part(new.email,'@',1)), 80),
    left(coalesce(nullif(trim(m->>'college_name'),''), 'Unknown'), 120),
    case when m->>'department' in ('Computer Science','Information Technology','Electronics','Mechanical','Civil') then m->>'department' else 'Other' end,
    case when m->>'academic_year' in ('First Year','Second Year','Third Year','Fourth Year') then m->>'academic_year' else 'First Year' end,
    left(coalesce(m->>'bio',''), 280),
    coalesce(array(select jsonb_array_elements_text(case when jsonb_typeof(m->'interests')='array' then m->'interests' else '[]'::jsonb end)), '{}'),
    case when char_length(coalesce(m->>'avatar_url','')) < 60000 then nullif(m->>'avatar_url','') end);
  return new;
end $$;
create trigger on_auth_user_created after insert on auth.users for each row execute function public.handle_new_user();
