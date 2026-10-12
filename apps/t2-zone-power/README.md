# T2 Zone Power

<p align="center">
<img src="assets/zonepower.svg" alt="T2 Zone Power logo" width="96">
</p>

Applies the power limits of the SMC on T2 Macs running Linux, the way macOS does.

The SMC balances the shared heatpipe between CPU and GPUs itself. It hands
out limit steps for the CPU, the integrated GPU, the discrete GPU and forced
idle. macOS only applies them. Linux ignored them so far, so the SMC kept
escalating until it throttled the CPU through PROCHOT.

## How it works

`t2-zonepowerd` reads the steps from the t2smc driver (`smc_plimit_raw`) and
applies them every 250 ms.

| Step | Linux | macOS counterpart |
|---|---|---|
| CPU | `scaling_max_freq` at the ACPI P-state the step indexes, step 0 is turbo | X86PlatformShim to XCPM |
| Forced idle | `intel_powerclamp`, idle share of `100 - step` percent, at most 70 % | X86PlatformShim to XCPM |
| dGPU | `power1_cap` from the PowerTune table, TDP down to the driver floor in 16 steps | AGPM to the AMD driver |
| iGPU | shown, not applied yet | AGPM |

The dGPU floor follows the macOS drivers. Navi 1x goes down to 40 % of its
TDP, Polaris down to 0 W. A runtime suspended dGPU is left alone and gets its
cap once it wakes. On exit the daemon restores all limits.

t2smc also tells the SMC that the dGPU has 16 steps (`HE0N`), as macOS does.
Without it the SMC does not limit the dGPU and balances the heatpipe on the
CPU alone.

The GUI shows zone power against target, zone throttle, the applied limits
and CPU, dGPU and fin stack temperatures. It has no settings.

## Requirements

- t2smc with `smc_plimit_raw` and `cpu_pstates_mhz`
- `intel_pstate` or another cpufreq driver
- `intel_powerclamp`

## Build and install

```
make build
sudo make install
```

`make install` installs the binary, the desktop file, the icon and
`t2-zonepowerd.service`, and enables the service.
