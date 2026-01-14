# Migration Plan: Apply go-shared to Services

**Date:** January 13, 2026  
**Scope:** User, Tenant, Auth, API Gateway

## 🎯 OBJECTIVES

1. Migrate từ MongoDB → YugabyteDB cho transactional data
2. Apply go-shared packages (yugabyte, outbox, tracing, interceptor)
3. Configure với connection strings provided
4. Maintain MongoDB cho tenant configs (theo Polyglot Persistence)
5. Setup Debezium CDC cho outbox pattern

---

## 📊 CURRENT STATE ANALYSIS

### User Service
- **Database:** MongoDB (users, user_tenants, user_preferences)
- **Entities:** User, UserTenant, UserPreferences
- **Repository:** user_repository.go (MongoDB driver)
- **Issues:**
  - ❌ No ACID transactions across collections
  - ❌ No transactional outbox
  - ❌ No distributed tracing
  - ✅ Has soft delete (deletedAt)
  - ✅ Has tenant isolation (tenantId)
  - ✅ Has optimistic locking (version)

### Tenant Service
- **Database:** MongoDB (tenants, tenant_users, service_configs)
- **Entities:** Tenant, TenantUser, ServiceConfig
- **Repository:** tenant_repository.go, service_config_repository.go
- **Issues:**
  - ❌ No ACID transactions
  - ❌ No transactional outbox
  - ❌ No distributed tracing
  - ✅ Has soft delete
  - ✅ Has tenant isolation

### Auth Service
- **Current:** JWT generation, login/register
- **No database entities** - mostly stateless
- **Issues:**
  - ❌ No distributed tracing
  - ❌ gRPC interceptors not standardized

### API Gateway
- **Current:** Routing, authentication, tenant extraction
- **Issues:**
  - ❌ No distributed tracing propagation
  - ❌ gRPC client interceptors not standardized

---

## 🔄 MIGRATION STRATEGY

### Phase 1: Infrastructure (Priority: CRITICAL)

#### Task 1.1: Create Shared Config Package ✅
```go
// pkg/database/yugabyte.go
type YugabyteConfig struct {
    Host     string
    Port     int
    User     string
    Password string
    Database string
    SSLMode  string
}

// pkg/database/clickhouse.go
type ClickHouseConfig struct {
    Host     string
    Port     int
    User     string
    Password string
    Database string
}
```

**Connection Strings:**
```env
# YugabyteDB (ACID, Transactional)
YUGABYTE_URL=postgresql://vhv_saas:yugabyteDBVHV@2627@192.168.1.207:30433/vhv_saas?sslmode=require

# ClickHouse (Analytics, Logs via Kafka)
CLICKHOUSE_HOST=clickhouse-clickhouse.clickhouse.svc.cluster.local
CLICKHOUSE_PORT=9000
CLICKHOUSE_USER=admin
CLICKHOUSE_PASSWORD=clickhouseSAAS2627
CLICKHOUSE_DB=default

# MongoDB (Keep for Tenant Configs only)
MONGODB_URI=mongodb://...
```

