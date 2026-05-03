# Demo Recording Guide

Instructions for recording the GIF demos used in package READMEs.

## Setup
- Device: iPhone 14 or Pixel 7 simulator (375×812 logical pixels)
- Duration per GIF: 6–10 seconds
- Frame rate: 30fps
- Tool: macOS QuickTime Player screen recording, then convert to GIF with `ffmpeg` or Gifox

## GIFs to record (7 total)

### 1. `docs/images/demo_search_debounce.gif`
**Package**: flutter_debounce_throttle / dart_debounce_throttle
**App**: `packages/flutter_debounce_throttle/example/` → Search tab
**Script**:
1. Tap the search field
2. Type "flutter" quickly, one letter at a time with ~150ms between keys
3. Pause — watch the spinner appear and results load
4. Highlight the stat cards: "Keystrokes: 7, API Calls: 1, Saved: 6"
**Total time**: ~8s

### 2. `docs/images/demo_throttle_antispam.gif`
**Package**: flutter_debounce_throttle
**App**: `packages/flutter_debounce_throttle/example/` → Anti-Spam tab
**Script**:
1. Tap "Pay $99" button 8 times rapidly (all within 1-2 seconds)
2. Show stat cards: "Taps: 8, Payments: 1, Blocked: 7"
3. Wait 2 seconds
4. Tap once more — it fires again (Payments: 2)
**Total time**: ~7s

### 3. `docs/images/demo_async_submit.gif`
**Package**: flutter_debounce_throttle
**App**: `packages/flutter_debounce_throttle/example/` → Async Form tab
**Script**:
1. Tap "Submit Form" — spinner appears, button disables
2. Tap 3-4 more times while spinner is running (button stays disabled / grey)
3. Submission completes — "Submitted!" appears
4. Show "Attempts: 4, Submitted: 1, Blocked: 3"
**Total time**: ~8s

### 4. `docs/images/demo_concurrency_replace.gif`
**Package**: flutter_debounce_throttle
**App**: `packages/flutter_debounce_throttle/example/` → Concurrency tab
**Script**:
1. Type "d" → log shows "Request #1 started"
2. Quickly type "da", "dar", "dart" — each replaces previous
3. Wait — only "Request #4 completed ✓" appears (others were cancelled)
4. Scroll log to show all entries
**Total time**: ~8s

### 5. `docs/images/demo_riverpod_debounce.gif`
**Package**: flutter_debounce_throttle_riverpod
**App**: `packages/flutter_debounce_throttle_riverpod/example/` → Search tab
**Script**:
1. Type "flutter" quickly
2. Stat cards show: "Keystrokes: 7, API Calls: 1, Saved: 6"
3. Results appear after debounce fires
**Total time**: ~7s

### 6. `docs/images/demo_riverpod_autodispose.gif`
**Package**: flutter_debounce_throttle_riverpod
**App**: `packages/flutter_debounce_throttle_riverpod/example/` → Auto-Dispose tab
**Script**:
1. Type a few characters — log shows "Started debouncing..."
2. Immediately tap "Reset Provider"
3. Log shows "Provider reset — debounce CANCELLED" (red)
4. Verify "API called" does NOT appear
**Total time**: ~6s

### 7. `docs/images/demo_hooks_debounce.gif`
**Package**: flutter_debounce_throttle_hooks
**App**: `packages/flutter_debounce_throttle_hooks/example/` → Search tab
**Script**:
1. Type "hooks" quickly
2. Shows "Keystrokes: 5, API Calls: 1"
3. Results appear
**Total time**: ~6s

## Converting to GIF

```bash
# Record .mov with QuickTime, then:
ffmpeg -i recording.mov -vf "fps=30,scale=390:-1:flags=lanczos" -c:v gif demo.gif

# Or use Gifox (macOS app) for best quality
```

## Where to place GIFs

Place all GIFs in `docs/images/` directory in the repo root. Then reference them in READMEs as:
```markdown
![Demo](https://raw.githubusercontent.com/brewkits/flutter_debounce_throttle/main/docs/images/demo_search_debounce.gif)
```
