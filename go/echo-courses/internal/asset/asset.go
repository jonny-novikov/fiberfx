// Package asset serves the externalized design-system CSS and interactive JS from
// content-hash routes (ec.5 D-1). At boot Load reads the two embedded files
// (web/static/app.css + app.js — embedded by web.FS), computes an 8-char sha256
// fingerprint of each, and exposes:
//
//   - the public URLs (/static/app.<hash>.css, /static/app.<hash>.js) the layout
//     head/footer link to, carried per-page in render.Head;
//   - a Register that wires those exact URLs as explicit GET routes serving the
//     embedded bytes with an immutable, year-long Cache-Control and the correct
//     Content-Type — so a byte change yields a new hash → a new URL (correct cache
//     invalidation by construction, ec.5 §ec5-risks), never a stale-style window.
//
// The fingerprinted assets are served from the embedded bytes, NOT the disk
// e.Static path (which stays for web/static/version.txt). The externalized bytes
// are byte-equivalent to the former inline <style>/<script> bodies (ec.5 AC1, the
// signature invariant) — asset only changes how they are delivered, never their
// content.
package asset

import (
	"crypto/sha256"
	"encoding/hex"
	"fmt"
	"io/fs"
	"net/http"

	"github.com/labstack/echo/v5"
)

// Embedded asset locations within web.FS (rooted at web/), and the served URL
// prefix. The hashed filename is built as <prefix>app.<hash8>.<ext>.
const (
	cssFile   = "static/app.css"
	jsFile    = "static/app.js"
	urlPrefix = "/static/"

	// cssContentType / jsContentType are the exact Content-Types the hashed
	// routes serve (with the charset — html/CSS/JS are UTF-8 text). They are set
	// explicitly because the bytes are served via c.Blob, not the net/http file
	// server's extension sniffing.
	cssContentType = "text/css; charset=utf-8"
	jsContentType  = "text/javascript; charset=utf-8"

	// immutableCacheControl ties a one-year, never-revalidate cache to the
	// content-hash URL: safe because a byte change yields a new hash → a new URL
	// (ec.5 D-1). 31536000 = 60*60*24*365.
	immutableCacheControl = "public, max-age=31536000, immutable"

	// hashLen is the hex-prefix length of the sha256 fingerprint (8 hex chars =
	// 32 bits — the conventional fingerprint width; collision-free for this set).
	hashLen = 8
)

// blob is one fingerprinted asset: the URL it is served from, its bytes, and its
// Content-Type.
type blob struct {
	url         string
	body        []byte
	contentType string
}

// Assets holds the two boot-computed fingerprinted assets. Build it once at boot
// (Load), read CSSURL/JSURL into the per-page render.Head, and call Register to
// wire the routes.
type Assets struct {
	css blob
	js  blob
}

// Load reads the embedded app.css + app.js out of fsys (web.FS), fingerprints
// each by an 8-char sha256 prefix, and returns the Assets ready to Register and
// to read URLs from. A missing embedded file is a named error so boot fails fast
// (mirroring render.New / catalog.Load), rather than serving a dead asset link.
func Load(fsys fs.FS) (*Assets, error) {
	css, err := loadBlob(fsys, cssFile, cssContentType)
	if err != nil {
		return nil, err
	}
	js, err := loadBlob(fsys, jsFile, jsContentType)
	if err != nil {
		return nil, err
	}
	return &Assets{css: css, js: js}, nil
}

// loadBlob reads one embedded asset and derives its fingerprinted URL.
func loadBlob(fsys fs.FS, file, contentType string) (blob, error) {
	body, err := fs.ReadFile(fsys, file)
	if err != nil {
		return blob{}, fmt.Errorf("asset: read %s: %w", file, err)
	}
	sum := sha256.Sum256(body)
	hash := hex.EncodeToString(sum[:])[:hashLen]
	// "static/app.css" -> "app", "css"; build /static/app.<hash>.css.
	name, ext := splitAppExt(file)
	url := fmt.Sprintf("%s%s.%s.%s", urlPrefix, name, hash, ext)
	return blob{url: url, body: body, contentType: contentType}, nil
}

// CSSURL is the fingerprinted URL of the externalized design system (the layout
// <head> stylesheet link).
func (a *Assets) CSSURL() string { return a.css.url }

// JSURL is the fingerprinted URL of the externalized interactivity (the deferred
// <script> before </body>).
func (a *Assets) JSURL() string { return a.js.url }

// Register wires the two content-hash routes onto e: an exact GET for each
// fingerprinted URL, serving the embedded bytes with the immutable Cache-Control
// and the correct Content-Type. The routes are concrete static paths; they
// coexist with a wildcard e.Static("/static", …) because the radix router
// prioritizes a fully-static path over a wildcard for its exact match — so a
// wrong hash falls through to (and 404s past) the disk handler, while version.txt
// keeps serving from disk.
func (a *Assets) Register(e *echo.Echo) {
	for _, b := range []blob{a.css, a.js} {
		b := b // capture per-iteration for the closure
		e.GET(b.url, func(c *echo.Context) error {
			c.Response().Header().Set("Cache-Control", immutableCacheControl)
			return c.Blob(http.StatusOK, b.contentType, b.body)
		})
	}
}

// splitAppExt splits a "static/<name>.<ext>" path into its base name and
// extension (e.g. "static/app.css" -> "app", "css"). The embedded asset files
// are flat under static/, so a single trailing-dot split suffices.
func splitAppExt(file string) (name, ext string) {
	base := file
	for i := len(file) - 1; i >= 0; i-- {
		if file[i] == '/' {
			base = file[i+1:]
			break
		}
	}
	for i := len(base) - 1; i >= 0; i-- {
		if base[i] == '.' {
			return base[:i], base[i+1:]
		}
	}
	return base, ""
}
