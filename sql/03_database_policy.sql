DROP POLICY IF EXISTS "public.users_grant_create" ON public.users;
DROP POLICY IF EXISTS "public.users_grant_read" ON public.users;
DROP POLICY IF EXISTS "public.users_grant_update" ON public.users;
DROP POLICY IF EXISTS "public.users_grant_delete" ON public.users;

DROP POLICY IF EXISTS "public.rooms_grant_create" ON public.rooms;
DROP POLICY IF EXISTS "public.rooms_grant_read" ON public.rooms;
DROP POLICY IF EXISTS "public.rooms_grant_update" ON public.rooms;
DROP POLICY IF EXISTS "public.rooms_grant_delete" ON public.rooms;

DROP POLICY IF EXISTS "public.messages_grant_create" ON public.messages;
DROP POLICY IF EXISTS "public.messages_grant_read" ON public.messages;
DROP POLICY IF EXISTS "public.messages_grant_update" ON public.messages;
DROP POLICY IF EXISTS "public.messages_grant_delete" ON public.messages;

CREATE OR REPLACE FUNCTION public.is_auth()
    RETURNS boolean
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE NOT LEAKPROOF SECURITY INVOKER
    SET search_path = ''
AS $BODY$
BEGIN
  return auth.uid() IS NOT NULL;
end;
$BODY$;

CREATE OR REPLACE FUNCTION public.is_owner(user_id uuid)
    RETURNS boolean
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE NOT LEAKPROOF SECURITY INVOKER
    SET search_path = ''
AS $BODY$
BEGIN
  return auth.uid() = user_id;
end;
$BODY$;

CREATE OR REPLACE FUNCTION public.is_member(members uuid[])
    RETURNS boolean
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE NOT LEAKPROOF SECURITY INVOKER
    SET search_path = ''
AS $BODY$
BEGIN
  return auth.uid() = ANY(members);
end;
$BODY$;

CREATE OR REPLACE FUNCTION public.is_chat_member(room_id bigint)
    RETURNS boolean
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE NOT LEAKPROOF SECURITY INVOKER
    SET search_path = ''
AS $BODY$
DECLARE
  members uuid[];
BEGIN
    SELECT "userIds" INTO members
      FROM public.rooms
      WHERE id = room_id;
  return public.is_member(members);
end;
$BODY$;

CREATE POLICY "public.users_grant_create"
    ON public.users
    AS PERMISSIVE
    FOR INSERT
    TO public
    WITH CHECK (false); -- Created by trigger

CREATE POLICY "public.users_grant_read"
    ON public.users
    AS PERMISSIVE
    FOR SELECT
    TO public
    USING (public.is_auth());

CREATE POLICY "public.users_grant_update"
    ON public.users
    AS PERMISSIVE
    FOR UPDATE
    TO public
    USING (public.is_auth())
    WITH CHECK (public.is_owner(id));

CREATE POLICY "public.users_grant_delete"
    ON public.users
    AS PERMISSIVE
    FOR DELETE
    TO public
    USING (false); -- Delete by foreign key

CREATE POLICY "public.rooms_grant_create"
    ON public.rooms
    AS PERMISSIVE
    FOR INSERT
    TO public
    WITH CHECK (public.is_auth());

CREATE POLICY "public.rooms_grant_read"
    ON public.rooms
    AS PERMISSIVE
    FOR SELECT
    TO public
    USING (public.is_member("userIds"));

CREATE POLICY "public.rooms_grant_update"
    ON public.rooms
    AS PERMISSIVE
    FOR UPDATE
    TO public
    USING (public.is_member("userIds"))
    WITH CHECK (public.is_member("userIds"));

CREATE POLICY "public.rooms_grant_delete"
    ON public.rooms
    AS PERMISSIVE
    FOR DELETE
    TO public
    USING (public.is_member("userIds"));

CREATE POLICY "public.messages_grant_create"
    ON public.messages
    AS PERMISSIVE
    FOR INSERT
    TO public
    WITH CHECK (public.is_chat_member("roomId"));

CREATE POLICY "public.messages_grant_read"
    ON public.messages
    AS PERMISSIVE
    FOR SELECT
    TO public
    USING (public.is_chat_member("roomId"));

CREATE POLICY "public.messages_grant_update"
    ON public.messages
    AS PERMISSIVE
    FOR UPDATE
    TO public
    USING (public.is_chat_member("roomId"))
    WITH CHECK (public.is_chat_member("roomId"));

CREATE POLICY "public.messages_grant_delete"
    ON public.messages
    AS PERMISSIVE
    FOR DELETE
    TO public
    USING (public.is_chat_member("roomId"));