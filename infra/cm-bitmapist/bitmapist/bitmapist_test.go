package bitmapist

import (
	"context"
	"testing"
	"time"
)

func TestKeyConventions(t *testing.T) {
	c := New(NewMemStore())
	tm := time.Date(2020, 1, 25, 9, 0, 0, 0, time.UTC) // a Saturday in ISO week 4
	cases := map[Period]string{
		Day:    "bitmapist__active_2020-1-25",
		Week:   "bitmapist__active_W2020-4",
		Month:  "bitmapist__active_2020-1",
		Year:   "bitmapist__active_Y2020",
		Unique: "bitmapist__active",
	}
	for p, want := range cases {
		if got := c.Key("active", tm, p); got != want {
			t.Errorf("period %d: got %q want %q", p, got, want)
		}
	}
}

func TestMarkCountMembershipBranded(t *testing.T) {
	ctx := context.Background()
	c := New(NewMemStore())
	tm := time.Date(2026, 6, 1, 12, 0, 0, 0, time.UTC)

	// Two real branded ids (decode + hash inside Mark).
	alice := "USR0KHTOWnGLuC"
	bob := "USR0NgWEfAEJfs"
	if err := c.Mark(ctx, "active", alice, tm); err != nil {
		t.Fatal(err)
	}
	if err := c.Mark(ctx, "active", bob, tm); err != nil {
		t.Fatal(err)
	}
	if err := c.Mark(ctx, "paid", alice, tm); err != nil {
		t.Fatal(err)
	}

	if n, _ := c.Count(ctx, "active", tm, Month); n != 2 {
		t.Errorf("active month: got %d want 2", n)
	}
	if n, _ := c.Count(ctx, "paid", tm, Month); n != 1 {
		t.Errorf("paid month: got %d want 1", n)
	}
	if in, _ := c.In(ctx, "active", alice, tm, Day); !in {
		t.Error("alice should be active today")
	}
	if err := c.Mark(ctx, "active", "not-a-branded-id", tm); err == nil {
		t.Error("expected invalid id to error")
	}
}

func TestCohortAndFunnel(t *testing.T) {
	ctx := context.Background()
	c := New(NewMemStore())
	tm := time.Date(2026, 6, 1, 12, 0, 0, 0, time.UTC)
	alice, bob := "USR0KHTOWnGLuC", "USR0NgWEfAEJfs"

	c.Mark(ctx, "registered", alice, tm)
	c.Mark(ctx, "registered", bob, tm)
	c.Mark(ctx, "played", alice, tm)
	c.Mark(ctx, "played", bob, tm)
	c.Mark(ctx, "paid", alice, tm) // only alice converts

	reg := c.Key("registered", tm, Month)
	played := c.Key("played", tm, Month)
	paid := c.Key("paid", tm, Month)

	// funnel registered -> played -> paid
	if n, _ := c.AndCount(ctx, reg, played, paid); n != 1 {
		t.Errorf("funnel: got %d want 1", n)
	}
	if n, _ := c.OrCount(ctx, reg, played); n != 2 {
		t.Errorf("union: got %d want 2", n)
	}
	// retention curve: cohort = registered, follow = played, paid
	row, _ := c.RetentionRow(ctx, reg, []string{played, paid})
	if len(row) != 3 || row[0] != 2 || row[1] != 2 || row[2] != 1 {
		t.Errorf("retention row: got %v want [2 2 1]", row)
	}
}
