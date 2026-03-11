---
name: creating-course
description: "Creates a complete course folder with course.json and topic content following the project's course authoring guide. Use when creating a new course, generating educational content, or when asked to build a course on a topic."
argument-hint: "[course-topic]"
allowed-tools:
  - Write
  - Edit
  - Read
  - Bash
  - Glob
  - Grep
  - Agent
  - WebSearch
  - WebFetch
  - AskUserQuestion
---

# Create Course

Create a complete course on: **$ARGUMENTS**

ultrathink

## Reference

Read [docs/course_authoring_guide.md](./course_authoring_guide.md) for the full course format specification before starting. All generated content must conform to that spec exactly.

## Process

### 1. Gather inputs

- Use AskUserQuestion to ask for the **author name** to use in course.json.
- Derive a kebab-case `id` from the topic (e.g. "Introduction to Rust" -> `intro-to-rust`).

### 2. Research the topic (if needed)

Before designing the course outline, decide whether online research is needed:

**DO research** when the topic involves:
- A software library, framework, or tool (APIs change, versions matter)
- A technology with recent updates (language features, platform changes)
- Current events, statistics, or rapidly evolving fields
- Anything where your training data might be stale

**SKIP research** when the topic is:
- Foundational CS concepts (data structures, algorithms, Big-O)
- Stable mathematical or scientific principles
- General programming concepts (OOP, functional programming, design patterns)
- History, philosophy, or other stable knowledge domains

When researching, use WebSearch to find:
- The current stable version and any recent breaking changes
- Current best practices and recommended patterns
- Any deprecated features or migration guides
- Official documentation URLs for reference

### 3. Design the course structure

Plan however many topics are needed to take a learner from beginner to advanced on the subject. Let the scope and depth of the subject dictate the number of topics — don't artificially constrain or pad the list.

**Topic count guidelines:**

| Subject scope | Target topics | Examples |
|---|---|---|
| Focused tool/concept | 8-12 | Markdown, a single library, a CLI tool |
| Broad subject | 15-25 | A programming language, a science domain |
| Comprehensive discipline | 15-30 | Economics, world history |

Each topic should be completable in 10-20 minutes. If a topic would take longer, split it. If it would take under 5 minutes, combine it with an adjacent topic.

**Progressive structure:** the first ~20% of topics should cover foundations and motivation, the middle ~60% should build core concepts in increasing complexity, and the final ~20% should cover advanced patterns, real-world application, and synthesis.

Err on the side of more topics with tighter focus rather than fewer topics that try to cover too much.

Each topic should be:
- Focused on a single coherent concept
- Buildable on previous topics
- Named with numeric prefix in kebab-case (e.g. `01-getting-started`, `02-core-concepts`)

### 4. Create the course directory and course.json

Create the course folder in the **current working directory**:

```
<course-id>/
├── course.json
└── topics/
```

Write `course.json` with all required fields: `id`, `title`, `description`, `version` (use "1.0.0"), `author`, `tags`, and `topicOrder`.

### 5. Create topics using subagents

Launch **parallel subagents** (using the Agent tool) to create each topic simultaneously. Each subagent should:

1. **Read** `docs/course_authoring_guide.md` to understand the block format
2. **Decide independently** whether online research is needed for its specific subtopic (using the same research criteria from Step 2)
3. **If research is needed**, use WebSearch/WebFetch to get current information
4. **Create the topic folder** and all its files:
   - `content.json` — an ordered array of blocks
   - `.md` files for text blocks (use `src`, not inline `content`, for anything longer than 2 sentences)
   - Code example files with appropriate extensions (use `src` for code blocks)
5. **Follow the required topic structure:**
   a. **Overview** (text, 15-30 lines): Frame the *problem* this concept solves. Include 3-5 learning objectives as "By the end of this topic, you will..." bullets.
   b. **Core content** (text + code interleaved): 20-50 line `.md` files. One concept per file. Number files: `01-overview.md`, `02-details.md`, etc.
   c. **Knowledge checks** (3-5 quizzes, inline): Place after each major concept, NOT clustered at the end. Every quiz MUST have an `explanation` field. Mix types: conceptual, applied, "what happens when...", scenario-based. At least one scenario-based question per topic. Distractors must be plausible real misconceptions.
   d. **Reveal blocks** (at least 2): One ELI5/analogy for the hardest concept. One deep dive for learners who want more. Optional: common mistakes, "try it yourself" exercise.
   e. **Callouts** (2-4): Tips, warnings, and context distributed throughout the topic — not all at the end.
   f. **Key takeaways** (text block): 3-5 bullet recap of what was covered, placed before the checkpoint.
   g. **Checkpoint** (at end): Use "I can..." or "I understand..." phrasing.

   **Minimum block counts per topic:** 1 overview text + 2+ core text blocks + 3+ quizzes + 2+ reveals + 2+ callouts + 1 takeaways text + 1 checkpoint = at least 12 blocks.

