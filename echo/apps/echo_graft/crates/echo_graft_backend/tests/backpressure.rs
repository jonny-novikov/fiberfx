//! eg.4 Step 6 — per-Volume backpressure isolation (S-7 / criterion 7).
//!
//! A producer flooding Volume A's command lane must be back-pressured (rejected at the cap)
//! while Volume B's commands still flow unaffected. The cap is per-Volume, so A's saturation
//! never consults or consumes B's budget — the isolation the brief requires.

use echo_graft_backend::{Backpressure, DEFAULT_MAX_IN_FLIGHT};

const VOL_A: &str = "3QJmnh7Yx2Kp9Wd5Lr8Tz4A";
const VOL_B: &str = "3QJmnh7Yx2Kp9Wd5Lr8Tz4B";

#[test]
fn a_flood_on_one_volume_does_not_block_another() {
    let bp = Backpressure::new(4);

    // flood Volume A up to its cap, holding every permit
    let mut a_permits = Vec::new();
    for _ in 0..4 {
        a_permits.push(bp.admit(VOL_A).expect("A admits below the cap"));
    }
    assert_eq!(bp.in_flight(VOL_A), 4);

    // A is now at the cap: the next A command is rejected (the caller maps this to
    // `unavailable`), NOT blocked and NOT buffered
    assert!(bp.admit(VOL_A).is_none(), "A is back-pressured at the cap");

    // ...yet Volume B is completely unaffected — its budget is untouched
    assert_eq!(bp.in_flight(VOL_B), 0);
    let b_permit = bp.admit(VOL_B).expect("B admits while A is saturated");
    assert_eq!(bp.in_flight(VOL_B), 1);

    // releasing one A permit re-opens exactly one A slot (B still independent)
    a_permits.pop();
    assert_eq!(bp.in_flight(VOL_A), 3);
    let _a_again = bp.admit(VOL_A).expect("A re-admits after a release");
    assert_eq!(bp.in_flight(VOL_A), 4);

    drop(b_permit);
    assert_eq!(bp.in_flight(VOL_B), 0, "B's slot released cleanly");
}

#[test]
fn a_permit_releases_on_drop() {
    let bp = Backpressure::new(2);
    {
        let _p1 = bp.admit(VOL_A).unwrap();
        let _p2 = bp.admit(VOL_A).unwrap();
        assert_eq!(bp.in_flight(VOL_A), 2);
        assert!(bp.admit(VOL_A).is_none(), "at cap");
    }
    // both permits dropped at scope end → the Volume's slots are fully freed
    assert_eq!(bp.in_flight(VOL_A), 0);
    assert!(bp.admit(VOL_A).is_some(), "fully released after the scope");
}

#[test]
fn default_cap_is_the_documented_constant() {
    let bp = Backpressure::with_default();
    assert_eq!(bp.max_in_flight(), DEFAULT_MAX_IN_FLIGHT);
}

/// The shared control lane (`egraft:cmd:_control`, the vid-less handshake/open path) is exempt
/// from per-Volume backpressure by design (see the `backpressure` moduledoc). This pins the
/// keying property that makes the exemption safe: the cap accounts each key independently, so
/// saturating a `{vol}` lane neither consults nor consumes the control lane's budget — and the
/// dispatch only ever consults this gate for vid-bearing commands, never for `_control`.
#[test]
fn the_control_lane_is_outside_the_per_volume_cap() {
    const CONTROL: &str = "egraft:cmd:_control";
    let bp = Backpressure::new(2);

    // saturate a real Volume lane to its cap
    let _a1 = bp.admit(VOL_A).unwrap();
    let _a2 = bp.admit(VOL_A).unwrap();
    assert!(bp.admit(VOL_A).is_none(), "VOL_A is at its cap");

    // the control lane's accounting is wholly independent — a saturated Volume does not
    // touch it (it starts at 0 regardless of VOL_A's state)
    assert_eq!(bp.in_flight(CONTROL), 0, "the control lane shares no budget with a Volume");
}
