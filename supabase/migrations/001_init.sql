-- Migration: 001_init.sql
-- Description: Membuat tabel kos dan mengonfigurasi Row Level Security (RLS)

-- 1. Buat tabel kos
CREATE TABLE IF NOT EXISTS public.kos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    owner_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    area TEXT NOT NULL,
    price BIGINT NOT NULL CHECK (price >= 0),
    type TEXT NOT NULL CHECK (type IN ('Putra', 'Putri', 'Campur')),
    facilities TEXT[] NOT NULL DEFAULT '{}',
    rooms_available INTEGER NOT NULL DEFAULT 0 CHECK (rooms_available >= 0),
    contact_name TEXT NOT NULL,
    contact_phone TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- 2. Index untuk mendukung kecepatan pencarian dan filter
CREATE INDEX IF NOT EXISTS idx_kos_area_lower ON public.kos (lower(area));
CREATE INDEX IF NOT EXISTS idx_kos_price ON public.kos (price);
CREATE INDEX IF NOT EXISTS idx_kos_type ON public.kos (type);
CREATE INDEX IF NOT EXISTS idx_kos_owner_id ON public.kos (owner_id);

-- 3. Aktifkan Row Level Security (RLS)
ALTER TABLE public.kos ENABLE ROW LEVEL SECURITY;

-- 4. Definisi Policy RLS

-- US01, US02, US03, US06: Publik (anon & authenticated) dapat melihat seluruh listing kos
CREATE POLICY "Public can view all kos listings"
    ON public.kos
    FOR SELECT
    USING (true);

-- US05: Pemilik kos terautentikasi dapat menambah listing miliknya
CREATE POLICY "Authenticated owners can insert their own kos"
    ON public.kos
    FOR INSERT
    WITH CHECK (auth.uid() = owner_id);

-- US06: Pemilik kos hanya dapat mengubah listing miliknya sendiri
CREATE POLICY "Owners can update their own kos"
    ON public.kos
    FOR UPDATE
    USING (auth.uid() = owner_id)
    WITH CHECK (auth.uid() = owner_id);

-- US06: Pemilik kos hanya dapat menghapus listing miliknya sendiri
CREATE POLICY "Owners can delete their own kos"
    ON public.kos
    FOR DELETE
    USING (auth.uid() = owner_id);
