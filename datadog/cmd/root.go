package cmd

import (
	"context"
	"fmt"
	"os"
	"path/filepath"

	"github.com/DataDog/datadog-api-client-go/v2/api/datadog"
	"github.com/fiberfx/datadog/config"
	"github.com/spf13/cobra"
)

var (
	apiKey    string
	appKey    string
	env       string
	outputFmt string
	confDir   string
	cfg       *config.Config
)

var rootCmd = &cobra.Command{
	Use:   "datadog",
	Short: "Datadog toolkit for phoenix workspace",
	Long: `A CLI toolkit for querying Datadog API.

Supports:
  - hosts    List and query infrastructure hosts
  - apm      Query APM services and traces
  - validate Validate API credentials

Configuration:
  Uses datadog.conf (nginx-style) for env-less operation.
  Falls back to DD_API_KEY / DD_APP_KEY environment variables.

Example datadog.conf:
  api {
      key     YOUR_API_KEY;
      app_key YOUR_APP_KEY;
  }
`,
	PersistentPreRunE: func(cmd *cobra.Command, args []string) error {
		// Load config from confDir or current directory
		dir := confDir
		if dir == "" {
			// Try executable directory first
			if exe, err := os.Executable(); err == nil {
				dir = filepath.Dir(exe)
			}
		}
		if dir == "" {
			dir = "."
		}

		var err error
		cfg, err = config.LoadFromDir(dir)
		if err != nil {
			return fmt.Errorf("config load: %w", err)
		}

		// Apply config defaults if flags not set
		if outputFmt == "" || outputFmt == "json" {
			if cfg.Defaults.Output != "" {
				outputFmt = cfg.Defaults.Output
			}
		}
		if env == "" || env == "production" {
			if cfg.Defaults.Env != "" {
				env = cfg.Defaults.Env
			}
		}

		return nil
	},
}

func Execute() error {
	return rootCmd.Execute()
}

func init() {
	rootCmd.PersistentFlags().StringVar(&apiKey, "api-key", "", "Datadog API key (overrides config)")
	rootCmd.PersistentFlags().StringVar(&appKey, "app-key", "", "Datadog App key (overrides config)")
	rootCmd.PersistentFlags().StringVar(&env, "env", "production", "Environment filter")
	rootCmd.PersistentFlags().StringVarP(&outputFmt, "output", "o", "json", "Output format: json, table")
	rootCmd.PersistentFlags().StringVar(&confDir, "conf-dir", "", "Config directory (default: executable dir)")
}

// newAPIContext creates a context with Datadog credentials
func newAPIContext() (context.Context, *datadog.APIClient, error) {
	// Priority: flag > config > env
	key := apiKey
	if key == "" && cfg != nil {
		key = cfg.API.Key
	}
	if key == "" {
		key = os.Getenv("DD_API_KEY")
	}

	app := appKey
	if app == "" && cfg != nil {
		app = cfg.API.AppKey
	}
	if app == "" {
		app = os.Getenv("DD_APP_KEY")
	}

	if key == "" || app == "" {
		return nil, nil, fmt.Errorf("API credentials required: use --api-key/--app-key, datadog.conf, or DD_API_KEY/DD_APP_KEY env")
	}

	ctx := context.WithValue(context.Background(), datadog.ContextAPIKeys, map[string]datadog.APIKey{
		"apiKeyAuth": {Key: key},
		"appKeyAuth": {Key: app},
	})

	configuration := datadog.NewConfiguration()
	client := datadog.NewAPIClient(configuration)

	return ctx, client, nil
}
