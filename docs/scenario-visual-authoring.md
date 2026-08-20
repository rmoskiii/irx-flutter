# Scenario Visual Authoring Notes

Use this prompt/instruction sheet when updating backend JSON beats for
Neighborhood / The Secret and Career / The Instruction.

## Client Contract

The Flutter client now supports two visual upgrades:

1. Existing `presentation.type: "scene"` and `"messages"` nodes can include
   optional `presentation.data.visual`.
2. Career nodes can use a new inline `presentation.type: "work_artifact"`.
3. Modal career scenes can include an optional `presentation.data.artifact`
   object. This renders a work artifact inside the scene modal while keeping
   the character and choices in frame.

Everything is backward-compatible. If `visual` is absent, Flutter infers a
setting from `presentation.data.location`.

## Scene Visual Metadata

Add this inside `presentation.data` for important emotional/place beats:

```json
"visual": {
  "setting": "kitchen",
  "pressure": "confession / promise / first reaction",
  "props": ["tea towel", "glasses", "counter"]
}
```

Supported `setting` values:

- `kitchen`
- `coffee_shop`
- `party`
- `street`
- `flat`
- `phone`
- `desk`
- `meeting_room`
- `review_room`
- `office`
- `scene`

Guidelines:

- Use `pressure` for the invisible thing the moment is asking the player to
  carry: `two secrets`, `proposal energy`, `timestamp`, `your name on the
  form`, `review asks for evidence`.
- Keep `props` concrete and short. They are visual anchors, not prose.
- Do not add `visual` to every node. Use it where the scene should feel like
  a distinct room, artifact, or pressure shift.

## The Secret Pass

Target beats:

- Kitchen confession: `setting: "kitchen"`, pressure around judgment/secret.
- Alex proposal reveal: `setting: "flat"`, pressure around `two secrets`.
- Coffee shop confrontation: `setting: "coffee_shop"`, pressure around
  `proposal / suspicion`.
- Alex truth moment: `setting: "flat"`, pressure around `how long have you
  known`.
- Jessica call / street: `setting: "street"`, pressure around `betrayal`.
- Engagement party: `setting: "party"`, pressure around `toast / ring /
  secret in public`.
- Aftermath text threads: `setting: "phone"`, pressure around `unread /
  group text / silence`.

Example:

```json
"presentation": {
  "type": "scene",
  "modal": true,
  "data": {
    "location": "Alex's flat, three weeks later",
    "character": {
      "name": "Alex",
      "role": "Your friend first",
      "mood": "excited"
    },
    "visual": {
      "setting": "flat",
      "pressure": "two secrets in the hallway",
      "props": ["ring", "hallway", "watching your face"]
    }
  }
}
```

## Work Artifact Presentation

Use this for Career when the story beat is a record, system, form, review, or
evidence object. Keep `modal: false`.

```json
"presentation": {
  "type": "work_artifact",
  "modal": false,
  "data": {
    "variant": "qa_checklist",
    "eyebrow": "Internal checklist",
    "title": "Northstar QA Checklist",
    "status": "unsigned",
    "fields": [
      { "label": "Assigned analyst", "value": "You" },
      { "label": "Completion date", "value": "14 April" },
      { "label": "QA sign-off", "value": "Pending" }
    ],
    "actions": ["name required", "date locked"]
  }
}
```

Supported `variant` values:

- `qa_checklist`
- `file_upload`
- `review_notice`
- `chronology`
- `email_draft`
- `record`

The node `message` becomes the body text inside the artifact card.

## Work Artifact Inside A Scene Modal

Use this when the pressure comes from both a person and a document. The
important example is `ask2_qa`: Ray's face is the pressure, so keep the node as
`presentation.type: "scene"` and `modal: true`, then put the checklist inside
`presentation.data.artifact`.

