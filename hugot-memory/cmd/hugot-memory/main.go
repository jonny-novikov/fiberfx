package main

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

var (
	version   = "dev"
	commit    = "unknown"
	buildDate = "unknown"
)

func main() {
	os.Exit(run(os.Args[1:]))
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
