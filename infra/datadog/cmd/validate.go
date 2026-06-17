package cmd

import (
	"encoding/json"
	"fmt"

	"github.com/DataDog/datadog-api-client-go/v2/api/datadogV1"
	"github.com/spf13/cobra"
)

var validateCmd = &cobra.Command{
	Use:   "validate",
	Short: "Validate API credentials",
	Long:  `Validate that the provided Datadog API credentials are valid.`,
	RunE: func(cmd *cobra.Command, args []string) error {
		ctx, client, err := newAPIContext()
		if err != nil {
			return err
		}

		api := datadogV1.NewAuthenticationApi(client)
		resp, _, err := api.Validate(ctx)
		if err != nil {
			return fmt.Errorf("Validate failed: %w", err)
		}

		if outputFmt == "table" {
			valid := false
			if resp.Valid != nil {
				valid = *resp.Valid
			}
			if valid {
				fmt.Println("✓ API credentials are valid")
			} else {
				fmt.Println("✗ API credentials are invalid")
			}
			return nil
		}

		out, _ := json.MarshalIndent(resp, "", "  ")
		fmt.Println(string(out))
		return nil
	},
}

func init() {
	rootCmd.AddCommand(validateCmd)
}
