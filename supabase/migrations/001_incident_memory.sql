create extension if not exists pgcrypto;

create table if not exists public.incidents (
  id text primary key,
  title text not null,
  description text not null,
  service text not null,
  severity text not null check (severity in ('Critical','High','Medium','Low')),
  status text not null default 'Open',
  outcome text not null default 'open' check (outcome in ('open','successful','failed')),
  environment text not null default 'Production',
  error_logs text,
  root_cause text,
  resolution text,
  failed_attempts text,
  resolution_minutes integer,
  troubleshooting_steps jsonb not null default '[]'::jsonb,
  failed_solutions jsonb not null default '[]'::jsonb,
  is_sample boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.incidents add column if not exists outcome text not null default 'open';
alter table public.incidents add column if not exists environment text not null default 'Production';
alter table public.incidents add column if not exists failed_attempts text;
alter table public.incidents add column if not exists resolution_minutes integer;
alter table public.incidents add column if not exists troubleshooting_steps jsonb not null default '[]'::jsonb;
alter table public.incidents add column if not exists failed_solutions jsonb not null default '[]'::jsonb;
alter table public.incidents add column if not exists is_sample boolean not null default false;

create index if not exists incidents_created_at_idx on public.incidents (created_at desc);
create index if not exists incidents_service_idx on public.incidents (service);
create index if not exists incidents_severity_status_idx on public.incidents (severity, status);

create table if not exists public.incident_memories (
  id uuid primary key default gen_random_uuid(),
  incident_id text not null unique references public.incidents(id) on delete cascade,
  memory_content text not null,
  service text,
  severity text,
  error_logs text,
  root_cause text,
  resolution text,
  failed_attempts text,
  resolution_steps jsonb not null default '[]'::jsonb,
  outcome text not null default 'open' check (outcome in ('open','successful','failed')),
  hindsight_memory_id text,
  hindsight_document_id text,
  hindsight_operation_id text,
  hindsight_retained boolean not null default false,
  retention_error text,
  created_at timestamptz not null default now()
);

alter table public.incident_memories add column if not exists service text;
alter table public.incident_memories add column if not exists severity text;
alter table public.incident_memories add column if not exists error_logs text;
alter table public.incident_memories add column if not exists resolution text;
alter table public.incident_memories add column if not exists failed_attempts text;
alter table public.incident_memories add column if not exists hindsight_document_id text;
alter table public.incident_memories add column if not exists hindsight_operation_id text;
alter table public.incident_memories add column if not exists hindsight_retained boolean not null default false;
alter table public.incident_memories add column if not exists retention_error text;

create index if not exists incident_memories_retained_idx on public.incident_memories (hindsight_retained, created_at desc);

create table if not exists public.memory_activity (
  id uuid primary key default gen_random_uuid(),
  incident_id text not null references public.incidents(id) on delete cascade,
  activity_type text not null check (activity_type in ('retained','retention_failed','recalled')),
  activity_description text not null,
  created_at timestamptz not null default now()
);

create index if not exists memory_activity_created_at_idx on public.memory_activity (created_at desc);

create table if not exists public.incident_notifications (
  id uuid primary key default gen_random_uuid(),
  incident_id text not null references public.incidents(id) on delete cascade,
  notification_type text not null,
  title text not null,
  body text not null,
  created_at timestamptz not null default now(),
  read_at timestamptz
);

create index if not exists incident_notifications_created_at_idx on public.incident_notifications (created_at desc);
create index if not exists incident_notifications_unread_idx on public.incident_notifications (read_at) where read_at is null;

-- Access is server-only through the Supabase service role key. Do not expose it to Vite.
alter table public.incidents enable row level security;
alter table public.incident_memories enable row level security;
alter table public.memory_activity enable row level security;
alter table public.incident_notifications enable row level security;
