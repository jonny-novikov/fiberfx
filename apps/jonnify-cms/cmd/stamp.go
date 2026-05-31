package cmd

import (
	"fmt"
	"time"

	"github.com/jonny-novikov/jonnify-cms/internal/snowflake"
	"github.com/spf13/cobra"
)

func newStampCmd() *cobra.Command {
	c := &cobra.Command{Use: "stamp", Short: "Branded Snowflake build stamp (mint/decode)"}

	var ns, at string
	var node, seq uint64
	mint := &cobra.Command{
		Use:   "mint",
		Short: "Mint a 14-character branded id",
		RunE: func(cmd *cobra.Command, args []string) error {
			t := time.Time{}
			if at != "" {
				parsed, err := time.Parse(time.RFC3339, at)
				if err != nil {
					return err
				}
				t = parsed
			}
			id, err := snowflake.Mint(ns, node, seq, t)
			if err != nil {
				return err
			}
			fmt.Println(id)
			return nil
		},
	}
	mint.Flags().StringVar(&ns, "ns", "TSK", "3-character namespace")
	mint.Flags().Uint64Var(&node, "node", 0, "node id (10-bit)")
	mint.Flags().Uint64Var(&seq, "seq", 0, "sequence (12-bit)")
	mint.Flags().StringVar(&at, "at", "", "RFC3339 instant (default: now)")

	decode := &cobra.Command{
		Use:   "decode BRANDED",
		Short: "Decode a branded id into its fields",
		Args:  cobra.ExactArgs(1),
		RunE: func(cmd *cobra.Command, args []string) error {
			d, err := snowflake.Decode(args[0])
			if err != nil {
				return err
			}
			fmt.Printf("%-11s %s\n", "branded", d.Branded)
			fmt.Printf("%-11s %s\n", "namespace", d.Namespace)
			fmt.Printf("%-11s %d\n", "snowflake", d.Snowflake)
			fmt.Printf("%-11s %d\n", "node", d.Node)
			fmt.Printf("%-11s %d\n", "seq", d.Seq)
			fmt.Printf("%-11s %s\n", "timestamp", d.Timestamp)
			return nil
		},
	}
	c.AddCommand(mint, decode)
	return c
}
