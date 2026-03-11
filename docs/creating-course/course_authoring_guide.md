# Course Authoring Guide

This document describes the file structure, metadata, and content format required to create a course compatible with Course Imports.

---

## Folder Structure

A course is a single folder containing a `course.json` metadata file and a `topics/` directory. Each topic is a numbered subfolder with its own `content.json` and any referenced files (markdown, code, images).

```
my-course/
├── course.json
└── topics/
    ├── 01-introduction/
    │   ├── content.json
    │   ├── intro.md
    │   └── hello.py
    ├── 02-variables-and-types/
    │   ├── content.json
    │   ├── overview.md
    │   ├── example.py
    │   └── diagram.png
    └── 03-functions/
        ├── content.json
        └── explanation.md
```

---

## course.json

The root metadata file. All fields are required unless noted.

```json
{
  "id": "intro-to-python",
  "title": "Introduction to Python",
  "description": "A beginner-friendly course covering Python fundamentals.",
  "version": "1.0.0",
  "author": "Jane Smith",
  "tags": ["programming", "python", "beginner"],
  "topicOrder": [
    "01-introduction",
    "02-variables-and-types",
    "03-functions"
  ]
}
```

| Field        | Type       | Description                                                        |
| ------------ | ---------- | ------------------------------------------------------------------ |
| `id`         | `string`   | Unique identifier for the course (use kebab-case).                 |
| `title`      | `string`   | Display title.                                                     |
| `description`| `string`   | Short summary of the course.                                       |
| `version`    | `string`   | Semver version string.                                             |
| `author`     | `string`   | Course author name.                                                |
| `tags`       | `string[]` | Keywords for categorisation.                                       |
| `topicOrder` | `string[]` | Ordered list of topic folder names. Must match folders in `topics/`. |

---

## Topics

Each entry in `topicOrder` must correspond to a subfolder inside `topics/`.

**Naming convention:** prefix with a number for ordering, e.g. `01-introduction`. The display title is derived automatically by stripping the numeric prefix and title-casing the remainder (`01-introduction` becomes "Introduction").

Each topic folder must contain a `content.json` file.

---

## content.json

An ordered JSON array of **blocks**. Blocks are rendered top-to-bottom in the order they appear.

```json
[
  { "type": "text", "src": "intro.md" },
  { "type": "code", "language": "python", "src": "hello.py", "label": "hello.py" },
  { "type": "callout", "style": "info", "body": "Python is case-sensitive." },
  { "type": "quiz", "question": "What does print() do?", "options": ["Saves a file", "Outputs text", "Creates a variable"], "answer": 1, "explanation": "print() outputs text to the console." },
  { "type": "reveal", "label": "ELI5: What is print?", "body": "Think of `print()` like a megaphone — it takes whatever you give it and announces it out loud." },
  { "type": "image", "src": "diagram.png", "alt": "Memory model diagram" },
  { "type": "checkpoint", "label": "I can write and run a Python script" }
]
```

---

## Block Types

### Text

Renders markdown content. Reference an external `.md` file with `src`, or provide content inline.

```json
{ "type": "text", "src": "intro.md" }
```

```json
{ "type": "text", "content": "Welcome to the course. This is **markdown**." }
```

| Field     | Type     | Required | Description                                  |
| --------- | -------- | -------- | -------------------------------------------- |
| `type`    | `"text"` | Yes      | Must be `"text"`.                            |
| `src`     | `string` | No       | Path to a `.md` file relative to the topic folder. |
| `content` | `string` | No       | Inline markdown string. Used if `src` is absent.   |

One of `src` or `content` must be provided.

---

### Code

Displays a syntax-highlighted code block.

```json
{ "type": "code", "language": "python", "src": "hello.py", "label": "hello.py" }
```

```json
{ "type": "code", "language": "javascript", "content": "console.log('hello')" }
```

| Field      | Type     | Required | Description                                         |
| ---------- | -------- | -------- | --------------------------------------------------- |
| `type`     | `"code"` | Yes      | Must be `"code"`.                                   |
| `language` | `string` | Yes      | Language identifier for syntax highlighting.         |
| `src`      | `string` | No       | Path to a source file relative to the topic folder.  |
| `content`  | `string` | No       | Inline code string. Used if `src` is absent.         |
| `label`    | `string` | No       | Display label shown above the code block.            |

One of `src` or `content` must be provided.

---

### Quiz

Presents a question with selectable options.

```json
{
  "type": "quiz",
  "question": "What does the print() function do?",
  "options": [
    "Saves a file",
    "Outputs text to the console",
    "Creates a variable",
    "Imports a module"
  ],
  "answer": 1,
  "explanation": "print() writes output to the standard console."
}
```

