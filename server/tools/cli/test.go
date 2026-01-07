package main

import (
	"fmt"
	"os"

	"github.com/spf13/cobra"
)

var (
	testType string
)

var testCmd = &cobra.Command{
	Use:   "test",
	Short: "Run tests",
	Long: `Run various types of tests.

Examples:
  saas test               # Run all tests
  saas test --type=unit   # Run unit tests only
  saas test --type=integration  # Run integration tests
  saas test --type=e2e    # Run end-to-end tests
  saas test --type=load   # Run load tests`,
	Run: func(cmd *cobra.Command, args []string) {
		target := "test"

		switch testType {
		case "unit":
			fmt.Println("🧪 Running unit tests...")
			target = "test-unit"
		case "integration":
			fmt.Println("🧪 Running integration tests...")
			target = "test-integration"
		case "e2e":
			fmt.Println("🧪 Running end-to-end tests...")
			target = "test-e2e"
		case "load":
			fmt.Println("🧪 Running load tests...")
			target = "test-load"
		default:
			fmt.Println("🧪 Running all tests...")
		}

		if err := runCommand("make", target); err != nil {
			fmt.Fprintf(os.Stderr, "❌ Tests failed: %v\n", err)
			os.Exit(1)
		}

		fmt.Println("✅ Tests complete!")
	},
}

func init() {
	testCmd.Flags().StringVar(&testType, "type", "", "Test type: unit, integration, e2e, load")
}
