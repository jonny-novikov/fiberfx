// Datadog toolkit for phoenix workspace
// Provides CLI commands for querying Datadog API: hosts, APM services, traces
package main

import (
	"os"

	"github.com/fiberfx/datadog/cmd"
	"github.com/joho/godotenv"
)

func main() {
	// Load .env if present
	_ = godotenv.Load()
	_ = godotenv.Load(".env.local")

	if err := cmd.Execute(); err != nil {
		os.Exit(1)
	}
}
