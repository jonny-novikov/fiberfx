// Package fiberfx provides branded identifier types for Atlas schema definitions.
//
// This file registers Codemojex domain-specific namespaces for game entities.
// These complement the Atlas schema namespaces (TBL, COL, IDX, FKY) and
// generic namespaces (USR, SES, TSK) defined in namespace.go.

package fiberfx

// Codemojex domain namespaces - registered at init time
//
// Players Domain
var (
	NS_PLAYER          = MustRegister("PLR", "Player profile")
	NS_PLAYER_RESOURCE = MustRegister("RSC", "Player key/diamond resources")
)

// Games Domain
var (
	NS_ROOM        = MustRegister("ROM", "Game room")
	NS_ROOM_PLAYER = MustRegister("RMP", "Room player membership")
	NS_GAME        = MustRegister("GAM", "Game instance")
	NS_EMOJI_SET   = MustRegister("EMS", "Emoji set collection")
)

// Gameplay Domain
var (
	NS_GUESS         = MustRegister("GUS", "Player guess submission")
	NS_POSITION_LOCK = MustRegister("PLK", "Position lock confirmation")
	NS_EMOJI_NOTE    = MustRegister("EMJ", "Player emoji note")
)

// Leaderboard Domain
var (
	NS_PERIOD_SCORE = MustRegister("PSC", "Period score aggregate")
	NS_ACHIEVEMENT  = MustRegister("ACH", "Player achievement")
	NS_SNAPSHOT     = MustRegister("SNP", "Leaderboard snapshot")
)

// Economy Domain
var (
	NS_TRANSACTION       = MustRegister("TXN", "Resource transaction")
	NS_ORDER_TRANSACTION = MustRegister("OTX", "Order transaction")
	NS_PACKAGE           = MustRegister("PKG", "Shop package")
)

// Bank Domain
var (
	NS_PRIZE_BANK = MustRegister("BNK", "Prize escrow")
)

// Social Domain
var (
	NS_SHARE = MustRegister("SHR", "Share token")
)

// System Domain
var (
	NS_DEPLOYMENT = MustRegister("DPL", "FWHD deployment")
	NS_WEBHOOK    = MustRegister("WHK", "Webhook endpoint")
	NS_AUDIT      = MustRegister("AUD", "Audit log entry")
)
