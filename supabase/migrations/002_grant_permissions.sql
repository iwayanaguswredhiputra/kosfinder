-- Migration: 002_grant_permissions.sql
-- Description: Memberikan izin skema dan akses tabel kos untuk anon dan authenticated

GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT SELECT ON TABLE public.kos TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.kos TO authenticated;
