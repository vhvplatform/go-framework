// Update admin password with correct hash
use saas_framework;

db.users.updateOne(
    { email: "admin@test.com" },
    {
        $set: {
            password: "$2a$10$vlZNtBZIYraBi41aBplLmetms/Ae3dWwbJfAkE/8kAaWnRDCDFxuu"
        }
    }
);

print("Updated admin user password");
var user = db.users.findOne({ email: "admin@test.com" });
print("Email: " + user.email);
print("Has password: " + (user.password ? "Yes" : "No"));
print("Has tenants: " + (user.tenants ? "Yes (" + user.tenants.length + ")" : "No"));
print("IsActive: " + user.isActive);
