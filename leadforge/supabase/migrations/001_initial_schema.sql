-- LeadForge AI — Initial Supabase Schema
-- 14 tables: businesses, contacts, locations, business_reviews, business_socials,
-- website_audits, business_intelligence, leads, campaigns, generated_websites,
-- emails, interactions, workflow_runs, agent_tasks

-- Enable extensions
CREATE EXTENSION IF NOT EXISTS "pgvector";
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================
-- 1. BUSINESSES
-- ============================================
CREATE TABLE businesses (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    category TEXT,
    sub_category TEXT,
    description TEXT,
    business_type TEXT,
    brand_name TEXT,
    source TEXT,
    external_id TEXT,
    phone TEXT,
    email TEXT,
    website_url TEXT,
    has_website BOOLEAN DEFAULT false,
    rating DECIMAL(2,1),
    review_count INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(source, external_id)
);

CREATE INDEX idx_businesses_category ON businesses(category);
CREATE INDEX idx_businesses_has_website ON businesses(has_website);
CREATE INDEX idx_businesses_rating ON businesses(rating);
CREATE INDEX idx_businesses_source_external ON businesses(source, external_id);

-- ============================================
-- 2. CONTACTS
-- ============================================
CREATE TABLE contacts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    business_id UUID REFERENCES businesses(id) ON DELETE CASCADE,
    phone TEXT,
    secondary_phone TEXT,
    email TEXT,
    secondary_email TEXT,
    whatsapp TEXT,
    contact_page TEXT,
    likely_owner TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_contacts_business_id ON contacts(business_id);
CREATE INDEX idx_contacts_email ON contacts(email);

-- ============================================
-- 3. LOCATIONS
-- ============================================
CREATE TABLE locations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    business_id UUID REFERENCES businesses(id) ON DELETE CASCADE,
    country TEXT,
    country_code TEXT,
    state TEXT,
    region TEXT,
    city TEXT,
    area TEXT,
    postal_code TEXT,
    full_address TEXT,
    latitude DECIMAL(10,7),
    longitude DECIMAL(10,7),
    timezone TEXT
);

CREATE INDEX idx_locations_business_id ON locations(business_id);
CREATE INDEX idx_locations_city ON locations(city);
CREATE INDEX idx_locations_geo ON locations(latitude, longitude);

