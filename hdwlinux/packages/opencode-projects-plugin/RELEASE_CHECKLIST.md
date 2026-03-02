# Release Checklist: opencode-projects-plugin v0.9.0

**Target Date:** 2026-03-02  
**Quality Standard:** 10/10 for today's ship target  
**Breaking Changes:** Allowed (pre-1.0 release)

---

## Quality Rubric Definition

### What "10/10 Quality" Means for Today

This is a **pre-1.0 release** focused on core functionality and developer experience. The quality bar is:

1. **Functional Completeness** - Core features work reliably
2. **Type Safety** - Full TypeScript coverage with strict mode
3. **Test Coverage** - Critical paths tested, edge cases handled
4. **Developer Experience** - Clear documentation, good error messages
5. **Runtime Stability** - No crashes, graceful error handling
6. **Code Quality** - Consistent patterns, maintainable architecture

**NOT required for today:**
- Public API stability (breaking changes allowed)
- Comprehensive integration tests
- Performance optimization
- Production monitoring/telemetry
- Extensive user documentation

---

## Pre-Release Gates

### 1. Build & Type Safety

- [ ] **TypeScript compilation passes** (`bun run typecheck`)
  - Zero type errors
  - Strict mode enabled
  - All exports properly typed
  
- [ ] **Build succeeds** (`bun run build`)
  - Bundles without errors
  - Output size reasonable (<1MB)
  - External dependencies properly marked

- [ ] **No linter errors** (`bun run lint`)
  - ⚠️ **BLOCKER**: ESLint not configured
  - Action: Add ESLint config or remove lint script

### 2. Test Coverage

- [ ] **All tests pass** (`bun test`)
  - Current: 730 tests passing ✅
  - Zero failures
  - No flaky tests
  
- [ ] **Critical paths covered**
  - Project lifecycle (create, list, focus, close)
  - Issue management (create, update, claim)
  - Delegation workflow (start, complete, notify)
  - VCS operations (git, jj)
  - Planning phases (discovery, synthesis, breakdown)
  
- [ ] **Error handling tested**
  - Invalid inputs rejected with clear messages
  - Result types properly tested
  - Edge cases handled

### 3. Documentation

- [ ] **README.md exists** ⚠️ **MISSING**
  - Installation instructions
  - Quick start guide
  - Basic usage examples
  - Link to detailed docs
  
- [ ] **API documentation complete**
  - `docs/tools.md` - Tool reference ✅
  - `docs/workflows.md` - Usage patterns ✅
  - `docs/architecture.md` - System design ✅
  - `AGENTS.md` - Developer guide ✅
  
- [ ] **CHANGELOG.md exists** ⚠️ **MISSING**
  - Version history
  - Breaking changes noted
  - Migration guide (if needed)

### 4. Package Metadata

- [ ] **package.json complete**
  - ✅ Name: `opencode-projects`
  - ✅ Version: `0.9.0`
  - ✅ Description present
  - ✅ License: MIT
  - ✅ Author: Craig Wilson
  - ✅ Keywords defined
  - ⚠️ **Main entry point**: Currently `src/index.ts` (should be `dist/index.js` for npm)
  - ⚠️ **Missing fields**: `repository`, `bugs`, `homepage`
  - ⚠️ **Missing**: `files` array (what to publish)
  - ⚠️ **Missing**: `engines` field (Bun requirement)

### 5. Runtime Assumptions

- [ ] **Bun runtime required**
  - Document in README
  - Add `engines` field to package.json
  - Consider Node.js compatibility (future)
  
- [ ] **OpenCode SDK compatibility**
  - Tested with `@opencode-ai/plugin@^1.2.15`
  - Tested with `@opencode-ai/sdk@^1.2.15`
  - Version constraints documented

### 6. API Stability Decisions

**For v0.9.0 (pre-1.0):**
- ✅ Breaking changes allowed without major version bump
- ✅ Tool signatures can change
- ✅ Configuration schema can evolve
- ✅ Internal APIs unstable

**Stability commitments:**
- Tool names stable (no renames)
- Core workflow patterns stable
- Storage format backward compatible (best effort)

