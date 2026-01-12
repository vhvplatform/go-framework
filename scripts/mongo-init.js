// MongoDB Initialization Script for VHV Platform
// This script runs automatically when MongoDB container starts for the first time

print('===== Initializing VHV Platform Databases =====');

// Switch to admin database to create users
db = db.getSiblingDB('admin');

// Create databases
db = db.getSiblingDB('vhv_auth');
db.createCollection('users');
db.createCollection('tokens');
db.createCollection('roles');
db.createCollection('permissions');
print('✓ Created vhv_auth database');

db = db.getSiblingDB('vhv_tenant');
db.createCollection('tenants');
db.createCollection('tenant_users');
db.createCollection('service_configs');
print('✓ Created vhv_tenant database');

db = db.getSiblingDB('vhv_user');
db.createCollection('users');
db.createCollection('user_preferences');
print('✓ Created vhv_user database');

db = db.getSiblingDB('vhv_notification');
db.createCollection('notifications');
db.createCollection('notification_templates');
print('✓ Created vhv_notification database');

print('===== MongoDB Initialization Complete =====');