#### Task 1.2: Create Database Migrations
```sql
-- YugabyteDB Schema

-- Users Table (Migrated from MongoDB)
CREATE TABLE users (
    _id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email            VARCHAR(255) NOT NULL UNIQUE,
    password_hash    TEXT,
    phone            VARCHAR(50),
    avatar_url       TEXT,
    is_active        BOOLEAN DEFAULT true,
    
    -- Standard fields
    tenant_id        UUID NOT NULL,
    version          BIGINT DEFAULT 1,
    created_at       TIMESTAMPTZ DEFAULT NOW(),
    updated_at       TIMESTAMPTZ DEFAULT NOW(),
    deleted_at       TIMESTAMPTZ NULL,
    created_by       UUID,
    updated_by       UUID,
    
    INDEX idx_users_tenant (tenant_id, deleted_at),
    INDEX idx_users_email (email) WHERE deleted_at IS NULL
);

-- User Tenants (Many-to-Many)
CREATE TABLE user_tenants (
    _id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id          UUID NOT NULL REFERENCES users(_id),
    tenant_id        UUID NOT NULL,
    roles            TEXT[], -- Array of role names
    first_name       VARCHAR(100),
    last_name        VARCHAR(100),
    is_active        BOOLEAN DEFAULT true,
    joined_at        TIMESTAMPTZ DEFAULT NOW(),
    
    -- Standard fields
    version          BIGINT DEFAULT 1,
    created_at       TIMESTAMPTZ DEFAULT NOW(),
    updated_at       TIMESTAMPTZ DEFAULT NOW(),
    deleted_at       TIMESTAMPTZ NULL,
    created_by       UUID,
    updated_by       UUID,
    
    UNIQUE(user_id, tenant_id),
    INDEX idx_user_tenants_tenant (tenant_id, deleted_at),
    INDEX idx_user_tenants_user (user_id, deleted_at)
);

-- Tenants Table
CREATE TABLE tenants (
    _id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name                 VARCHAR(255) NOT NULL UNIQUE,
    domain               VARCHAR(255) UNIQUE,
    subscription_tier    VARCHAR(50) DEFAULT 'free',
    is_active            BOOLEAN DEFAULT true,
    default_service      VARCHAR(100),
    
    -- Standard fields (tenant_id is self-referential)
    tenant_id            UUID NOT NULL, -- Points to itself
    version              BIGINT DEFAULT 1,
    created_at           TIMESTAMPTZ DEFAULT NOW(),
    updated_at           TIMESTAMPTZ DEFAULT NOW(),
    deleted_at           TIMESTAMPTZ NULL,
    created_by           UUID,
    updated_by           UUID,
    
    INDEX idx_tenants_name (name) WHERE deleted_at IS NULL,
    INDEX idx_tenants_domain (domain) WHERE deleted_at IS NULL
);

-- Outbox Events (Transactional Outbox Pattern)
CREATE TABLE outbox_events (
    _id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    aggregate_id     UUID NOT NULL,
    aggregate_type   VARCHAR(50) NOT NULL,
    event_type       VARCHAR(50) NOT NULL,
    payload          JSONB NOT NULL,
    tenant_id        UUID NOT NULL,
    trace_id         VARCHAR(64),
    created_at       TIMESTAMPTZ DEFAULT NOW(),
    published_at     TIMESTAMPTZ NULL,
    version          BIGINT DEFAULT 1,
    metadata         JSONB,
    
    INDEX idx_outbox_pending (tenant_id, published_at, created_at) WHERE published_at IS NULL,
    INDEX idx_outbox_aggregate (aggregate_id, aggregate_type),
    INDEX idx_outbox_trace (trace_id)
);
```

---

### Phase 2: User Service Migration (Priority: HIGH)

#### Task 2.1: Update Entities to use BaseEntity

**Before (MongoDB):**
```go
type User struct {
    ID           primitive.ObjectID `bson:"_id,omitempty" json:"id"`
    Email        string             `bson:"email" json:"email"`
    PasswordHash string             `bson:"passwordHash,omitempty" json:"-"`
    CreatedAt    time.Time          `bson:"createdAt" json:"createdAt"`
    // ...
}
```

**After (YugabyteDB + go-shared):**
```go
import "github.com/vhvplatform/go-shared/yugabyte"

type User struct {
    yugabyte.BaseEntity                     // ✅ Standard fields
    Email        string `db:"email" json:"email"`
    PasswordHash string `db:"password_hash" json:"-"`
    Phone        string `db:"phone" json:"phone,omitempty"`
    AvatarURL    string `db:"avatar_url" json:"avatarUrl,omitempty"`
    IsActive     bool   `db:"is_active" json:"isActive"`
}

type UserTenant struct {
    yugabyte.BaseEntity
    UserID    string   `db:"user_id" json:"userId"`
    Roles     []string `db:"roles" json:"roles"` // PostgreSQL array
    FirstName string   `db:"first_name" json:"firstName,omitempty"`
    LastName  string   `db:"last_name" json:"lastName,omitempty"`
    IsActive  bool     `db:"is_active" json:"isActive"`
    JoinedAt  time.Time `db:"joined_at" json:"joinedAt"`
}
```