| Field         | Type                 | Required | Description                                       |
| ------------- | -------------------- | -------- | ------------------------------------------------- |
| `type`        | `"quiz"`             | Yes      | Must be `"quiz"`.                                 |
| `question`    | `string`             | Yes      | The question text.                                |
| `options`     | `string[]`           | Yes      | List of answer choices.                           |
| `answer`      | `number`             | Yes      | Zero-based index of the correct option.           |
| `explanation` | `string`             | No       | Shown after the user answers.                     |

---

### Callout

A highlighted box for tips, warnings, or extra info.

```json
{ "type": "callout", "style": "warning", "body": "Do not use `eval()` in production code." }
```

| Field   | Type                            | Required | Description                         |
| ------- | ------------------------------- | -------- | ----------------------------------- |
| `type`  | `"callout"`                     | Yes      | Must be `"callout"`.                |
| `style` | `"info"` \| `"warning"` \| `"tip"` | Yes  | Visual style of the callout.        |
| `body`  | `string`                        | Yes      | Markdown-formatted callout content. |

---

### Reveal

A collapsible block that hides content behind a clickable header. Useful for supplementary material that not every learner needs to see.

```json
{
  "type": "reveal",
  "label": "ELI5: What is a variable?",
  "body": "Think of a variable like a labeled box. You write a name on the outside (the variable name) and put something inside (the value). When you need that thing later, you just look for the box with the right label."
}
```

| Field   | Type       | Required | Description                                              |
| ------- | ---------- | -------- | -------------------------------------------------------- |
| `type`  | `"reveal"` | Yes      | Must be `"reveal"`.                                      |
| `label` | `string`   | No       | Collapsed header text. Defaults to "Reveal" if omitted.  |
| `body`  | `string`   | Yes      | Markdown content shown when expanded.                    |

The `body` field supports full markdown including headings, lists, code fences, and inline formatting.

**Recommended uses:**

- **ELI5 explanations** — simplified analogies that make abstract concepts concrete
- **Deep dives** — extended technical detail for curious learners who want to go further
- **Common mistakes** — pitfalls and misconceptions with guidance on how to avoid them
- **Exercises** — "try it yourself" prompts with hints or starter code

---

### Checkpoint

A completion marker that lets the learner signal they've understood the topic. Rendered as a toggleable button.

```json
{ "type": "checkpoint", "label": "I can write and call a Python function" }
```

| Field   | Type           | Required | Description                                                     |
| ------- | -------------- | -------- | --------------------------------------------------------------- |
| `type`  | `"checkpoint"` | Yes      | Must be `"checkpoint"`.                                         |
| `label` | `string`       | No       | Button text. Defaults to "Mark as complete" if omitted.         |

Place checkpoints at the end of a topic. Phrase the label as a self-assessment: "I can..." or "I understand..." statements work well (e.g. "I can use Git branches to work on features independently").

---

### Image

Displays an image with alt text.

```json
{
  "type": "image",
  "src": "diagram.png",
  "alt": "Python variable memory model",
  "caption": "How Python stores variables in memory"
}
```

| Field     | Type      | Required | Description                                        |
| --------- | --------- | -------- | -------------------------------------------------- |
| `type`    | `"image"` | Yes      | Must be `"image"`.                                 |
| `src`     | `string`  | Yes      | Path to the image file relative to the topic folder. |
| `alt`     | `string`  | Yes      | Alt text for accessibility.                        |
| `caption` | `string`  | No       | Caption displayed below the image.                 |

Images must be under 10 MB.

---

## Topic Completion Rules

- **Topics without quizzes or checkpoints** are marked complete when first viewed.
- **Topics with quizzes** are marked complete only when all quizzes in the topic have been answered.
- **Topics with checkpoints** are marked complete when all checkpoints have been toggled.
- **Topics with both quizzes and checkpoints** require all quizzes answered and all checkpoints toggled.

---

## Loading a Course

Courses can be loaded in two ways:

1. **Local folder** — select the course folder using the file picker.
2. **GitHub repository** — paste a GitHub repo URL. The repo must follow the same folder structure above. A GitHub personal access token can be provided for private repos.

---

## Validation Checklist

The app validates courses on load. Use this checklist to catch issues before importing:

- [ ] `course.json` exists at the root and is valid JSON
- [ ] All required fields in `course.json` are present (`id`, `title`, `description`, `version`, `author`, `tags`, `topicOrder`)
- [ ] A `topics/` directory exists
- [ ] Every entry in `topicOrder` has a matching folder in `topics/`
- [ ] Every topic folder contains a valid `content.json` (a JSON array)
- [ ] Every block in `content.json` has a `type` field
- [ ] All `src` paths point to files that exist within the topic folder (no `../` path traversal)
- [ ] Images are under 10 MB
- [ ] Multiple-choice quizzes have an `options` array and a valid `answer` index
- [ ] Text and code blocks provide either `src` or `content`

