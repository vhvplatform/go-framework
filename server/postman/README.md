# Postman Collections

This directory contains Postman collections and environments for testing the SaaS Platform API.

## Files

- **SaaS-Platform.postman_collection.json** - Complete API collection
- **Development.postman_environment.json** - Development environment (localhost)
- **Staging.postman_environment.json** - Staging environment template

## Import into Postman

1. Open Postman
2. Click "Import" button
3. Select all files from this directory
4. Collections and environments will be imported

## Usage

### 1. Select Environment

In Postman, select the appropriate environment from the dropdown in the top-right corner:
- Development (localhost:8080)
- Staging (your staging URL)

### 2. Authenticate

Run the "Login" request from the Authentication folder. This will:
- Send login credentials
- Automatically save the JWT token to the environment
- Make the token available for subsequent requests

### 3. Make API Calls

All requests are organized by functionality:
- **Health** - Service health checks
- **Authentication** - User authentication flows
- **Users** - User management operations
- **Tenants** - Tenant/organization management

Most requests automatically use the saved JWT token for authentication.

## Environment Variables

### Development Environment

- `baseUrl`: http://localhost:8080
- `jwt_token`: Automatically populated after login
- `refresh_token`: Automatically populated after login
- `user_id`: Automatically populated after registration
- `tenant_id`: Default tenant ID (tenant-1)

### Staging Environment

Update the `baseUrl` with your staging API URL.

## Testing Workflows

### Complete User Flow

1. Register User → Creates account
2. Login → Gets JWT token
3. Get Current User → Retrieves user profile
4. Update User → Modifies user data
5. Logout → Invalidates token

### Admin Flow

1. Login (with admin credentials)
2. List Users → See all users
3. List Tenants → See all tenants
4. Create Tenant → Add new organization

## Tips

- Use the Collection Runner for automated testing
- Add tests to requests for validation
- Export environment to backup token values
- Use variables for dynamic data (timestamps, random IDs)

## Creating Custom Requests

Use existing requests as templates. All authenticated requests should include:

```
Authorization: Bearer {{jwt_token}}
Content-Type: application/json
```

## Troubleshooting

### Token Expired
Re-run the Login request to get a fresh token.

### CORS Errors
Ensure the API Gateway has CORS configured for your origin.

### Connection Refused
Check if services are running: `make status`

## Advanced Usage

### Pre-request Scripts

Add timestamp to request:
```javascript
pm.environment.set("timestamp", new Date().toISOString());
```

### Test Scripts

Validate response:
```javascript
pm.test("Status is 200", function() {
    pm.response.to.have.status(200);
});

pm.test("Response has token", function() {
    var jsonData = pm.response.json();
    pm.expect(jsonData.token).to.exist;
});
```

## Export & Share

To share with team:
1. Export collection: Right-click → Export
2. Export environment: Settings → Export
3. Share JSON files via Git or team drive
