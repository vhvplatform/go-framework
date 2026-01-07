package main

import (
	"fmt"
	"os"

	"github.com/spf13/cobra"
)

var (
	devMode bool
)

var startCmd = &cobra.Command{
	Use:   "start [service]",
	Short: "Start services",
	Long: `Start all services or a specific service.

Examples:
  saas start              # Start all services
  saas start auth         # Start only auth service
  saas start --dev        # Start with hot-reload`,
	Run: func(cmd *cobra.Command, args []string) {
		if len(args) == 0 {
			// Start all services
			fmt.Println("🚀 Starting all services...")

			target := "start"
			if devMode {
				target = "start-dev"
				fmt.Println("   (development mode with hot-reload)")
			}

			if err := runCommand("make", target); err != nil {
				fmt.Fprintf(os.Stderr, "❌ Failed to start services: %v\n", err)
				os.Exit(1)
			}
		} else {
			// Start specific service
			service := args[0]
			fmt.Printf("🚀 Starting %s...\n", service)

			if err := runCommand("make", "restart-service", "SERVICE="+service+"-service"); err != nil {
				fmt.Fprintf(os.Stderr, "❌ Failed to start %s: %v\n", service, err)
				os.Exit(1)
			}
		}

		fmt.Println("✅ Services started!")
		fmt.Println("\nCheck status with: saas status")
	},
}

func init() {
	startCmd.Flags().BoolVar(&devMode, "dev", false, "Start in development mode with hot-reload")
}
