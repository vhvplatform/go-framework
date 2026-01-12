// MongoDB Seed Data Script for VHV Platform Development
// Run with: mongosh "mongodb://colombo:SASSMongoDB%232627@192.168.1.203:27017/saas_framework?authSource=admin" --file seed-dev-data.js

print('===== VHV Platform - Loading Development Seed Data =====');

// Use the saas_framework database
db = db.getSiblingDB('saas_framework');

// ========================================
// 1. CREATE INDEXES (Idempotent)
// ========================================
print('\n[1/6] Creating indexes...');

try {
    db.tenants.createIndex({ "tenantId": 1 }, { unique: true, name: "idx_tenantId" });
    db.users.createIndex({ "email": 1, "tenantId": 1 }, { unique: true, name: "idx_email_tenantId" });
    db.users.createIndex({ "userId": 1 }, { unique: true, name: "idx_userId" });
    db.tokens.createIndex({ "token": 1 }, { unique: true, name: "idx_token" });
    db.tokens.createIndex({ "userId": 1 }, { name: "idx_token_userId" });
    db.roles.createIndex({ "roleId": 1 }, { unique: true, name: "idx_roleId" });
    db.roles.createIndex({ "name": 1, "tenantId": 1 }, { unique: true, name: "idx_role_name_tenantId" });
    db.permissions.createIndex({ "permissionId": 1 }, { unique: true, name: "idx_permissionId" });
    db.user_roles.createIndex({ "userId": 1, "roleId": 1 }, { unique: true, name: "idx_userId_roleId" });
    print('✓ Indexes created successfully');
} catch (e) {
    print('⚠ Some indexes may already exist: ' + e.message);
}

// ========================================
// 2. INSERT DEFAULT TENANT (Idempotent)
// ========================================
print('\n[2/6] Creating default tenant...');

const tenantResult = db.tenants.updateOne(
    { tenantId: "default-tenant" },
    {
        $setOnInsert: {
            tenantId: "default-tenant",
            name: "Default Tenant",
            domain: "localhost",
            subscriptionTier: "enterprise",
            isActive: true,
            authSettings: {
                allowedLoginMethods: ["email", "username", "phone", "document_number"]
            },
            defaultService: "http://localhost:3000",
            settings: {
                maxUsers: 1000,
                features: ["user_management", "auth", "notifications"]
            },
            createdAt: new Date(),
            updatedAt: new Date(),
            createdBy: "system"
        }
    },
    { upsert: true }
);

print(tenantResult.upsertedCount > 0 ? '✓ Tenant created' : '✓ Tenant already exists');

// ========================================
// 3. INSERT ADMIN USER (Idempotent)
// ========================================
print('\n[3/6] Creating admin user...');

// Password: Admin@123
// Generated with: bcrypt hash at cost 10
const adminPasswordHash = "$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy";

const adminResult = db.users.updateOne(
    { email: "admin@test.com" },
    {
        $setOnInsert: {
            userId: "admin-user-001",
            email: "admin@test.com",
            username: "admin",
            phone: "+84901234567",
            documentNumber: "ADMIN001",
            passwordHash: adminPasswordHash,
            firstName: "Admin",
            lastName: "User",
            isActive: true,
            tenantId: "default-tenant",
            metadata: {
                source: "seed-data",
                description: "System administrator account"
            },
            createdAt: new Date(),
            updatedAt: new Date(),
            createdBy: "system"
        }
    },
    { upsert: true }
);

print(adminResult.upsertedCount > 0 ? '✓ Admin user created' : '✓ Admin user already exists');

// ========================================
// 4. INSERT ROLES & PERMISSIONS (Idempotent)
// ========================================
print('\n[4/6] Creating roles and permissions...');

// Permissions
const permissions = [
    { permissionId: "perm-001", code: "*", name: "All Permissions", description: "Full system access" },
    { permissionId: "perm-002", code: "user.read", name: "Read Users", description: "View user information" },
    { permissionId: "perm-003", code: "user.write", name: "Write Users", description: "Create/Update users" },
    { permissionId: "perm-004", code: "user.delete", name: "Delete Users", description: "Delete users" },
    { permissionId: "perm-005", code: "tenant.read", name: "Read Tenants", description: "View tenant information" },
    { permissionId: "perm-006", code: "tenant.write", name: "Write Tenants", description: "Create/Update tenants" },
];