-- ============================================
-- 4. BUSINESS_REVIEWS
-- ============================================
CREATE TABLE business_reviews (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    business_id UUID REFERENCES businesses(id) ON DELETE CASCADE,
    review_text TEXT,
    rating DECIMAL(2,1),
    review_date DATE,
    review_source TEXT,
    sentiment TEXT,
    topics TEXT[],
    complaints TEXT[],
    strengths TEXT[],
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_reviews_business_id ON business_reviews(business_id);
CREATE INDEX idx_reviews_sentiment ON business_reviews(sentiment);
CREATE INDEX idx_reviews_rating ON business_reviews(rating);

-- ============================================
-- 5. BUSINESS_SOCIALS
-- ============================================
CREATE TABLE business_socials (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    business_id UUID REFERENCES businesses(id) ON DELETE CASCADE,
    instagram TEXT,
    facebook TEXT,
    linkedin TEXT,
    youtube TEXT,
    tiktok TEXT,
    twitter TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_socials_business_id ON business_socials(business_id);

-- ============================================
-- 6. WEBSITE_AUDITS
-- ============================================
CREATE TABLE website_audits (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    business_id UUID REFERENCES businesses(id) ON DELETE CASCADE,
    website_url TEXT,
    website_status TEXT,
    domain TEXT,
    domain_age INTEGER,
    ssl_status TEXT,
    mobile_friendly BOOLEAN,
    performance_score INTEGER,
    seo_score INTEGER,
    website_quality_score INTEGER,
    audit_raw JSONB,
    audited_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_audits_business_id ON website_audits(business_id);
CREATE INDEX idx_audits_quality_score ON website_audits(website_quality_score);

-- ============================================
-- 7. BUSINESS_INTELLIGENCE
-- ============================================
CREATE TABLE business_intelligence (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    business_id UUID REFERENCES businesses(id) ON DELETE CASCADE,
    summary TEXT,
    strengths TEXT[],
    weaknesses TEXT[],
    customer_needs TEXT[],
    customer_complaints TEXT[],
    recommended_services TEXT[],
    website_opportunity_score INTEGER,
    lead_score INTEGER,
    website_strategy TEXT,
    marketing_strategy TEXT,
    embedding VECTOR(1536),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_intel_business_id ON business_intelligence(business_id);
CREATE INDEX idx_intel_lead_score ON business_intelligence(lead_score);
CREATE INDEX idx_intel_embedding ON business_intelligence USING ivfflat (embedding vector_cosine_ops);

-- ============================================
-- 8. LEADS
-- ============================================
CREATE TABLE leads (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    business_id UUID REFERENCES businesses(id) ON DELETE CASCADE,
    status TEXT DEFAULT 'NEW' CHECK (
        status IN ('NEW','RESEARCHED','QUALIFIED','WEBSITE_GENERATED',
                   'CONTACTED','REPLIED','MEETING','CLIENT','REJECTED')
    ),
    lead_score INTEGER,
    website_opportunity_score INTEGER,
    estimated_business_value DECIMAL(12,2),
    assigned_to TEXT,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_leads_status ON leads(status);
CREATE INDEX idx_leads_business_id ON leads(business_id);
CREATE INDEX idx_leads_score ON leads(lead_score DESC);

-- ============================================
-- 9. CAMPAIGNS
-- ============================================
CREATE TABLE campaigns (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    description TEXT,
    target_category TEXT,
    target_location TEXT,
    status TEXT DEFAULT 'DRAFT' CHECK (status IN ('DRAFT','ACTIVE','PAUSED','COMPLETED')),
    total_sent INTEGER DEFAULT 0,
    total_opened INTEGER DEFAULT 0,
    total_clicked INTEGER DEFAULT 0,
    total_replied INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_campaigns_status ON campaigns(status);

-- ============================================
-- 10. GENERATED_WEBSITES
-- ============================================
CREATE TABLE generated_websites (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    business_id UUID REFERENCES businesses(id) ON DELETE CASCADE,
    lead_id UUID REFERENCES leads(id) ON DELETE SET NULL,
    framework TEXT DEFAULT 'nextjs',
    repository TEXT,
    preview_url TEXT,
    status TEXT DEFAULT 'PENDING' CHECK (status IN ('PENDING','GENERATING','READY','DEPLOYED','FAILED')),
    generated_at TIMESTAMPTZ,
    deployed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_websites_business_id ON generated_websites(business_id);
CREATE INDEX idx_websites_status ON generated_websites(status);

-- ============================================
-- 11. EMAILS
-- ============================================
CREATE TABLE emails (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    business_id UUID REFERENCES businesses(id) ON DELETE CASCADE,
    lead_id UUID REFERENCES leads(id) ON DELETE SET NULL,
    campaign_id UUID REFERENCES campaigns(id) ON DELETE SET NULL,
    contact_email TEXT,
    subject TEXT,
    message TEXT,
    sent_at TIMESTAMPTZ,
    opened_at TIMESTAMPTZ,
    clicked_at TIMESTAMPTZ,
    replied_at TIMESTAMPTZ,
    status TEXT DEFAULT 'DRAFT' CHECK (status IN ('DRAFT','QUEUED','SENT','OPENED','CLICKED','REPLIED','BOUNCED','FAILED')),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_emails_business_id ON emails(business_id);
CREATE INDEX idx_emails_campaign_id ON emails(campaign_id);
CREATE INDEX idx_emails_status ON emails(status);

-- ============================================
-- 12. INTERACTIONS
-- ============================================
CREATE TABLE interactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    business_id UUID REFERENCES businesses(id) ON DELETE CASCADE,
    lead_id UUID REFERENCES leads(id) ON DELETE SET NULL,
    type TEXT CHECK (type IN ('EMAIL','CALL','MEETING','WHATSAPP','SMS','OTHER')),
    direction TEXT CHECK (direction IN ('INBOUND','OUTBOUND')),
    summary TEXT,
    outcome TEXT,
    interaction_at TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_interactions_business_id ON interactions(business_id);
CREATE INDEX idx_interactions_type ON interactions(type);

-- ============================================
-- 13. WORKFLOW_RUNS
-- ============================================
CREATE TABLE workflow_runs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    workflow_name TEXT NOT NULL,
    n8n_execution_id TEXT,
    status TEXT DEFAULT 'PENDING' CHECK (status IN ('PENDING','RUNNING','SUCCESS','FAILED','CANCELLED')),
    input_data JSONB,
    output_data JSONB,
    error_message TEXT,
    started_at TIMESTAMPTZ DEFAULT NOW(),
    completed_at TIMESTAMPTZ
);

CREATE INDEX idx_workflow_runs_status ON workflow_runs(status);
CREATE INDEX idx_workflow_runs_name ON workflow_runs(workflow_name);

-- ============================================
-- 14. AGENT_TASKS
-- ============================================
CREATE TABLE agent_tasks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    business_id UUID REFERENCES businesses(id) ON DELETE CASCADE,
    agent_type TEXT NOT NULL CHECK (agent_type IN (
        'RESEARCH','REVIEW_ANALYST','LEAD_SCORING',
        'WEBSITE_STRATEGIST','WEBSITE_DEVELOPER',
        'OUTREACH','REPLY_ANALYST'
    )),
    status TEXT DEFAULT 'PENDING' CHECK (status IN ('PENDING','RUNNING','COMPLETED','FAILED')),
    input_data JSONB,
    output_data JSONB,
    error_message TEXT,
    tokens_used INTEGER,
    cost DECIMAL(10,4),
    started_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_agent_tasks_business_id ON agent_tasks(business_id);
CREATE INDEX idx_agent_tasks_status ON agent_tasks(status);
CREATE INDEX idx_agent_tasks_agent_type ON agent_tasks(agent_type);

-- ============================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================
ALTER TABLE businesses ENABLE ROW LEVEL SECURITY;
ALTER TABLE contacts ENABLE ROW LEVEL SECURITY;
ALTER TABLE locations ENABLE ROW LEVEL SECURITY;
ALTER TABLE business_reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE business_socials ENABLE ROW LEVEL SECURITY;
ALTER TABLE website_audits ENABLE ROW LEVEL SECURITY;
ALTER TABLE business_intelligence ENABLE ROW LEVEL SECURITY;
ALTER TABLE leads ENABLE ROW LEVEL SECURITY;
ALTER TABLE campaigns ENABLE ROW LEVEL SECURITY;
ALTER TABLE generated_websites ENABLE ROW LEVEL SECURITY;
ALTER TABLE emails ENABLE ROW LEVEL SECURITY;
ALTER TABLE interactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE workflow_runs ENABLE ROW LEVEL SECURITY;
ALTER TABLE agent_tasks ENABLE ROW LEVEL SECURITY;

-- Allow authenticated users full access (adjust for production)
CREATE POLICY "Authenticated full access" ON businesses FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Authenticated full access" ON contacts FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Authenticated full access" ON locations FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Authenticated full access" ON business_reviews FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Authenticated full access" ON business_socials FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Authenticated full access" ON website_audits FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Authenticated full access" ON business_intelligence FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Authenticated full access" ON leads FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Authenticated full access" ON campaigns FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Authenticated full access" ON generated_websites FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Authenticated full access" ON emails FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Authenticated full access" ON interactions FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Authenticated full access" ON workflow_runs FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Authenticated full access" ON agent_tasks FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- ============================================
-- UPDATED_AT TRIGGER
-- ============================================
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_businesses_updated_at BEFORE UPDATE ON businesses FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER update_leads_updated_at BEFORE UPDATE ON leads FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER update_campaigns_updated_at BEFORE UPDATE ON campaigns FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER update_intel_updated_at BEFORE UPDATE ON business_intelligence FOR EACH ROW EXECUTE FUNCTION update_updated_at();