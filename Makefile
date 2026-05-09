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
		printf '%s\n' 'Analyze the following code for Code Quality only.'; \
		printf '%s\n' 'Focus on readability, structure, maintainability, and duplication.'; \
		printf '%s\n' 'Output 5-7 markdown bullets. Each bullet must be: problem -> fix.'; \
		printf '%s\n' 'Do not include any other sections or prose.'; \
		printf '%s\n\n' 'Codebase:'; \
		cat $(CODEBASE); \
	} | $(ASK) > $@

# Phase 1 - FAN-OUT: Performance branch.
# This can run in parallel with quality.md and security.md when make is called with -j.
perf.md: $(CODEBASE) $(ASK) | check-env
	@{ \
		printf '%s\n' 'Analyze the following code for Performance only.'; \
		printf '%s\n' 'Focus on bottlenecks, unnecessary work, inefficient I/O, and scalability limits.'; \
		printf '%s\n' 'Output 5-7 markdown bullets. Each bullet must be: issue -> optimization.'; \
		printf '%s\n' 'Do not include any other sections or prose.'; \
		printf '%s\n\n' 'Codebase:'; \
		cat $(CODEBASE); \
	} | $(ASK) > $@

# Phase 1 - FAN-OUT: Security branch.
# This can run in parallel with quality.md and perf.md when make is called with -j.
security.md: $(CODEBASE) $(ASK) | check-env
	@{ \
		printf '%s\n' 'Analyze the following code for Security only.'; \
		printf '%s\n' 'Focus on vulnerabilities, unsafe patterns, exposure risks, and missing validation.'; \
		printf '%s\n' 'Output 5-7 markdown bullets. Each bullet must be: risk -> mitigation.'; \
		printf '%s\n' 'Do not include any other sections or prose.'; \
		printf '%s\n\n' 'Codebase:'; \
		cat $(CODEBASE); \
	} | $(ASK) > $@

# Phase 2 - LOCAL SUMMARIZATION: summarize Code Quality findings.
quality.sum.md: quality.md $(ASK) | check-env
	@{ \
		printf '%s\n' 'Compress this Code Quality analysis to exactly 5 markdown bullets.'; \
		printf '%s\n' 'Keep only actionable items. Preserve problem -> fix wording.'; \
		printf '%s\n' 'Do not include a heading or any extra prose.'; \
		printf '%s\n\n' 'Quality analysis:'; \
		cat quality.md; \
	} | $(ASK) > $@

# Phase 2 - LOCAL SUMMARIZATION: summarize Performance findings.
perf.sum.md: perf.md $(ASK) | check-env
	@{ \
		printf '%s\n' 'Compress this Performance analysis to exactly 5 markdown bullets.'; \
		printf '%s\n' 'Keep only actionable items. Preserve issue -> optimization wording.'; \
		printf '%s\n' 'Do not include a heading or any extra prose.'; \
		printf '%s\n\n' 'Performance analysis:'; \
		cat perf.md; \
	} | $(ASK) > $@

# Phase 2 - LOCAL SUMMARIZATION: summarize Security findings.
security.sum.md: security.md $(ASK) | check-env
	@{ \
		printf '%s\n' 'Compress this Security analysis to exactly 5 markdown bullets.'; \
		printf '%s\n' 'Keep only actionable items. Preserve risk -> mitigation wording.'; \
		printf '%s\n' 'Do not include a heading or any extra prose.'; \
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
		printf '%s\n' 'Refine this engineering report.'; \
		printf '%s\n' 'Keep these sections: Code Quality, Performance, Security.'; \
		printf '%s\n' 'Rules: remove duplicates, keep only high-signal issues, preserve actionable markdown bullets.'; \
		printf '%s\n' 'Do not add unrelated recommendations.'; \
		printf '%s\n\n' 'Concatenated report:'; \
		cat concatenated.md; \
	} | $(ASK) > $@

# Phase 5 - FAN-IN #2: generate the final Engineering Action Plan.
action.plan.md: refined.md $(ASK) | check-env
	@{ \
		printf '%s\n' 'Generate the final markdown document titled "Engineering Action Plan".'; \
		printf '%s\n' 'Use the refined report below as input.'; \
		printf '%s\n' 'Must include prioritized actions using High / Medium / Low.'; \
		printf '%s\n' 'Must include an effort estimate for each action using Small / Medium / Large.'; \
		printf '%s\n' 'Must include a clear execution order.'; \
		printf '%s\n' 'Keep the output concise and practical.'; \
		printf '%s\n\n' 'Refined report:'; \
		cat refined.md; \
	} | $(ASK) > $@
clean:
	@rm -f quality.md perf.md security.md quality.sum.md perf.sum.md security.sum.md concatenated.md refined.md action.plan.md