#### Task 2.2: Migrate Repository to BaseRepository

**Before:**
```go
type UserRepository struct {
    users       *mongo.Collection
    userTenants *mongo.Collection
}

func (r *UserRepository) FindByID(ctx context.Context, id, tenantID string) (*User, error) {
    filter := bson.M{"_id": id, "tenantId": tenantID, "deletedAt": nil}
    var user User
    err := r.users.FindOne(ctx, filter).Decode(&user)
    return &user, err
}
```

**After:**
```go
import (
    "github.com/vhvplatform/go-shared/yugabyte"
    "github.com/vhvplatform/go-shared/outbox"
)

type UserRepository struct {
    yugabyte.BaseRepository[User]
    userTenants yugabyte.BaseRepository[UserTenant]
    outbox      outbox.Repository
}

func NewUserRepository(db *sql.DB) *UserRepository {
    return &UserRepository{
        BaseRepository: yugabyte.NewBaseRepository[User](db, "users"),
        userTenants:    yugabyte.NewBaseRepository[UserTenant](db, "user_tenants"),
        outbox:         outbox.NewYugabyteRepository(db),
    }
}

func (r *UserRepository) FindByID(ctx context.Context, id, tenantID string) (*User, error) {
    repo := r.WithTenant(tenantID) // ✅ Automatic tenant filtering
    return repo.FindByID(ctx, id)  // ✅ Automatic soft delete filtering
}
```

#### Task 2.3: Add Transactional Outbox to Service

```go
func (s *UserService) CreateUser(ctx context.Context, req *CreateUserRequest) error {
    tenantID := interceptor.GetTenantID(ctx)
    traceID := s.tracer.GetTraceID(ctx)
    
    // ✅ Transactional Outbox Pattern
    return yugabyte.WithTransaction(ctx, s.db, func(tx *sql.Tx) error {
        // 1. Create user
        user := &User{Email: req.Email, ...}
        repo := s.userRepo.WithTx(tx).WithTenant(tenantID)
        if err := repo.Create(ctx, user); err != nil {
            return err
        }
        
        // 2. Create outbox event in SAME transaction
        payload, _ := json.Marshal(map[string]interface{}{
            "userId": user.ID,
            "email":  user.Email,
        })
        
        event := &outbox.Event{
            AggregateID:   user.ID,
            AggregateType: outbox.AggregateTypeUser,
            EventType:     outbox.EventTypeCreated,
            Payload:       payload,
            TenantID:      tenantID,
            TraceID:       traceID, // ✅ Distributed tracing
        }
        
        outboxRepo := s.outboxRepo.WithTx(tx)
        return outboxRepo.SaveEvent(ctx, event)
    })
}
```

#### Task 2.4: Setup gRPC Server with Interceptors

```go
import "github.com/vhvplatform/go-shared/pkg/grpc/interceptor"

func setupGRPCServer(logger *zap.Logger, authCfg interceptor.AuthConfig) *grpc.Server {
    return grpc.NewServer(
        grpc.UnaryInterceptor(
            interceptor.ChainUnaryServer(
                interceptor.RecoveryUnaryInterceptor(logger),
                interceptor.TenantUnaryInterceptor(),    // Extract X-Tenant-ID
                interceptor.AuthUnaryInterceptor(authCfg), // Validate JWT
                tracing.UnaryServerInterceptor(tracer),   // Tracing
                interceptor.LoggingUnaryInterceptor(logger),
            ),
        ),
    )
}
```

#### Task 2.5: Update Config

