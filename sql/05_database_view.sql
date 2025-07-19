DROP VIEW IF EXISTS public.messages_l;
DROP VIEW IF EXISTS public.rooms_l;

create or replace view public.rooms_l
    with (security_invoker='on') as
select r.id,
       r."imageUrl",
       r.metadata,
       case
           when r.type = 'direct' and auth.uid() is not null then
               (select coalesce(u."firstName", '') || ' ' || coalesce(u."lastName", '')
                from public.users u
                where u.id = any (r."userIds")
                  and u.id <> auth.uid()
                limit 1)
           else
               r.name
           end                          as name,
       r.type,
       r."userIds",
       r."lastMessages",
       r."userRoles",
       r."createdAt",
       r."updatedAt",
       (select jsonb_agg(to_jsonb(u))
        from public.users u
        where u.id = any (r."userIds")) as users
from public.rooms r;


create or replace view public.messages_l
    with (security_invoker='on') as
select m.id,
       m."createdAt",
       m.metadata,
       m.duration,
       m."mimeType",
       m.name,
       m."remoteId",
       m."repliedMessage",
       m."roomId",
       m."showStatus",
       m.size,
       m.status,
       m.type,
       m."updatedAt",
       m.uri,
       m."waveForm",
       m."isLoading",
       m.height,
       m.width,
       m."previewData",
       m."authorId",
       m.text,
       to_jsonb(u) as author,
       to_jsonb(r) as room
from public.messages m
         left join public.users u on u.id = m."authorId"
         left join public.rooms_l r on r.id = m."roomId";
