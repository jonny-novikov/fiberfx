package main

import "errors"

var (
	errInvalidFormat   = errors.New("invalid --format value")
	errInvalidSeverity = errors.New("invalid --severity value")
	errRootRequired    = errors.New("--root required (no MEMORY.md found in walk-up)")
)

type exitError struct {
	code int
	err  error
}

func (e *exitError) Error() string { return e.err.Error() }
func (e *exitError) Unwrap() error { return e.err }