```go
// cmd/main.go
func main() {
    // Load config
    cfg := config.Load()
    
    // YugabyteDB connection
    ybConfig := yugabyte.Config{
        Host:     "192.168.1.207",
        Port:     30433,
        User:     "vhv_saas",
        Password: "yugabyteDBVHV@2627",
        Database: "vhv_saas",
        SSLMode:  "require",
    }
    
    db, err := yugabyte.Connect(ybConfig)
    if err != nil {
        log.Fatal(err)
    }
    defer db.Close()
    
    // Initialize tracer
    tracerCfg := tracing.DefaultConfig()
    tracerCfg.ServiceName = "user-service"
    tracerCfg.Environment = cfg.Environment
    tracer, err := tracing.NewOpenTelemetryTracer(tracerCfg)
    if err != nil {
        log.Fatal(err)
    }
    defer tracer.Shutdown(context.Background())
    
    // Initialize repositories
    userRepo := repository.NewUserRepository(db)
    outboxRepo := outbox.NewYugabyteRepository(db)
    
    // Initialize service
    userService := service.NewUserService(userRepo, outboxRepo, tracer)
    
    // Start gRPC server
    grpcServer := setupGRPCServer(logger, authCfg)
    pb.RegisterUserServiceServer(grpcServer, grpc.NewUserServiceServer(userService))
    
    // ... start server
}
```

---

### Phase 3: Tenant Service Migration (Priority: HIGH)

Similar migration steps as User Service:
1. Update entities with BaseEntity
2. Migrate repositories to BaseRepository
3. Add Transactional Outbox
4. Setup gRPC interceptors
5. Update config

**Special Note:** Keep MongoDB for tenant configs (schema-less settings), use YugabyteDB for tenants table (relational).

---

### Phase 4: Auth Service Update (Priority: MEDIUM)

Auth service is mostly stateless, focus on:
1. Add distributed tracing
2. Standardize gRPC interceptors
3. Propagate trace_id in JWT claims

---

### Phase 5: API Gateway Update (Priority: MEDIUM)

1. Add tracing middleware for HTTP
2. Setup gRPC client interceptors for outgoing calls
3. Propagate trace_id and tenant_id to downstream services

---

### Phase 6: Debezium CDC Setup (Priority: HIGH)

#### Task 6.1: Create Debezium Connector

```json
{
  "name": "user-service-outbox-connector",
  "config": {
    "connector.class": "io.debezium.connector.postgresql.PostgresConnector",
    "database.hostname": "192.168.1.207",
    "database.port": "30433",
    "database.user": "vhv_saas",
    "database.password": "yugabyteDBVHV@2627",
    "database.dbname": "vhv_saas",
    "database.server.name": "vhv-saas",
    "table.include.list": "public.outbox_events",
    "transforms": "outbox",
    "transforms.outbox.type": "io.debezium.transforms.outbox.EventRouter",
    "transforms.outbox.table.field.event.id": "_id",
    "transforms.outbox.table.field.event.key": "aggregate_id",
    "transforms.outbox.table.field.event.type": "event_type",
    "transforms.outbox.table.field.event.payload": "payload",
    "transforms.outbox.table.field.event.timestamp": "created_at",
    "transforms.outbox.route.topic.replacement": "vhv.events.${routedByValue}",
    "transforms.outbox.route.by.field": "aggregate_type"
  }
}
```

Deploy:
```bash
curl -X POST http://kafka-connect:8083/connectors \
  -H "Content-Type: application/json" \
  -d @debezium-user-outbox.json
```

---

## 📋 DETAILED TASK BREAKDOWN

### Task List (In Order)

1. **✅ Create go-shared/pkg/database package**
   - YugabyteConfig
   - ClickHouseConfig
   - Connection helpers

2. **✅ Create YugabyteDB migrations**
   - users table
   - user_tenants table
   - tenants table
   - outbox_events table

3. **✅ Migrate User Service entities**
   - User → yugabyte.BaseEntity
   - UserTenant → yugabyte.BaseEntity

