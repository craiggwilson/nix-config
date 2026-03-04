# Research Index: Hooks Abstraction Patterns

**Project:** opencode-projects-plugin-hooks-0d2eb5  
**Issue:** opencode-projects-plugin-hooks-0d2eb5-944.1  
**Date:** 2026-03-04  
**Status:** Complete  
**Recommendation:** Adopt HookRegistry class pattern

---

## Quick Summary

This research investigates how to abstract hook registration in the opencode-projects-plugin. The plugin currently registers 5 hooks inline in `src/index.ts`, which becomes unwieldy as more hooks are added.

**Recommendation:** Adopt the **HookRegistry class pattern** with explicit dependency injection.

**Key Benefits:**
- ✅ Explicit dependency injection - clear what each hook needs
- ✅ Improved testability - easy to mock dependencies
- ✅ Consistent with existing patterns - aligns with ProjectManager
- ✅ Handles stateful hooks cleanly - encapsulates state as instance variables
- ✅ Scales well - straightforward to add new hooks

---

## Research Documents

### 1. RESEARCH_SUMMARY.md (Start Here!)
**Overview of the entire research**

Quick reference with:
- Key findings from the research
- Recommended design (HookRegistry)
- Implementation roadmap
- Success criteria
- Next steps

**Read this first** for a high-level understanding.

### 2. research/hooks-abstraction-research.md
**Comprehensive research document**

Detailed analysis including:
- Current hook inventory (5 hooks, their dependencies)
- Reference implementation analysis (oh-my-opencode-slim)
- Four design alternatives with detailed tradeoffs
- Comparative analysis and scoring matrix
- Recommendation with rationale
- Implementation considerations
- Testing strategy
- Future extensibility

**Read this** for deep understanding of the research process.

### 3. research/design-recommendation.md
**Design recommendation document**

Focused on the recommended design:
- Summary of findings
- Why HookRegistry is recommended
- Comparison with alternatives
- Key design decisions
- Implementation plan (3 phases)
- Future extensibility
- Conclusion

**Read this** to understand the recommended design in detail.

### 4. research/implementation-guide.md
**Step-by-step implementation guide**

Complete implementation instructions:
- Phase 1: Create HookRegistry class
  - Full code for `src/hooks/hook-registry.ts`
  - Full code for `src/hooks/index.ts`
  - Unit test template
- Phase 2: Update plugin entry point
  - Updated `src/index.ts` code
  - Verification steps
- Phase 3: Cleanup and documentation
  - Documentation updates
  - Commit message template
- Testing checklist
- Rollback plan
- Future enhancements

**Read this** when implementing the HookRegistry pattern.

### 5. decisions/hook-abstraction-decision.md
**Decision record**

Formal decision documentation:
- Context and problem statement
- Decision: Adopt HookRegistry class pattern
- Alternatives considered and rejected
- Rationale for the decision
- Implementation plan
- Risks and mitigations
- Success criteria
- Consequences (positive, negative, neutral)
- Related decisions
- Future considerations

**Read this** for the formal decision record.

---

## Key Findings

### Current State

The plugin registers 5 hooks inline in `src/index.ts`:

| Hook | Type | Complexity | Key Dependencies |
|------|------|-----------|------------------|
| `experimental.chat.system.transform` | System prompt | Low | projectManager, worktreeManager |
| `experimental.session.compacting` | Session compaction | High | projectManager, delegationManager, teamManager, typedClient, config, log |
| `shell.env` | Environment | Minimal | projectManager |
| `event` | Event handler | Medium | delegationManager, projectManager, typedClient, log |
| `config` | Configuration | Medium | config, log |

**Problem:** The `event` hook maintains mutable state (`orchestratorSessionId`), which is problematic for testing and reusability.

### Design Options Evaluated

| Option | Score | Status |
|--------|-------|--------|
| **A: HookRegistry Class** | 8.7/10 | ⭐ **RECOMMENDED** |
| B: Modular Factories | 8.6/10 | Alternative |
| C: Decorator Pattern | 7.4/10 | Not recommended |
| D: Composition Module | 8.6/10 | Alternative |

### Recommended Design

**HookRegistry Class Pattern**

```typescript
export class HookRegistry {
  constructor(
    private projectManager: ProjectManager,
    private delegationManager: DelegationManager,
    private teamManager: TeamManager,
    private worktreeManager: WorktreeManager,
    private typedClient: OpencodeClient,
    private config: ConfigManager,
    private log: Logger,
  ) {}

  getHooks() {
    return {
      ...this.getSystemTransformHook(),
      ...this.getSessionCompactingHook(),
      ...this.getShellEnvHook(),
      ...this.getEventHook(),
      ...this.getConfigHook(),
    }
  }

  // Private methods for each hook...
}
```

