// Direct insert to test auth
use saas_framework;

// Delete existing to ensure clean state
db.users.deleteOne({ email: "admin@test.com" });

// Insert admin user with all required fields
db.users.insertOne({
    email: "admin@test.com",
    username: "admin",
    password: "$2a$10$vlZNtBZIYraBi41aBplLmetms/Ae3dWwbJfAkE/8kAaWnRDCDFxuu",
    phone: "+84123456789",
    tenants: ["default-tenant"],
    isActive: true,
    createdAt: new Date(),
    updatedAt: new Date()
});

print("✓ Admin user inserted");

// Verify
var user = db.users.findOne({ email: "admin@test.com" });
print("\nUser details:");
print("  Email: " + user.email);
print("  Username: " + user.username);
print("  Password: " + user.password.substring(0, 20) + "...");
print("  Tenants: " + JSON.stringify(user.tenants));
print("  IsActive: " + user.isActive);
