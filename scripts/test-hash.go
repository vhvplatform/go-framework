package main

import (
	"fmt"

	"golang.org/x/crypto/bcrypt"
)

func main() {
	password := "Admin@123"

	// Test với hash cũ từ seed script
	oldHash := "$2a$10$8K1p/a0dL3.y6l5Mqi7hQuw0.0wQ7T5SxRqHJZqU0WqJw9LxqJqZK"
	err := bcrypt.CompareHashAndPassword([]byte(oldHash), []byte(password))
	if err == nil {
		fmt.Println("✓ Old hash works!")
	} else {
		fmt.Println("✗ Old hash failed:", err)
	}

	// Test với hash mới
	newHash := "$2a$10$vlZNtBZIYraBi41aBplLmetms/Ae3dWwbJfAkE/8kAaWnRDCDFxuu"
	err = bcrypt.CompareHashAndPassword([]byte(newHash), []byte(password))
	if err == nil {
		fmt.Println("✓ New hash works!")
	} else {
		fmt.Println("✗ New hash failed:", err)
	}
}
