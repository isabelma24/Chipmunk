# Women’s Health Learning App — Product Brief

*Working title: Chipmunk*

## Product idea

A game-like iOS learning app that teaches women’s health and mental health through short, research-based lessons. The material should feel like a real course: clear foundational concepts, scientific depth, and topics people may not encounter in everyday conversation.

## Audience and stance

- Designed for ages 16 and older, with a women-centered focus.
- Learners choose between two tracks at onboarding:
  - **Women’s health:** centered on the body, with relevant mental health topics.
- **Mental health:** a broad curriculum on mental health and mental disorders, with women-centered research and attention to body connections. ADHD is one topic alongside depression, anxiety, and other important areas.
- Use inclusive, precise language. Each lesson should identify the population studied and the relevant biology when describing research; do not assume all women have the same anatomy or reproductive capacity.
- US-first content.
- Educational, not diagnostic. Include optional notes or diary prompts and topic-related exercises, without directing users to self-diagnose.

## Learning and game loop

- Short daily lessons with quizzes and interactive exercises.
- Start at the beginning by default. Offer an optional placement quiz; adapt the starting point if a learner takes it.
- Unlock lessons in sequence, remember the learner’s place, and let them replay completed quizzes. No jumping ahead through the course.
- Use a visible progress map, streaks, unlocks, and story-based activities. Each learner is paired with a chipmunk companion they can name and care for through learning.
- Daily care starts at 0 and is the percentage of all five needs refilled since the local day began. It reaches 100 only when every need is full. A lesson raises the lowest need by 10, its activity raises the lowest need by 5, and passing the unit quiz raises the lowest need by 10. Each need halves at the next local calendar day; lessons remain available at any care level.
- Chip starts at age 16 and gains one year per 10 unique lessons completed across both tracks, up to age 100. There is no lifetime XP or separate numeric wellness score.
- The app streak counts consecutive local calendar days when the learner completes at least one lesson or interactive activity. Opening the app alone does not preserve the streak.
- Shared categorical badges are earned by keeping daily care above 90 for 1, 3, 7, or 14 consecutive local days. There are no lesson badges, mastery badges, or lifetime XP. The highest earned care badge serves as the learner’s level and unlocks companion accent colors.
- Keep individual health learning progress private. Future optional group challenges can compare companion wellbeing, not personal health data or course scores.
- Use one shared progression grammar across both tracks: foundation lessons, a cumulative unit quiz, then more advanced units. Lesson completion stays separate from the app-wide daily care streak and shared badge level.
- Make earned rewards visible in a Collection: shared care-streak badges and the learner’s chipmunk companion. Interactive learning and unit reviews add companion care; the daily care ceiling is 100, while lesson and quiz access stays open.
- Keep the bottom navigation to three spaces: Learn for lessons, streak, and level; Library for both tracks’ concept maps and optional reflection notes; Collection for the companion and earned rewards. Show both foundation maps in Library and add later lesson maps as they are learned.
- After a learner finishes a lesson, preview the next lesson’s central concept as a brief “tomorrow” teaser. Avoid streak punishment, artificial waiting periods, or hiding educational content to drive return visits.
- Teach through concept-first flashcards, colored and underlined keywords, connected maps, examples, and retrieval questions. User-facing lesson copy should teach the health/science content or give a necessary safety boundary; it should not narrate the app’s timing, prototype status, or mechanics.

## Research experience

- During play, show a brief evidence note and a source link alongside relevant claims.
- Build a reference library where learners can revisit topics and explore deeper explanations and sources.
- Prioritize systematic reviews and official guidelines for lesson summaries; link primary studies for key claims.
- Clearly communicate study populations, evidence limits, and uncertainty in plain language. Date references and distinguish stronger evidence from early or mixed findings.

## Curriculum direction

The app should lead learners through a textbook-style sequence rather than ask them to supply the syllabus. Start with general anatomy and physiology, then build toward women-centered topics and specific conditions. Keep the sequence beginner-friendly, and explain scientific terms as they appear.

### Women’s health track

1. Body basics in textbook order: anatomical language and levels of organization; chemistry and cells; tissues; homeostasis; then how organs form systems.
2. Whole-body foundations: skin, hair, and nails; bones and muscles; brain and nerves; hormones; blood and heart; immunity and inflammation; breathing; digestion; urinary health; sleep and pain.
3. Reproductive and sexual health: anatomy, puberty, menstrual cycle, ovulation, common variation, contraception, fertility, pregnancy and postpartum, and menopause.
4. Health conditions and differences: gynecologic conditions (including endometriosis, fibroids, and PCOS), skin and hair conditions, autoimmune disease, cardiovascular health, bone health, chronic pain, cancer, and other areas where women's evidence or care needs context.
5. Health across the lifespan and in context: how development, aging, environment, behavior, social factors, and access to care can shape health.
6. How women’s health research works: study design, who was studied, uncertainty, underdiagnosis, and how sex and gender can affect evidence and care.

