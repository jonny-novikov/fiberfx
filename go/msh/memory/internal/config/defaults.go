package config

func Defaults() *Config {
	return &Config{
		DeletedPaths: []string{
			"apps/mcp/**",
			"apps/mcp-shim/internal/legacy/**",
		},
		RemovedTools: []string{
			"tool_x",
			"tool_x_infer_progress",
			"tool_x_compress_context",
			"tsk_continue",
			"tsk_search",
			"tsk_handoff",
			"agent_broadcast",
			"llms_parse",
			"llms_generate",
			"llms_expand",
			"llms_format",
			"llms_convert",
			"llms_component",
		},
		ContextWhitelistKeywords: []string{
			"deleted",
			"removed",
			"unregistered",
			"do not reference",
			"no longer registered",
			"dead",
			"superseded",
			"legacy",
		},
		IgnoreOrphans: []string{
			"completed-projects.md",
			"topics/feedback-index.md",
		},
		Hugot: HugotConfig{
			Endpoint:       "http://localhost:8902",
			Model:          "",
			TimeoutSeconds: 30,
		},
		Similarity: SimilarityConfig{
			DefaultThreshold: 0.85,
			DefaultTopK:      5,
		},
	}
}
