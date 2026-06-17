package main

// Original apps/msh/cmd/main.go stub spec (preserved verbatim so it can't be
// lost again):
//
//	- msh cobra toolchain
//	  - command: mint
//	    - usage:
//	      - msh mint -ns USR        -> USR0KHTOWnGLuC   # encoded brd14
//	      - msh mint -f json -ns USR                    # -f format: csv, json, ndjson, yaml
//	- msh mcp server
//	    - start, stop, restart on specified port (default: 8899)
//	    - setup in .mcp.json
//	      - mcp__msh__mint tool
//
// Note: cobra/pflag uses GNU-style long flags, so the namespace is `--ns`
// (the doc's `-ns` is shorthand); it is also accepted as a positional arg:
// `msh mint USR`.

import (
	"context"
	"encoding/csv"
	"encoding/json"
	"fmt"
	"strconv"
	"strings"
	"time"

	"github.com/spf13/cobra"
	"gopkg.in/yaml.v3"

	"github.com/fiberfx/mcp-go/v2/mcp"
	"github.com/jonny-novikov/msh/brandedid"
)

// mintRecord is one minted id with its decoded snowflake fields.
type mintRecord struct {
	ID        string `json:"id" yaml:"id"`
	NS        string `json:"ns" yaml:"ns"`
	Snowflake uint64 `json:"snowflake" yaml:"snowflake"`
	UnixMs    int64  `json:"unix_ms" yaml:"unix_ms"`
	Time      string `json:"time" yaml:"time"`
	Node      uint64 `json:"node" yaml:"node"`
	Seq       uint64 `json:"seq" yaml:"seq"`
}

// mintIDs mints count branded ids under ns on the given node.
func mintIDs(ns string, count int, node uint64) ([]mintRecord, error) {
	g := brandedid.NewGenerator(node)
	recs := make([]mintRecord, 0, count)
	for i := 0; i < count; i++ {
		snow := g.Next()
		id, err := brandedid.Encode(ns, snow)
		if err != nil {
			return nil, err
		}
		recs = append(recs, mintRecord{
			ID:        id,
			NS:        ns,
			Snowflake: snow,
			UnixMs:    brandedid.UnixMs(snow),
			Time:      brandedid.Time(snow).UTC().Format(time.RFC3339Nano),
			Node:      brandedid.NodeOf(snow),
			Seq:       brandedid.SeqOf(snow),
		})
	}
	return recs, nil
}

// renderMint serializes minted records. text (default) prints one id per line;
// json/ndjson/csv/yaml emit the full decoded records.
func renderMint(recs []mintRecord, format string) (string, error) {
	switch strings.ToLower(strings.TrimSpace(format)) {
	case "", "text", "plain", "id":
		var b strings.Builder
		for _, r := range recs {
			b.WriteString(r.ID)
			b.WriteByte('\n')
		}
		return b.String(), nil
	case "json":
		out, err := json.MarshalIndent(recs, "", "  ")
		if err != nil {
			return "", err
		}
		return string(out) + "\n", nil
	case "ndjson":
		var b strings.Builder
		enc := json.NewEncoder(&b)
		for _, r := range recs {
			if err := enc.Encode(r); err != nil {
				return "", err
			}
		}
		return b.String(), nil
	case "yaml", "yml":
		out, err := yaml.Marshal(recs)
		if err != nil {
			return "", err
		}
		return string(out), nil
	case "csv":
		var b strings.Builder
		w := csv.NewWriter(&b)
		_ = w.Write([]string{"id", "ns", "snowflake", "unix_ms", "time", "node", "seq"})
		for _, r := range recs {
			_ = w.Write([]string{
				r.ID, r.NS,
				strconv.FormatUint(r.Snowflake, 10),
				strconv.FormatInt(r.UnixMs, 10),
				r.Time,
				strconv.FormatUint(r.Node, 10),
				strconv.FormatUint(r.Seq, 10),
			})
		}
		w.Flush()
		return b.String(), w.Error()
	default:
		return "", fmt.Errorf("mint: invalid format %q (want text|json|ndjson|csv|yaml)", format)
	}
}

func resolveMintNode(changed bool, node int) uint64 {
	if changed {
		return uint64(node) & 1023
	}
	return brandedid.DefaultNode()
}

// newMintCmd builds `msh mint`.
func newMintCmd() *cobra.Command {
	var ns string
	var format string
	var count int
	var node int

	cmd := &cobra.Command{
		Use:   "mint [NS]",
		Short: "Mint branded snowflake id(s) — brd14: 3-letter namespace + 11 base62.",
		Long: "Mints time-ordered, coordination-free branded ids (e.g. SES…, USR…). " +
			"The namespace is given via --ns or as a positional arg.",
		Args: cobra.MaximumNArgs(1),
		RunE: func(cmd *cobra.Command, args []string) error {
			if ns == "" && len(args) == 1 {
				ns = args[0]
			}
			if ns == "" {
				return fmt.Errorf("namespace required: pass --ns USR or a positional arg (msh mint USR)")
			}
			if count < 1 {
				return fmt.Errorf("--count must be >= 1")
			}
			recs, err := mintIDs(ns, count, resolveMintNode(cmd.Flags().Changed("node"), node))
			if err != nil {
				return err
			}
			out, err := renderMint(recs, format)
			if err != nil {
				return err
			}
			fmt.Fprint(cmd.OutOrStdout(), out)
			return nil
		},
	}
	cmd.Flags().StringVar(&ns, "ns", "", "3-letter uppercase namespace (e.g. USR, SES)")
	cmd.Flags().StringVarP(&format, "format", "f", "text", "Output format: text | json | ndjson | csv | yaml")
	cmd.Flags().IntVarP(&count, "count", "n", 1, "Number of ids to mint")
	cmd.Flags().IntVar(&node, "node", 0, "Node id 0..1023 (default: hostname-derived)")
	return cmd
}

// mintToolArgs is the input schema for the mcp__msh__mint tool.
type mintToolArgs struct {
	NS     string `json:"ns" jsonschema:"3-letter uppercase namespace, e.g. USR or SES"`
	Count  int    `json:"count,omitempty" jsonschema:"how many ids to mint (default 1)"`
	Node   *int   `json:"node,omitempty" jsonschema:"node id 0..1023 (default: host-derived)"`
	Format string `json:"format,omitempty" jsonschema:"text (default) | json | ndjson | csv | yaml"`
}

// registerMintTool binds `msh mint` as the mcp__msh__mint tool.
func registerMintTool(s *mcp.Server) {
	mcp.AddTool(s, &mcp.Tool{
		Name: "mint",
		Description: "Mint branded snowflake id(s): brd14 = a 3-letter uppercase namespace + 11 base62 over a " +
			"ts(41)|node(10)|seq(12) snowflake (epoch 2024-01-01Z) — time-ordered and coordination-free.",
	}, func(_ context.Context, _ *mcp.CallToolRequest, in mintToolArgs) (*mcp.CallToolResult, any, error) {
		count := in.Count
		if count <= 0 {
			count = 1
		}
		node := brandedid.DefaultNode()
		if in.Node != nil {
			node = uint64(*in.Node) & 1023
		}
		recs, err := mintIDs(in.NS, count, node)
		if err != nil {
			return nil, nil, err
		}
		out, err := renderMint(recs, in.Format)
		if err != nil {
			return nil, nil, err
		}
		return textResult(out), nil, nil
	})
}
