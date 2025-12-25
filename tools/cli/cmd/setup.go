package main

import (
	"fmt"
	"os"
	"os/exec"

	"github.com/spf13/cobra"
)

var setupCmd = &cobra.Command{
	Use:   "setup",
	Short: "Setup development environment",
	Long: `Install dependencies, clone repositories, and setup workspace.

This command will:
  1. Install required dependencies (Go, Docker, kubectl, etc.)
  2. Clone all service repositories
  3. Install Go development tools
  4. Initialize workspace configuration`,
	Run: func(cmd *cobra.Command, args []string) {
		fmt.Println("🚀 Setting up development environment...")
		
		// Run make setup
		makeCmd := exec.Command("make", "setup")
		makeCmd.Stdout = os.Stdout
		makeCmd.Stderr = os.Stderr
		
		if err := makeCmd.Run(); err != nil {
			fmt.Fprintf(os.Stderr, "❌ Setup failed: %v\n", err)
			os.Exit(1)
		}
		
		fmt.Println("✅ Setup complete!")
		fmt.Println("\nNext steps:")
		fmt.Println("  saas start    # Start all services")
		fmt.Println("  saas status   # Check service status")
	},
}