---

## Writing Effective Course Content

### Recommended topic structure

Each topic should follow this flow to create a consistent, engaging learning experience:

1. **Overview** (text block, 15-30 lines)
   - Frame the *problem* this topic solves before defining the concept
   - Include 3-5 learning objectives as bullets ("By the end of this topic, you will...")
   - Set context for where this fits in the course

2. **Core content** (interleaved text + code blocks)
   - Each `.md` file: 20-50 lines, covering one coherent concept
   - Weave code into narrative — don't dump code at the end
   - Number `.md` files for clarity: `01-overview.md`, `02-branching.md`

3. **Inline knowledge checks** (quiz blocks placed after each major concept)
   - 3-5 quizzes minimum per topic
   - Never cluster all quizzes at the end — place after the concept they test
   - Every quiz MUST have an `explanation` field
   - Mix question types: conceptual, applied, "what happens when...", scenario-based
   - Distractors must be plausible (real misconceptions, not joke answers)
   - Include at least one scenario-based question per topic

4. **Supplementary depth** (reveal blocks, at least 2 per topic)
   - One ELI5 or analogy for the hardest concept in the topic
   - One deep dive for learners who want more technical detail
   - Optionally: common mistakes reveal, "try it yourself" exercise

5. **Callouts** (2-4 per topic, distributed throughout)
   - `tip` for actionable advice
   - `warning` for gotchas and footguns
   - `info` for background context

6. **Key takeaways** (text block before checkpoint)
   - 3-5 bullet recap of what was covered
   - Reinforces the main ideas

7. **Checkpoint** (at topic end)
   - "I can..." or "I understand..." phrasing

### Writing style guidance

- Write as a knowledgeable colleague at a whiteboard, not a textbook
- Open every topic with the *problem* before the solution — "why does this exist?"
- Use concrete analogies for abstract concepts (e.g., "Git branches are like parallel timelines")
- Use second person ("you"), present tense
- Vary sentence rhythm — short sentences punch. Longer ones connect ideas and walk through reasoning.
- Never use foo/bar/baz — use realistic names and scenarios
- Show the "wrong way" before the "right way" where helpful
- Reference earlier topics when building on them ("Remember how we used X in the previous topic?")
- Include at least one concrete example or real-world scenario in every text block

### Content depth guidance

- Overview `.md` files: 15-30 lines
- Core content `.md` files: 20-50 lines
- Code examples should be complete, runnable, and accompanied by explanation
- Where possible, show what happens when something goes wrong (not just the happy path)

---

## Full Example

A single topic from a Python course, demonstrating the recommended structure with all block types:

```
python-basics/
├── course.json
└── topics/
    └── 03-functions/
        ├── content.json
        ├── 01-overview.md
        ├── 02-defining-functions.md
        ├── 03-parameters.md
        └── 04-takeaways.md
```