---

## Implementation Roadmap

### Phase 1: Create HookRegistry (1-2 hours)
- Create `src/hooks/hook-registry.ts`
- Implement HookRegistry class with all hook methods
- Add comprehensive unit tests

### Phase 2: Update Plugin Entry Point (30 minutes)
- Update `src/index.ts` to use HookRegistry
- Verify all hooks work correctly
- Run integration tests

### Phase 3: Cleanup (30 minutes)
- Remove inline hook implementations from src/index.ts
- Update documentation
- Commit changes

**Total Effort:** ~2-3 hours

---

## Why HookRegistry?

1. **Explicit Dependency Injection**
   - All dependencies visible in constructor
   - Clear what each hook needs
   - Follows existing ProjectManager pattern

2. **Improved Testability**
   - Easy to inject mock managers
   - Each hook method testable independently
   - No need to mock entire PluginInput

3. **Stateful Hook Support**
   - The `event` hook needs to track `orchestratorSessionId`
   - HookRegistry encapsulates this as instance state
   - Cleaner than closure variables

4. **Consistency**
   - Aligns with existing ProjectManager, DelegationManager patterns
   - Uses constructor injection like other core components
   - Follows established codebase conventions

5. **Scalability**
   - Adding a new hook is straightforward
   - No need to modify src/index.ts beyond initial setup
   - Can organize related hooks into sub-registries if needed

---

## Success Criteria

- ✅ All hooks work correctly after refactoring
- ✅ Unit tests pass (100% coverage of hook methods)
- ✅ Integration tests pass
- ✅ No performance regression
- ✅ Code is easier to understand and maintain
- ✅ Adding a new hook is straightforward

---

## How to Use This Research

### For Understanding the Problem
1. Read **RESEARCH_SUMMARY.md** for overview
2. Read **research/hooks-abstraction-research.md** for detailed analysis

### For Understanding the Solution
1. Read **research/design-recommendation.md** for the recommended design
2. Review **decisions/hook-abstraction-decision.md** for the formal decision

### For Implementation
1. Follow **research/implementation-guide.md** step-by-step
2. Use the provided code examples and test templates
3. Follow the testing checklist

### For Future Reference
- **RESEARCH_SUMMARY.md** - Quick reference
- **decisions/hook-abstraction-decision.md** - Decision record
- **research/implementation-guide.md** - How to add new hooks

---

## Document Map

```
.projects/opencode-projects-plugin-hooks-0d2eb5/
├── INDEX.md                          # This file - navigation guide
├── RESEARCH_SUMMARY.md               # Quick summary of research
├── research/
│   ├── hooks-abstraction-research.md # Comprehensive research
│   ├── design-recommendation.md      # Design recommendation
│   └── implementation-guide.md       # Step-by-step implementation
└── decisions/
    └── hook-abstraction-decision.md  # Formal decision record
```

---

## Key Metrics

| Metric | Value |
|--------|-------|
| Current hooks | 5 |
| Hook complexity range | Minimal to High |
| Design options evaluated | 4 |
| Recommended design score | 8.7/10 |
| Implementation effort | 2-3 hours |
| Test coverage goal | 100% |
| Risk level | Low |

---

## Next Steps

1. **Review** this research and the design recommendation
2. **Discuss** with team if needed
3. **Implement** HookRegistry following the implementation guide
4. **Test** thoroughly with unit and integration tests
5. **Verify** all hooks work correctly
6. **Commit** changes with clear commit message
7. **Document** the pattern for future hook additions

---

## Questions?

Refer to the appropriate document:

- **"What's the problem?"** → RESEARCH_SUMMARY.md
- **"Why HookRegistry?"** → research/design-recommendation.md
- **"How do I implement it?"** → research/implementation-guide.md
- **"What was the decision process?"** → decisions/hook-abstraction-decision.md
- **"How do I add a new hook?"** → research/implementation-guide.md (Future Enhancements)

---

## Document Statistics

| Document | Size | Sections | Purpose |
|----------|------|----------|---------|
| RESEARCH_SUMMARY.md | 9.4 KB | 12 | Quick overview |
| hooks-abstraction-research.md | 20 KB | 10 | Comprehensive analysis |
| design-recommendation.md | 9.1 KB | 11 | Design details |
| implementation-guide.md | 27 KB | 3 phases | Step-by-step guide |
| hook-abstraction-decision.md | 6.5 KB | 11 | Formal decision |

**Total Research:** ~72 KB of documentation

---

**Research Status:** ✅ Complete  
**Recommendation:** ⭐ HookRegistry Class Pattern  
**Confidence:** High (8.7/10)  
**Ready for Implementation:** Yes

---

*Last updated: 2026-03-04*
