package main

import (
	"fmt"
	"os"
	"os/exec"

	"github.com/spf13/cobra"
)

var (
	version = "1.0.0"
)

// runCommand executes a command with the given arguments and pipes output to stdout/stderr.
// Returns an error if the command fails.
func runCommand(name string, args ...string) error {
	cmd := exec.Command(name, args...)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	return cmd.Run()
}

var rootCmd = &cobra.Command{
	Use:   "saas",
	Short: "SaaS Platform Developer CLI",
	Long: `A command-line tool to manage local development of the SaaS Platform.

This tool provides convenient commands for:
  - Setting up development environment
  - Managing services (start, stop, restart)
  - Running tests
  - Deploying to local/dev environments
  - Viewing logs and status

Examples:
  saas setup          # Setup development environment
  saas start          # Start all services
  saas stop           # Stop all services
  saas logs auth      # View auth service logs
  saas test           # Run all tests
  saas deploy local   # Deploy to local Kubernetes

For more information, visit: https://github.com/vhvplatform/go-framework`,
	Run: func(cmd *cobra.Command, args []string) {
		cmd.Help()
	},
}

var versionCmd = &cobra.Command{
	Use:   "version",
	Short: "Print version information",
	Run: func(cmd *cobra.Command, args []string) {
		fmt.Printf("SaaS Platform CLI v%s\n", version)
	},
}

func init() {
	rootCmd.AddCommand(versionCmd)
	rootCmd.AddCommand(setupCmd)
	rootCmd.AddCommand(startCmd)
	rootCmd.AddCommand(stopCmd)
	rootCmd.AddCommand(logsCmd)
	rootCmd.AddCommand(testCmd)
	rootCmd.AddCommand(statusCmd)
	rootCmd.AddCommand(deployCmd)
}

func main() {
	if err := rootCmd.Execute(); err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
}
