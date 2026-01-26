package db

import (
	"testing"
)

func TestConvertPostgresValue(t *testing.T) {
	tests := []struct {
		name  string
		input any
		want  any
	}{
		{
			name: "UUID standard format",
			input: [16]byte{
				0x55, 0x0e, 0x84, 0x00, 0xe2, 0x9b, 0x41, 0xd4,
				0xa7, 0x16, 0x44, 0x66, 0x55, 0x44, 0x00, 0x00,
			},
			want: "550e8400-e29b-41d4-a716-446655440000",
		},
		{
			name:  "UUID all zeros",
			input: [16]byte{},
			want:  "00000000-0000-0000-0000-000000000000",
		},
		{
			name:  "UUID all ones",
			input: [16]byte{0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff},
			want:  "ffffffff-ffff-ffff-ffff-ffffffffffff",
		},
		{
			name:  "BYTEA Hello",
			input: []byte("Hello"),
			want:  `\x48656c6c6f`,
		},
		{
			name:  "BYTEA empty",
			input: []byte{},
			want:  `\x`,
		},
		{
			name:  "BYTEA binary with null and high bytes",
			input: []byte{0x00, 0xff, 0x7f, 0x80},
			want:  `\x00ff7f80`,
		},
		{
			name:  "Passthrough int",
			input: 42,
			want:  42,
		},
		{
			name:  "Passthrough int64",
			input: int64(9223372036854775807),
			want:  int64(9223372036854775807),
		},
		{
			name:  "Passthrough float64",
			input: 3.14159,
			want:  3.14159,
		},
		{
			name:  "Passthrough string",
			input: "test",
			want:  "test",
		},
		{
			name:  "Passthrough bool true",
			input: true,
			want:  true,
		},
		{
			name:  "Passthrough bool false",
			input: false,
			want:  false,
		},
		{
			name:  "Passthrough nil",
			input: nil,
			want:  nil,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got := convertPostgresValue(tt.input)
			if got != tt.want {
				t.Errorf("convertPostgresValue(%v) = %v (%T), want %v (%T)",
					tt.input, got, got, tt.want, tt.want)
			}
		})
	}
}
