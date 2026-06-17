package cmd

import (
	"encoding/json"
	"fmt"
	"os"
	"text/tabwriter"
	"time"

	"github.com/DataDog/datadog-api-client-go/v2/api/datadogV1"
	"github.com/spf13/cobra"
)

var (
	metricQuery string
	metricFrom  int64
	metricTo    int64
)

var metricsCmd = &cobra.Command{
	Use:   "metrics",
	Short: "Query Datadog metrics",
	Long: `Query timeseries metrics from Datadog.

Examples:
  datadog metrics query -q "avg:system.cpu.user{service:codemoji-game}"
  datadog metrics list`,
}

var metricsQueryCmd = &cobra.Command{
	Use:   "query",
	Short: "Query timeseries metrics",
	Long: `Query metric timeseries data.

Query syntax: <aggregator>:<metric>{<tags>}
  Aggregators: avg, sum, min, max, count

Examples:
  datadog metrics query -q "avg:system.cpu.user{*}"
  datadog metrics query -q "avg:trace.fastify.request.duration{service:codemoji-game}"`,
	RunE: func(cmd *cobra.Command, args []string) error {
		ctx, client, err := newAPIContext()
		if err != nil {
			return err
		}

		api := datadogV1.NewMetricsApi(client)

		// Default time range: last hour
		now := time.Now().Unix()
		from := metricFrom
		to := metricTo
		if from == 0 {
			from = now - 3600 // 1 hour ago
		}
		if to == 0 {
			to = now
		}

		resp, _, err := api.QueryMetrics(ctx, from, to, metricQuery)
		if err != nil {
			return fmt.Errorf("QueryMetrics failed: %w", err)
		}

		if outputFmt == "table" {
			return printMetricsTable(resp)
		}

		out, _ := json.MarshalIndent(resp, "", "  ")
		fmt.Println(string(out))
		return nil
	},
}

var metricsListCmd = &cobra.Command{
	Use:   "list",
	Short: "List available metrics",
	Long: `List all active metrics in your Datadog account.

Note: This returns metrics that have been submitted in the last 24 hours.`,
	RunE: func(cmd *cobra.Command, args []string) error {
		ctx, client, err := newAPIContext()
		if err != nil {
			return err
		}

		api := datadogV1.NewMetricsApi(client)

		// Get metrics from last hour
		from := time.Now().Add(-1 * time.Hour).Unix()
		resp, _, err := api.ListActiveMetrics(ctx, from)
		if err != nil {
			return fmt.Errorf("ListActiveMetrics failed: %w", err)
		}

		if outputFmt == "table" {
			return printMetricsList(resp)
		}

		out, _ := json.MarshalIndent(resp, "", "  ")
		fmt.Println(string(out))
		return nil
	},
}

func printMetricsTable(resp datadogV1.MetricsQueryResponse) error {
	w := tabwriter.NewWriter(os.Stdout, 0, 0, 2, ' ', 0)
	fmt.Fprintln(w, "METRIC\tSCOPE\tPOINTS\tUNIT")

	if resp.Series != nil {
		for _, series := range resp.Series {
			metric := ""
			scope := ""
			points := 0
			unit := ""

			if series.Metric != nil {
				metric = *series.Metric
			}
			if series.Scope != nil {
				scope = *series.Scope
				if len(scope) > 40 {
					scope = scope[:37] + "..."
				}
			}
			if series.Pointlist != nil {
				points = len(series.Pointlist)
			}
			if series.Unit != nil && len(series.Unit) > 0 {
				if series.Unit[0].Name != nil {
					unit = *series.Unit[0].Name
				}
			}

			fmt.Fprintf(w, "%s\t%s\t%d\t%s\n", metric, scope, points, unit)
		}
	}

	return w.Flush()
}

func printMetricsList(resp datadogV1.MetricsListResponse) error {
	w := tabwriter.NewWriter(os.Stdout, 0, 0, 2, ' ', 0)

	// Group by prefix for better readability
	if resp.Metrics != nil {
		count := 0
		for _, metric := range resp.Metrics {
			fmt.Fprintln(w, metric)
			count++
			if count >= 100 {
				fmt.Fprintf(w, "... and %d more metrics\n", len(resp.Metrics)-100)
				break
			}
		}
	}

	return w.Flush()
}

func init() {
	metricsQueryCmd.Flags().StringVarP(&metricQuery, "query", "q", "", "Metric query (required)")
	metricsQueryCmd.MarkFlagRequired("query")
	metricsQueryCmd.Flags().Int64Var(&metricFrom, "from", 0, "Start timestamp (Unix epoch, default: 1 hour ago)")
	metricsQueryCmd.Flags().Int64Var(&metricTo, "to", 0, "End timestamp (Unix epoch, default: now)")

	metricsCmd.AddCommand(metricsQueryCmd)
	metricsCmd.AddCommand(metricsListCmd)
	rootCmd.AddCommand(metricsCmd)
}
