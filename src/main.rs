use clap::Parser;
use std::io::ErrorKind;
use std::path::{Path, PathBuf};

fn main() {
    let args = Args::parse();
    go(&args.path).unwrap();
}

fn go(dir: &Path) -> std::io::Result<()> {
    for entry in std::fs::read_dir(dir)? {
        let entry = entry?;
        if entry.metadata()?.is_dir() {
            let path = entry.path();
            go(&path)?;
            match std::fs::remove_dir(&path) {
                Ok(_) => {
                    eprintln!("Removed empty folder {}", path.display());
                }
                Err(e) => match e.kind() {
                    ErrorKind::DirectoryNotEmpty => {}
                    _ => panic!("{}", e),
                },
            }
        }
    }
    Ok(())
}

/// Removes all empty directories, recursively
#[derive(clap::Parser)]
struct Args {
    /// The path on which to operate
    #[clap(default_value("."))]
    path: PathBuf,
}
