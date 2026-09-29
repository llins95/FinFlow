create or replace function public.reset_finflow_data(
  p_entries jsonb,
  p_client_updated_at timestamptz
)
returns setof public.financial_months
language plpgsql
set search_path = ''
as $$
begin
  delete from public.financial_months
  where user_id = (select auth.uid());

  return query
  insert into public.financial_months (
    user_id,
    year,
    month,
    entries,
    client_updated_at
  )
  values (
    (select auth.uid()),
    2100,
    12,
    p_entries,
    p_client_updated_at
  )
  returning *;
end;
$$;

revoke all on function public.reset_finflow_data(
  jsonb,
  timestamptz
) from public, anon;

grant execute on function public.reset_finflow_data(
  jsonb,
  timestamptz
) to authenticated, service_role;
