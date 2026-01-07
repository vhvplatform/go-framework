# Test Fixtures

This directory contains test data for seeding databases and testing the SaaS Platform.

## Files

- **users.json** - Sample user accounts
- **tenants.json** - Sample tenant/organization data
- **roles.json** - Role definitions with permissions

## Usage

### Load into MongoDB

```bash
# From framework directory
make db-seed

# Or directly
./scripts/database/seed.sh
```

### Generate New Test Data

```bash
make test-data
```

## Data Structure

### Users
- `id`: Unique user identifier
- `email`: User email address
- `name`: Full name
- `tenant_id`: Associated tenant
- `role`: User role (admin, user, viewer)
- `created_at`: Timestamp

### Tenants
- `id`: Unique tenant identifier
- `name`: Organization name
- `slug`: URL-friendly identifier
- `plan`: Subscription plan (free, pro, enterprise)
- `status`: Account status (active, suspended, etc.)
- `created_at`: Timestamp

### Roles
- `id`: Unique role identifier
- `name`: Role name
- `permissions`: Array of permission strings
- `description`: Role description

## Customization

Edit the JSON files directly or modify the `generate-test-data.sh` script to create custom test data.

## Notes

- Test data is meant for development and testing only
- Do not use in production environments
- Passwords in test data are hashed with bcrypt
- Default test password: `testpass123`