6. **Write in the right style** (do not rely on the subagent picking this up from the authoring guide — include these requirements directly):
   - Colleague-at-whiteboard tone, not textbook. Conversational but accurate.
   - Open every topic with the *problem* before the solution — "why does this exist?"
   - Use concrete analogies for abstract concepts (e.g., "A database index is like a book's index — it helps you jump to what you need instead of reading every page")
   - Use realistic names and scenarios — never foo/bar/baz
   - Reference earlier topics where relevant ("In topic N, you learned...")
   - Make cross-topic references specific to the actual concepts being connected. Do **not** use repeated bridge lines or stock phrasing across multiple topics.
   - Show the "wrong way" before the "right way" where it helps understanding
   - Vary sentence-level framing and transitions from topic to topic. Do **not** stamp the same "wrong turn", "better move", or "real codebase" wording across the course.
   - Use second person ("you"), present tense
   - Vary sentence rhythm — short sentences punch. Longer ones connect ideas.

When launching each subagent, provide it with:
- The course topic and this specific subtopic's name and number
- The list of all topics so it understands where this one fits in the sequence
- The path to the topic folder to create
- Clear instruction to read `docs/course_authoring_guide.md`
- Instruction on whether research is likely needed

### 5.5. Quality review

After all subagents complete but before structural validation, spot-check content quality:

- Open the `content.json` for the **first**, **middle**, and **last** topics
- Open the overview and at least one core `.md` file for those same topics
- Verify each has: overview text with learning objectives, 3+ quizzes with explanations, 2+ reveals, a checkpoint, and a key takeaways text block
- Check that `.md` files are substantive (15+ lines for overviews, 20+ for core content — not 5-6 line stubs)
- Check that quizzes have plausible distractors and explanations
- Check for repeated boilerplate wording across topics. If you see the same 8+ word phrase reused in multiple topic markdown files, rewrite it unless it is a necessary technical phrase.
- Check that cross-topic references sound natural and specific to the concepts being linked, not like reusable template glue.
- If any topic falls short, revise it directly or re-launch the subagent with specific feedback about what's missing

### 6. Validate

After quality review, verify the course structure:
- Every folder in `topicOrder` exists under `topics/`
- Every topic folder has a valid `content.json`
- All `src` references point to files that exist
- Multiple-choice quizzes have valid `answer` indexes
- All text and code blocks have either `src` or `content`

Fix any issues found.

### 7. Report

Tell the user:
- The course folder path
- Number of topics created
- A brief summary of what each topic covers
- Any research findings that influenced the content

## Content quality guidelines

### Writing style
- Write as a knowledgeable colleague explaining at a whiteboard — conversational, clear, never condescending
- Open every topic by framing the *problem* the concept solves before jumping to syntax or definitions
- Use concrete analogies and metaphors to ground abstract ideas
- Use second person ("you"), present tense
- Vary sentence rhythm deliberately — short sentences punch. Longer ones walk through reasoning.
- Use realistic names and scenarios (never foo/bar/baz)
- Show the "wrong way" before the "right way" where helpful — learners remember mistakes they almost made
- Reference earlier topics when building on prior knowledge ("Remember when we set up X in topic 3?")
- Make callbacks and transitions topic-specific. Avoid copy-pasted connective tissue between lessons.
- Avoid repeated stock phrases across multiple topics. If a line sounds reusable in any lesson, rewrite it until it sounds tied to this lesson.

### Content depth
- Overview `.md` files: 15-30 lines — set context, frame the problem, list learning objectives
- Core content `.md` files: 20-50 lines — one concept per file, explored thoroughly
- At least one concrete example or real-world scenario in every text block
- Code examples should be complete, runnable, and accompanied by explanation of what they do and why

### Engagement techniques
- ELI5 analogies in reveal blocks for hard concepts — make the abstract tangible
- Deep-dive reveals for curious learners who want to go further
- Common mistakes callouts or reveals to head off misconceptions before they form
- "Try it yourself" exercise reveals with starter code or prompts
- Callbacks to earlier topics ("Remember when we learned X?") to reinforce connections
- Scenario-based framing ("Imagine you're deploying to production and...") to motivate concepts

### Quiz standards
- 3-5 quizzes per topic minimum, placed inline after the concept they test
- Every quiz MUST have an `explanation` field — this is required, not optional
- Distractors must be plausible — based on real misconceptions learners actually have
- Mix question types: conceptual ("What is..."), applied ("Given this code, what..."), "what happens when...", scenario-based ("Your team needs to...")
- At least one scenario-based question per topic

### Structural requirements per topic
- Overview text block with learning objectives
- 2+ core content text blocks (one concept per file)
- 3+ quizzes with explanations (inline, not clustered)
- 2+ reveal blocks (ELI5/analogy + deep dive minimum)
- 2+ callouts distributed through the topic
- Key takeaways text block (3-5 bullet recap)
- Checkpoint at end ("I can..." phrasing)

### Progressive difficulty
- **Early topics:** gentle, welcoming, over-explain — assume the learner is encountering these ideas for the first time
- **Middle topics:** assume prior knowledge from earlier topics, move faster, introduce more nuance
- **Late topics:** challenge with complex scenarios, synthesis across concepts, and real-world application
- Explicitly call back to earlier material when building on it — don't make learners guess the connection