4. **✅ Migrate User Service repositories**
   - UserRepository → yugabyte.BaseRepository
   - Add Outbox repository

5. **✅ Update User Service**
   - Add Transactional Outbox
   - Setup gRPC interceptors
   - Add tracing

6. **✅ Update User Service config**
   - YugabyteDB connection
   - Tracer config

7. **✅ Migrate Tenant Service** (Similar to steps 3-6)

8. **✅ Update Auth Service**
   - Add tracing
   - Standardize interceptors

9. **✅ Update API Gateway**
   - HTTP tracing middleware
   - gRPC client interceptors

10. **✅ Setup Debezium CDC**
    - Create connector config
    - Deploy to Kafka Connect
    - Verify event publishing

11. **✅ Integration Testing**
    - End-to-end flow
    - Trace propagation
    - Event publishing

---

## 🔍 TESTING CHECKLIST

### Unit Tests
- [ ] Entity validation
- [ ] Repository CRUD operations
- [ ] Soft delete behavior
- [ ] Tenant isolation
- [ ] Optimistic locking

### Integration Tests
- [ ] YugabyteDB connection
- [ ] Transaction rollback
- [ ] Outbox event creation
- [ ] Debezium CDC publishing
- [ ] Trace propagation

### End-to-End Tests
1. **Create User Flow:**
   - API Gateway receives request
   - Extracts tenant_id and trace_id
   - Calls User Service gRPC
   - Service creates user + outbox event in same TX
   - Debezium publishes to Kafka
   - Verify trace_id propagation

2. **Query User Flow:**
   - Verify tenant isolation
   - Verify soft delete filtering
   - Verify trace propagation

3. **Update User Flow:**
   - Verify optimistic locking
   - Verify outbox event created
   - Verify audit trail (updated_by)

---

## 📊 SUCCESS METRICS

- ✅ All services compile without errors
- ✅ 100% tenant isolation (no cross-tenant data leaks)
- ✅ 100% soft delete compliance (no physical DELETE)
- ✅ Transactional outbox working (events in same TX as data)
- ✅ Debezium CDC publishing events to Kafka
- ✅ End-to-end trace propagation working
- ✅ < 5 seconds event latency (DB → Kafka)
- ✅ Zero data inconsistencies

---

## 🚨 RISKS & MITIGATION

| Risk                       | Impact | Mitigation                                                                     |
| -------------------------- | ------ | ------------------------------------------------------------------------------ |
| Data loss during migration | HIGH   | 1. Backup MongoDB<br>2. Parallel write to both DBs<br>3. Verify data integrity |
| Downtime during cutover    | MEDIUM | 1. Blue-green deployment<br>2. Feature flags                                   |
| Debezium CDC failure       | MEDIUM | 1. Polling publisher as backup<br>2. Monitor pending events                    |
| Performance degradation    | LOW    | 1. Index optimization<br>2. Connection pooling                                 |

---

## 📅 TIMELINE ESTIMATE

| Phase               | Tasks                    | Estimated Time           |
| ------------------- | ------------------------ | ------------------------ |
| Infrastructure      | Config, migrations       | 2 hours                  |
| User Service        | Entity, repo, service    | 4 hours                  |
| Tenant Service      | Entity, repo, service    | 3 hours                  |
| Auth Service        | Tracing, interceptors    | 1 hour                   |
| API Gateway         | Middleware, interceptors | 2 hours                  |
| Debezium CDC        | Setup, testing           | 2 hours                  |
| Integration Testing | E2E tests                | 3 hours                  |
| **TOTAL**           |                          | **17 hours** (~2-3 days) |

---

## 🎯 NEXT STEPS

Bạn muốn tôi:
1. **Bắt đầu với User Service** (migrate entities → repositories → outbox)?
2. **Tạo database migrations trước**?
3. **Setup infrastructure (config package) trước**?

Which task should I start with?
