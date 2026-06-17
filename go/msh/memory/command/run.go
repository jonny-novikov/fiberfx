package command

import (
	"context"
	"errors"
	"os"
	"os/signal"
	"syscall"
)

const (
	exitOK      = 0
	exitGeneric = 1
	exitUsage   = 2
	exitSIGINT  = 130
)

// Build metadata, overridable at link time via
// -X github.com/jonny-novikov/msh/memory/command.version=... (see Makefile).
var (
	version   = "dev"
	commit    = "unknown"
	buildDate = "unknown"
)

// Run executes the standalone "msh" memory CLI with args (typically os.Args[1:])
// and returns a process exit code. The cmd/msh-memory binary is a thin shim over
// this, and a host (apps/msh) mounts the same tree via New.
func Run(args []string) int {
	return run(args)
}

func run(args []string) int {
	ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
	defer stop()

	root := newRootCmd(rootConfig{})
	root.SetArgs(args)

	err := root.ExecuteContext(ctx)
	if err == nil {
		return exitOK
	}

	if errors.Is(err, context.Canceled) || errors.Is(err, context.DeadlineExceeded) {
		if cause := context.Cause(ctx); errors.Is(cause, context.DeadlineExceeded) {
			return exitGeneric
		}
		return exitSIGINT
	}

	var ee *exitError
	if errors.As(err, &ee) {
		return ee.code
	}
	return exitGeneric
}
