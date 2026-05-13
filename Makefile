.DEFAULT_GOAL := engineering-action-plan
.PHONY: concatenated engineering-action-plan check-env clean quality performance refined security
.DELETE_ON_ERROR:

ASK ?= ./ask
CODEBASE ?= codebase.txt

engineering-action-plan: action.plan.md

# Check required environment before any LLM call.
check-env:
	@if [ -z "$$ASK_API_URL" ]; then echo "ASK_API_URL environment variable is missing."; exit 1; fi
	@if [ -z "$$ASK_MODEL" ]; then echo "ASK_MODEL environment variable is missing."; exit 1; fi
	@if [ -z "$$ASK_API_KEY" ]; then echo "ASK_API_KEY environment variable is missing."; exit 1; fi
	@if [ ! -x "$(ASK)" ]; then echo "$(ASK) is missing or not executable."; exit 1; fi

# Named entry points for starting one analysis branch.
quality: quality.md

performance: perf.md

security: security.md

concatenated: concatenated.md

refined: refined.md


# Phase 1 - FAN-OUT: Code Quality branch.
# This can run in parallel with perf.md and security.md when make is called with -j.
quality.md: $(CODEBASE) $(ASK) | check-env
	@{ \
		printf '%s\n' 'You are a senior code reviewer. Analyze the code for Code Quality only.'; \
		printf '%s\n' 'Scope: readability, structure, maintainability, naming, organization, and duplication.'; \
		printf '%s\n' 'Ignore performance and security unless they are directly caused by a code-quality issue.'; \
		printf '%s\n' 'Output 5-7 markdown bullets, with no heading, introduction, conclusion, or extra prose.'; \
		printf '%s\n' 'Each bullet must use this format: - Problem: <specific issue> -> Fix: <specific action>'; \
		printf '%s\n' 'Prefer concrete references to files, functions, commands, or patterns when visible.'; \
		printf '%s\n' 'Avoid generic advice; every fix must be directly actionable.'; \
		printf '%s\n\n' 'Codebase:'; \
		cat $(CODEBASE); \
	} | $(ASK) > $@

# Phase 1 - FAN-OUT: Performance branch.
# This can run in parallel with quality.md and security.md when make is called with -j.
perf.md: $(CODEBASE) $(ASK) | check-env
	@{ \
		printf '%s\n' 'You are a senior performance reviewer. Analyze the code for Performance only.'; \
		printf '%s\n' 'Scope: bottlenecks, unnecessary work, inefficient I/O, repeated computation, and scalability limits.'; \
		printf '%s\n' 'Ignore code style and security unless they directly create a performance problem.'; \
		printf '%s\n' 'Output 5-7 markdown bullets, with no heading, introduction, conclusion, or extra prose.'; \
		printf '%s\n' 'Each bullet must use this format: - Issue: <specific inefficiency> -> Optimization: <specific change>'; \
		printf '%s\n' 'Prefer concrete references to files, functions, loops, commands, or data-flow patterns when visible.'; \
		printf '%s\n' 'Avoid vague tuning advice; every optimization must be directly actionable.'; \
		printf '%s\n\n' 'Codebase:'; \
		cat $(CODEBASE); \
	} | $(ASK) > $@

# Phase 1 - FAN-OUT: Security branch.
# This can run in parallel with quality.md and perf.md when make is called with -j.
security.md: $(CODEBASE) $(ASK) | check-env
	@{ \
		printf '%s\n' 'You are a senior application security reviewer. Analyze the code for Security only.'; \
		printf '%s\n' 'Scope: vulnerabilities, unsafe patterns, secrets, injection, validation, and unsafe shell/file handling.'; \
		printf '%s\n' 'Ignore code style and performance unless they directly create a security risk.'; \
		printf '%s\n' 'Output 5-7 markdown bullets, with no heading, introduction, conclusion, or extra prose.'; \
		printf '%s\n' 'Each bullet must use this format: - Risk: <specific security risk> -> Mitigation: <specific control>'; \
		printf '%s\n' 'Prefer concrete references to files, functions, commands, inputs, or trust boundaries when visible.'; \
		printf '%s\n' 'Avoid generic security advice; every mitigation must be directly actionable.'; \
		printf '%s\n\n' 'Codebase:'; \
		cat $(CODEBASE); \
	} | $(ASK) > $@

