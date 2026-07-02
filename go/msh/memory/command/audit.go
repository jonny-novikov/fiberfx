package command

import (
	"github.com/spf13/cobra"

	"github.com/jonny-novikov/msh/memory/internal/config"
	"github.com/jonny-novikov/msh/memory/internal/render"
	"github.com/jonny-novikov/msh/memory/internal/stale"
)

func newAuditCmd(cfg *rootConfig, flags *globalFlags) *cobra.Command {
	var maxWarn int
	var emitExitCode bool
	cmd := &cobra.Command{
		Use:          "audit",
		Short:        "Composite scan + stale + summary; non-zero exit on errors.",
		Long:         "Walks memory, runs all stale-detection rules, prints a summary, and exits non-zero when any error-severity findings are present (or when --max-warn is exceeded by warn-severity findings).",
		Args:         cobra.NoArgs,
		SilenceUsage: true,
		RunE: func(cmd *cobra.Command, _ []string) error {
			root, err := resolveRoot(flags.Root)
			if err != nil {
				return err
			}
			conf, _, err := config.Resolve(flags.Config, root)
			if err != nil {
				return &exitError{code: exitGeneric, err: err}
			}
			g, src, err := loadCorpus(root)
			if err != nil {
				return &exitError{code: exitGeneric, err: err}
			}
			findings := stale.Run(g, conf, src, []string{"all"}, utcToday())
			if err := render.PrettyAuditSummary(cfg.Stdout, findings.Counts(), g.NodeCount()); err != nil {
				return err
			}
			if err := render.PrettyFindings(cfg.Stdout, findings.FilterBySeverity(stale.SeverityWarn)); err != nil {
				return err
			}
			counts := findings.Counts()
			if !emitExitCode {
				return nil
			}
			// Exit on ANY error-severity finding — aligned to the Long contract
			// above (msh2.2 D6): DEAD-TARGET stays covered, and an invalid
			// review_after now fails the gate alike.
			if counts[stale.SeverityError] > 0 {
				return &exitError{code: exitGeneric, err: errAuditFailed{message: "audit found error-severity findings"}}
			}
			if maxWarn >= 0 && counts[stale.SeverityWarn] > maxWarn {
				return &exitError{code: exitGeneric, err: errAuditFailed{message: "audit warn count exceeds --max-warn threshold"}}
			}
			return nil
		},
	}
	cmd.Flags().IntVar(&maxWarn, "max-warn", -1, "Fail audit when warn-severity count exceeds this threshold (-1 disables)")
	cmd.Flags().BoolVar(&emitExitCode, "exit-code", true, "Exit non-zero on error-severity findings (default true)")
	return cmd
}

type errAuditFailed struct {
	message string
}

func (e errAuditFailed) Error() string { return e.message }
