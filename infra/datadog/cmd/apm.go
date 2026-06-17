package cmd

import (
	"encoding/json"
	"fmt"
	"os"
	"text/tabwriter"

	"github.com/DataDog/datadog-api-client-go/v2/api/datadogV2"
	"github.com/spf13/cobra"
)

var apmCmd = &cobra.Command{
	Use:   "apm",
	Short: "APM services and traces",
	Long:  `Query Datadog APM for services and trace data.`,
}

var apmServicesCmd = &cobra.Command{
	Use:   "services",
	Short: "List APM services",
	RunE: func(cmd *cobra.Command, args []string) error {
		ctx, client, err := newAPIContext()
		if err != nil {
			return err
		}

		api := datadogV2.NewAPMApi(client)
		resp, _, err := api.GetServiceList(ctx)
		if err != nil {
			return fmt.Errorf("GetServiceList failed: %w", err)
		}

		if outputFmt == "table" {
			return printServicesTable(resp)
		}

		out, _ := json.MarshalIndent(resp, "", "  ")
		fmt.Println(string(out))
		return nil
	},
}

func printServicesTable(resp datadogV2.ServiceList) error {
	w := tabwriter.NewWriter(os.Stdout, 0, 0, 2, ' ', 0)
	fmt.Fprintln(w, "SERVICE\tTYPE")

	if resp.Data != nil {
		data := resp.Data
		name := ""
		svcType := ""
		if data.Id != nil {
			name = *data.Id
		}
		svcType = string(data.Type)
		fmt.Fprintf(w, "%s\t%s\n", name, svcType)
	}
	return w.Flush()
}

func init() {
	apmCmd.AddCommand(apmServicesCmd)
	rootCmd.AddCommand(apmCmd)
}