**topics/03-functions/content.json**
```json
[
  { "type": "text", "src": "01-overview.md" },

  { "type": "text", "src": "02-defining-functions.md" },
  {
    "type": "code",
    "language": "python",
    "label": "greet.py",
    "content": "def greet(name):\n    \"\"\"Return a personalised greeting.\"\"\"\n    return f\"Hello, {name}! Welcome aboard.\"\n\nmessage = greet(\"Priya\")\nprint(message)  # Hello, Priya! Welcome aboard."
  },
  {
    "type": "callout",
    "style": "tip",
    "body": "Give your functions verb-based names that describe what they do: `calculate_total`, `send_email`, `validate_input`. A reader should understand the purpose without checking the body."
  },
  {
    "type": "quiz",
    "question": "What does the `return` keyword do in a Python function?",
    "options": [
      "It prints output to the console",
      "It sends a value back to the caller and exits the function",
      "It stops the program entirely",
      "It defines a new variable in the global scope"
    ],
    "answer": 1,
    "explanation": "`return` sends a value back to wherever the function was called and immediately exits the function. Without a `return` statement, a function returns `None` by default."
  },

  { "type": "text", "src": "03-parameters.md" },
  {
    "type": "code",
    "language": "python",
    "label": "default_params.py",
    "content": "def create_user(name, role=\"viewer\", active=True):\n    return {\n        \"name\": name,\n        \"role\": role,\n        \"active\": active\n    }\n\n# Using defaults\nviewer = create_user(\"Alex\")\n# Overriding defaults\nadmin = create_user(\"Jordan\", role=\"admin\")\n\nprint(viewer)  # {'name': 'Alex', 'role': 'viewer', 'active': True}\nprint(admin)   # {'name': 'Jordan', 'role': 'admin', 'active': True}"
  },
  {
    "type": "callout",
    "style": "warning",
    "body": "Never use a mutable object (like a list or dictionary) as a default parameter value. Python creates the default once, and every call shares the same object. Use `None` as the default and create the mutable object inside the function."
  },
  {
    "type": "quiz",
    "question": "You call `create_user(\"Sam\")` using the function above. What value does the `role` key have in the returned dictionary?",
    "options": [
      "None",
      "\"admin\"",
      "\"viewer\"",
      "An error is raised because `role` was not provided"
    ],
    "answer": 2,
    "explanation": "When you don't pass a value for `role`, the default value `\"viewer\"` is used. Default parameters let callers skip arguments that have sensible defaults."
  },
  {
    "type": "quiz",
    "question": "A colleague writes a function with 8 positional parameters. What would you recommend?",
    "options": [
      "This is fine — functions can have as many parameters as needed",
      "Refactor: group related parameters into a dictionary or data class, or split the function",
      "Convert all parameters to global variables instead",
      "Use *args to accept unlimited arguments"
    ],
    "answer": 1,
    "explanation": "Functions with many parameters become hard to call correctly and difficult to read. Grouping related parameters into a data class or dictionary, or splitting the function into smaller pieces, makes the code more maintainable."
  },
  {
    "type": "reveal",
    "label": "ELI5: What is a function, really?",
    "body": "Imagine you have a recipe card for making a sandwich. The card has a title (the function name), a list of ingredients you need to provide (parameters), and step-by-step instructions (the function body). When you want a sandwich, you don't re-invent the process each time — you just follow the card and swap in different ingredients.\n\nA function works the same way. You write the instructions once, give them a name, and then \"call\" that recipe whenever you need it — with different inputs each time."
  },
  {
    "type": "reveal",
    "label": "Deep dive: How Python resolves function arguments",
    "body": "Python evaluates arguments in a specific order of priority:\n\n1. **Positional arguments** — matched left to right\n2. **Keyword arguments** — matched by name\n3. **`*args`** — captures extra positional arguments as a tuple\n4. **`**kwargs`** — captures extra keyword arguments as a dictionary\n\nThe full signature order is:\n\n```python\ndef func(pos_only, /, normal, *, kw_only, **kwargs):\n    ...\n```\n\n- Parameters before `/` are positional-only (Python 3.8+)\n- Parameters after `*` are keyword-only\n- This gives you fine-grained control over how callers interact with your API"
  },
  {
    "type": "callout",
    "style": "info",
    "body": "In the previous topic, you learned how variables store values. Functions take this further — they let you store *behaviour* and reuse it with different values each time."
  },
  {
    "type": "quiz",
    "question": "You have a function `def send_alert(message, urgent=False)`. A new requirement says alerts should also include a timestamp. What is the best approach?",
    "options": [
      "Add a global variable for the timestamp",
      "Add a `timestamp` parameter with a default of `None`, and generate it inside the function if not provided",
      "Create a completely new function called `send_alert_with_timestamp`",
      "Hard-code the current time inside the function with no parameter"
    ],
    "answer": 1,
    "explanation": "Adding an optional parameter with a `None` default is the most flexible approach. Callers who don't need a custom timestamp get automatic behaviour, while those who do can pass one explicitly. This keeps the API backwards-compatible."
  },

  { "type": "text", "src": "04-takeaways.md" },
  { "type": "checkpoint", "label": "I can define functions with parameters, defaults, and return values" }
]
```

**topics/03-functions/01-overview.md**
```markdown
# Functions

You've been writing code that runs top to bottom, one line after another.
That works for small scripts, but what happens when you need the same
logic in three different places? You copy and paste — and now you have
three copies to update every time something changes.

Functions solve this. They let you wrap a piece of logic in a reusable
package, give it a name, and call it whenever you need it. Change the
logic once, and every call gets the update.

Beyond avoiding repetition, functions make your code *readable*. A
well-named function tells the reader what happens without forcing them
to parse every line.

## What you'll learn

- How to define a function with `def`
- How parameters and return values work
- How to use default parameter values
- When and why to break code into functions
- Common pitfalls with mutable defaults
```

**topics/03-functions/04-takeaways.md**
```markdown
## Key Takeaways

- **Functions encapsulate reusable logic** — define once, call many times
- **Parameters make functions flexible** — the same function works with different inputs
- **Default values** let callers skip arguments that have sensible defaults
- **`return` sends a value back** to the caller; without it, a function returns `None`
- **Keep functions focused** — each function should do one thing well
```
