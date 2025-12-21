extends RefCounted
class_name GameTiming

## GameTiming - Shared timing constants used by logic and presentation layers
## Ensures logic ticks, invulnerability, and other frame-based durations stay synchronized.

const LOGIC_TPS: int = 10
const INVULNERABILITY_SECONDS: float = 3.0
const INVULNERABILITY_FRAMES: int = int(LOGIC_TPS * INVULNERABILITY_SECONDS)
