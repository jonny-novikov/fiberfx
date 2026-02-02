package cmd

import (
	"encoding/json"
	"fmt"
	"os"
	"text/tabwriter"

	"github.com/DataDog/datadog-api-client-go/v2/api/datadogV1"
	"github.com/spf13/cobra"
)

var (
	hostsFilter string
	hostsLimit  int64
)

var hostsCmd = &cobra.Command{
	Use:   "hosts",
	Short: "List infrastructure hosts",
	Long:  `Query Datadog for infrastructure hosts with optional filtering.`,
	RunE: func(cmd *cobra.Command, args []string) error {
		ctx, client, err := newAPIContext()
		if err != nil {
			return err
		}

		api := datadogV1.NewHostsApi(client)
		opts := datadogV1.NewListHostsOptionalParameters()
		if hostsFilter != "" {
			opts = opts.WithFilter(hostsFilter)
		}
		if hostsLimit > 0 {
			opts = opts.WithCount(hostsLimit)
		}

		resp, _, err := api.ListHosts(ctx, *opts)
		if err != nil {
			return fmt.Errorf("ListHosts failed: %w", err)
		}

		if outputFmt == "table" {
			return printHostsTable(resp)
		}

		out, _ := json.MarshalIndent(resp, "", "  ")
		fmt.Println(string(out))
		return nil
	},
}

func printHostsTable(resp datadogV1.HostListResponse) error {
	w := tabwriter.NewWriter(os.Stdout, 0, 0, 2, ' ', 0)
	fmt.Fprintln(w, "NAME\tUP\tAPPS\tSOURCES")

	for _, h := range resp.HostList {
		name := ""
		if h.Name != nil {
			name = *h.Name
		}
		up := false
		if h.Up != nil {
			up = *h.Up
		}
		apps := ""
		for i, a := range h.Apps {
			if i > 0 {
				apps += ", "
			}
			apps += a
		}
		sources := ""
		for i, s := range h.Sources {
			if i > 0 {
				sources += ", "
			}
			sources += s
		}
		fmt.Fprintf(w, "%s\t%v\t%s\t%s\n", name, up, apps, sources)
	}
	return w.Flush()
}

var hostsTotalsCmd = &cobra.Command{
	Use:   "totals",
	Short: "Get host totals",
	RunE: func(cmd *cobra.Command, args []string) error {
		ctx, client, err := newAPIContext()
		if err != nil {
			return err
		}

		api := datadogV1.NewHostsApi(client)
		resp, _, err := api.GetHostTotals(ctx, *datadogV1.NewGetHostTotalsOptionalParameters())
		if err != nil {
			return fmt.Errorf("GetHostTotals failed: %w", err)
		}

		out, _ := json.MarshalIndent(resp, "", "  ")
		fmt.Println(string(out))
		return nil
	},
}

func init() {
	hostsCmd.Flags().StringVarP(&hostsFilter, "filter", "f", "", "Host filter (e.g., 'env:production')")
	hostsCmd.Flags().Int64VarP(&hostsLimit, "limit", "n", 100, "Max hosts to return")

	hostsCmd.AddCommand(hostsTotalsCmd)
	rootCmd.AddCommand(hostsCmd)
}
