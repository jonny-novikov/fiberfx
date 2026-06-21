//! Branded-Snowflake identity at the external edge (eg.3).
//!
//! The platform addresses everything by a 14-char branded id — a 3-letter
//! uppercase namespace followed by an 11-char Base62 body (e.g. `VOL0O5fmcxbds8`)
//! — while the engine keeps its native `Gid` (`VolumeId`/`LogId`) internal. This
//! module is the validated external identity; the branded ↔ native mapping that
//! pairs it with a Volume lives in the local store (`fjall_storage`) as the single
//! source of truth (see `Runtime::volume_open_branded`).
//!
//! Branded ids are **caller-supplied** — the platform mints them; the engine only
//! validates, stores, and round-trips them. There is deliberately no minter here.

use std::{
    fmt::{self, Debug, Display},
    str::FromStr,
};

use thiserror::Error;

/// Length of the namespace prefix (3 uppercase ASCII letters, e.g. `VOL`).
pub const NAMESPACE_LEN: usize = 3;
/// Length of the Base62 body (an 11-char encoded Snowflake).
pub const BODY_LEN: usize = 11;
/// Total length of a branded id.
pub const BRANDED_LEN: usize = NAMESPACE_LEN + BODY_LEN;

/// A validated branded id: `{NS}{base62}` where `NS` is 3 uppercase ASCII letters
/// and the body is 11 Base62 (`[0-9A-Za-z]`) characters. ASCII throughout, so a
/// byte length is a character length.
#[derive(Clone, PartialEq, Eq, Hash)]
pub struct BrandedId(String);

#[derive(Debug, Error, PartialEq, Eq)]
pub enum BrandedIdErr {
    #[error("branded id must be {BRANDED_LEN} characters, got {0}")]
    InvalidLength(usize),

    #[error("branded id namespace must be {NAMESPACE_LEN} uppercase ASCII letters")]
    InvalidNamespace,

    #[error("branded id body must be {BODY_LEN} Base62 characters")]
    InvalidBody,
}

impl BrandedId {
    /// Parse and validate a branded id from its string form.
    pub fn parse(s: &str) -> Result<Self, BrandedIdErr> {
        if s.len() != BRANDED_LEN {
            return Err(BrandedIdErr::InvalidLength(s.len()));
        }
        let (ns, body) = s.split_at(NAMESPACE_LEN);
        if !ns.bytes().all(|b| b.is_ascii_uppercase()) {
            return Err(BrandedIdErr::InvalidNamespace);
        }
        // Base62 is the ASCII alphanumeric set [0-9A-Za-z].
        if !body.bytes().all(|b| b.is_ascii_alphanumeric()) {
            return Err(BrandedIdErr::InvalidBody);
        }
        Ok(Self(s.to_owned()))
    }

    /// The 3-letter namespace (e.g. `VOL`, `LOG`).
    #[inline]
    pub fn namespace(&self) -> &str {
        &self.0[..NAMESPACE_LEN]
    }

    /// The 11-char Base62 body.
    #[inline]
    pub fn body(&self) -> &str {
        &self.0[NAMESPACE_LEN..]
    }

    /// The whole branded id as a string slice.
    #[inline]
    pub fn as_str(&self) -> &str {
        &self.0
    }
}

impl Display for BrandedId {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        f.write_str(&self.0)
    }
}

impl Debug for BrandedId {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        f.write_str(&self.0)
    }
}

impl FromStr for BrandedId {
    type Err = BrandedIdErr;

    fn from_str(s: &str) -> Result<Self, Self::Err> {
        Self::parse(s)
    }
}

impl AsRef<str> for BrandedId {
    fn as_ref(&self) -> &str {
        &self.0
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use test_log::test;

    #[test]
    fn parse_valid() {
        let id = BrandedId::parse("VOL0O5fmcxbds8").unwrap();
        assert_eq!(id.namespace(), "VOL");
        assert_eq!(id.body(), "0O5fmcxbds8");
        assert_eq!(id.as_str(), "VOL0O5fmcxbds8");
        // round-trips through FromStr / Display
        assert_eq!("VOL0O5fmcxbds8".parse::<BrandedId>().unwrap(), id);
        assert_eq!(id.to_string(), "VOL0O5fmcxbds8");

        // a different namespace (LOG) is equally well-formed
        assert_eq!(BrandedId::parse("LOGabcDEF01234").unwrap().namespace(), "LOG");
    }

    #[test]
    fn parse_rejects_malformed() {
        // wrong length
        assert_eq!(
            BrandedId::parse("VOL0O5fmcxbd").unwrap_err(),
            BrandedIdErr::InvalidLength(12)
        );
        assert_eq!(
            BrandedId::parse("VOL0O5fmcxbds8x").unwrap_err(),
            BrandedIdErr::InvalidLength(15)
        );
        // lowercase namespace
        assert_eq!(
            BrandedId::parse("vol0O5fmcxbds8").unwrap_err(),
            BrandedIdErr::InvalidNamespace
        );
        // digit in namespace
        assert_eq!(
            BrandedId::parse("VO10O5fmcxbds8").unwrap_err(),
            BrandedIdErr::InvalidNamespace
        );
        // non-Base62 byte in the body ('-')
        assert_eq!(
            BrandedId::parse("VOL0O5fmcx-ds8").unwrap_err(),
            BrandedIdErr::InvalidBody
        );
    }
}
