package main

import (
	"fmt"
	"os"
	"os/exec"

	"github.com/spf13/cobra"
)

var deployCmd = &cobra.Command{
	Use:   "deploy [environment]",
	Short: "Deploy to environment",
	Long: `Deploy services to specified environment.

Environments:
  local     # Deploy to local Kubernetes cluster
  dev       # Deploy to development environment

Examples:
  saas deploy local   # Deploy to local cluster
  saas deploy dev     # Deploy to dev environment`,
	Args: cobra.ExactArgs(1),
	Run: func(cmd *cobra.Command, args []string) {
		env := args[0]

		var target string
		switch env {
		case "local":
			target = "deploy-local"
			fmt.Println("☸️  Deploying to local Kubernetes...")
		case "dev":
			target = "deploy-dev"
			fmt.Println("☸️  Deploying to development environment...")
		default:
			fmt.Fprintf(os.Stderr, "❌ Unknown environment: %s\n", env)
			fmt.Println("Available environments: local, dev")
			os.Exit(1)
		}

		makeCmd := exec.Command("make", target)
		makeCmd.Stdout = os.Stdout
		makeCmd.Stderr = os.Stderr

		if err := makeCmd.Run(); err != nil {
			fmt.Fprintf(os.Stderr, "❌ Deployment failed: %v\n", err)
			os.Exit(1)
		}

		fmt.Println("✅ Deployment complete!")
	},
}
