-- ============================================
-- BillMind - Supabase Veritabanı Tabloları
-- Bu SQL'i Supabase Dashboard > SQL Editor'de çalıştırın.
-- ============================================

-- 1) Kullanıcı Profilleri Tablosu
-- Supabase Auth ile otomatik bağlanır (auth.users.id = profiles.id)
CREATE TABLE IF NOT EXISTS profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    full_name TEXT,
    email TEXT,
    avatar_url TEXT,
    company_name TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Yeni kayıt olunduğunda otomatik profil oluştur
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, full_name, email)
    VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'full_name', ''),
        NEW.email
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger: auth.users'a kayıt eklenince profil oluştur
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_user();

-- 2) Belgeler / Faturalar Tablosu
CREATE TABLE IF NOT EXISTS documents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    file_name TEXT NOT NULL,
    file_url TEXT DEFAULT '',
    file_type TEXT DEFAULT '',
    file_size_bytes BIGINT DEFAULT 0,
    status TEXT DEFAULT 'BEKLEMEDE',
    uploaded_at TIMESTAMPTZ DEFAULT NOW(),
    company_name TEXT DEFAULT '',
    invoice_number TEXT DEFAULT '',
    invoice_date TIMESTAMPTZ,
    total_amount DECIMAL(15,2) DEFAULT 0,
    currency TEXT DEFAULT 'TRY',
    category TEXT DEFAULT '',
    raw_ocr_text TEXT DEFAULT ''
);

-- İndeksler (performans)
CREATE INDEX IF NOT EXISTS idx_documents_user_id ON documents(user_id);
CREATE INDEX IF NOT EXISTS idx_documents_uploaded_at ON documents(uploaded_at DESC);
CREATE INDEX IF NOT EXISTS idx_documents_status ON documents(status);
CREATE INDEX IF NOT EXISTS idx_documents_category ON documents(category);

-- 3) Row Level Security (RLS)
-- Her kullanıcı sadece kendi verilerini görebilir/değiştirebilir

ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE documents ENABLE ROW LEVEL SECURITY;

-- Profiles politikaları
CREATE POLICY "Kullanıcılar kendi profilini görebilir"
    ON profiles FOR SELECT
    USING (auth.uid() = id);

CREATE POLICY "Kullanıcılar kendi profilini güncelleyebilir"
    ON profiles FOR UPDATE
    USING (auth.uid() = id);

-- Documents politikaları
CREATE POLICY "Kullanıcılar kendi belgelerini görebilir"
    ON documents FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Kullanıcılar belge ekleyebilir"
    ON documents FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Kullanıcılar kendi belgelerini güncelleyebilir"
    ON documents FOR UPDATE
    USING (auth.uid() = user_id);

CREATE POLICY "Kullanıcılar kendi belgelerini silebilir"
    ON documents FOR DELETE
    USING (auth.uid() = user_id);
