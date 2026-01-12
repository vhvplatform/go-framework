package main

import (
	"fmt"

	"golang.org/x/crypto/bcrypt"
)

func main() {
	password := "Admin@123"
	hashFromDB := "$2a$10$vlZNtBZIYraBi41aBplLmetms/Ae3dWwbJfAkE/8kAaWnRDCDFxuu"

	fmt.Println("Testing password:", password)
	fmt.Println("Against hash:", hashFromDB)
	fmt.Println()

	err := bcrypt.CompareHashAndPassword([]byte(hashFromDB), []byte(password))
	if err == nil {
		fmt.Println("✓✓✓ PASSWORD MATCHES! ✓✓✓")
	} else {
		fmt.Println("✗✗✗ PASSWORD DOES NOT MATCH! ✗✗✗")
		fmt.Println("Error:", err)
	}
}
