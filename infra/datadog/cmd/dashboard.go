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
	dashboardFile string
)

var dashboardCmd = &cobra.Command{
	Use:   "dashboard",
	Short: "Dashboard management",
	Long:  `Create, list, get, and delete Datadog dashboards using JSON templates.`,
}

var dashboardListCmd = &cobra.Command{
	Use:   "list",
	Short: "List all dashboards",
	RunE: func(cmd *cobra.Command, args []string) error {
		ctx, client, err := newAPIContext()
		if err != nil {
			return err
		}

		api := datadogV1.NewDashboardsApi(client)
		resp, _, err := api.ListDashboards(ctx)
		if err != nil {
			return fmt.Errorf("ListDashboards failed: %w", err)
		}

		if outputFmt == "table" {
			return printDashboardListTable(resp)
		}

		out, _ := json.MarshalIndent(resp, "", "  ")
		fmt.Println(string(out))
		return nil
	},
}

var dashboardGetCmd = &cobra.Command{
	Use:   "get <dashboard-id>",
	Short: "Get dashboard by ID (JSON output for templates)",
	Args:  cobra.ExactArgs(1),
	RunE: func(cmd *cobra.Command, args []string) error {
		ctx, client, err := newAPIContext()
		if err != nil {
			return err
		}

		api := datadogV1.NewDashboardsApi(client)
		resp, _, err := api.GetDashboard(ctx, args[0])
		if err != nil {
			return fmt.Errorf("GetDashboard failed: %w", err)
		}

		out, _ := json.MarshalIndent(resp, "", "  ")
		fmt.Println(string(out))
		return nil
	},
}

var dashboardCreateCmd = &cobra.Command{
	Use:   "create",
	Short: "Create dashboard from JSON template",
	Long: `Create a dashboard from a JSON template file.

Example:
  datadog dashboard create -f templates/apm-echo.json
  cat dashboard.json | datadog dashboard create -f -`,
	RunE: func(cmd *cobra.Command, args []string) error {
		ctx, client, err := newAPIContext()
		if err != nil {
			return err
		}

		// Read JSON from file or stdin
		var data []byte
		if dashboardFile == "-" {
			data, err = os.ReadFile("/dev/stdin")
		} else {
			data, err = os.ReadFile(dashboardFile)
		}
		if err != nil {
			return fmt.Errorf("read template: %w", err)
		}

		var dashboard datadogV1.Dashboard
		if err := json.Unmarshal(data, &dashboard); err != nil {
			return fmt.Errorf("parse template: %w", err)
		}

		api := datadogV1.NewDashboardsApi(client)
		resp, _, err := api.CreateDashboard(ctx, dashboard)
		if err != nil {
			return fmt.Errorf("CreateDashboard failed: %w", err)
		}

		if outputFmt == "table" {
			fmt.Printf("✓ Dashboard created: %s\n", *resp.Id)
			fmt.Printf("  Title: %s\n", resp.Title)
			fmt.Printf("  URL: https://app.datadoghq.com/dashboard/%s\n", *resp.Id)
			return nil
		}

		out, _ := json.MarshalIndent(resp, "", "  ")
		fmt.Println(string(out))
		return nil
	},
}

var dashboardDeleteCmd = &cobra.Command{
	Use:   "delete <dashboard-id>",
	Short: "Delete a dashboard",
	Args:  cobra.ExactArgs(1),
	RunE: func(cmd *cobra.Command, args []string) error {
		ctx, client, err := newAPIContext()
		if err != nil {
			return err
		}

		api := datadogV1.NewDashboardsApi(client)
		_, _, err = api.DeleteDashboard(ctx, args[0])
		if err != nil {
			return fmt.Errorf("DeleteDashboard failed: %w", err)
		}

		fmt.Printf("✓ Dashboard %s deleted\n", args[0])
		return nil
	},
}

func printDashboardListTable(resp datadogV1.DashboardSummary) error {
	w := tabwriter.NewWriter(os.Stdout, 0, 0, 2, ' ', 0)
	fmt.Fprintln(w, "ID\tTITLE\tLAYOUT\tCREATED")

	if resp.Dashboards != nil {
		for _, d := range resp.Dashboards {
			id := ""
			title := ""
			layout := ""
			created := ""

			if d.Id != nil {
				id = *d.Id
			}
			if d.Title != nil {
				title = *d.Title
				if len(title) > 40 {
					title = title[:37] + "..."
				}
			}
			if d.LayoutType != nil {
				layout = string(*d.LayoutType)
			}
			if d.CreatedAt != nil {
				created = d.CreatedAt.Format("2006-01-02")
			}

			fmt.Fprintf(w, "%s\t%s\t%s\t%s\n", id, title, layout, created)
		}
	}
	return w.Flush()
}

func init() {
	dashboardCreateCmd.Flags().StringVarP(&dashboardFile, "file", "f", "", "JSON template file (use - for stdin)")
	dashboardCreateCmd.MarkFlagRequired("file")

	dashboardCmd.AddCommand(dashboardListCmd)
	dashboardCmd.AddCommand(dashboardGetCmd)
	dashboardCmd.AddCommand(dashboardCreateCmd)
	dashboardCmd.AddCommand(dashboardDeleteCmd)
	rootCmd.AddCommand(dashboardCmd)
}
