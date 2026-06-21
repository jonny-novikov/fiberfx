package asset_test

import (
	"crypto/sha256"
	"encoding/hex"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"github.com/fiberfx/echo-courses/internal/asset"
	"github.com/fiberfx/echo-courses/web"
	"github.com/labstack/echo/v5"
)

// load is the boot path: Load over the real embedded web.FS. A failure here means
// the embed directive lost static/ (ec.5 D-1) — a fatal setup error.
func load(t *testing.T) *asset.Assets {
	t.Helper()
	a, err := asset.Load(web.FS)
	if err != nil {
		t.Fatalf("asset.Load(web.FS): %v", err)
	}
	return a
}

// AC1 (D-1): the fingerprinted URLs are the content-hash form
// /static/app.<8 hex>.<ext>, and the hash is the sha256-prefix of the served
// bytes (proven by recomputing it from the served body in the route test below).
func TestLoad_URLShape(t *testing.T) {
	a := load(t)
	for name, url := range map[string]string{"css": a.CSSURL(), "js": a.JSURL()} {
		if !strings.HasPrefix(url, "/static/app.") {
			t.Errorf("%s URL %q lacks the /static/app. prefix", name, url)
		}
		if !strings.HasSuffix(url, "."+name) {
			t.Errorf("%s URL %q lacks the .%s suffix", name, url, name)
		}
		// /static/app.<hash>.<ext> — the segment between "app." and the final dot
		// is an 8-char lowercase hex hash.
		mid := strings.TrimSuffix(strings.TrimPrefix(url, "/static/app."), "."+name)
		if len(mid) != 8 {
			t.Errorf("%s URL hash %q is not 8 chars", name, mid)
		}
		if _, err := hex.DecodeString(mid); err != nil {
			t.Errorf("%s URL hash %q is not hex: %v", name, mid, err)
		}
	}
}

// AC1/AC2 (D-1): each fingerprinted route serves 200 with the exact Content-Type,
// the immutable Cache-Control, and bytes whose sha256-prefix matches the URL hash
// (the URL truly is the content fingerprint). A WRONG hash 404s — the route is the
// exact hashed path, and the wildcard disk handler has no such file.
func TestRegister_ServesHashedAndRejectsWrong(t *testing.T) {
	a := load(t)
	e := echo.New()
	// A disk static mount on the SAME prefix, to prove the concrete hashed route
	// wins by router priority and a wrong hash falls through to a 404 (no file).
	e.Static("/static", t.TempDir())
	a.Register(e)

	cases := []struct {
		name        string
		url         string
		contentType string
	}{
		{"css", a.CSSURL(), "text/css; charset=utf-8"},
		{"js", a.JSURL(), "text/javascript; charset=utf-8"},
	}
	for _, tc := range cases {
		rec := httptest.NewRecorder()
		e.ServeHTTP(rec, httptest.NewRequest(http.MethodGet, tc.url, nil))

		if rec.Code != http.StatusOK {
			t.Errorf("%s GET %s = %d, want 200", tc.name, tc.url, rec.Code)
			continue
		}
		if got := rec.Header().Get("Content-Type"); got != tc.contentType {
			t.Errorf("%s Content-Type = %q, want %q", tc.name, got, tc.contentType)
		}
		if got := rec.Header().Get("Cache-Control"); got != "public, max-age=31536000, immutable" {
			t.Errorf("%s Cache-Control = %q, want the immutable year-long policy", tc.name, got)
		}
		// The hash in the URL is the sha256-prefix of the served bytes.
		sum := sha256.Sum256(rec.Body.Bytes())
		wantHash := hex.EncodeToString(sum[:])[:8]
		if !strings.Contains(tc.url, "app."+wantHash+".") {
			t.Errorf("%s served bytes hash %q is not in the URL %q (URL is not the fingerprint)", tc.name, wantHash, tc.url)
		}
	}

	// A wrong hash → 404 (the exact route does not exist; the disk wildcard has no
	// such file).
	wrong := "/static/app.00000000.css"
	rec := httptest.NewRecorder()
	e.ServeHTTP(rec, httptest.NewRequest(http.MethodGet, wrong, nil))
	if rec.Code != http.StatusNotFound {
		t.Errorf("GET %s (wrong hash) = %d, want 404", wrong, rec.Code)
	}
}

// AC1 (the SIGNATURE invariant, in-suite): the served CSS bytes are exactly the
// embedded web/static/app.css, and the served JS exactly app.js — the route is a
// pass-through of the embedded bytes, not a re-encode. (The git-HEAD
// byte-equivalence proof — that those embedded bytes equal the former inline
// <style>/<script> bodies — is the scripted gate check; this proves the serving
// path does not mutate them.)
func TestRegister_ServesEmbeddedBytesVerbatim(t *testing.T) {
	a := load(t)
	e := echo.New()
	a.Register(e)

	for _, f := range []struct {
		url  string
		file string
	}{
		{a.CSSURL(), "static/app.css"},
		{a.JSURL(), "static/app.js"},
	} {
		want, err := web.FS.ReadFile(f.file)
		if err != nil {
			t.Fatalf("read embedded %s: %v", f.file, err)
		}
		rec := httptest.NewRecorder()
		e.ServeHTTP(rec, httptest.NewRequest(http.MethodGet, f.url, nil))
		if rec.Code != http.StatusOK {
			t.Fatalf("GET %s = %d, want 200", f.url, rec.Code)
		}
		if rec.Body.String() != string(want) {
			t.Errorf("served %s differs from the embedded %s (the route must serve the bytes verbatim)", f.url, f.file)
		}
	}
}
