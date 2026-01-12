// Quick fix for admin user - run this in mongosh
use saas_framework;

db.users.updateOne(
    { email: "admin@test.com" },
    {
        $set: {
            tenants: ["default-tenant"],
            isActive: true
        }
    }
);

print("Updated admin user with tenants field");
print(JSON.stringify(db.users.findOne({ email: "admin@test.com" }), null, 2));
