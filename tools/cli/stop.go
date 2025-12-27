package main

import (
	"fmt"
	"os"

	"github.com/spf13/cobra"
)

var stopCmd = &cobra.Command{
	Use:   "stop [service]",
	Short: "Stop services",
	Long: `Stop all services or a specific service.

Examples:
  saas stop           # Stop all services
  saas stop auth      # Stop only auth service`,
	Run: func(cmd *cobra.Command, args []string) {
		if len(args) == 0 {
			// Stop all services
			fmt.Println("⏸️  Stopping all services...")

			if err := runCommand("make", "stop"); err != nil {
				fmt.Fprintf(os.Stderr, "❌ Failed to stop services: %v\n", err)
				os.Exit(1)
			}
		} else {
			// Stop specific service
			service := args[0]
			fmt.Printf("⏸️  Stopping %s...\n", service)

			if err := runCommand("docker-compose", "-f", "docker/docker-compose.yml", "stop", service+"-service"); err != nil {
				fmt.Fprintf(os.Stderr, "❌ Failed to stop %s: %v\n", service, err)
				os.Exit(1)
			}
		}

		fmt.Println("✅ Services stopped!")
	},
}
