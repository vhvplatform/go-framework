# Database Separation Strategy

## 🎯 Nguyên Tắc Phân Tách Dữ Liệu (Polyglot Persistence)

Hệ thống sử dụng **3 loại database** với mục đích rõ ràng:

```
┌─────────────────────────────────────────────────────────────┐
│  APPLICATION LAYER                                          │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐    │
│  │   MongoDB    │  │  YugabyteDB  │  │  ClickHouse  │    │
│  │ (Auth Data)  │  │ (Master Data)│  │  (Analytics) │    │
│  └──────────────┘  └──────────────┘  └──────────────┘    │
│       ↓                  ↓                  ↓             │
│   Runtime           Transactional        Time-Series      │
│   Security           ACID Data          Logs & Metrics    │
└─────────────────────────────────────────────────────────────┘
```

---

## 📊 Database Role Definitions

### 1. MongoDB (Authentication Runtime)

**Purpose**: Lưu trữ dữ liệu **runtime authentication** - thay đổi thường xuyên, cần TTL, không cần ACID mạnh.

**Database**: `auth_service`

**Collections**:
```javascript
auth_users              // Password hashes, login identifiers
  - email, username, phone
  - passwordHash (bcrypt)
  - isActive, isVerified
  - mfaEnabled, mfaSecret

tenant_login_configs    // Per-tenant login rules
  - allowedIdentifiers: ["email", "username"]
  - passwordMinLength, require2FA
  - maxLoginAttempts, lockoutDuration

refresh_tokens          // JWT refresh tokens (TTL)
  - token (hashed)
  - userId, tenantId
  - expiresAt (TTL index)
  - revokedAt

login_attempts          // Rate limiting (TTL)
  - identifier, tenantId
  - attemptAt (TTL: 24h)
  - ipAddress, success

user_lockouts           // Temporary account locks
  - userId, tenantId
  - unlockAt
  - reason, isActive
```

**Characteristics**:
- ✅ Fast writes for login attempts
- ✅ TTL indexes auto-cleanup
- ✅ Flexible schema cho security configs
- ✅ No foreign keys needed
- ❌ NOT for master data
- ❌ NOT for user-tenant relationships

---

### 2. YugabyteDB (Transactional Master Data)

**Purpose**: Lưu trữ **master data & relationships** - cần ACID, foreign keys, complex queries.

**Database**: `vhv_saas` 

**Schema**: `core`

**Key Tables**:

#### Core Identity & Tenancy
```sql
users                   -- Global user identity (NO tenant_id)
  - _id (UUID v7)
  - email (UNIQUE globally)
  - full_name, phone_number, avatar_url
  - status, is_support_staff, mfa_enabled
  - ⚠️ NO password_hash (stored in MongoDB)

tenants                 -- Organization/tenant master data
  - _id, code (UNIQUE)
  - name, tier, status
  - data_region, compliance_level
  - profile, settings (JSONB)

tenant_members          -- User ↔ Tenant relationships (ACID)
  - _id
  - tenant_id → tenants(_id) FK
  - user_id → users(_id) FK
  - display_name, status
  - custom_data (JSONB) - roles, permissions
  - UNIQUE(tenant_id, user_id)
```

#### Authorization (RBAC)
```sql
roles                   -- Role definitions
  - _id, tenant_id
  - name, description
  - permissions (TEXT[])

permissions             -- Permission definitions
  - _id, resource, action
  - description

user_roles              -- User role assignments
  - member_id → tenant_members(_id)
  - role_id → roles(_id)
  - scope_type, scope_values
```

#### Other Master Data
```sql
departments, user_groups, api_keys, webhooks, etc.
```

**Characteristics**:
- ✅ ACID transactions
- ✅ Foreign key constraints
- ✅ Complex JOINs
- ✅ PostgreSQL compatible
- ✅ Horizontal scalability
- ❌ NOT for high-frequency writes (login attempts)
- ❌ NOT for temporary data

---

### 3. ClickHouse (Analytics & Logs)

**Purpose**: Lưu trữ **time-series data, logs, metrics** - write-heavy, analytical queries.

**Database**: `vhv_saas`

**Key Tables**:
```sql
auth_logs               -- Authentication events
  - timestamp, user_id, tenant_id
  - event_type, ip_address, user_agent
  - success, failure_reason
  
security_audit_logs     -- Security events
  - timestamp, actor_id, action
  - resource_type, resource_id
  - metadata

api_usage_logs          -- API call tracking
  - timestamp, tenant_id, user_id
  - endpoint, method, status_code
  - response_time, request_size

user_registration_logs  -- Signup tracking
  - timestamp, user_id, tenant_id
  - source, referrer
```

**Characteristics**:
- ✅ Columnar storage (fast aggregations)
- ✅ Real-time ingestion
- ✅ Compression (1:10 ratio)
- ✅ Skipping indexes for fast filters
- ❌ NOT for updates/deletes
- ❌ NOT for transactional data

---

## 🔍 Data Flow Examples

### Login Flow

