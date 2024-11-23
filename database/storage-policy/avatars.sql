
-- Allow write access for the owner of the file
((bucket_id = 'avatars'::text) AND ((storage.foldername(name))[1] = ("auth"."jwt"() ->> 'wallet_address'::"text")::text))

-- Allow read access for all users
bucket_id = 'avatars'
