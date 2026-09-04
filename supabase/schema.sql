-- ============================================================================
-- THE GAME — current schema (as actually deployed)
-- This reflects everything applied to the live Supabase project, including
-- fixes made after the initial build. If you ever need to rebuild the
-- database from scratch, running this file top-to-bottom reproduces the
-- current live state.
-- ============================================================================

create extension if not exists "pgcrypto";

-- ----------------------------------------------------------------------------
-- ENUMS
-- ----------------------------------------------------------------------------
create type answer_value as enum ('full_spark', 'warming_up', 'blushing_yes', 'just_for_you', 'cold_card');
create type dare_type as enum ('apart', 'together', 'either', 'reunion');
create type intensity_level as enum ('tease', 'risque', 'bold', 'wild');
create type dare_status as enum (
  'sent', 'accepted', 'countered', 'declined',
  'in_progress', 'completed', 'completed_proof',
  'completed_face_to_face', 'not_completed', 'cancelled'
);
create type completion_kind as enum (
  'no_proof', 'proof_in_person', 'proof_sent_externally', 'confirmed_by_partner'
);

-- ----------------------------------------------------------------------------
-- TABLES
-- ----------------------------------------------------------------------------
create table profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null,
  gender text check (gender in ('male','female')),  -- cosmetic only, drives the colour theme
  created_at timestamptz not null default now()
);

create table couples (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now()
);

create table couple_invites (
  code text primary key,
  couple_id uuid not null references couples(id) on delete cascade,
  created_by uuid not null references profiles(id),
  created_at timestamptz not null default now(),
  expires_at timestamptz not null default (now() + interval '7 days'),
  redeemed_at timestamptz,
  redeemed_by uuid references profiles(id)
);

create table couple_members (
  couple_id uuid not null references couples(id) on delete cascade,
  user_id uuid not null references profiles(id) on delete cascade,
  joined_at timestamptz not null default now(),
  primary key (couple_id, user_id),
  unique (user_id)
);

create table boundary_categories (
  id uuid primary key default gen_random_uuid(),
  name text unique not null,
  sort_order int not null default 0,
  created_at timestamptz not null default now()
);

create table boundary_questions (
  id uuid primary key default gen_random_uuid(),
  couple_id uuid not null references couples(id) on delete cascade,
  category text not null,
  title text not null,
  explanation text,
  image_path text,
  max_intensity intensity_level not null default 'tease',
  suitable_for dare_type not null default 'either',
  active boolean not null default true,
  sort_order int not null default 0,
  created_at timestamptz not null default now()
);

create table boundary_answers (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references profiles(id) on delete cascade,
  question_id uuid not null references boundary_questions(id) on delete cascade,
  answer answer_value not null,
  updated_at timestamptz not null default now(),
  unique (user_id, question_id)
);

create table dares (
  id uuid primary key default gen_random_uuid(),
  couple_id uuid not null references couples(id) on delete cascade,
  creator_id uuid not null references profiles(id),
  recipient_id uuid not null references profiles(id),
  question_id uuid references boundary_questions(id),
  title text not null,
  instructions text not null,
  teaser text,
  dare_type dare_type not null,
  intensity intensity_level not null,
  base_points int not null,
  deadline timestamptz,
  requires_confirmation boolean not null default false,
  reward_text text,
  reusable boolean not null default false,
  favorite boolean not null default false,
  status dare_status not null default 'sent',
  sent_at timestamptz not null default now(),
  responded_at timestamptz,
  completed_at timestamptz,
  completion_kind completion_kind,
  points_awarded int,
  score_multiplier numeric,
  created_at timestamptz not null default now()
);

create table dare_events (
  id uuid primary key default gen_random_uuid(),
  dare_id uuid not null references dares(id) on delete cascade,
  couple_id uuid not null references couples(id) on delete cascade,
  actor_id uuid not null references profiles(id),
  event_type text not null,
  detail text,
  created_at timestamptz not null default now()
);

