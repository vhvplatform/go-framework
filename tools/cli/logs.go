package main

import (
	"fmt"
	"os"
	"os/exec"

	"github.com/spf13/cobra"
)

var (
	follow bool
)

var logsCmd = &cobra.Command{
	Use:   "logs [service]",
	Short: "View service logs",
	Long: `View logs from all services or a specific service.

Examples:
  saas logs              # View all logs
  saas logs auth         # View auth service logs
  saas logs -f auth      # Follow auth service logs`,
	Run: func(cmd *cobra.Command, args []string) {
		var target string

		if len(args) == 0 {
			// All logs
			fmt.Println("📋 Viewing all service logs...")
			target = "logs"
		} else {
			// Specific service
			service := args[0]
			fmt.Printf("📋 Viewing %s logs...\n", service)
			target = fmt.Sprintf("logs-service SERVICE=%s-service", service)
		}

		makeCmd := exec.Command("make", target)
		makeCmd.Stdout = os.Stdout
		makeCmd.Stderr = os.Stderr

		if err := makeCmd.Run(); err != nil {
			fmt.Fprintf(os.Stderr, "❌ Failed to view logs: %v\n", err)
			os.Exit(1)
		}
	},
}

func init() {
	logsCmd.Flags().BoolVarP(&follow, "follow", "f", false, "Follow log output")
}
