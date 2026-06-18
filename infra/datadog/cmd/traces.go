package cmd

import (
	"encoding/json"
	"fmt"
	"os"
	"text/tabwriter"
	"time"

	"github.com/DataDog/datadog-api-client-go/v2/api/datadog"
	"github.com/DataDog/datadog-api-client-go/v2/api/datadogV2"
	"github.com/spf13/cobra"
)

var (
	traceQuery   string
	traceService string
	traceFrom    string
	traceTo      string
	traceLimit   int32
)

var tracesCmd = &cobra.Command{
	Use:   "traces",
	Short: "Query and analyze APM traces",
	Long: `Query distributed traces and spans from Datadog APM.

Examples:
  datadog traces list -q "service:echo-games"
  datadog traces list --service echo-games --from 1h
  datadog traces aggregate --service echo-games`,
}

var tracesListCmd = &cobra.Command{
	Use:   "list",
	Short: "List spans matching query",
	RunE: func(cmd *cobra.Command, args []string) error {
		ctx, client, err := newAPIContext()
		if err != nil {
			return err
		}

		api := datadogV2.NewSpansApi(client)

		// Build query
		query := traceQuery
		if traceService != "" && query == "" {
			query = fmt.Sprintf("service:%s", traceService)
		}
		if query == "" {
			query = "*"
		}

		// Parse time range
		from, to := parseTimeRange(traceFrom, traceTo)

		// Build request body
		body := datadogV2.SpansListRequest{
			Data: &datadogV2.SpansListRequestData{
				Attributes: &datadogV2.SpansListRequestAttributes{
					Filter: &datadogV2.SpansQueryFilter{
						Query: datadog.PtrString(query),
						From:  datadog.PtrString(from.Format(time.RFC3339)),
						To:    datadog.PtrString(to.Format(time.RFC3339)),
					},
					Page: &datadogV2.SpansListRequestPage{
						Limit: datadog.PtrInt32(traceLimit),
					},
				},
				Type: datadogV2.SPANSLISTREQUESTTYPE_SEARCH_REQUEST.Ptr(),
			},
		}

		resp, _, err := api.ListSpans(ctx, body)
		if err != nil {
			return fmt.Errorf("ListSpans failed: %w", err)
		}

		if outputFmt == "table" {
			return printSpansTable(resp)
		}

		out, _ := json.MarshalIndent(resp, "", "  ")
		fmt.Println(string(out))
		return nil
	},
}

var tracesAggregateCmd = &cobra.Command{
	Use:   "aggregate",
	Short: "Aggregate spans into metrics",
	Long: `Aggregate spans to compute metrics like count, latency percentiles.

Examples:
  datadog traces aggregate --service echo-games
  datadog traces aggregate -q "service:echo-games AND resource_name:GET*"`,
	RunE: func(cmd *cobra.Command, args []string) error {
		ctx, client, err := newAPIContext()
		if err != nil {
			return err
		}

		api := datadogV2.NewSpansApi(client)

		// Build query
		query := traceQuery
		if traceService != "" && query == "" {
			query = fmt.Sprintf("service:%s", traceService)
		}
		if query == "" {
			query = "*"
		}

		// Parse time range
		from, to := parseTimeRange(traceFrom, traceTo)

		// Build aggregation request
		body := datadogV2.SpansAggregateRequest{
			Data: &datadogV2.SpansAggregateData{
				Attributes: &datadogV2.SpansAggregateRequestAttributes{
					Filter: &datadogV2.SpansQueryFilter{
						Query: datadog.PtrString(query),
						From:  datadog.PtrString(from.Format(time.RFC3339)),
						To:    datadog.PtrString(to.Format(time.RFC3339)),
					},
					Compute: []datadogV2.SpansCompute{
						{
							Aggregation: datadogV2.SPANSAGGREGATIONFUNCTION_COUNT,
							Type:        datadogV2.SPANSCOMPUTETYPE_TOTAL.Ptr(),
						},
					},
					GroupBy: []datadogV2.SpansGroupBy{
						{
							Facet: "service",
							Limit: datadog.PtrInt64(10),
						},
						{
							Facet: "resource_name",
							Limit: datadog.PtrInt64(10),
						},
					},
				},
				Type: datadogV2.SPANSAGGREGATEREQUESTTYPE_AGGREGATE_REQUEST.Ptr(),
			},
		}

		resp, _, err := api.AggregateSpans(ctx, body)
		if err != nil {
			return fmt.Errorf("AggregateSpans failed: %w", err)
		}

		if outputFmt == "table" {
			return printAggregateTable(resp)
		}

		out, _ := json.MarshalIndent(resp, "", "  ")
		fmt.Println(string(out))
		return nil
	},
}

