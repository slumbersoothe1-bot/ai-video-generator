-- Public storage for generated image and video artifacts.
insert into storage.buckets (id, name, public)
values ('generated-media', 'generated-media', true)
on conflict (id) do update set public = true;

drop policy if exists "public read generated media" on storage.objects;
create policy "public read generated media" on storage.objects
for select using (bucket_id = 'generated-media');
