mod actuators;
mod daemon;
mod error;
mod plimit;
mod sysfs;

fn main() -> std::process::ExitCode {
    if std::env::args().any(|arg| arg == "--daemon") {
        if let Err(error) = daemon::run() {
            eprintln!("{error}");
            return std::process::ExitCode::from(1);
        }
        return std::process::ExitCode::SUCCESS;
    }
    eprintln!("the debug GUI is not built yet, run with --daemon");
    std::process::ExitCode::from(2)
}
