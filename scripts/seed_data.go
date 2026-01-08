package main

import (
	"context"
	"fmt"
	"log"
	"time"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
	"golang.org/x/crypto/bcrypt"
)

const (
	mongoURI = "mongodb://colombo:SASSMongoDB%232627@192.168.1.203:27017,192.168.1.222:27017,192.168.1.223:27017/saas_framework?authSource=admin&replicaSet=dbsaas&readPreference=secondaryPreferred&retryWrites=true"
	dbName   = "saas_framework"
)

func main() {
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	client, err := mongo.Connect(ctx, options.Client().ApplyURI(mongoURI))
	if err != nil {
		log.Fatal(err)
	}
	defer client.Disconnect(ctx)

	db := client.Database(dbName)

	// 1. Data Definitions
	tenantID := "tenant_001"
	email := "admin@tenant1.com"
	password := "Admin@123"

	hash, _ := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
	passwordHash := string(hash)

	tenantObjID, _ := primitive.ObjectIDFromHex("659b8b0e8b4e3a1234567890") // Fixed ID for consistency

	// 2. Insert Tenant
	fmt.Println("Seeding Tenant...")
	tenantsCol := db.Collection("tenants")
	_, err = tenantsCol.UpdateOne(ctx,
		bson.M{"_id": tenantObjID},
		bson.M{"$set": bson.M{
			"name":             "Test Tenant 1",
			"domain":           "tenant1.localhost",
			"subscriptionTier": "premium",
			"isActive":         true,
			"createdAt":        time.Now(),
			"updatedAt":        time.Now(),
		}},
		options.Update().SetUpsert(true),
	)
	if err != nil {
		log.Printf("Error seeding tenant: %v", err)
	}

	// 3. Insert Auth User (Auth Service)
	fmt.Println("Seeding Auth User...")
	authCol := db.Collection("users_auth")
	_, err = authCol.UpdateOne(ctx,
		bson.M{"email": email},
		bson.M{"$set": bson.M{
			"passwordHash": passwordHash,
			"tenantId":     tenantID,
			"roles":        []string{"admin"},
			"isActive":     true,
			"isVerified":   true,
			"createdAt":    time.Now(),
			"updatedAt":    time.Now(),
		}},
		options.Update().SetUpsert(true),
	)
	if err != nil {
		log.Printf("Error seeding auth user: %v", err)
	}

	// 4. Insert User Profile (User Service)
	fmt.Println("Seeding User Profile...")
	usersCol := db.Collection("users")
	_, err = usersCol.UpdateOne(ctx,
		bson.M{"email": email},
		bson.M{"$set": bson.M{
			"phone":     "+84987654321",
			"avatarUrl": "https://i.pravatar.cc/150?u=admin",
			"isActive":  true,
			"createdAt": time.Now(),
			"updatedAt": time.Now(),
		}},
		options.Update().SetUpsert(true),
	)
	if err != nil {
		log.Printf("Error seeding user profile: %v", err)
	}

	// Get internal ID
	var u bson.M
	_ = usersCol.FindOne(ctx, bson.M{"email": email}).Decode(&u)
	profileID := u["_id"].(primitive.ObjectID)

	// 5. Insert User-Tenant Relation (User Service)
	fmt.Println("Seeding User-Tenant Relation...")
	utCol := db.Collection("user_tenants")
	_, err = utCol.UpdateOne(ctx,
		bson.M{"userId": profileID, "tenantId": tenantID},
		bson.M{"$set": bson.M{
			"roles":     []string{"admin"},
			"firstName": "Admin",
			"lastName":  "Tenant 1",
			"isActive":  true,
			"joinedAt":  time.Now(),
		}},
		options.Update().SetUpsert(true),
	)
	if err != nil {
		log.Printf("Error seeding user-tenant: %v", err)
	}

	fmt.Println("Seeding completed successfully!")
}