```
1. User submits credentials
   ↓
2. Check auth_users (MongoDB)
   - Validate password hash
   - Check isActive, isVerified
   ↓
3. Check tenant_members (YugabyteDB)
   - Get user's tenants
   - Get roles & permissions
   ↓
4. Generate JWT tokens
   - Save refresh_token (MongoDB)
   - Set expiresAt with TTL
   ↓
5. Log auth event (ClickHouse)
   - auth_logs: success/failure
   - Include IP, user-agent
```

### Create User Flow

```
1. Start YugabyteDB transaction
   ↓
2. INSERT INTO users (YugabyteDB)
   - email, full_name, phone
   - status = 'ACTIVE'
   ↓
3. INSERT INTO tenant_members (YugabyteDB)
   - user_id, tenant_id
   - display_name, custom_data
   ↓
4. COMMIT transaction
   ↓
5. INSERT INTO auth_users (MongoDB)
   - email, passwordHash
   - isActive = true
   ↓
6. Log registration (ClickHouse)
   - user_registration_logs
```

---

## ⚠️ Common Anti-Patterns (AVOID)

### ❌ WRONG: Storing user_tenants in MongoDB

```javascript
// DON'T DO THIS
db.user_tenants.insertOne({
    userId: "...",
    tenantId: "...",
    roles: ["admin"],
    isActive: true
});
```

**Why wrong?**
- No foreign key enforcement
- Can't JOIN with users/tenants
- Duplicate data across databases
- ACID integrity broken

### ✅ CORRECT: Store in YugabyteDB

```sql
-- DO THIS
INSERT INTO tenant_members (
    _id, tenant_id, user_id, 
    display_name, status, custom_data
) VALUES (...);
```

---

### ❌ WRONG: Storing roles in MongoDB

```javascript
// DON'T DO THIS
db.roles.insertMany([
    { name: "admin", permissions: ["*"] },
    { name: "user", permissions: ["read:profile"] }
]);
```

**Why wrong?**
- Authorization is business logic
- Needs referential integrity with tenant_members
- Requires complex queries (inheritance, scoping)

### ✅ CORRECT: Store in YugabyteDB

```sql
-- DO THIS
CREATE TABLE roles (
    _id UUID PRIMARY KEY,
    tenant_id UUID REFERENCES tenants(_id),
    name VARCHAR(100) NOT NULL,
    permissions TEXT[] NOT NULL,
    UNIQUE(tenant_id, name)
);
```

---

### ❌ WRONG: Storing logs in YugabyteDB

```sql
-- DON'T DO THIS
CREATE TABLE auth_logs (
    _id UUID PRIMARY KEY,
    user_id UUID,
    timestamp TIMESTAMPTZ,
    event_type VARCHAR(50),
    ip_address INET
);
-- Will have millions of rows, slow INSERTs
```

**Why wrong?**
- Log data is write-heavy
- Rarely updated/deleted
- Analytical queries need aggregations
- Wastes transactional DB resources

### ✅ CORRECT: Store in ClickHouse

```sql
-- DO THIS
CREATE TABLE auth_logs (
    timestamp DateTime,
    user_id String,
    event_type String,
    ip_address String,
    INDEX idx_user_id user_id TYPE bloom_filter GRANULARITY 1
) ENGINE = MergeTree()
ORDER BY (timestamp, user_id);
```

---

## 📋 Quick Reference Table

| Data Type | MongoDB | YugabyteDB | ClickHouse |
|-----------|---------|------------|------------|
| Password hashes | ✅ | ❌ | ❌ |
| User master data | ❌ | ✅ | ❌ |
| User-tenant links | ❌ | ✅ | ❌ |
| Roles & permissions | ❌ | ✅ | ❌ |
| Refresh tokens | ✅ | ❌ | ❌ |
| Login attempts | ✅ | ❌ | ❌ |
| Rate limiting | ✅ | ❌ | ❌ |
| Auth event logs | ❌ | ❌ | ✅ |
| API usage logs | ❌ | ❌ | ✅ |
| Audit trails | ❌ | ❌ | ✅ |
| Business reports | ❌ | ❌ | ✅ |

---

## 🎓 Decision Checklist

**Use MongoDB when:**
- [ ] Data is authentication-specific (passwords, tokens)
- [ ] Frequent writes (login attempts, session tracking)
- [ ] TTL/auto-cleanup needed
- [ ] No foreign key relationships required
- [ ] Flexible schema preferred

**Use YugabyteDB when:**
- [ ] Data is master/reference data
- [ ] ACID transactions required
- [ ] Foreign keys needed
- [ ] Complex JOINs involved
- [ ] Data rarely deleted (soft delete)

**Use ClickHouse when:**
- [ ] Time-series/log data
- [ ] Write-once, read-many pattern
- [ ] Analytical queries (aggregations, GROUP BY)
- [ ] High write throughput needed
- [ ] Data retention policies required

---

## 🔗 Related Documents

- [CoreCollections.md](./CoreCollections.md) - Complete table schemas
- [YugabyteDB_CoreSchema.sql](./YugabyteDB_CoreSchema.sql) - SQL DDL
- [clickhouse/telemetry_schema.sql](./clickhouse/telemetry_schema.sql) - ClickHouse DDL
- [001_init_multi_tenant.js](../../apps/auth/migrations/001_init_multi_tenant.js) - MongoDB setup

---

**Last Updated**: 2026-01-19  
**Version**: 1.0.0  
**Maintainer**: Architecture Team
