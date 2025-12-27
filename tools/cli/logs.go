package main

import (
	"fmt"
	"os"

	"github.com/spf13/cobra"
)

var logsCmd = &cobra.Command{
	Use:   "logs [service]",
	Short: "View service logs",
	Long: `View logs from all services or a specific service.

Examples:
  saas logs              # View all logs
  saas logs auth         # View auth service logs`,
	Run: func(cmd *cobra.Command, args []string) {
		target := "logs"

		if len(args) > 0 {
			// Specific service
			service := args[0]
			fmt.Printf("📋 Viewing %s logs...\n", service)
			target = "logs-service SERVICE=" + service + "-service"
		} else {
			// All logs
			fmt.Println("📋 Viewing all service logs...")
		}

		if err := runCommand("make", target); err != nil {
			fmt.Fprintf(os.Stderr, "❌ Failed to view logs: %v\n", err)
			os.Exit(1)
		}
	},
}