func parseTimeRange(fromStr, toStr string) (time.Time, time.Time) {
	now := time.Now()
	to := now

	// Parse "to" if specified
	if toStr != "" {
		if parsed, err := time.Parse(time.RFC3339, toStr); err == nil {
			to = parsed
		}
	}

	// Parse "from" - supports relative times like "1h", "24h", "7d"
	from := now.Add(-1 * time.Hour) // default 1 hour
	if fromStr != "" {
		switch {
		case fromStr == "1h":
			from = now.Add(-1 * time.Hour)
		case fromStr == "6h":
			from = now.Add(-6 * time.Hour)
		case fromStr == "24h" || fromStr == "1d":
			from = now.Add(-24 * time.Hour)
		case fromStr == "7d":
			from = now.Add(-7 * 24 * time.Hour)
		case fromStr == "30d":
			from = now.Add(-30 * 24 * time.Hour)
		default:
			if parsed, err := time.Parse(time.RFC3339, fromStr); err == nil {
				from = parsed
			}
		}
	}

	return from, to
}

func printSpansTable(resp datadogV2.SpansListResponse) error {
	w := tabwriter.NewWriter(os.Stdout, 0, 0, 2, ' ', 0)
	fmt.Fprintln(w, "TRACE_ID\tSPAN_ID\tSERVICE\tRESOURCE\tDURATION")

	if resp.Data != nil {
		for _, span := range resp.Data {
			traceID := ""
			spanID := ""
			service := ""
			resource := ""
			duration := ""

			if span.Id != nil {
				spanID = *span.Id
				if len(spanID) > 12 {
					spanID = spanID[:12] + "..."
				}
			}

			if span.Attributes != nil {
				attrs := span.Attributes
				if attrs.TraceId != nil {
					traceID = *attrs.TraceId
					if len(traceID) > 12 {
						traceID = traceID[:12] + "..."
					}
				}
				if attrs.Service != nil {
					service = *attrs.Service
				}
				if attrs.ResourceName != nil {
					resource = *attrs.ResourceName
					if len(resource) > 30 {
						resource = resource[:27] + "..."
					}
				}
				// Calculate duration from timestamps
				if attrs.StartTimestamp != nil && attrs.EndTimestamp != nil {
					dur := attrs.EndTimestamp.Sub(*attrs.StartTimestamp)
					duration = dur.String()
				}
			}

			fmt.Fprintf(w, "%s\t%s\t%s\t%s\t%s\n", traceID, spanID, service, resource, duration)
		}
	}

	return w.Flush()
}

func printAggregateTable(resp datadogV2.SpansAggregateResponse) error {
	w := tabwriter.NewWriter(os.Stdout, 0, 0, 2, ' ', 0)
	fmt.Fprintln(w, "SERVICE\tRESOURCE\tCOUNT")

	if resp.Data != nil {
		for _, bucket := range resp.Data {
			service := ""
			resource := ""
			count := ""

			if bucket.Attributes != nil {
				attrs := bucket.Attributes
				if attrs.By != nil {
					byMap := attrs.By
					if svc, ok := byMap["service"]; ok {
						service = fmt.Sprintf("%v", svc)
					}
					if res, ok := byMap["resource_name"]; ok {
						resource = fmt.Sprintf("%v", res)
						if len(resource) > 30 {
							resource = resource[:27] + "..."
						}
					}
				}
				if attrs.Computes != nil {
					computes := attrs.Computes
					if c, ok := computes["c0"]; ok {
						// SpansAggregateBucketValue can be different types
						if val := c.SpansAggregateBucketValueSingleNumber; val != nil {
							count = fmt.Sprintf("%.0f", *val)
						}
					}
				}
			}

			fmt.Fprintf(w, "%s\t%s\t%s\n", service, resource, count)
		}
	}

	return w.Flush()
}

func init() {
	// Common flags for trace commands
	tracesCmd.PersistentFlags().StringVarP(&traceQuery, "query", "q", "", "Span query (e.g., 'service:myapp AND status:error')")
	tracesCmd.PersistentFlags().StringVar(&traceService, "service", "", "Filter by service name")
	tracesCmd.PersistentFlags().StringVar(&traceFrom, "from", "1h", "Start time (1h, 6h, 24h, 7d, or RFC3339)")
	tracesCmd.PersistentFlags().StringVar(&traceTo, "to", "", "End time (default: now)")

	tracesListCmd.Flags().Int32VarP(&traceLimit, "limit", "l", 50, "Maximum spans to return")

	tracesCmd.AddCommand(tracesListCmd)
	tracesCmd.AddCommand(tracesAggregateCmd)
	rootCmd.AddCommand(tracesCmd)
}