create table score_adjustments (
  id uuid primary key default gen_random_uuid(),
  couple_id uuid not null references couples(id) on delete cascade,
  user_id uuid not null references profiles(id),
  points int not null,
  reason text not null,
  created_by uuid not null references profiles(id),
  created_at timestamptz not null default now()
);

create table heat_meter (
  couple_id uuid primary key references couples(id) on delete cascade,
  progress int not null default 0 check (progress >= 0 and progress <= 100),
  updated_at timestamptz not null default now()
);

create table rewards (
  id uuid primary key default gen_random_uuid(),
  couple_id uuid not null references couples(id) on delete cascade,
  title text not null,
  teaser text,
  details text not null,
  unlock_condition text not null,
  heat_threshold int,
  creator_id uuid not null references profiles(id),
  expiry_date timestamptz,
  revealed boolean not null default false,
  completed boolean not null default false,
  created_at timestamptz not null default now()
);

create table notifications (
  id uuid primary key default gen_random_uuid(),
  couple_id uuid not null references couples(id) on delete cascade,
  recipient_id uuid not null references profiles(id),
  message text not null,
  dare_id uuid references dares(id) on delete cascade,
  read boolean not null default false,
  created_at timestamptz not null default now()
);

-- ----------------------------------------------------------------------------
-- HELPER: current user's couple id
-- ----------------------------------------------------------------------------
create or replace function my_couple_id()
returns uuid
language sql
security definer
stable
set search_path = public
as $$
  select couple_id from couple_members where user_id = auth.uid();
$$;
revoke execute on function my_couple_id() from public, anon;
grant execute on function my_couple_id() to authenticated;

-- ----------------------------------------------------------------------------
-- ROW LEVEL SECURITY
-- ----------------------------------------------------------------------------
alter table profiles enable row level security;
alter table couples enable row level security;
alter table couple_invites enable row level security;
alter table couple_members enable row level security;
alter table boundary_categories enable row level security;
alter table boundary_questions enable row level security;
alter table boundary_answers enable row level security;
alter table dares enable row level security;
alter table dare_events enable row level security;
alter table score_adjustments enable row level security;
alter table heat_meter enable row level security;
alter table rewards enable row level security;
alter table notifications enable row level security;

create policy "profiles_select_own" on profiles for select using (id = auth.uid());
create policy "profiles_update_own" on profiles for update using (id = auth.uid());
create policy "profiles_insert_own" on profiles for insert with check (id = auth.uid());

create policy "couples_select_member" on couples for select using (id = my_couple_id());

create policy "invites_select_own" on couple_invites for select
  using (created_by = auth.uid() or redeemed_by = auth.uid());
create policy "invites_insert_own" on couple_invites for insert
  with check (created_by = auth.uid());

create policy "members_select_own_couple" on couple_members for select
  using (couple_id = my_couple_id());
create policy "members_insert_self" on couple_members for insert
  with check (user_id = auth.uid());

create policy "categories_select_all" on boundary_categories for select
  using (auth.role() = 'authenticated');

create policy "questions_select_couple" on boundary_questions for select
  using (couple_id = my_couple_id());
create policy "questions_insert_none" on boundary_questions for insert with check (false);
create policy "questions_update_couple" on boundary_questions for update
  using (couple_id = my_couple_id());

create policy "answers_select_own" on boundary_answers for select using (user_id = auth.uid());
create policy "answers_insert_own" on boundary_answers for insert with check (user_id = auth.uid());
create policy "answers_update_own" on boundary_answers for update using (user_id = auth.uid());

create policy "dares_select_couple" on dares for select using (couple_id = my_couple_id());
create policy "dares_update_couple" on dares for update using (couple_id = my_couple_id());
create policy "dares_insert_none" on dares for insert with check (false);