permissions.forEach(perm => {
    db.permissions.updateOne(
        { permissionId: perm.permissionId },
        {
            $setOnInsert: {
                ...perm,
                createdAt: new Date(),
                updatedAt: new Date()
            }
        },
        { upsert: true }
    );
});
print('✓ Permissions loaded');

// Roles
const roles = [
    {
        roleId: "role-admin",
        name: "admin",
        displayName: "Administrator",
        tenantId: "default-tenant",
        permissions: ["*"],
        description: "Full system access"
    },
    {
        roleId: "role-user",
        name: "user",
        displayName: "User",
        tenantId: "default-tenant",
        permissions: ["user.read"],
        description: "Basic user access"
    },
    {
        roleId: "role-manager",
        name: "manager",
        displayName: "Manager",
        tenantId: "default-tenant",
        permissions: ["user.read", "user.write", "tenant.read"],
        description: "Manager access"
    }
];

roles.forEach(role => {
    db.roles.updateOne(
        { roleId: role.roleId },
        {
            $setOnInsert: {
                ...role,
                isActive: true,
                createdAt: new Date(),
                updatedAt: new Date(),
                createdBy: "system"
            }
        },
        { upsert: true }
    );
});
print('✓ Roles loaded');

// ========================================
// 5. ASSIGN ADMIN ROLE TO ADMIN USER
// ========================================
print('\n[5/6] Assigning admin role...');

db.user_roles.updateOne(
    { userId: "admin-user-001", roleId: "role-admin" },
    {
        $setOnInsert: {
            userId: "admin-user-001",
            roleId: "role-admin",
            tenantId: "default-tenant",
            assignedAt: new Date(),
            assignedBy: "system"
        }
    },
    { upsert: true }
);
print('✓ Admin role assigned');

// ========================================
// 6. INSERT SAMPLE USERS FOR TESTING
// ========================================
print('\n[6/6] Creating sample users...');

const samplePassword = "$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy"; // Admin@123

for (let i = 1; i <= 5; i++) {
    const userId = `user-00${i}`;
    const result = db.users.updateOne(
        { email: `user${i}@test.com` },
        {
            $setOnInsert: {
                userId: userId,
                email: `user${i}@test.com`,
                username: `user${i}`,
                phone: `+8490123456${i}`,
                passwordHash: samplePassword,
                firstName: `User`,
                lastName: `${i}`,
                isActive: true,
                tenantId: "default-tenant",
                metadata: {
                    source: "seed-data",
                    description: `Test user ${i}`
                },
                createdAt: new Date(),
                updatedAt: new Date(),
                createdBy: "system"
            }
        },
        { upsert: true }
    );

    // Assign user role
    if (result.upsertedCount > 0) {
        db.user_roles.updateOne(
            { userId: userId, roleId: "role-user" },
            {
                $setOnInsert: {
                    userId: userId,
                    roleId: "role-user",
                    tenantId: "default-tenant",
                    assignedAt: new Date(),
                    assignedBy: "system"
                }
            },
            { upsert: true }
        );
    }
}
print('✓ Sample users created (5 users)');

// ========================================
// SUMMARY
// ========================================
print('\n===== Seed Data Summary =====');
print('Tenants:     ' + db.tenants.countDocuments({ tenantId: "default-tenant" }));
print('Users:       ' + db.users.countDocuments({ tenantId: "default-tenant" }));
print('Roles:       ' + db.roles.countDocuments({ tenantId: "default-tenant" }));
print('Permissions: ' + db.permissions.countDocuments());
print('User Roles:  ' + db.user_roles.countDocuments({ tenantId: "default-tenant" }));

print('\n===== Test Credentials =====');
print('Email:    admin@test.com');
print('Password: Admin@123');
print('Tenant:   default-tenant');

print('\n✅ Seed data loaded successfully (idempotent)!\n');
