# The Secret — Anchor Scenario Context

**Status:** sole active scenario. Everything else in the repo (The Prince, The Bank) predates the v3 stateful engine and will not resolve correctly. Ignore them entirely.

**Schema version:** 3
**District:** `neighborhood`
**Shape:** 27 nodes, 4 acts, 7 distinct endings (A, B, C, C2, D, D2, E)

---

## 1. What this scenario is

Your closest friend, Jordan, confesses an affair. Their partner Alex — your friend first — is about to propose. You are handed a secret you never agreed to carry.

Design principle: **there is no correct answer.** Every choice is defensible. The scenario measures judgment under ambiguity, not pattern-recognition. This is the opposite of the Digital District, where recognising a scam is a real skill with a real right answer.

Feedback timing is `end_only` — per-choice score deltas are **suppressed during play** and revealed only on the outcome screen. This is gated by `district.id == 'neighborhood'` in `scenario_screen.dart`, not by a scenario flag.

---

## 2. Backend contract (v3)

### `GET /api/scenarios/today?scenarioId=the_secret`

```json
{
  "scenarioId": "the_secret",
  "title": "The Secret",
  "district": "neighborhood",
  "difficulty": 1,
  "persona": { "name": "Jordan", "role": "Close friend" },
  "state": { "trajectory": "compassionate", "judgedFirst": false, "jordanTrust": 0, "...": "..." },
  "node": {
    "nodeId": "establish",
    "message": "...",
    "thread": null,
    "presentation": { "type": "scene", "modal": false, "data": {} },
    "reactionDelay": null,
    "interstitial": null,
    "choices": []
  }
}
```

### `POST /api/scenarios/respond`

Body: `{ scenarioId, nodeId, choiceId, runningTotal, state, testerId }`

Non-terminal response: `{ scores, reasons, beat, terminal: false, state, node }`
Terminal response: `{ scores, reasons, beat, terminal: true, state, consequence, landing, outcomeExplanation }`

### Contract rules the client must honour

1. **`state` is an opaque courier.** Seed from `Scenario.state`, replace with `result.state` on every turn, send back verbatim. The client must never read a key out of it — all routing and variant logic is server-side.
2. **A node has `message` OR `thread`, never both.** Either may be null. `thread` is a `List<ThreadSegment>`; a segment is `{from, text}` (bubble) or `{narration}` (prose between bubbles).
3. **`interstitial`** = `{label, durationMs}`. Renders full-screen **before** the node's content. Consumes no choice, creates no node. Tapping skips early and reveals the node — it must not advance past it.
4. **`beat`** = one line of narration returned on `/respond`. Renders between the player's reply and the next node's message, styled as italic prose, never as dialogue.
5. **`landing`** = final cinematic beat between the terminal choice and the outcome screen. Present on most but not all terminal choices.
6. **`requires`** is filtered server-side. `node.choices` in a response contains only choices that passed. Render all of them; do not filter again client-side.
7. **Presentation types used:** `scene` (inline `SceneCard` / modal `SceneModal`) and `messages` (modal `MessagesCard`). No others.

### Ordering that must not change

`setState` → `beat` → `nextRules` → navigate → resolve variants on destination.

If variants resolve before `setState`, `act2_probe_response:hold_line` silently renders Act 3's default text instead of the "Alex is suspicious" version. No error, just a scenario that forgets what you did.

`nextRules` evaluate **before** `next`, in array order, first match wins. A matched rule with `next: null` means "resolve this choice's own `terminal` block" — not a dead end, not a missing key.

`when` inside `messageVariants` / `threadVariants` / `nextRules` = **AND** across all pairs, missing key is a non-match.
`requires` on a choice = array of `when` objects, **OR**'d together. Opposite combining rule. Do not normalise these together.

---

## 3. Client files in scope

| File | Role |
|---|---|
| `lib/models/scenario.dart` | `ThreadSegment`, `ScenarioInterstitial`, `ScenarioNode` (nullable `message`, `thread`, `interstitial`), `Scenario.state`, `TurnResult.state`/`.beat` |
| `lib/services/api_service.dart` | Sends `state` on `submitChoice`, accepts `scenarioId` on `fetchTodayScenario` |
| `lib/screens/scenario_screen.dart` | Orchestration: transcript, state courier, reveal tokens, interstitial, beat, landing, modal dispatch |
| `lib/widgets/messages_card.dart` | Phone-thread rendering + `showMessagesModal`, staged segment reveal |
| `lib/widgets/interstitial_overlay.dart` | `showInterstitial` — full-screen time-stamp card |
| `lib/widgets/scene_card.dart` / `scene_modal.dart` | Scene rendering with mood-transition avatar |
| `lib/widgets/sms_card.dart` | **Not used by The Secret.** Digital District only. Distinct from `messages_card.dart`. |

