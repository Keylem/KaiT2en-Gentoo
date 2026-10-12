use std::{
    path::PathBuf,
    sync::{
        atomic::{AtomicBool, Ordering},
        Arc,
    },
    thread,
    time::{Duration, Instant},
};

use signal_hook::consts::signal::{SIGINT, SIGTERM};

use crate::{
    actuators::{CpuCap, DGpuCap, ForcedIdle},
    error::{Result, ZonePowerError},
    plimit::PLimits,
    sysfs::find_t2smc,
};

const TICK: Duration = Duration::from_millis(250);
const REDISCOVER: Duration = Duration::from_secs(10);

/// Applies the SMC power limit steps like X86PlatformShim and AGPM do on
/// macOS. The iGPU step is not applied yet, its frequency table is not known.
pub fn run() -> Result<()> {
    let stop = Arc::new(AtomicBool::new(false));
    for signal in [SIGTERM, SIGINT] {
        signal_hook::flag::register(signal, stop.clone()).map_err(|source| ZonePowerError::Io {
            path: PathBuf::from("<signal-hook>"),
            source,
        })?;
    }

    let t2smc = find_t2smc()?;
    let cpu = CpuCap::discover(&t2smc)?;
    let idle = ForcedIdle::discover()?;
    let mut dgpu = DGpuCap::discover()?;
    let mut last_discovery = Instant::now();
    let mut last = None;
    report_missing(&cpu, &idle, &dgpu);

    while !stop.load(Ordering::Relaxed) {
        if dgpu.is_none() && last_discovery.elapsed() >= REDISCOVER {
            dgpu = DGpuCap::discover()?;
            last_discovery = Instant::now();
        }

        match PLimits::read(&t2smc) {
            Ok(limits) => {
                if last != Some(limits) {
                    eprintln!(
                        "plimit cpu {} igpu {} mem {} idle {} dgpu {}",
                        format_step(limits.cpu.step, limits.cpu.hard),
                        format_step(limits.igpu.step, limits.igpu.hard),
                        format_step(limits.memory.step, limits.memory.hard),
                        format_step(limits.idle.step, limits.idle.hard),
                        format_step(limits.dgpu.step, limits.dgpu.hard),
                    );
                    last = Some(limits);
                }
                apply(&limits, cpu.as_ref(), idle.as_ref(), dgpu.as_ref());
            }
            Err(error) => eprintln!("{error}"),
        }
        thread::sleep(TICK);
    }

    restore(cpu.as_ref(), idle.as_ref(), dgpu.as_ref());
    Ok(())
}

fn apply(limits: &PLimits, cpu: Option<&CpuCap>, idle: Option<&ForcedIdle>, dgpu: Option<&DGpuCap>) {
    if let Some(cpu) = cpu {
        report(cpu.apply(cpu.target_khz(limits.cpu.step)));
    }
    if let Some(idle) = idle {
        report(idle.apply(idle.target_percent(limits.idle.step)));
    }
    if let Some(dgpu) = dgpu {
        report(dgpu.apply(dgpu.target_w(limits.dgpu.step)));
    }
}

fn restore(cpu: Option<&CpuCap>, idle: Option<&ForcedIdle>, dgpu: Option<&DGpuCap>) {
    if let Some(cpu) = cpu {
        report(cpu.restore());
    }
    if let Some(idle) = idle {
        report(idle.restore());
    }
    if let Some(dgpu) = dgpu {
        report(dgpu.restore());
    }
}

fn report(result: Result<()>) {
    if let Err(error) = result {
        eprintln!("{error}");
    }
}

fn report_missing(cpu: &Option<CpuCap>, idle: &Option<ForcedIdle>, dgpu: &Option<DGpuCap>) {
    if cpu.is_none() {
        eprintln!("no CPU P-states from t2smc or no cpufreq policy, CPU step is not applied");
    }
    if idle.is_none() {
        eprintln!("intel_powerclamp is missing, idle step is not applied");
    }
    if dgpu.is_none() {
        eprintln!("no supported dGPU found yet, dGPU step is not applied");
    }
}

fn format_step(step: u8, hard: bool) -> String {
    if hard { format!("{step}!") } else { step.to_string() }
}