### Mental health track

1. Foundations: brain and nervous system, attention, emotion, behavior, stress response, sleep, mental well-being, symptoms, and how diagnosis works.
2. Mood and anxiety: depression, bipolar disorders, anxiety disorders, and related conditions, covering what is known, how they affect daily life, and how research defines them.
3. Neurodevelopment and attention: ADHD and other relevant neurodevelopmental topics, including research on recognition and presentation in girls and women.
4. Other major areas: trauma and PTSD, eating disorders, OCD, substance use, psychosis, sleep-related concerns, and co-occurring conditions, introduced at an appropriate level.
5. Mind-body connections: stress physiology, sleep, hormones and mood, pain, immune and metabolic health, and reproductive life stages. Explain when evidence is strong, mixed, or early.
6. Women-centered lens and support literacy: sex and gender influences, social factors, research gaps, stigma, how diagnosis is assessed, and how to prepare questions for a qualified professional.

These tracks are a broad starting map, not a claim that every condition affects all women in the same way. Unit order and depth should follow an established anatomy-and-physiology sequence, then expand to high-impact and historically understudied women's health topics. OpenStax A&P 2e provides a standard course sequence for foundational body science; NIH ORWH's women’s health research resources span mental health, skin, cardiovascular, autoimmune, reproductive, menopause, trauma, and other areas.

### Lesson design defaults

- Keep each lesson focused on one learning objective, with clear textbook-style explanations.
- Start with flashcards for its key terms; underline and color those terms in explanations, diagrams, and the concept map.
- Use the same flashcard, lesson check, and progress/reward pattern in both tracks. After every ten-lesson unit, give a cumulative quiz before the learner advances to harder material.
- Alternate active recall, scenario questions, topic-specific diagrams, and occasional story-based situations; reward understanding and review, not speed.
- Do not award badges for individual lessons or the cumulative quiz. Show earned and locked care-streak badges together.
- Use spaced review and replayable quizzes. Maintain one linear next step in the learning path.
- During play, show a concise “what research says” note plus a source link. Prefer systematic reviews, consensus statements, and public-health guidance for summaries; link to primary studies for key findings. Maintain a deeper reference library.
- Have lessons reviewed by a qualified subject-matter reviewer before release when feasible; label source dates and evidence strength.

## Visual and game direction

- Chic, minimal, modern, science-forward, with a small amount of sparkle. Use a calm editorial visual identity with refined typography, a restrained palette, clear information hierarchy, fine-line scientific diagrams, and subtle celebratory motion.
- Keep the game loop engaging through meaningful progress, short challenges, immediate feedback, streaks, unlocks, and story scenarios. Let the chipmunk care loop carry the playful tone while health lessons stay calm, chic, and science-forward.
- Research synthesis so far: game mechanics and visual design are usually studied separately. Gamification meta-analysis shows a small positive behavioral effect (g = 0.25), while a visual-emotional-design meta-analysis reports small-to-medium learning effects (retention d = 0.39, comprehension d = 0.32, transfer d = 0.33), mostly in younger samples. There is no rigorous adult trial directly comparing playful character-led design with calm minimal design. Treat the premium minimal direction as a fit to the product and audience, not a proven engagement advantage.
- Research references: [Sailer & Homner, gamification meta-analysis](https://doi.org/10.1007/s10648-019-09498-w); [Brom et al., visual emotional design meta-analysis](https://www.sciencedirect.com/science/article/abs/pii/S1747938X18302148); [Duolingo streak experiments (company-reported)](https://blog.duolingo.com/how-streaks-keep-duolingo-learners-committed-to-their-language-goals).

## Later ideas

- Provider discovery or connections may be considered later; it is outside the initial scope.

## Open design decisions

- Product name and visual identity.
- Continue building the full, evidence-driven curriculum map across both tracks; the founder is a learner and should not need to provide topic lists.
- Specify the next, deeper units in both tracks so the foundation quiz advances into progressively more detailed systems, conditions, and research interpretation.
- Lesson voice, accessibility needs, and the precise balance of story, quiz, and other game mechanics.
- MVP scope and technical implementation details.
