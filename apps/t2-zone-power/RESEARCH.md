# How macOS applies SMC power limits

Reverse engineered from macOS 15.4.1 (24E263): `AppleSMC`, `X86PlatformPlugin`,
`X86PlatformShim`, `AGPM`, `AMDRadeonX6000Framebuffer` and `AMD9500Controller`.
This is the reference t2-zone-power rebuilds.

## The SMC decides, macOS applies

The power balancing between CPU and GPUs runs inside the SMC firmware. macOS
does not compute limits from temperatures or power zones. It only applies the
limit steps the SMC hands out.

None of the macOS drivers reads the fin stack keys (`Th1H`, `Th2H`) or the
power zone keys (`PZ*`). They are internal to the SMC.

## SMC side (AppleSMC)

- The SMC raises event `0x80` (PLimitChange) whenever a limit changes.
- `AppleSMC::smcGetPLimits` then reads the I/O port window of the SMC.

| Port | Byte | Field |
|---|---|---|
| base + 0x10 | 0 | CPU |
| base + 0x10 | 1 | GPU (internal GPU in data version 3) |
| base + 0x10 | 2 | memory |
| base + 0x10 | 3 | idle |
| base + 0x14 | 0 | GPU, data version 3 only |

- Bit 7 of each byte flags a hard limit. Bits 0 to 6 hold the step.
- Memory and idle are only evaluated as soft limits.
- The data version comes from key `RGEN` (value 3 gives version 3). Without
  `RGEN`, key `DPLM` decides: 5 gives 3, 4 gives 2, 3 gives 1.

## Dispatch (X86PlatformPlugin)

- `cgCallPlatformFunction` splits the SMC data into the channels CPU, GPU,
  memory, idle and internal GPU.
- `normalizePLimit` only clamps the step to the range the listener
  registered. It does not scale it. Step `0x7f` means an uncalibrated SMC.
- A changed soft step goes to `<channel>-plimit-notification`. With the hard
  flag set, it also goes to `<channel>-plimit-notification-hard`.
- `setPLimitRange` tells the SMC how many steps a GPU listener has. It writes
  key `HE1N` (or `HE2N` if that key exists) for the external GPU and `HI1N`
  for the internal GPU. Nothing is sent when the range is a single step.

## CPU (X86PlatformShim to XCPM)

- The CPU step is an index into the P-state list from ACPI (`APSS`, else
  `_PSS`).
- `sendPLimitXCPM` passes the frequency of that P-state as upper bound and the
  lowest P-state as lower bound to XCPM (pmCPUControl `0xc0085803`).
- `CPU_Speed_Limit` is that frequency in percent of the highest guaranteed
  turbo frequency.
- macOS caps the CPU clock. It does not touch PL1 or PL2 for this.

## Discrete GPU (AGPM to the AMD driver)

- AGPM config for `GFX0` on MacBookPro15,1 and 16,1: `control-id 17`,
  `min-power-state 0`, `max-power-state 15`, `Heuristic ID -1`. That is 16
  steps and no AGPM heuristic of its own.
- AGPM passes the step unchanged as power limit index
  (`kAGDCPMPowerLimit`), as long as it is below the driver's NumPowerLimits.
- Both AMD drivers build the table linearly, step 0 is the maximum:
  `limit[i] = min + (max - min) * (n - 1 - i) / (n - 1)`

| Model | Driver | max | min | n |
|---|---|---|---|---|
| 16,1 Navi 14 | AMDRadeonX6000Framebuffer | TDP (50 W) | ceil(TDP * 0.4) = 20 W | 16 |
| 15,1 Polaris | AMD9500Controller | TDP | 0 W | 16 |

- Registry keys `CFG_PTPL2_MIN`, `CFG_PTPL2_MAX`, `CFG_PTPL2_CNT` and
  `CFG_PTPL2_TBL` can override the table. Apple does not set them for these
  models.

## Linux mapping

- t2smc: handle event `0x80`, expose the five steps with their hard flag in
  sysfs with poll notification, and write the step counts to `HE1N`/`HE2N`
  and `HI1N`.
- t2-zonepowerd: apply the CPU step as a frequency cap from the P-state list
  and the dGPU step as power limit from the table above.
- amdgpu: needs a patch so `power1_cap` accepts limits below TDP. On the 16,1
  it currently accepts exactly 50 W only, because the Apple pptable has no
  overdrive power limit range.

## Open

1. Which of the two GPU fields is the discrete GPU in data version 3.
2. The values of `RGEN` and `DPLM` on 15,1 and 16,1.
3. The `APSS`/`_PSS` P-state lists of 15,1 and 16,1.
4. Whether the SMC sends GPU steps before `HE1N`/`HE2N` is set.

Points 1, 2 and 4 need a live read of the port window and the keys.