# Phase 2 - LOCAL SUMMARIZATION: summarize Code Quality findings.
quality.sum.md: quality.md $(ASK) | check-env
	@{ \
		printf '%s\n' 'Compress this Code Quality analysis to exactly 5 markdown bullets.'; \
		printf '%s\n' 'Keep only distinct, high-impact, actionable items. Merge duplicates and remove low-value observations.'; \
		printf '%s\n' 'Do not invent new findings; use only the analysis below.'; \
		printf '%s\n' 'Preserve this format: - Problem: <specific issue> -> Fix: <specific action>'; \
		printf '%s\n' 'Do not include a heading, introduction, conclusion, or extra prose.'; \
		printf '%s\n\n' 'Quality analysis:'; \
		cat quality.md; \
	} | $(ASK) > $@

# Phase 2 - LOCAL SUMMARIZATION: summarize Performance findings.
perf.sum.md: perf.md $(ASK) | check-env
	@{ \
		printf '%s\n' 'Compress this Performance analysis to exactly 5 markdown bullets.'; \
		printf '%s\n' 'Keep only distinct, high-impact, actionable items. Merge duplicates and remove low-value observations.'; \
		printf '%s\n' 'Do not invent new findings; use only the analysis below.'; \
		printf '%s\n' 'Preserve this format: - Issue: <specific inefficiency> -> Optimization: <specific change>'; \
		printf '%s\n' 'Do not include a heading, introduction, conclusion, or extra prose.'; \
		printf '%s\n\n' 'Performance analysis:'; \
		cat perf.md; \
	} | $(ASK) > $@

# Phase 2 - LOCAL SUMMARIZATION: summarize Security findings.
security.sum.md: security.md $(ASK) | check-env
	@{ \
		printf '%s\n' 'Compress this Security analysis to exactly 5 markdown bullets.'; \
		printf '%s\n' 'Keep only distinct, high-impact, actionable items. Merge duplicates and remove low-value observations.'; \
		printf '%s\n' 'Do not invent new findings; use only the analysis below.'; \
		printf '%s\n' 'Preserve this format: - Risk: <specific security risk> -> Mitigation: <specific control>'; \
		printf '%s\n' 'Do not include a heading, introduction, conclusion, or extra prose.'; \
		printf '%s\n\n' 'Security analysis:'; \
		cat security.md; \
	} | $(ASK) > $@

# Phase 3 - CONCAT REPORT: combine summaries with shell tools, no ask.
concatenated.md: quality.sum.md perf.sum.md security.sum.md
	@echo '## Code Quality' > $@
	@echo '' >> $@
	@cat quality.sum.md >> $@
	@echo '' >> $@
	@echo '## Performance' >> $@
	@echo '' >> $@
	@cat perf.sum.md >> $@
	@echo '' >> $@
	@echo '## Security' >> $@
	@echo '' >> $@
	@cat security.sum.md >> $@

# Phase 4 - FAN-IN #1: refine the concatenated report with ask.
refined.md: concatenated.md $(ASK) | check-env
	@{ \
		printf '%s\n' 'Refine the concatenated engineering report below.'; \
		printf '%s\n' 'Keep exactly these markdown sections in this order: ## Code Quality, ## Performance, ## Security.'; \
		printf '%s\n' 'Remove duplicates across and within sections, merge overlapping items, and keep only high-signal actionable issues.'; \
		printf '%s\n' 'Keep each issue in the most appropriate section; move misplaced items if needed.'; \
		printf '%s\n' 'Do not invent new findings, do not add unrelated recommendations, and do not include an introduction or conclusion.'; \
		printf '%s\n' 'Use concise markdown bullets under each section.'; \
		printf '%s\n\n' 'Concatenated report:'; \
		cat concatenated.md; \
	} | $(ASK) > $@

# Phase 5 - FAN-IN #2: generate the final Engineering Action Plan.
action.plan.md: refined.md $(ASK) | check-env
	@{ \
		printf '%s\n' 'Generate the final markdown document titled exactly: # Engineering Action Plan'; \
		printf '%s\n' 'Use only the refined report below as input. Do not invent unrelated actions.'; \
		printf '%s\n' 'Create a concise action plan ordered by execution sequence.'; \
		printf '%s\n' 'Each action must include Priority using only High, Medium, or Low.'; \
		printf '%s\n' 'Each action must include Effort using only Small, Medium, or Large.'; \
		printf '%s\n' 'Prefer actions that reduce the most risk or unblock later work first.'; \
		printf '%s\n' 'Use this table format: | Order | Priority | Effort | Area | Action | Rationale |'; \
		printf '%s\n' 'After the table, include a short "Execution Notes" section with 2-4 bullets.'; \
		printf '%s\n' 'Keep the output concise, practical, and implementation-oriented.'; \
		printf '%s\n\n' 'Refined report:'; \
		cat refined.md; \
	} | $(ASK) > $@
clean:
	@rm -f quality.md perf.md security.md quality.sum.md perf.sum.md security.sum.md concatenated.md refined.md action.plan.md
