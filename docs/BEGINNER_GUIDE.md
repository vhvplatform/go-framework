# Beginner's Guide to Technologies

This guide explains all the technologies used in go-framework in simple terms with examples. Perfect for developers new to microservices, containers, or these specific tools.

## Table of Contents

- [Docker & Containers](#docker--containers)
- [Go Programming Language](#go-programming-language)
- [MongoDB](#mongodb)
- [Redis](#redis)
- [RabbitMQ](#rabbitmq)
- [gRPC](#grpc)
- [JWT (JSON Web Tokens)](#jwt-json-web-tokens)
- [Microservices Architecture](#microservices-architecture)
- [REST API](#rest-api)
- [Prometheus & Grafana](#prometheus--grafana)
- [Jaeger Tracing](#jaeger-tracing)
- [Git & GitHub](#git--github)
- [Makefile](#makefile)
- [Shell Scripting](#shell-scripting)

---

## Docker & Containers

### What is Docker?

Docker is like a **shipping container for software**. Just like physical containers allow you to ship anything anywhere, Docker containers package your application and everything it needs to run.

**Why use Docker?**
- ✅ "Works on my machine" → Works everywhere
- ✅ Easy to share and deploy
- ✅ Isolated from other applications
- ✅ Quick to start and stop

### Real-World Analogy

Think of Docker like meal prep containers:
- **Container**: Your lunch box with food
- **Image**: The recipe for making the food
- **Dockerfile**: The cooking instructions
- **Docker Compose**: Organizing multiple lunch boxes for a family

### Basic Example

```bash
# See what containers are running
docker ps

# Output:
# CONTAINER ID   IMAGE              STATUS      PORTS
# abc123         mongo:7.0          Up 5 mins   27017->27017
# def456         redis:7-alpine     Up 5 mins   6379->6379

# Start a new container
docker run -d --name my-mongodb -p 27017:27017 mongo:7.0

# Stop a container
docker stop my-mongodb

# Remove a container
docker rm my-mongodb
```

### Docker Compose Example

```yaml
# docker-compose.yml - Lunch menu for the family
version: '3.8'

services:
  # Dad's lunch (MongoDB database)
  mongodb:
    image: mongo:7.0
    ports:
      - "27017:27017"
    
  # Mom's lunch (Redis cache)
  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"
```

```bash
# Start all containers
docker-compose up -d

# Stop all containers
docker-compose down
```

### Common Commands

```bash
# View logs
docker logs container-name

# Access container shell
docker exec -it container-name bash

# View container details
docker inspect container-name

# Clean up unused containers
docker system prune
```

---

## Go Programming Language

### What is Go?

Go (or Golang) is a programming language created by Google. It's like **Python's simplicity** meets **C's performance**.

**Why use Go?**
- ✅ Fast compilation and execution
- ✅ Built-in concurrency (handle many things at once)
- ✅ Simple syntax, easy to learn
- ✅ Great for web services and APIs
- ✅ Static typing catches errors early

### Hello World Example

```go
package main

import "fmt"

func main() {
    fmt.Println("Hello, World!")
}
```

```bash
# Run the program
go run main.go
# Output: Hello, World!
```

### HTTP Server Example

```go
package main

import (
    "fmt"
    "net/http"
)

func helloHandler(w http.ResponseWriter, r *http.Request) {
    fmt.Fprintf(w, "Hello, %s!", r.URL.Query().Get("name"))
}

func main() {
    http.HandleFunc("/hello", helloHandler)
    fmt.Println("Server starting on :8080")
    http.ListenAndServe(":8080", nil)
}
```

```bash
# Test it
curl "http://localhost:8080/hello?name=Alice"
# Output: Hello, Alice!
```

### Key Concepts

**1. Goroutines (Concurrent Tasks)**
```go
// Do things in parallel
go doSomething()  // Runs in background
go doSomethingElse()  // Also runs in background
```

**2. Structs (Data Structures)**
```go
type User struct {
    ID    string
    Name  string
    Email string
}

user := User{
    ID:    "123",
    Name:  "Alice",
    Email: "alice@example.com",
}
```

**3. Error Handling**
```go
result, err := doSomething()
if err != nil {
    // Handle error
    log.Fatal(err)
}
// Use result
```

---

## MongoDB

### What is MongoDB?

MongoDB is a **NoSQL database** that stores data in JSON-like documents. Think of it as a filing cabinet where each drawer can hold different types of papers.

**Why use MongoDB?**
- ✅ Flexible schema (no rigid structure)
- ✅ Stores data like JSON
- ✅ Scales easily
- ✅ Fast for reads and writes

### Real-World Analogy

**SQL Database (PostgreSQL)**:
- Like a spreadsheet with fixed columns
- Must define structure first
- All rows must match columns

**NoSQL Database (MongoDB)**:
- Like a folder of documents
- Each document can be different
- Add fields anytime

### Basic Example

```javascript
// Connect to MongoDB
use go_dev

// Insert a user
db.users.insertOne({
  _id: "user-123",
  email: "alice@example.com",
  name: "Alice Smith",
  age: 28,
  roles: ["user", "editor"],
  created_at: new Date()
})

// Find users
db.users.find({ email: "alice@example.com" })

// Update user
db.users.updateOne(
  { _id: "user-123" },
  { $set: { age: 29 } }
)

// Delete user
db.users.deleteOne({ _id: "user-123" })
```

### Using MongoDB in Go

```go
package main

import (
    "context"
    "go.mongodb.org/mongo-driver/mongo"
    "go.mongodb.org/mongo-driver/mongo/options"
)

type User struct {
    ID    string `bson:"_id"`
    Name  string `bson:"name"`
    Email string `bson:"email"`
}

func main() {
    // Connect to MongoDB
    client, _ := mongo.Connect(
        context.Background(),
        options.Client().ApplyURI("mongodb://localhost:27017"),
    )
    
    // Get collection
    collection := client.Database("go_dev").Collection("users")
    
    // Insert user
    user := User{
        ID:    "user-123",
        Name:  "Alice",
        Email: "alice@example.com",
    }
    collection.InsertOne(context.Background(), user)
    
    // Find user
    var result User
    collection.FindOne(
        context.Background(),
        map[string]string{"email": "alice@example.com"},
    ).Decode(&result)
}
```

### Common Operations

```bash
# Access MongoDB shell
docker exec -it mongodb mongosh

# Show databases
show dbs

# Use database
use go_dev

# Show collections
show collections

# Count documents
db.users.countDocuments()

# Pretty print
db.users.find().pretty()
```

---

## Redis

### What is Redis?

Redis is an **in-memory data store** - like a super-fast notepad for your application. Data is stored in RAM (memory) instead of disk.

**Why use Redis?**
- ✅ Extremely fast (millions of operations/second)
- ✅ Simple key-value storage
- ✅ Automatic expiration (TTL)
- ✅ Built-in data structures

### Real-World Analogy

Think of Redis like **sticky notes on your desk**:
- MongoDB: File cabinet (permanent storage)
- Redis: Sticky notes (quick access, temporary)

### Basic Example

```bash
# Connect to Redis
docker exec -it redis redis-cli

# Set a value
SET user:123:name "Alice"
# Output: OK

# Get a value
GET user:123:name
# Output: "Alice"

# Set with expiration (30 minutes)
SETEX session:abc123 1800 "user-123"

# Check time to live
TTL session:abc123
# Output: 1795 (seconds remaining)

# Delete a key
DEL user:123:name

# Check if key exists
EXISTS user:123:name
# Output: 0 (doesn't exist)
```

### Data Structures

**1. Strings**
```bash
SET counter 1
INCR counter  # counter = 2
INCRBY counter 5  # counter = 7
```

**2. Lists (like arrays)**
```bash
LPUSH tasks "Send email"
LPUSH tasks "Process payment"
LRANGE tasks 0 -1  # Get all tasks
```

**3. Sets (unique values)**
```bash
SADD tags "golang"
SADD tags "docker"
SADD tags "golang"  # Ignored (already exists)
SMEMBERS tags  # ["golang", "docker"]
```

**4. Hashes (like objects)**
```bash
HSET user:123 name "Alice"
HSET user:123 email "alice@example.com"
HGETALL user:123  # Get all fields
```

### Using Redis in Go

```go
package main

import (
    "github.com/go-redis/redis/v8"
    "context"
    "time"
)

func main() {
    // Connect to Redis
    client := redis.NewClient(&redis.Options{
        Addr: "localhost:6379",
    })
    
    ctx := context.Background()
    
    // Set value
    client.Set(ctx, "user:123:name", "Alice", 0)
    
    // Get value
    name, _ := client.Get(ctx, "user:123:name").Result()
    // name = "Alice"
    
    // Set with expiration
    client.Set(ctx, "session:abc", "user-123", 30*time.Minute)
    
    // Delete
    client.Del(ctx, "user:123:name")
}
```

### Common Use Cases

1. **Session Storage**
```bash
# Store user session
SET session:abc123 "user-id-456" EX 86400  # 24 hours
```

2. **Caching**
```bash
# Cache user profile
SET cache:user:123 '{"name":"Alice","email":"..."}' EX 300  # 5 minutes
```

3. **Rate Limiting**
```bash
# Count API calls
INCR ratelimit:user:123:api_calls
EXPIRE ratelimit:user:123:api_calls 60  # Reset after 1 minute
```

---

## RabbitMQ

### What is RabbitMQ?

RabbitMQ is a **message queue** - like a post office for your applications. It receives messages from one service and delivers them to another.

**Why use RabbitMQ?**
- ✅ Asynchronous communication
- ✅ Decouples services
- ✅ Handles traffic spikes
- ✅ Guarantees message delivery
- ✅ Multiple consumers can process messages

### Real-World Analogy

Think of RabbitMQ like a **restaurant kitchen**:

```
Customer → Waiter → Kitchen → Chef
  (Client)  (Producer) (Queue)  (Consumer)
```

1. Customer orders food (Producer sends message)
2. Waiter writes order and clips it (Message goes to queue)
3. Chef picks up next order (Consumer receives message)
4. Chef cooks and delivers (Consumer processes message)

### Basic Concepts

**Exchange**: Like a post office sorting center
**Queue**: Like a mailbox for messages
**Routing Key**: Like a postal code
**Consumer**: Service that reads and processes messages

### Architecture

```
Producer → Exchange → Queue → Consumer
           (Topic)
             ├─→ email.queue → Email Service
             ├─→ sms.queue → SMS Service
             └─→ push.queue → Push Service
```

### Example: Sending Email Notifications

**Producer (User Service):**
```go
// When user registers, send message
message := map[string]string{
    "user_id": "123",
    "email":   "alice@example.com",
    "type":    "welcome_email",
}

// Publish to queue
channel.Publish(
    "notifications",  // exchange
    "email.welcome",  // routing key
    false,
    false,
    amqp.Publishing{
        ContentType: "application/json",
        Body:        json.Marshal(message),
    },
)
```

**Consumer (Notification Service):**
```go
// Listen for messages
messages, _ := channel.Consume(
    "email.queue",  // queue
    "",             // consumer
    false,          // auto-ack
    false,          // exclusive
    false,          // no-local
    false,          // no-wait
    nil,            // args
)

// Process messages
for message := range messages {
    // Parse message
    var notification Notification
    json.Unmarshal(message.Body, &notification)
    
    // Send email
    sendEmail(notification.Email, notification.Type)
    
    // Acknowledge
    message.Ack(false)
}
```

### RabbitMQ Management

```bash
# Access management UI
open http://localhost:15672
# Login: guest / guest

# View queues
rabbitmqctl list_queues

# View exchanges
rabbitmqctl list_exchanges

# View connections
rabbitmqctl list_connections
```

### Common Patterns

**1. Work Queue (Task Distribution)**
```
Producer → Queue → Worker 1
                → Worker 2
                → Worker 3
```
Multiple workers process tasks in parallel.

**2. Pub/Sub (Broadcast)**
```
Publisher → Fanout Exchange → Queue A → Consumer A
                            → Queue B → Consumer B
                            → Queue C → Consumer C
```
All subscribers receive the message.

**3. Topic (Routing)**
```
Publisher → Topic Exchange → *.error → Error Logger
                          → user.* → User Analytics
                          → email.* → Email Service
```
Messages routed based on pattern matching.

---

## gRPC

### What is gRPC?

gRPC is a modern **RPC (Remote Procedure Call)** framework. It lets services talk to each other as if calling local functions, but over the network.

**Why use gRPC?**
- ✅ Faster than REST (binary protocol)
- ✅ Strongly typed (catches errors early)
- ✅ Bi-directional streaming
- ✅ Built-in load balancing
- ✅ Language agnostic

### REST vs gRPC

**REST (HTTP/JSON):**
```http
POST /api/users HTTP/1.1
Content-Type: application/json

{"name": "Alice", "email": "alice@example.com"}
```

**gRPC (Protocol Buffers):**
```protobuf
// user.proto - Define the API
service UserService {
  rpc CreateUser(CreateUserRequest) returns (User) {}
}

message CreateUserRequest {
  string name = 1;
  string email = 2;
}

message User {
  string id = 1;
  string name = 2;
  string email = 3;
}
```

### Real-World Example

**1. Define API (user.proto)**
```protobuf
syntax = "proto3";

package user;

service UserService {
  rpc GetUser(GetUserRequest) returns (User) {}
  rpc ListUsers(ListUsersRequest) returns (ListUsersResponse) {}
}

message GetUserRequest {
  string user_id = 1;
}

message User {
  string id = 1;
  string name = 2;
  string email = 3;
  repeated string roles = 4;
}

message ListUsersRequest {
  int32 page = 1;
  int32 page_size = 2;
}

message ListUsersResponse {
  repeated User users = 1;
  int32 total = 2;
}
```

**2. Generate Code**
```bash
protoc --go_out=. --go-grpc_out=. user.proto
```

**3. Implement Server**
```go
type UserServer struct {
    pb.UnimplementedUserServiceServer
}

func (s *UserServer) GetUser(
    ctx context.Context,
    req *pb.GetUserRequest,
) (*pb.User, error) {
    // Fetch from database
    user, err := db.FindUserByID(req.UserId)
    if err != nil {
        return nil, err
    }
    
    return &pb.User{
        Id:    user.ID,
        Name:  user.Name,
        Email: user.Email,
        Roles: user.Roles,
    }, nil
}

func main() {
    listener, _ := net.Listen("tcp", ":50051")
    grpcServer := grpc.NewServer()
    pb.RegisterUserServiceServer(grpcServer, &UserServer{})
    grpcServer.Serve(listener)
}
```

**4. Create Client**
```go
// Connect to server
conn, _ := grpc.Dial("localhost:50051", grpc.WithInsecure())
client := pb.NewUserServiceClient(conn)

// Call method (like a local function!)
user, err := client.GetUser(context.Background(), &pb.GetUserRequest{
    UserId: "user-123",
})

fmt.Println(user.Name)  // "Alice"
```

### Why We Use Both REST and gRPC

**REST (External APIs)**
- Browsers and mobile apps
- Public APIs
- Easy to debug (curl, Postman)

**gRPC (Internal Services)**
- Service-to-service communication
- Faster and more efficient
- Type-safe contracts

```
Client (Browser) → REST → API Gateway → gRPC → Microservices
```

---

## JWT (JSON Web Tokens)

### What is JWT?

JWT is a way to **securely transmit information** between parties. Think of it like a tamper-proof badge or passport.

**Why use JWT?**
- ✅ Stateless authentication (no session storage)
- ✅ Self-contained (includes user info)
- ✅ Signed and verified
- ✅ Works across services

### Real-World Analogy

JWT is like a **theme park wristband**:
- Shows you paid (authenticated)
- Contains info (name, ticket type)
- Can't be faked (signed by park)
- Expires at end of day (expiration time)

### JWT Structure

```
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoiMTIzIiwibmFtZSI6IkFsaWNlIn0.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c

Header.Payload.Signature
```

**Decoded:**
```json
// Header
{
  "alg": "HS256",
  "typ": "JWT"
}

// Payload (claims)
{
  "user_id": "123",
  "email": "alice@example.com",
  "roles": ["user", "editor"],
  "exp": 1640000000  // Expiration
}

// Signature (verifies authenticity)
HMACSHA256(
  base64UrlEncode(header) + "." + base64UrlEncode(payload),
  secret
)
```

### Example Flow

**1. Login and Get Token**
```bash
curl -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "alice@example.com",
    "password": "password123"
  }'

# Response:
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "expires_at": "2024-12-26T12:00:00Z"
}
```

**2. Use Token for Requests**
```bash
curl http://localhost:8080/api/users/profile \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
```

### JWT in Go

**Generate Token:**
```go
import "github.com/golang-jwt/jwt/v5"

func generateToken(userID string) (string, error) {
    claims := jwt.MapClaims{
        "user_id": userID,
        "email":   "alice@example.com",
        "exp":     time.Now().Add(24 * time.Hour).Unix(),
    }
    
    token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
    return token.SignedString([]byte("your-secret-key"))
}
```

**Verify Token:**
```go
func verifyToken(tokenString string) (*jwt.Token, error) {
    return jwt.Parse(tokenString, func(token *jwt.Token) (interface{}, error) {
        return []byte("your-secret-key"), nil
    })
}

token, err := verifyToken(tokenString)
if err != nil {
    return errors.New("invalid token")
}

claims := token.Claims.(jwt.MapClaims)
userID := claims["user_id"].(string)
```

### Security Best Practices

```go
// ✅ DO: Use strong secret
JWT_SECRET=7X9k2m4P8qR5t1vW3yZ6aB8cD0eF2gH4jK6mN8pQ0sU2wY4zA6bC

// ❌ DON'T: Use weak secret
JWT_SECRET=secret123

// ✅ DO: Set expiration
"exp": time.Now().Add(24 * time.Hour).Unix()

// ❌ DON'T: Never expire
// (no exp field)

// ✅ DO: Verify signature
jwt.Parse(token, verifyFunction)

// ❌ DON'T: Trust without verification
// jwt.ParseUnverified(token)
```

---

## Microservices Architecture

### What are Microservices?

Microservices break a large application into **small, independent services**. Each service does one thing well.

**Monolith vs Microservices:**

**Monolith (Single App):**
```
┌─────────────────────────┐
│                         │
│   ┌────────────────┐   │
│   │ Auth           │   │
│   ├────────────────┤   │
│   │ Users          │   │
│   ├────────────────┤   │
│   │ Notifications  │   │
│   ├────────────────┤   │
│   │ Billing        │   │
│   └────────────────┘   │
│                         │
│   All in one database  │
└─────────────────────────┘
```

**Microservices (Separate Services):**
```
┌──────────┐  ┌──────────┐  ┌──────────┐
│ Auth     │  │ Users    │  │ Billing  │
│ Service  │  │ Service  │  │ Service  │
├──────────┤  ├──────────┤  ├──────────┤
│ MongoDB  │  │ MongoDB  │  │ MongoDB  │
└──────────┘  └──────────┘  └──────────┘
```

### Benefits

✅ **Independent deployment** - Update one service without touching others
✅ **Technology freedom** - Each service can use different tech
✅ **Team autonomy** - Teams own entire services
✅ **Fault isolation** - One service crash doesn't kill all
✅ **Scalability** - Scale busy services independently

### Trade-offs

❌ **Complexity** - More moving parts
❌ **Network calls** - Services talk over network (slower)
❌ **Data consistency** - No single transaction across services
❌ **Testing** - Need to test integrations
❌ **Monitoring** - More services to monitor

### Our Architecture

```
Client
  ↓
API Gateway (Single entry point)
  ├→ Auth Service (login, tokens)
  ├→ User Service (profiles, roles)
  ├→ Tenant Service (organizations)
  ├→ Notification Service (emails, alerts)
  └→ Config Service (settings, features)
```

### Communication Patterns

**1. Synchronous (gRPC)**
```
API Gateway --[GetUser request]--> User Service
API Gateway <--[User data]-------- User Service
```
Use when you need immediate response.

**2. Asynchronous (RabbitMQ)**
```
User Service --[user.created event]--> RabbitMQ
                                          ↓
Notification Service <--[consume]-------┘
```
Use for background tasks.

### Example: User Registration Flow

```go
// 1. API Gateway receives request
POST /api/auth/register
{
  "email": "alice@example.com",
  "password": "password123"
}

// 2. API Gateway → Auth Service (gRPC)
user, err := authClient.Register(ctx, &RegisterRequest{
    Email:    req.Email,
    Password: req.Password,
})

// 3. Auth Service creates user in DB
userID := db.CreateUser(email, hashedPassword)

// 4. Auth Service → RabbitMQ (async event)
publishEvent("user.created", userID)

// 5. Notification Service receives event
// Sends welcome email in background

// 6. Response to client
return User{ID: userID, Email: email}
```

---

## REST API

### What is REST?

REST (Representational State Transfer) is a way to build web APIs using HTTP. Think of it as a **menu at a restaurant** - it tells you what you can order and how.

### HTTP Methods (Verbs)

```
GET    - Read data (like asking for the menu)
POST   - Create new data (like placing an order)
PUT    - Update entire resource (replace the dish)
PATCH  - Update part of resource (add salt)
DELETE - Remove data (cancel order)
```

### Example API

```
GET    /api/users          Get all users
GET    /api/users/123      Get user with ID 123
POST   /api/users          Create new user
PUT    /api/users/123      Update user 123
PATCH  /api/users/123      Partially update user 123
DELETE /api/users/123      Delete user 123
```

### Request/Response Examples

**1. Get All Users**
```bash
curl http://localhost:8080/api/users

# Response: 200 OK
{
  "users": [
    {"id": "1", "name": "Alice", "email": "alice@example.com"},
    {"id": "2", "name": "Bob", "email": "bob@example.com"}
  ],
  "total": 2
}
```

**2. Create User**
```bash
curl -X POST http://localhost:8080/api/users \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Charlie",
    "email": "charlie@example.com"
  }'

# Response: 201 Created
{
  "id": "3",
  "name": "Charlie",
  "email": "charlie@example.com"
}
```

**3. Update User**
```bash
curl -X PUT http://localhost:8080/api/users/3 \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Charlie Brown",
    "email": "charlie.brown@example.com"
  }'

# Response: 200 OK
{
  "id": "3",
  "name": "Charlie Brown",
  "email": "charlie.brown@example.com"
}
```

**4. Delete User**
```bash
curl -X DELETE http://localhost:8080/api/users/3

# Response: 204 No Content
```

### HTTP Status Codes

```
2xx - Success
  200 OK          - Request succeeded
  201 Created     - Resource created
  204 No Content  - Success, but no data to return

4xx - Client Errors
  400 Bad Request      - Invalid data sent
  401 Unauthorized     - Not logged in
  403 Forbidden        - Logged in but no permission
  404 Not Found        - Resource doesn't exist
  422 Unprocessable    - Validation failed

5xx - Server Errors
  500 Internal Server Error  - Something broke
  502 Bad Gateway            - Upstream service error
  503 Service Unavailable    - Service down
```

### REST API in Go

```go
package main

import (
    "encoding/json"
    "net/http"
    "github.com/gorilla/mux"
)

type User struct {
    ID    string `json:"id"`
    Name  string `json:"name"`
    Email string `json:"email"`
}

// GET /api/users
func listUsers(w http.ResponseWriter, r *http.Request) {
    users := []User{
        {ID: "1", Name: "Alice", Email: "alice@example.com"},
        {ID: "2", Name: "Bob", Email: "bob@example.com"},
    }
    
    w.Header().Set("Content-Type", "application/json")
    json.NewEncoder(w).Encode(users)
}

// GET /api/users/{id}
func getUser(w http.ResponseWriter, r *http.Request) {
    vars := mux.Vars(r)
    userID := vars["id"]
    
    user := User{ID: userID, Name: "Alice", Email: "alice@example.com"}
    
    w.Header().Set("Content-Type", "application/json")
    json.NewEncoder(w).Encode(user)
}

// POST /api/users
func createUser(w http.ResponseWriter, r *http.Request) {
    var user User
    json.NewDecoder(r.Body).Decode(&user)
    
    user.ID = "new-id-123"
    
    w.Header().Set("Content-Type", "application/json")
    w.WriteStatus(http.StatusCreated)
    json.NewEncoder(w).Encode(user)
}

func main() {
    router := mux.NewRouter()
    
    router.HandleFunc("/api/users", listUsers).Methods("GET")
    router.HandleFunc("/api/users/{id}", getUser).Methods("GET")
    router.HandleFunc("/api/users", createUser).Methods("POST")
    
    http.ListenAndServe(":8080", router)
}
```

### Best Practices

**1. Use Plural Nouns**
```
✅ /api/users
❌ /api/user
```

**2. Use HTTP Methods Correctly**
```
✅ GET /api/users        (read)
✅ POST /api/users       (create)
❌ POST /api/getUsers    (wrong verb in URL)
❌ GET /api/createUser   (wrong method)
```

**3. Return Proper Status Codes**
```go
// Success
w.WriteStatus(http.StatusOK)         // 200

// Created
w.WriteStatus(http.StatusCreated)    // 201

// Validation error
w.WriteStatus(http.StatusBadRequest) // 400

// Not found
w.WriteStatus(http.StatusNotFound)   // 404
```

**4. Use Query Parameters for Filtering**
```
/api/users?role=admin
/api/users?page=2&limit=20
/api/products?category=electronics&sort=price
```

---

## Prometheus & Grafana

### What is Prometheus?

Prometheus **collects metrics** from your services. Think of it like a nurse taking your vitals (heart rate, temperature, blood pressure).

### What is Grafana?

Grafana **visualizes metrics**. It's like turning those vitals into easy-to-read charts and graphs.

```
Your Service → Prometheus (collects metrics) → Grafana (shows charts)
```

### Metrics Example

**Your application exposes metrics:**
```
http_requests_total{method="GET",path="/api/users",status="200"} 1523
http_requests_total{method="POST",path="/api/users",status="201"} 45
http_request_duration_seconds{method="GET",path="/api/users"} 0.032
```

**Prometheus scrapes (collects) them:**
```yaml
# prometheus.yml
scrape_configs:
  - job_name: 'api-gateway'
    static_configs:
      - targets: ['api-gateway:8080']
    scrape_interval: 15s
```

### Adding Metrics to Go Service

```go
package main

import (
    "github.com/prometheus/client_golang/prometheus"
    "github.com/prometheus/client_golang/prometheus/promhttp"
    "net/http"
)

// Define metrics
var (
    requestsTotal = prometheus.NewCounterVec(
        prometheus.CounterOpts{
            Name: "http_requests_total",
            Help: "Total number of HTTP requests",
        },
        []string{"method", "path", "status"},
    )
    
    requestDuration = prometheus.NewHistogramVec(
        prometheus.HistogramOpts{
            Name: "http_request_duration_seconds",
            Help: "HTTP request duration in seconds",
        },
        []string{"method", "path"},
    )
)

func init() {
    // Register metrics
    prometheus.MustRegister(requestsTotal)
    prometheus.MustRegister(requestDuration)
}

func metricsMiddleware(next http.Handler) http.Handler {
    return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
        start := time.Now()
        
        // Call next handler
        next.ServeHTTP(w, r)
        
        // Record metrics
        duration := time.Since(start).Seconds()
        requestsTotal.WithLabelValues(r.Method, r.URL.Path, "200").Inc()
        requestDuration.WithLabelValues(r.Method, r.URL.Path).Observe(duration)
    })
}

func main() {
    // Expose metrics endpoint
    http.Handle("/metrics", promhttp.Handler())
    
    // Your API routes
    http.Handle("/api/", metricsMiddleware(yourAPIHandler))
    
    http.ListenAndServe(":8080", nil)
}
```

### Grafana Dashboards

**Create a dashboard showing:**

1. **Request Rate**
```promql
rate(http_requests_total[5m])
```

2. **Error Rate**
```promql
rate(http_requests_total{status=~"5.."}[5m])
```

3. **Response Time (p95)**
```promql
histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))
```

4. **Active Users**
```promql
count(user_sessions)
```

### Accessing Grafana

```bash
# Open Grafana
open http://localhost:3000

# Login: admin / admin

# Add Prometheus as data source
# Configuration → Data Sources → Add Prometheus
# URL: http://prometheus:9090

# Import dashboard
# Create → Import → Upload JSON
```

---

## Jaeger Tracing

### What is Distributed Tracing?

When a request goes through multiple services, tracing **follows it everywhere** like a GPS tracker.

**Without Tracing:**
```
Client → API Gateway → ??? → Slow!
```
You know it's slow, but where?

**With Tracing:**
```
Client → API Gateway (5ms)
           → Auth Service (100ms)
               → MongoDB (95ms)  ← Found the problem!
           → User Service (10ms)
```

### Trace Structure

```
Trace (entire request journey)
  └─ Span (one operation)
      ├─ Span ID
      ├─ Parent Span ID
      ├─ Operation Name
      ├─ Start Time
      ├─ Duration
      └─ Tags/Logs
```

### Real Example

```
Trace ID: abc-123-def-456
Duration: 245ms

Span 1: HTTP GET /api/users/123 [245ms]
  Span 2: Validate JWT [5ms]
  Span 3: gRPC GetUser [220ms]
    Span 4: MongoDB Query [200ms]
      Span 5: Index Scan [195ms]
    Span 6: Object Mapping [20ms]
  Span 7: JSON Serialization [20ms]
```

### Adding Tracing to Go

```go
package main

import (
    "github.com/opentracing/opentracing-go"
    "github.com/uber/jaeger-client-go"
    "github.com/uber/jaeger-client-go/config"
)

func initTracer() {
    cfg := config.Configuration{
        ServiceName: "user-service",
        Sampler: &config.SamplerConfig{
            Type:  "const",
            Param: 1,  // Sample all traces
        },
        Reporter: &config.ReporterConfig{
            LocalAgentHostPort: "jaeger:6831",
        },
    }
    
    tracer, _ := cfg.NewTracer()
    opentracing.SetGlobalTracer(tracer)
}

func handleRequest(w http.ResponseWriter, r *http.Request) {
    // Start span
    span := opentracing.StartSpan("handleRequest")
    defer span.Finish()
    
    // Add tags
    span.SetTag("user_id", "123")
    span.SetTag("http.method", r.Method)
    
    // Do database query (child span)
    dbSpan := opentracing.StartSpan(
        "database_query",
        opentracing.ChildOf(span.Context()),
    )
    result := queryDatabase()
    dbSpan.Finish()
    
    // Log event
    span.LogEvent("user_found")
    
    w.Write([]byte(result))
}
```

### Viewing Traces in Jaeger

```bash
# Open Jaeger UI
open http://localhost:16686

# Search traces:
# - By service: user-service
# - By operation: handleRequest
# - By duration: > 100ms
# - By tags: http.status_code=500
```

---

## Git & GitHub

### What is Git?

Git is **version control** - like Google Docs history for your code. It tracks every change and lets you go back in time.

### Basic Git Workflow

```bash
# 1. Clone repository
git clone https://github.com/vhvcorp/go-framework.git
cd go-framework

# 2. Create branch for your feature
git checkout -b feature/add-avatar-upload

# 3. Make changes
# Edit files...

# 4. Check what changed
git status
git diff

# 5. Stage changes
git add file1.go file2.go
# Or add all changes
git add .

# 6. Commit changes
git commit -m "feat: add avatar upload functionality"

# 7. Push to GitHub
git push origin feature/add-avatar-upload

# 8. Create Pull Request on GitHub
# Go to GitHub → Pull Requests → New
```

### Common Commands

```bash
# See commit history
git log --oneline

# See changes
git diff

# Undo changes (not committed)
git checkout -- file.go

# Undo last commit (keep changes)
git reset --soft HEAD~1

# Get latest changes
git pull

# Switch branches
git checkout main
git checkout feature/my-feature

# Create new branch
git checkout -b feature/new-feature

# Delete branch
git branch -d feature/old-feature

# See all branches
git branch -a
```

### Commit Message Convention

```
feat: add new feature
fix: fix bug
docs: update documentation
style: code formatting
refactor: code restructure
test: add tests
chore: maintenance tasks
```

### Examples

```bash
git commit -m "feat(users): add avatar upload functionality"
git commit -m "fix(auth): fix JWT expiration bug"
git commit -m "docs: add API documentation"
git commit -m "test(users): add user creation tests"
```

---

## Makefile

### What is a Makefile?

A Makefile is like a **recipe book for commands**. Instead of typing long commands, you type short names.

### Example

**Without Makefile:**
```bash
docker-compose -f docker/docker-compose.yml up -d
docker-compose -f docker/docker-compose.yml logs -f
docker exec -it mongodb mongosh
```

**With Makefile:**
```bash
make start
make logs
make db-shell
```

### Basic Makefile

```makefile
# Makefile

# Default target (runs when you type just "make")
.DEFAULT_GOAL := help

# Start all services
start:
	@echo "Starting services..."
	docker-compose up -d

# Stop all services
stop:
	@echo "Stopping services..."
	docker-compose down

# View logs
logs:
	docker-compose logs -f

# Access database
db-shell:
	docker exec -it mongodb mongosh

# Run tests
test:
	go test ./...

# Help (shows all commands)
help:
	@echo "Available commands:"
	@echo "  make start    - Start all services"
	@echo "  make stop     - Stop all services"
	@echo "  make logs     - View logs"
	@echo "  make test     - Run tests"
```

### Using Variables

```makefile
SERVICE_NAME=user-service
IMAGE_NAME=vhvcorp/$(SERVICE_NAME)

# Build Docker image
build:
	docker build -t $(IMAGE_NAME) .

# Run specific service
run:
	docker run -p 8080:8080 $(IMAGE_NAME)

# Pass variable from command line
# make run SERVICE_NAME=auth-service
```

### Phony Targets

```makefile
# Tell make these aren't file names
.PHONY: start stop test clean

start:
	docker-compose up -d

stop:
	docker-compose down

test:
	go test ./...

clean:
	rm -rf bin/ tmp/
```

---

## Shell Scripting

### What is Shell Scripting?

Shell scripts are like **automated instructions** for your computer. Instead of typing commands one by one, write them in a file and run all at once.

### Basic Example

```bash
#!/bin/bash
# setup.sh - Setup script

echo "Starting setup..."

# Install dependencies
echo "Installing dependencies..."
brew install jq

# Create directories
echo "Creating directories..."
mkdir -p logs backups data

# Start services
echo "Starting services..."
docker-compose up -d

echo "Setup complete!"
```

```bash
# Make executable
chmod +x setup.sh

# Run it
./setup.sh
```

### Variables

```bash
#!/bin/bash

# Define variables
NAME="Alice"
AGE=25
WORKSPACE="$HOME/workspace"

echo "Name: $NAME"
echo "Age: $AGE"
echo "Workspace: $WORKSPACE"

# User input
read -p "Enter your name: " USERNAME
echo "Hello, $USERNAME!"
```

### Conditions

```bash
#!/bin/bash

# Check if file exists
if [ -f "config.yml" ]; then
    echo "Config file exists"
else
    echo "Config file not found"
    exit 1
fi

# Check if command exists
if command -v docker &> /dev/null; then
    echo "Docker is installed"
else
    echo "Docker not found"
fi

# Numeric comparison
AGE=25
if [ $AGE -ge 18 ]; then
    echo "Adult"
else
    echo "Minor"
fi
```

### Loops

```bash
#!/bin/bash

# Loop over list
SERVICES=("mongodb" "redis" "rabbitmq")

for service in "${SERVICES[@]}"; do
    echo "Starting $service..."
    docker start "$service"
done

# Loop with counter
for i in {1..5}; do
    echo "Attempt $i"
    sleep 1
done

# While loop
counter=0
while [ $counter -lt 5 ]; do
    echo "Counter: $counter"
    counter=$((counter + 1))
done
```

### Functions

```bash
#!/bin/bash

# Define function
check_service() {
    local service_name=$1
    
    if docker ps | grep -q "$service_name"; then
        echo "✓ $service_name is running"
        return 0
    else
        echo "✗ $service_name is not running"
        return 1
    fi
}

# Use function
check_service "mongodb"
check_service "redis"
check_service "api-gateway"
```

### Error Handling

```bash
#!/bin/bash

# Exit on error
set -e

# Function to handle errors
handle_error() {
    echo "Error occurred on line $1"
    exit 1
}

# Trap errors
trap 'handle_error $LINENO' ERR

# Your script
echo "Running command..."
docker-compose up -d

echo "Success!"
```

### Useful Patterns

**Check prerequisites:**
```bash
#!/bin/bash

# Check Docker
if ! command -v docker &> /dev/null; then
    echo "Error: Docker not installed"
    exit 1
fi

# Check file
if [ ! -f ".env" ]; then
    echo "Error: .env file not found"
    exit 1
fi

echo "All prerequisites met!"
```

**Color output:**
```bash
#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

echo -e "${GREEN}✓ Success${NC}"
echo -e "${RED}✗ Error${NC}"
```

**User confirmation:**
```bash
#!/bin/bash

read -p "Are you sure? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Proceeding..."
else
    echo "Cancelled"
    exit 0
fi
```

---

## Summary

This guide covered all the technologies in go-framework:

1. **Docker** - Containers for consistent environments
2. **Go** - Fast, simple programming language
3. **MongoDB** - Flexible NoSQL database
4. **Redis** - Super-fast in-memory cache
5. **RabbitMQ** - Message queue for async tasks
6. **gRPC** - Fast inter-service communication
7. **JWT** - Stateless authentication tokens
8. **Microservices** - Small, independent services
9. **REST API** - HTTP-based web APIs
10. **Prometheus & Grafana** - Metrics and monitoring
11. **Jaeger** - Distributed tracing
12. **Git** - Version control
13. **Makefile** - Command automation
14. **Shell Scripts** - Automated tasks

### Next Steps

1. **Hands-on Practice**: Try the examples in this guide
2. **Read Official Docs**: Each technology has great documentation
3. **Build a Project**: Best way to learn is by doing
4. **Ask Questions**: Use GitHub Issues or community forums

### Resources

- [Docker Documentation](https://docs.docker.com/)
- [Go by Example](https://gobyexample.com/)
- [MongoDB University](https://university.mongodb.com/)
- [Redis Documentation](https://redis.io/documentation)
- [RabbitMQ Tutorials](https://www.rabbitmq.com/getstarted.html)
- [gRPC Documentation](https://grpc.io/docs/)
- [JWT.io](https://jwt.io/)

---

**Last Updated:** 2024-12-25
