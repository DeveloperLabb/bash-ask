.PHONY: clean
.DELETE_ON_ERROR:

ASK ?= ./ask
CODEBASE ?= codebase.txt

action.plan.md: refined.md $(ASK)
	@{ \
		printf '%s\n' 'Generate the final markdown document titled "Engineering Action Plan".'; \
		printf '%s\n' 'Use the refined report below as input.'; \
		printf '%s\n' 'Must include prioritized actions using High / Medium / Low.'; \
		printf '%s\n' 'Must include an effort estimate for each action using Small / Medium / Large.'; \
		printf '%s\n' 'Must include a clear execution order.'; \
		printf '%s\n\n' 'Keep the output concise and practical.'; \
		cat refined.md; \
	} | $(ASK) > $@

quality.md: $(CODEBASE) $(ASK)
	@{ \
		printf '%s\n' 'Analyze the following code for Code Quality only.'; \
		printf '%s\n' 'Focus on readability, structure, maintainability, and duplication.'; \
		printf '%s\n' 'Output 5-7 markdown bullets. Each bullet must be: problem -> fix.'; \
		printf '%s\n\n' 'Do not include any other sections or prose.'; \
		cat $(CODEBASE); \
	} | $(ASK) > $@

perf.md: $(CODEBASE) $(ASK)
	@{ \
		printf '%s\n' 'Analyze the following code for Performance only.'; \
		printf '%s\n' 'Focus on bottlenecks, unnecessary work, inefficient I/O, and scalability limits.'; \
		printf '%s\n' 'Output 5-7 markdown bullets. Each bullet must be: issue -> optimization.'; \
		printf '%s\n\n' 'Do not include any other sections or prose.'; \
		cat $(CODEBASE); \
	} | $(ASK) > $@

security.md: $(CODEBASE) $(ASK)
	@{ \
		printf '%s\n' 'Analyze the following code for Security only.'; \
		printf '%s\n' 'Focus on vulnerabilities, unsafe patterns, exposure risks, and missing validation.'; \
		printf '%s\n' 'Output 5-7 markdown bullets. Each bullet must be: risk -> mitigation.'; \
		printf '%s\n\n' 'Do not include any other sections or prose.'; \
		cat $(CODEBASE); \
	} | $(ASK) > $@

quality.sum.md: quality.md $(ASK)
	@{ \
		printf '%s\n' 'Compress this Code Quality analysis to exactly 5 markdown bullets.'; \
		printf '%s\n' 'Keep only actionable items. Preserve problem -> fix wording.'; \
		printf '%s\n\n' 'Do not include a heading or any extra prose.'; \
		cat quality.md; \
	} | $(ASK) > $@

perf.sum.md: perf.md $(ASK)
	@{ \
		printf '%s\n' 'Compress this Performance analysis to exactly 5 markdown bullets.'; \
		printf '%s\n' 'Keep only actionable items. Preserve issue -> optimization wording.'; \
		printf '%s\n\n' 'Do not include a heading or any extra prose.'; \
		cat perf.md; \
	} | $(ASK) > $@

security.sum.md: security.md $(ASK)
	@{ \
		printf '%s\n' 'Compress this Security analysis to exactly 5 markdown bullets.'; \
		printf '%s\n' 'Keep only actionable items. Preserve risk -> mitigation wording.'; \
		printf '%s\n\n' 'Do not include a heading or any extra prose.'; \
		cat security.md; \
	} | $(ASK) > $@

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

refined.md: concatenated.md $(ASK)
	@{ \
		printf '%s\n' 'Refine this engineering report.'; \
		printf '%s\n' 'Keep these sections: Code Quality, Performance, Security.'; \
		printf '%s\n' 'Rules: remove duplicates, keep only high-signal issues, preserve actionable markdown bullets.'; \
		printf '%s\n\n' 'Do not add unrelated recommendations.'; \
		cat concatenated.md; \
	} | $(ASK) > $@

clean:
	@rm -f quality.md perf.md security.md quality.sum.md perf.sum.md security.sum.md concatenated.md refined.md action.plan.md