create policy "dare_events_select_couple" on dare_events for select using (couple_id = my_couple_id());
create policy "dare_events_insert_self" on dare_events for insert
  with check (couple_id = my_couple_id() and actor_id = auth.uid());

create policy "adjustments_select_couple" on score_adjustments for select using (couple_id = my_couple_id());
create policy "adjustments_insert_couple" on score_adjustments for insert
  with check (couple_id = my_couple_id() and created_by = auth.uid());

create policy "heat_select_couple" on heat_meter for select using (couple_id = my_couple_id());
create policy "heat_insert_none" on heat_meter for insert with check (false);
create policy "heat_update_none" on heat_meter for update using (false);

create policy "rewards_select_couple" on rewards for select using (couple_id = my_couple_id());
create policy "rewards_insert_couple" on rewards for insert
  with check (couple_id = my_couple_id() and creator_id = auth.uid());
create policy "rewards_update_couple" on rewards for update using (couple_id = my_couple_id());

create policy "notifications_select_own" on notifications for select using (recipient_id = auth.uid());
create policy "notifications_update_own" on notifications for update using (recipient_id = auth.uid());
create policy "notifications_insert_none" on notifications for insert with check (false);

-- ----------------------------------------------------------------------------
-- Partner's display name only, never their full row
-- ----------------------------------------------------------------------------
create or replace function get_partner_profile()
returns table (id uuid, display_name text)
language sql
security definer
stable
set search_path = public
as $$
  select p.id, p.display_name
  from profiles p
  join couple_members cm on cm.user_id = p.id
  where cm.couple_id = my_couple_id() and p.id <> auth.uid();
$$;
revoke execute on function get_partner_profile() from public, anon;
grant execute on function get_partner_profile() to authenticated;

-- ----------------------------------------------------------------------------
-- PAIRING
-- ----------------------------------------------------------------------------
create or replace function create_couple_invite()
returns text
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_couple_id uuid;
  v_code text;
begin
  if exists (select 1 from couple_members where user_id = auth.uid()) then
    raise exception 'You already belong to a couple.';
  end if;
  insert into couples default values returning id into v_couple_id;
  insert into couple_members (couple_id, user_id) values (v_couple_id, auth.uid());
  insert into heat_meter (couple_id, progress) values (v_couple_id, 0);
  v_code := upper(substr(encode(gen_random_bytes(4), 'hex'), 1, 6));
  insert into couple_invites (code, couple_id, created_by) values (v_code, v_couple_id, auth.uid());
  return v_code;
end;
$$;
revoke execute on function create_couple_invite() from public, anon;
grant execute on function create_couple_invite() to authenticated;

create or replace function redeem_couple_invite(p_code text)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_invite couple_invites;
begin
  if exists (select 1 from couple_members where user_id = auth.uid()) then
    raise exception 'You already belong to a couple.';
  end if;
  select * into v_invite from couple_invites
    where code = upper(p_code) and redeemed_at is null and expires_at > now();
  if v_invite is null then raise exception 'Invite code not found or expired.'; end if;
  if v_invite.created_by = auth.uid() then raise exception 'You cannot redeem your own invite.'; end if;
  insert into couple_members (couple_id, user_id) values (v_invite.couple_id, auth.uid());
  update couple_invites set redeemed_at = now(), redeemed_by = auth.uid() where code = v_invite.code;
  return v_invite.couple_id;
end;
$$;
revoke execute on function redeem_couple_invite(text) from public, anon;
grant execute on function redeem_couple_invite(text) to authenticated;

create or replace function get_active_invite_code()
returns text
language plpgsql
security definer
stable
set search_path = public
as $$
declare
  v_couple_id uuid := my_couple_id();
  v_code text;
begin
  if v_couple_id is null then return null; end if;
  select code into v_code from couple_invites
    where couple_id = v_couple_id and redeemed_at is null and expires_at > now()
    order by created_at desc limit 1;
  return v_code;
