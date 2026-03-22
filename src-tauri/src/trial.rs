use serde::Serialize;
use std::fs;
use std::path::PathBuf;
use std::time::{SystemTime, UNIX_EPOCH};

const TRIAL_DAYS: u64 = 14;
const SECS_PER_DAY: u64 = 86400;

#[derive(Serialize, Clone)]
pub struct TrialStatus {
    pub active: bool,
    pub expired: bool,
    pub days_left: u64,
    pub licensed: bool,
}

fn data_dir() -> PathBuf {
    dirs::data_dir()
        .unwrap_or_else(|| PathBuf::from("."))
        .join("4MA")
}

fn trial_file() -> PathBuf {
    data_dir().join("trial.json")
}

fn license_file() -> PathBuf {
    data_dir().join("license.key")
}

fn now_secs() -> u64 {
    SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .unwrap_or_default()
        .as_secs()
}

pub fn check() -> TrialStatus {
    // Licensed?
    if license_file().exists() {
        if let Ok(key) = fs::read_to_string(license_file()) {
            if validate_key(&key.trim()) {
                return TrialStatus {
                    active: true,
                    expired: false,
                    days_left: 9999,
                    licensed: true,
                };
            }
        }
    }

    // Trial
    let dir = data_dir();
    let _ = fs::create_dir_all(&dir);
    let path = trial_file();

    let start = if path.exists() {
        fs::read_to_string(&path)
            .ok()
            .and_then(|s| s.trim().parse::<u64>().ok())
            .unwrap_or_else(now_secs)
    } else {
        let ts = now_secs();
        let _ = fs::write(&path, ts.to_string());
        ts
    };

    let elapsed = now_secs().saturating_sub(start);
    let trial_secs = TRIAL_DAYS * SECS_PER_DAY;

    if elapsed >= trial_secs {
        TrialStatus {
            active: false,
            expired: true,
            days_left: 0,
            licensed: false,
        }
    } else {
        let left = (trial_secs - elapsed) / SECS_PER_DAY;
        TrialStatus {
            active: true,
            expired: false,
            days_left: left + 1,
            licensed: false,
        }
    }
}

pub fn activate(key: &str) -> Result<String, String> {
    if !validate_key(key) {
        return Err("invalid license key".to_string());
    }
    let dir = data_dir();
    let _ = fs::create_dir_all(&dir);
    fs::write(license_file(), key).map_err(|e| e.to_string())?;
    Ok("activated".to_string())
}

fn validate_key(key: &str) -> bool {
    // Simple validation: key must be 4MA-XXXX-XXXX-XXXX format
    // In production, verify against a server or use cryptographic validation
    key.starts_with("4MA-") && key.len() >= 16
}