### 7. Error Handling & Observability

- [ ] **Error messages are actionable**
  - Clear description of what went wrong
  - Suggestions for resolution
  - Context included (IDs, paths, etc.)
  
- [ ] **Logging is appropriate**
  - Info: Major operations (create project, start delegation)
  - Warn: Recoverable issues (missing config, fallback used)
  - Error: Failures (storage error, VCS error)
  - No spam in hot paths

### 8. Security & Safety

- [ ] **No secrets in code**
  - No hardcoded tokens/keys
  - No sensitive data in logs
  
- [ ] **Input validation**
  - All tool inputs validated with Zod
  - Path traversal prevented
  - Command injection prevented
  
- [ ] **Safe defaults**
  - Destructive operations require confirmation
  - Isolation enabled for code changes
  - Worktrees cleaned up on error

---

## npm Publish Readiness

### Pre-Publish Checklist

- [ ] **Fix package.json issues**
  - Change `main` to `dist/index.js`
  - Add `files` array: `["dist", "skills", "docs"]`
  - Add `repository` URL
  - Add `bugs` URL
  - Add `homepage` URL
  - Add `engines`: `{"bun": ">=1.0.0"}`
  
- [ ] **Add .npmignore or use files array**
  - Exclude: `src/`, `tests/`, `*.test.ts`, `.projects/`, `delegations/`
  - Include: `dist/`, `skills/`, `docs/`, `package.json`, `README.md`, `LICENSE`, `CHANGELOG.md`
  
- [ ] **Test local install**
  ```bash
  bun pack
  cd /tmp/test-install
  bun add /path/to/opencode-projects-0.9.0.tgz
  ```
  
- [ ] **Verify published contents**
  - Check tarball size (<500KB ideal)
  - Verify all necessary files included
  - Verify no unnecessary files included

### Publishing

```bash
# Dry run
bun publish --dry-run

# Actual publish (requires npm auth)
bun publish --access public
```

---

## Critical Blockers for Today's Ship

### Must Fix Before Release

1. **Add README.md** - Installation and quick start
2. **Add CHANGELOG.md** - Version 0.9.0 notes
3. **Fix package.json** - Correct main entry, add metadata
4. **Add LICENSE file** - MIT license text
5. **Fix or remove lint script** - ESLint not configured

### Should Fix (High Priority)

6. **Add .npmignore** - Control published files
7. **Test npm install** - Verify package works when installed

### Nice to Have (Can Defer)

8. Integration test suite
9. Performance benchmarks
10. Node.js compatibility layer

---

## Post-Release

### Immediate

- [ ] Tag release in git/jj
- [ ] Publish to npm
- [ ] Verify installation works
- [ ] Update dependent projects

### Follow-up

- [ ] Monitor for issues
- [ ] Gather feedback
- [ ] Plan v0.10.0 or v1.0.0
- [ ] Consider Node.js support

---

## Quality Gates Summary

| Gate | Status | Blocker? |
|------|--------|----------|
| TypeScript compiles | ✅ Pass | Yes |
| Build succeeds | ✅ Pass | Yes |
| Linter passes | ❌ Not configured | Yes |
| Tests pass | ✅ 730/730 | Yes |
| README exists | ❌ Missing | Yes |
| CHANGELOG exists | ❌ Missing | Yes |
| LICENSE exists | ❌ Missing | Yes |
| package.json valid | ⚠️ Needs fixes | Yes |
| npm install works | ⚠️ Untested | Yes |

**Current Status:** 🔴 **NOT READY** - 5 blockers to resolve

---

## Definition of Done

A release is **10/10 quality** when:

1. ✅ All tests pass
2. ✅ TypeScript compiles with zero errors
3. ✅ Build produces valid output
4. ✅ Linter passes (or lint script removed)
5. ✅ README.md provides clear installation/usage
6. ✅ CHANGELOG.md documents this version
7. ✅ LICENSE file present
8. ✅ package.json metadata complete and correct
9. ✅ `npm install` works from published package
10. ✅ Core workflows tested and documented

**Ship Criteria:** All 10 items checked ✅
