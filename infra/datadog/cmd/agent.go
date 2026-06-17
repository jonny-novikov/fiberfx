package cmd

import (
	"encoding/json"
	"fmt"
	"os"
	"os/exec"
	"strings"

	"github.com/spf13/cobra"
)

var (
	agentApp string
)

var agentCmd = &cobra.Command{
	Use:   "agent",
	Short: "Datadog agent management (via flyctl)",
	Long: `Manage the Datadog agent running on Fly.io.

Requires flyctl to be installed and authenticated.

Examples:
  datadog agent status
  datadog agent logs
  datadog agent check`,
}

var agentStatusCmd = &cobra.Command{
	Use:   "status",
	Short: "Get Datadog agent status on Fly.io",
	RunE: func(cmd *cobra.Command, args []string) error {
		// Check flyctl is available
		if _, err := exec.LookPath("flyctl"); err != nil {
			return fmt.Errorf("flyctl not found in PATH")
		}

		fmt.Printf("Checking agent status for app: %s\n\n", agentApp)

		// Get machine status
		out, err := exec.Command("flyctl", "status", "-a", agentApp).Output()
		if err != nil {
			return fmt.Errorf("flyctl status failed: %w", err)
		}
		fmt.Println(string(out))

		return nil
	},
}

var agentLogsCmd = &cobra.Command{
	Use:   "logs",
	Short: "Stream Datadog agent logs",
	Long: `Stream real-time logs from the Datadog agent.

This command uses flyctl logs to stream agent logs for debugging.`,
	RunE: func(cmd *cobra.Command, args []string) error {
		if _, err := exec.LookPath("flyctl"); err != nil {
			return fmt.Errorf("flyctl not found in PATH")
		}

		fmt.Printf("Streaming logs from: %s (Ctrl+C to stop)\n\n", agentApp)

		// Stream logs (this will run until interrupted)
		c := exec.Command("flyctl", "logs", "-a", agentApp)
		c.Stdout = os.Stdout
		c.Stderr = os.Stderr
		return c.Run()
	},
}

var agentCheckCmd = &cobra.Command{
	Use:   "check",
	Short: "Run agent health check via SSH",
	Long: `SSH into the agent and run datadog-agent status.

This provides detailed information about:
- Collector status
- APM status
- Forwarder status
- Running checks`,
	RunE: func(cmd *cobra.Command, args []string) error {
		if _, err := exec.LookPath("flyctl"); err != nil {
			return fmt.Errorf("flyctl not found in PATH")
		}

		fmt.Printf("Running agent status check on: %s\n\n", agentApp)

		// SSH and run agent status
		c := exec.Command("flyctl", "ssh", "console", "-a", agentApp, "-C", "datadog-agent status")
		c.Stdout = os.Stdout
		c.Stderr = os.Stderr
		return c.Run()
	},
}

var agentInfoCmd = &cobra.Command{
	Use:   "info",
	Short: "Get agent configuration info via API",
	RunE: func(cmd *cobra.Command, args []string) error {
		ctx, client, err := newAPIContext()
		if err != nil {
			return err
		}

		// Use the hosts API to get agent info
		_ = ctx
		_ = client

		// Get machine info from flyctl
		out, err := exec.Command("flyctl", "machines", "list", "-a", agentApp, "--json").Output()
		if err != nil {
			return fmt.Errorf("flyctl machines list failed: %w", err)
		}

		if outputFmt == "table" {
			var machines []map[string]interface{}
			if err := json.Unmarshal(out, &machines); err != nil {
				return fmt.Errorf("parse machines: %w", err)
			}

			fmt.Printf("Agent App: %s\n", agentApp)
			fmt.Println(strings.Repeat("-", 50))

			for _, m := range machines {
				fmt.Printf("Machine ID: %v\n", m["id"])
				fmt.Printf("State:      %v\n", m["state"])
				fmt.Printf("Region:     %v\n", m["region"])
				if config, ok := m["config"].(map[string]interface{}); ok {
					if image, ok := config["image"]; ok {
						fmt.Printf("Image:      %v\n", image)
					}
				}
				fmt.Println()
			}
			return nil
		}

		fmt.Println(string(out))
		return nil
	},
}

func init() {
	agentCmd.PersistentFlags().StringVar(&agentApp, "app", "sm-datadog-agent", "Fly.io app name for Datadog agent")

	agentCmd.AddCommand(agentStatusCmd)
	agentCmd.AddCommand(agentLogsCmd)
	agentCmd.AddCommand(agentCheckCmd)
	agentCmd.AddCommand(agentInfoCmd)
	rootCmd.AddCommand(agentCmd)
}