end;
$$;
revoke execute on function get_active_invite_code() from public, anon;
grant execute on function get_active_invite_code() to authenticated;

create or replace function create_additional_invite()
returns text
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_couple_id uuid := my_couple_id();
  v_code text;
  v_member_count int;
begin
  if v_couple_id is null then raise exception 'You are not part of a couple yet.'; end if;
  select count(*) into v_member_count from couple_members where couple_id = v_couple_id;
  if v_member_count > 1 then raise exception 'You already have a partner paired.'; end if;
  v_code := upper(substr(encode(gen_random_bytes(4), 'hex'), 1, 6));
  insert into couple_invites (code, couple_id, created_by) values (v_code, v_couple_id, auth.uid());
  return v_code;
end;
$$;
revoke execute on function create_additional_invite() from public, anon;
grant execute on function create_additional_invite() to authenticated;

-- ----------------------------------------------------------------------------
-- MUTUAL BOUNDARY CALCULATION
-- ----------------------------------------------------------------------------
create or replace function compute_shared_boundary()
returns table (
  question_id uuid, category text, title text, explanation text, image_path text,
  dare_type dare_type, permitted boolean, intensity_cap intensity_level
)
language plpgsql
security definer
stable
set search_path = public
as $$
declare
  v_couple_id uuid := my_couple_id();
  v_members uuid[];
  v_intensity_rank constant text[] := array['tease','risque','bold','wild'];
begin
  if v_couple_id is null then raise exception 'You are not paired with a partner yet.'; end if;
  select array_agg(user_id) into v_members from couple_members where couple_id = v_couple_id;
  if array_length(v_members, 1) <> 2 then return; end if;

  return query
  with a as (
    select ba.question_id, ba.user_id, ba.answer from boundary_answers ba where ba.user_id = any(v_members)
  ),
  paired as (
    select q.id as question_id, q.category, q.title, q.explanation, q.image_path,
      q.suitable_for as dare_type, q.max_intensity,
      max(case when a1.answer is not null then a1.answer::text end) as ans1,
      max(case when a2.answer is not null then a2.answer::text end) as ans2
    from boundary_questions q
    left join a a1 on a1.question_id = q.id and a1.user_id = v_members[1]
    left join a a2 on a2.question_id = q.id and a2.user_id = v_members[2]
    where q.active = true and q.couple_id = v_couple_id
    group by q.id, q.category, q.title, q.explanation, q.image_path, q.suitable_for, q.max_intensity
  ),
  scored as (
    select p.*,
      case p.ans1 when 'full_spark' then 4 when 'warming_up' then 3 when 'blushing_yes' then 2 when 'just_for_you' then 1 when 'cold_card' then -1 else null end as score1,
      case p.ans2 when 'full_spark' then 4 when 'warming_up' then 3 when 'blushing_yes' then 2 when 'just_for_you' then 1 when 'cold_card' then -1 else null end as score2
    from paired p
  )
  select s.question_id, s.category, s.title, s.explanation, s.image_path, s.dare_type,
    case when s.score1 is null or s.score2 is null then false
         when s.score1 = -1 or s.score2 = -1 then false
         else true end as permitted,
    case when s.score1 is null or s.score2 is null then null
         when s.score1 = -1 or s.score2 = -1 then null
         else (case least(s.score1, s.score2)
           when 4 then s.max_intensity
           when 3 then v_intensity_rank[greatest(1, array_position(v_intensity_rank, s.max_intensity::text) - 1)]::intensity_level
           when 2 then v_intensity_rank[greatest(1, array_position(v_intensity_rank, s.max_intensity::text) - 2)]::intensity_level
           when 1 then 'tease'::intensity_level
         end) end as intensity_cap
  from scored s;
end;
$$;
revoke execute on function compute_shared_boundary() from public, anon;
grant execute on function compute_shared_boundary() to authenticated;

