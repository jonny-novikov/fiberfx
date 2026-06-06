package echomq

import "testing"

func TestStreamForSingleInstance(t *testing.T) {
	kb := NewKeyBuilderWithHashTags("pubsub", false)
	got := kb.StreamFor("cclin.progress")
	want := "bull:cclin.progress:stream"
	if got != want {
		t.Errorf("StreamFor = %q, want %q", got, want)
	}
}

func TestStreamForClusterHashTags(t *testing.T) {
	kb := NewKeyBuilderWithHashTags("pubsub", true)
	got := kb.StreamFor("cclin.progress")
	want := "bull:{cclin.progress}:stream"
	if got != want {
		t.Errorf("StreamFor = %q, want %q", got, want)
	}
}

func TestStreamForDisjointFromEvents(t *testing.T) {
	kb := NewKeyBuilderWithHashTags("cclin.events", false)
	eventsKey := kb.Events()
	streamKey := kb.StreamFor("cclin.events")
	if eventsKey == streamKey {
		t.Errorf("Events() %q must not collide with StreamFor %q (FTR-008 D-TR-2)", eventsKey, streamKey)
	}
}