---

## 4. Known issues — open

### 4a. Pacing (client-side, high priority)

**Beats are buried by interstitials.** `_beatHoldDuration` is 900ms. Every beat in the scenario is 15–30 words (~5–9s of reading). Worse, `_BeatLine` fades in over 420ms and `_scrollToBottom` animates over 300ms, so effective full-opacity reading time is ~480ms — and on paths where the next node has an interstitial (`act2_probe_response:back_off` → `act3_jordan_returns`), a full-screen card covers the beat before it can be read. Beats are not re-readable.

Fix direction: scale hold to word count, e.g. `max(1600ms, words × 280ms)` capped ~7s. Optionally add `beatHoldMs` to the choice JSON for per-beat control.

**Fixed delays for variable text lengths.** `_reactionDelays` maps `short`/`medium`/`long` to 800/1500/2500ms regardless of message length. `establish` is ~150 words; `act3_limit_response` is 8. Reading-time should scale with content.

**Modal content is never re-readable.** `_isModalNode` skips the transcript entry, and nearly every node in The Secret is modal (`confession`, both Act 2 response nodes, all of Act 3, all endings). The transcript ends up as player bubbles + beats with almost no persona content. Decide: add modal messages to the transcript on dismissal, or lean fully into modal-as-medium and drop the transcript pretence for Neighbourhood.

**Choices appear too early inside modals.** Should be gated behind a read-time delay and faded in after the message, matching the inline treatment.

**No dwell after modal dismiss.** `_selectChoice` fires the instant the modal closes. ~600ms of silence would let the decision land.

### 4b. Narrative weight (JSON-side)

**Dead state keys — set but never read:**

| Key | Set | Read |
|---|---|---|
| `jordanTrust` | 8× | 0× |
| `jordanCallResponse` | 3× | 0× |
| `heardFullConfession` | 3× | 0× |
| `pausedWithAlex` | 1× | 0× |
| `partyResponse` | 3× | 1× (only `deflected`) |

Most costly: `jordanCallResponse` is set on `act3b_jordan_calls` — the emotional peak, Jordan devastated on the phone — with three genuinely distinct answers, and Ending E renders identically for all three.

Note: `when` supports strict equality only, no operators. Threshold logic on `jordanTrust` needs either an operator extension or discrete derived keys.

**Outcome tiers contradict the endings.** Thresholds are 60/25/0/−1000 against a realistic maximum around 235. Playthrough C totals **90** → top tier ("Both friendships survived, changed") while its `consequence` reads "You are now the third person in this engagement." Playthrough G totals **125** → same top tier, on the path where Jordan is lost.

Two fixes needed:
- Recalibrate thresholds — roughly 140 / 70 / 10.
- Rewrite tier text to describe **quality of judgment only**, never outcomes. `consequence` already owns what-happened; the tier asserting "both friendships survived" directly contradicts it on several paths.

Alternative: make `outcomeTiers` per-ending.

---

## 5. Done

- Mood-transition avatar (interpolated palette shifts between mood states)
- Messages-modal typing indicators (three-dot bubble before each incoming message)

## 6. Queued, not started

- Outcome screen sequenced reveal (consequence → explanation → ledger → ring → buttons)
- Ghosted "you could have chosen" alternates in the breakdown ledger
- Location strip promoted to an act spine using `node.act`
- Vignette treatment for the `establish` node
- Read receipts and unopened-Jordan preview in the messages modal
- Single audio motif on interstitials

---

## 7. Verification

`the_secret.json` carries seven `testPlaythroughs`, each with a `path` and an `expect` string. They cover every variant, both `nextRules` outcomes, and the `next: null` case.

- **D** is the sharpest — `nextRules` skip Act 3 entirely for avoidant players. If Act 3 dialogue renders on that path, `nextRules` is being evaluated after `next`.
- **E** is the only path exercising `next: null`.
- **F** is the only path proving unused state doesn't throw (`liedToAlex` set, never read).

Run all seven and check each `expect`. If all seven produce the expected text, the contract is correctly implemented.