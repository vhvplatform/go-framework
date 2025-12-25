package main

import (
	"fmt"
	"os"
	"os/exec"

	"github.com/spf13/cobra"
)

var statusCmd = &cobra.Command{
	Use:   "status",
	Short: "Check service status",
	Long: `Check the health and status of all services.

This command will:
  - Check if services are running
  - Verify health endpoints
  - Show service URLs`,
	Run: func(cmd *cobra.Command, args []string) {
		fmt.Println("🏥 Checking service status...")
		fmt.Println()
		
		// Run make status
		makeCmd := exec.Command("make", "status")
		makeCmd.Stdout = os.Stdout
		makeCmd.Stderr = os.Stderr
		
		if err := makeCmd.Run(); err != nil {
			fmt.Fprintf(os.Stderr, "❌ Status check failed: %v\n", err)
			os.Exit(1)
		}
		
		fmt.Println()
		fmt.Println("💡 View service URLs: saas info")
		fmt.Println("💡 View logs: saas logs [service]")
	},
}
