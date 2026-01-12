// Manual seed script - Copy and paste into mongosh console
// First connect: mongosh "mongodb://192.168.1.203:27017/saas_framework?replicaSet=rs0"

use saas_framework;

// 1. Insert tenant
db.tenants.updateOne(
    { code: "default-tenant" },
    {
        $set: {
            code: "default-tenant",
            name: "Default Tenant",
            loginMethods: ["email", "username", "phone"],
            is_active: true,
            isActive: true,
            created_at: new Date(),
            updated_at: new Date(),
            createdAt: new Date(),
            updatedAt: new Date()
        }
    },
    { upsert: true }
);

print("✓ Tenant created");

// 2. Insert admin user
db.users.updateOne(
    { email: "admin@test.com" },
    {
        $set: {
            email: "admin@test.com",
            username: "admin",
            password: "$2a$10$8K1p/a0dL3.y6l5Mqi7hQuw0.0wQ7T5SxRqHJZqU0WqJw9LxqJqZK", // Admin@123
            phone: "+84123456789",
            tenants: ["default-tenant"],
            tenant_id: "default-tenant",
            is_active: true,
            isActive: true,
            is_verified: true,
            created_at: new Date(),
            updated_at: new Date()
        }
    },
    { upsert: true }
);

print("✓ Admin user created");

// 3. Insert roles
db.roles.insertMany([
    {
        name: "admin",
        description: "Administrator role",
        tenant_id: "default-tenant",
        permissions: ["*"],
        created_at: new Date(),
        updated_at: new Date()
    },
    {
        name: "user",
        description: "Regular user role",
        tenant_id: "default-tenant",
        permissions: ["read:users", "update:own-profile"],
        created_at: new Date(),
        updated_at: new Date()
    },
    {
        name: "manager",
        description: "Manager role",
        tenant_id: "default-tenant",
        permissions: ["read:users", "create:users", "update:users"],
        created_at: new Date(),
        updated_at: new Date()
    }
], { ordered: false }).catch(() => print("Roles already exist"));

print("✓ Roles created");

// 4. Assign admin role to admin user
var adminUser = db.users.findOne({ email: "admin@test.com" });
if (adminUser) {
    db.user_roles.updateOne(
        { user_id: adminUser._id.toString(), tenant_id: "default-tenant" },
        {
            $set: {
                user_id: adminUser._id.toString(),
                tenant_id: "default-tenant",
                roles: ["admin"],
                created_at: new Date(),
                updated_at: new Date()
            }
        },
        { upsert: true }
    );
    print("✓ Admin role assigned");
}

// 5. Insert sample users
var sampleUsers = [
    { email: "john@test.com", username: "john", name: "John Doe", phone: "+84987654321" },
    { email: "jane@test.com", username: "jane", name: "Jane Smith", phone: "+84987654322" },
    { email: "bob@test.com", username: "bob", name: "Bob Johnson", phone: "+84987654323" },
    { email: "alice@test.com", username: "alice", name: "Alice Williams", phone: "+84987654324" },
    { email: "charlie@test.com", username: "charlie", name: "Charlie Brown", phone: "+84987654325" }
];

sampleUsers.forEach(function (user) {
    db.users.updateOne(
        { email: user.email },
        {
            $set: {
                email: user.email,
                username: user.username,
                password: "$2a$10$8K1p/a0dL3.y6l5Mqi7hQuw0.0wQ7T5SxRqHJZqU0WqJw9LxqJqZK", // Admin@123
                phone: user.phone,
                tenants: ["default-tenant"],
                tenant_id: "default-tenant",
                is_active: true,
                isActive: true,
                is_verified: true,
                created_at: new Date(),
                updated_at: new Date()
            }
        },
        { upsert: true }
    );
});

print("✓ Sample users created");

// Verify data
print("\n=== Data Summary ===");
print("Tenants: " + db.tenants.countDocuments());
print("Users: " + db.users.countDocuments());
print("Roles: " + db.roles.countDocuments());
print("User Roles: " + db.user_roles.countDocuments());
print("\nAdmin credentials: admin@test.com / Admin@123");