-- ----------------------------------------------------------------------------
-- ADDING YOUR OWN CONTENT (headings + cards)
-- ----------------------------------------------------------------------------
create or replace function add_boundary_category(p_name text)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_id uuid;
begin
  insert into boundary_categories (name, sort_order)
    values (trim(p_name), (select coalesce(max(sort_order), 0) + 10 from boundary_categories))
    on conflict (name) do nothing;
  select id into v_id from boundary_categories where name = trim(p_name);
  return v_id;
end;
$$;
revoke execute on function add_boundary_category(text) from public, anon;
grant execute on function add_boundary_category(text) to authenticated;

create or replace function add_boundary_question(
  p_category text, p_title text, p_explanation text, p_image_path text,
  p_max_intensity intensity_level, p_suitable_for dare_type
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_couple_id uuid := my_couple_id();
  v_id uuid;
  v_sort int;
begin
  if v_couple_id is null then raise exception 'You are not paired with a partner yet.'; end if;
  select coalesce(max(sort_order), 0) + 10 into v_sort from boundary_questions where couple_id = v_couple_id;
  insert into boundary_questions
    (couple_id, category, title, explanation, image_path, max_intensity, suitable_for, active, sort_order)
  values
    (v_couple_id, p_category, p_title, p_explanation, p_image_path, p_max_intensity, p_suitable_for, true, v_sort)
  returning id into v_id;
  return v_id;
end;
$$;
revoke execute on function add_boundary_question(text, text, text, text, intensity_level, dare_type) from public, anon;
grant execute on function add_boundary_question(text, text, text, text, intensity_level, dare_type) to authenticated;

-- ----------------------------------------------------------------------------
-- DARE CREATION
-- ----------------------------------------------------------------------------
create or replace function create_dare(
  p_question_id uuid, p_title text, p_instructions text, p_teaser text,
  p_dare_type dare_type, p_intensity intensity_level, p_deadline timestamptz,
  p_requires_confirmation boolean, p_reward_text text, p_reusable boolean
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_couple_id uuid := my_couple_id();
  v_recipient uuid;
  v_boundary record;
  v_base_points int;
  v_dare_id uuid;
  v_intensity_rank constant text[] := array['tease','risque','bold','wild'];
begin
  if v_couple_id is null then raise exception 'You are not paired with a partner yet.'; end if;
  select user_id into v_recipient from couple_members where couple_id = v_couple_id and user_id <> auth.uid();
  if v_recipient is null then raise exception 'No partner found to send this dare to.'; end if;

  select * into v_boundary from compute_shared_boundary() where question_id = p_question_id;
  if v_boundary is null or v_boundary.permitted is not true then
    raise exception 'This category is not within your shared boundary.';
  end if;
  if v_boundary.intensity_cap is not null and
     array_position(v_intensity_rank, p_intensity::text) > array_position(v_intensity_rank, v_boundary.intensity_cap::text) then
    raise exception 'This intensity exceeds your current shared boundary for this category.';
  end if;

  v_base_points := case p_intensity when 'tease' then 10 when 'risque' then 25 when 'bold' then 50 when 'wild' then 100 end;

  insert into dares (couple_id, creator_id, recipient_id, question_id, title, instructions, teaser,
    dare_type, intensity, base_points, deadline, requires_confirmation, reward_text, reusable, status, sent_at)
  values (v_couple_id, auth.uid(), v_recipient, p_question_id, p_title, p_instructions, p_teaser,
    p_dare_type, p_intensity, v_base_points, p_deadline, p_requires_confirmation, p_reward_text, p_reusable, 'sent', now())
  returning id into v_dare_id;

  insert into dare_events (dare_id, couple_id, actor_id, event_type) values (v_dare_id, v_couple_id, auth.uid(), 'sent');
  insert into notifications (couple_id, recipient_id, message, dare_id) values (v_couple_id, v_recipient, 'You have a new move waiting.', v_dare_id);
  return v_dare_id;
end;
$$;
revoke execute on function create_dare(uuid, text, text, text, dare_type, intensity_level, timestamptz, boolean, text, boolean) from public, anon;
grant execute on function create_dare(uuid, text, text, text, dare_type, intensity_level, timestamptz, boolean, text, boolean) to authenticated;

-- ----------------------------------------------------------------------------
-- DARE RESPONSE
-- ----------------------------------------------------------------------------
create or replace function respond_to_dare(
  p_dare_id uuid, p_action text, p_new_deadline timestamptz default null,
  p_new_intensity intensity_level default null, p_new_instructions text default null
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_dare dares;
begin
  select * into v_dare from dares where id = p_dare_id and couple_id = my_couple_id();
  if v_dare is null then raise exception 'Dare not found.'; end if;
  if v_dare.recipient_id <> auth.uid() then raise exception 'Only the recipient can respond.'; end if;

  if p_action = 'accept' then
    update dares set status = 'accepted', responded_at = now() where id = p_dare_id;
  elsif p_action = 'decline' then
    update dares set status = 'declined', responded_at = now() where id = p_dare_id;
  elsif p_action = 'counter' then
    update dares set status = 'countered', responded_at = now(),
      deadline = coalesce(p_new_deadline, deadline), intensity = coalesce(p_new_intensity, intensity),
      instructions = coalesce(p_new_instructions, instructions)
    where id = p_dare_id;
  else
    raise exception 'Unknown action.';
  end if;

  insert into dare_events (dare_id, couple_id, actor_id, event_type) values (p_dare_id, v_dare.couple_id, auth.uid(), p_action);
  insert into notifications (couple_id, recipient_id, message, dare_id)
    values (v_dare.couple_id, v_dare.creator_id,
      case p_action when 'accept' then 'Your move was accepted.' when 'decline' then 'Your move was declined — no hard feelings.' else 'Your move came back with a counter-offer.' end,
      p_dare_id);
end;
$$;
revoke execute on function respond_to_dare(uuid, text, timestamptz, intensity_level, text) from public, anon;
grant execute on function respond_to_dare(uuid, text, timestamptz, intensity_level, text) to authenticated;

-- ----------------------------------------------------------------------------
-- COMPLETE DARE
-- ----------------------------------------------------------------------------
create or replace function complete_dare(p_dare_id uuid, p_completion_kind completion_kind)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_dare dares;
  v_minutes numeric;
  v_multiplier numeric;
  v_points int;
  v_heat_gain int;
begin
  select * into v_dare from dares where id = p_dare_id and couple_id = my_couple_id();
  if v_dare is null then raise exception 'Dare not found.'; end if;
  if v_dare.recipient_id <> auth.uid() then raise exception 'Only the recipient can complete this dare.'; end if;
  if v_dare.status not in ('accepted','in_progress') then raise exception 'This dare is not in a completable state.'; end if;

  if v_dare.dare_type = 'reunion' then
    if v_dare.deadline is null or now() <= v_dare.deadline then v_multiplier := 1.0; else v_multiplier := 0.5; end if;
  else
    v_minutes := extract(epoch from (now() - coalesce(v_dare.responded_at, v_dare.sent_at))) / 60.0;
    if v_minutes <= 30 then v_multiplier := 2.0;
    elsif v_minutes <= 180 then v_multiplier := 1.5;
    elsif v_dare.deadline is null or now() <= v_dare.deadline then v_multiplier := 1.0;
    else v_multiplier := 0.5;
    end if;
  end if;

  v_points := round(v_dare.base_points * v_multiplier);
  update dares set status = 'completed', completed_at = now(), completion_kind = p_completion_kind,
    points_awarded = v_points, score_multiplier = v_multiplier where id = p_dare_id;
  insert into dare_events (dare_id, couple_id, actor_id, event_type, detail)
    values (p_dare_id, v_dare.couple_id, auth.uid(), 'completed', v_points || ' points at x' || v_multiplier);

  v_heat_gain := greatest(1, round(v_points / 10.0));
  update heat_meter set progress = least(100, progress + v_heat_gain), updated_at = now() where couple_id = v_dare.couple_id;
  insert into notifications (couple_id, recipient_id, message, dare_id) values (v_dare.couple_id, v_dare.creator_id, 'Your move was completed.', p_dare_id);
end;
$$;
revoke execute on function complete_dare(uuid, completion_kind) from public, anon;
grant execute on function complete_dare(uuid, completion_kind) to authenticated;

-- ----------------------------------------------------------------------------
-- SCOREBOARD
-- ----------------------------------------------------------------------------
create or replace function get_scoreboard()
returns table (user_id uuid, display_name text, score bigint)
language sql
security definer
stable
set search_path = public
as $$
  select p.id, p.display_name,
    coalesce((select sum(d.points_awarded) from dares d where d.recipient_id = p.id and d.status = 'completed'), 0)
    + coalesce((select sum(sa.points) from score_adjustments sa where sa.user_id = p.id), 0) as score
  from profiles p join couple_members cm on cm.user_id = p.id where cm.couple_id = my_couple_id();
$$;
revoke execute on function get_scoreboard() from public, anon;
grant execute on function get_scoreboard() to authenticated;

-- ----------------------------------------------------------------------------
-- PRIVATE IMAGE STORAGE for boundary cards
-- ----------------------------------------------------------------------------
insert into storage.buckets (id, name, public) values ('boundary-images', 'boundary-images', false) on conflict (id) do nothing;

create policy "boundary_images_select" on storage.objects for select
  using (bucket_id = 'boundary-images' and (storage.foldername(name))[1] = my_couple_id()::text);
create policy "boundary_images_insert" on storage.objects for insert
  with check (bucket_id = 'boundary-images' and (storage.foldername(name))[1] = my_couple_id()::text);
create policy "boundary_images_delete" on storage.objects for delete
  using (bucket_id = 'boundary-images' and (storage.foldername(name))[1] = my_couple_id()::text);

-- ----------------------------------------------------------------------------
-- SEED DATA: starter headings only — no demo cards.
-- ----------------------------------------------------------------------------
insert into boundary_categories (name, sort_order) values
  ('Flirting & Anticipation', 10),
  ('Messages & Voice Notes', 20),
  ('Compliments & Vulnerability', 30),
  ('Clothing & Appearance', 40),
  ('Sensory Experiences', 50),
  ('Physical Affection', 60),
  ('Positions', 70),
  ('Roleplay & Fantasy', 80),
  ('Control & Surrender', 90),
  ('Toys & Accessories', 100),
  ('Public-but-Discreet', 110),
  ('Trying Something New', 120),
  ('Reunion Challenges', 130)
on conflict do nothing;

-- ============================================================================
-- IMPORTANT: Supabase grants EXECUTE directly to the `anon` role on every
-- new function by default — separate from, and in addition to, the general
-- PUBLIC grant. Revoking from PUBLIC alone is NOT enough to stop
-- unauthenticated access; every function above explicitly revokes from
-- BOTH `public` and `anon`. If you ever add a new function, follow the
-- same pattern, and verify with a query like:
--
--   select has_function_privilege('anon', 'your_function_name'::regproc, 'EXECUTE');
--
-- rather than trusting that "revoke ... from public" alone locked it down.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- DELETING BOUNDARY CARDS (added after duplicates showed up from repeated
-- CSV imports) — no delete policy existed before this.
-- ----------------------------------------------------------------------------
create policy "questions_delete_couple" on boundary_questions for delete
  using (couple_id = my_couple_id());

-- If a dare ever references a deleted card, don't block the delete — the
-- dare just keeps its history with no linked card.
alter table dares drop constraint dares_question_id_fkey;
alter table dares add constraint dares_question_id_fkey
  foreign key (question_id) references boundary_questions(id) on delete set null;
