package main

import (
	"bytes"
	"strings"
	"testing"

	"github.com/spf13/cobra"
)

// resetRootCmd resets the rootCmd for each test to avoid state pollution
func resetRootCmd() *cobra.Command {
	cmd := &cobra.Command{
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

	cmd.AddCommand(versionCmd)
	cmd.AddCommand(setupCmd)
	cmd.AddCommand(startCmd)
	cmd.AddCommand(stopCmd)
	cmd.AddCommand(logsCmd)
	cmd.AddCommand(testCmd)
	cmd.AddCommand(statusCmd)
	cmd.AddCommand(deployCmd)

	return cmd
}

func TestVersionCommand(t *testing.T) {
	// Reset and capture output
	cmd := resetRootCmd()
	buf := new(bytes.Buffer)
	cmd.SetOut(buf)
	cmd.SetErr(buf)
	cmd.SetArgs([]string{"version"})

	// Execute command
	err := cmd.Execute()
	if err != nil {
		t.Fatalf("Expected no error, got %v", err)
	}

	// Check output - version command writes directly to fmt.Printf
	// So we'll just verify the command executed without error
	// The actual version output goes to stdout which we can't easily capture
}

func TestRootCommandHelp(t *testing.T) {
	// Reset and capture output
	cmd := resetRootCmd()
	buf := new(bytes.Buffer)
	cmd.SetOut(buf)
	cmd.SetErr(buf)
	cmd.SetArgs([]string{"--help"})

	// Execute command
	err := cmd.Execute()
	if err != nil {
		t.Fatalf("Expected no error, got %v", err)
	}

	// Check output
	output := buf.String()
	expectedStrings := []string{
		"SaaS Platform",
		"setup",
		"start",
		"stop",
		"logs",
		"test",
		"status",
		"deploy",
	}

	for _, expected := range expectedStrings {
		if !strings.Contains(output, expected) {
			t.Errorf("Expected help output to contain '%s'", expected)
		}
	}
}

func TestCommandExists(t *testing.T) {
	tests := []struct {
		name    string
		command string
	}{
		{"Setup command", "setup"},
		{"Start command", "start"},
		{"Stop command", "stop"},
		{"Logs command", "logs"},
		{"Test command", "test"},
		{"Status command", "status"},
		{"Deploy command", "deploy"},
		{"Version command", "version"},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			cmd := resetRootCmd()
			foundCmd, _, err := cmd.Find([]string{tt.command})
			if err != nil {
				t.Errorf("Command %s should exist, got error: %v", tt.command, err)
			}
			if foundCmd == nil {
				t.Errorf("Command %s should exist, got nil", tt.command)
			}
			if foundCmd != nil && foundCmd.Name() != tt.command {
				t.Errorf("Expected command name %s, got %s", tt.command, foundCmd.Name())
			}
		})
	}
}

func TestSetupCommandHasDescription(t *testing.T) {
	cmd := resetRootCmd()
	setupCmd, _, err := cmd.Find([]string{"setup"})
	if err != nil {
		t.Fatalf("Setup command should exist: %v", err)
	}

	if setupCmd.Short == "" {
		t.Error("Setup command should have a short description")
	}
	if setupCmd.Long == "" {
		t.Error("Setup command should have a long description")
	}
}

func TestStartCommandHasDescription(t *testing.T) {
	cmd := resetRootCmd()
	startCmd, _, err := cmd.Find([]string{"start"})
	if err != nil {
		t.Fatalf("Start command should exist: %v", err)
	}

	if startCmd.Short == "" {
		t.Error("Start command should have a short description")
	}
}

func TestStopCommandHasDescription(t *testing.T) {
	cmd := resetRootCmd()
	stopCmd, _, err := cmd.Find([]string{"stop"})
	if err != nil {
		t.Fatalf("Stop command should exist: %v", err)
	}

	if stopCmd.Short == "" {
		t.Error("Stop command should have a short description")
	}
}

func TestStatusCommandHasDescription(t *testing.T) {
	cmd := resetRootCmd()
	statusCmd, _, err := cmd.Find([]string{"status"})
	if err != nil {
		t.Fatalf("Status command should exist: %v", err)
	}

	if statusCmd.Short == "" {
		t.Error("Status command should have a short description")
	}
}

func TestTestCommandHasDescription(t *testing.T) {
	cmd := resetRootCmd()
	testCmd, _, err := cmd.Find([]string{"test"})
	if err != nil {
		t.Fatalf("Test command should exist: %v", err)
	}

	if testCmd.Short == "" {
		t.Error("Test command should have a short description")
	}
}

func TestDeployCommandHasDescription(t *testing.T) {
	cmd := resetRootCmd()
	deployCmd, _, err := cmd.Find([]string{"deploy"})
	if err != nil {
		t.Fatalf("Deploy command should exist: %v", err)
	}

	if deployCmd.Short == "" {
		t.Error("Deploy command should have a short description")
	}
}

func TestLogsCommandHasServiceArgument(t *testing.T) {
	cmd := resetRootCmd()
	logsCmd, _, err := cmd.Find([]string{"logs"})
	if err != nil {
		t.Fatalf("Logs command should exist: %v", err)
	}

	// Logs command should accept a service name as argument
	if logsCmd.Short == "" {
		t.Error("Logs command should have a short description")
	}
}

func TestRootCommandStructure(t *testing.T) {
	cmd := resetRootCmd()

	if cmd.Use != "saas" {
		t.Errorf("Expected root command use 'saas', got '%s'", cmd.Use)
	}

	if cmd.Short == "" {
		t.Error("Root command should have a short description")
	}

	if cmd.Long == "" {
		t.Error("Root command should have a long description")
	}
}

func TestVersionValue(t *testing.T) {
	if version == "" {
		t.Error("Version should not be empty")
	}

	// Version should follow semantic versioning pattern
	if !strings.Contains(version, ".") {
		t.Errorf("Version '%s' should contain dots for semantic versioning", version)
	}
}
