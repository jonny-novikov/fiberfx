// Command mcpd controls the local MCP servers — aaw (apps/aaw, :8905) and msh
// (apps/msh, :8899) — as background daemons living in <repo>/bin.
//
// With no arguments it opens a Bubble Tea control panel. For scripting it offers
// plain subcommands:
//
//	mcpd start   [-d]   build (if needed) and start both servers
//	mcpd restart [-d]   build → atomic swap → restart both (safe hot-swap)
//	mcpd stop           stop both
//	mcpd status         one-shot status table
//
// Without -d, start/restart supervise in the foreground (Ctrl-C stops both);
// with -d they detach and return, leaving the servers running. `make mcp` runs
// `mcpd restart -d`.
package main

import (
	"fmt"
	"os"

	"github.com/spf13/cobra"
)

// rootFlagRepo is the value of the persistent --root flag (empty ⇒ auto-detect).
var rootFlagRepo string

func main() {
	if err := newRootCmd().Execute(); err != nil {
		fmt.Fprintln(os.Stderr, "mcpd:", err)
		os.Exit(1)
	}
}

func newRootCmd() *cobra.Command {
	root := &cobra.Command{
		Use:   "mcpd",
		Short: "Control the aaw + msh MCP servers (bin/aaw, bin/msh).",
		Long: "mcpd builds, starts, stops and hot-swap-restarts the local MCP\n" +
			"servers — aaw (:8905) and msh (:8899). Run with no args for the TUI.",
		Args:          cobra.NoArgs,
		SilenceUsage:  true,
		SilenceErrors: true,
		RunE: func(_ *cobra.Command, _ []string) error {
			root, err := resolveRoot(rootFlagRepo)
			if err != nil {
				return err
			}
			return runTUI(root)
		},
	}
	root.PersistentFlags().StringVar(&rootFlagRepo, "root", "", "jonnify repo root (default: auto-detect from the mcpd binary / cwd)")
	root.AddCommand(newStartCmd(), newRestartCmd(), newStopCmd(), newStatusCmd())
	return root
}

func newStartCmd() *cobra.Command {
	var detach bool
	c := &cobra.Command{
		Use:   "start",
		Short: "Build (if needed) and start both MCP servers.",
		Args:  cobra.NoArgs,
		RunE:  func(_ *cobra.Command, _ []string) error { return runStart(detach) },
	}
	c.Flags().BoolVarP(&detach, "detach", "d", false, "start in the background and return (servers outlive mcpd)")
	return c
}

func newRestartCmd() *cobra.Command {
	var detach bool
	c := &cobra.Command{
		Use:   "restart",
		Short: "Build → atomic swap → restart both servers (safe hot-swap).",
		Args:  cobra.NoArgs,
		RunE:  func(_ *cobra.Command, _ []string) error { return runRestart(detach) },
	}
	c.Flags().BoolVarP(&detach, "detach", "d", false, "restart in the background and return (servers outlive mcpd)")
	return c
}

func newStopCmd() *cobra.Command {
	return &cobra.Command{
		Use:   "stop",
		Short: "Stop both MCP servers.",
		Args:  cobra.NoArgs,
		RunE:  func(_ *cobra.Command, _ []string) error { return runStop() },
	}
}

func newStatusCmd() *cobra.Command {
	return &cobra.Command{
		Use:   "status",
		Short: "Show whether each MCP server is running.",
		Args:  cobra.NoArgs,
		RunE:  func(_ *cobra.Command, _ []string) error { return runStatus() },
	}
}