```json
"presentation": {
  "type": "scene",
  "modal": true,
  "data": {
    "location": "The small meeting room, Friday",
    "character": {
      "name": "Ray",
      "role": "Your manager",
      "mood": "pressed"
    },
    "visual": {
      "setting": "meeting_room",
      "pressure": "your name needs to be on it",
      "props": ["laptop", "checklist", "closed door"]
    },
    "artifact": {
      "variant": "qa_checklist",
      "eyebrow": "Internal checklist",
      "title": "Northstar QA Checklist",
      "status": "unsigned",
      "fields": [
        { "label": "Assigned analyst", "value": "You" },
        { "label": "Completion date", "value": "14 April" },
        { "label": "QA sign-off", "value": "Pending" }
      ],
      "actions": ["name required", "formality"]
    }
  }
}
```

## The Instruction Pass

Target beats:

- Ask 1 date change: use `scene.visual` on Ray's ask, then optionally
  `work_artifact` with `variant: "file_upload"` on upload aftermath.
- Ask 2 QA checklist: keep it as a modal `scene` with
  `visual.setting: "meeting_room"` and add `data.artifact.variant:
  "qa_checklist"`. Do not convert this node to inline `work_artifact`; Ray
  needs to stay in frame for the hinge beat.
- Ask 3 client email: keep the existing `email` presentation. The sender email
  matters, and this beat should feel like an ordinary forwarded inbox item, not
  a pre-labelled record.
- Dana escalation: use `scene.visual`, `setting: "review_room"`,
  `pressure: "what have you got"`.
- September review email: use `work_artifact`, `variant: "review_notice"`.
  Keep `fields` state-neutral because presentation data is static per node;
  the five message variants should carry the specific asks.
- Strong documentation paths: defer `chronology` for now. The obvious home is
  state-dependent resolution prose, but presentation is fixed per node. Adding
  a new node would violate structure preservation in this pass.

Example review notice:

```json
"presentation": {
  "type": "work_artifact",
  "modal": false,
  "data": {
    "variant": "review_notice",
    "eyebrow": "Delivery Assurance",
    "title": "Northstar April Delivery Review",
    "status": "respond by Friday",
    "fields": [
      { "label": "Account", "value": "Northstar" },
      { "label": "Period", "value": "April delivery" },
      { "label": "Respond by", "value": "Friday" }
    ],
    "actions": ["routine review", "evidence requested"]
  }
}
```

## Prompt For Updating Backend JSON

Paste this into your backend-editing assistant:

```text
Update The Secret and The Instruction scenario JSON to use the Flutter visual
presentation contract below. Do not change scoring, routing, state keys,
choice ids, nextRules, terminal logic, or authored prose unless a field must be
split into visual metadata. Only add or adjust presentation metadata.

For scene/messages nodes, add presentation.data.visual selectively:
- setting: one of kitchen, coffee_shop, party, street, flat, phone, desk,
  meeting_room, review_room, office, scene
- pressure: a short phrase naming the invisible tension of the beat
- props: 2-3 concrete visual anchors

For Career artifact beats, change or add presentation.type "work_artifact" with
modal false only when the node is primarily a form, record, upload, review
notice, chronology, or draft. Supported variants: qa_checklist, file_upload,
review_notice, chronology, email_draft, record. Put structured values in
data.fields as [{ "label": "...", "value": "..." }]. Put short tags in
data.actions. Keep the node message as the card body.

Preserve these decisions:
- ask2_qa stays presentation.type "scene", modal true. Add
  data.visual.setting "meeting_room" and data.artifact.variant "qa_checklist"
  if a checklist is needed inside the modal.
- ask3_client_email stays presentation.type "email"; do not convert it to
  email_draft.
- audit_email may become work_artifact/review_notice, but data.fields must be
  state-neutral: Account / Period / Respond by. Leave variant-specific asks in
  messageVariants.
- Do not add chronology in this pass; it needs a later structural pass.
- file_upload on ask1_reaction is safe because its reachable branches both set
  alteredDate true.

Apply this lightly. The goal is that The Secret feels spatial and relational,
and The Instruction feels procedural and evidentiary, without overdecorating
every node.
```
