# TypeScript DI Framework Evaluation

**Date:** 2026-03-04  
**Status:** Complete  
**Scope:** Evaluate existing minimal TypeScript DI frameworks against hand-rolled container for opencode-projects-plugin

---

## Executive Summary

After evaluating five candidate frameworks against the plugin's specific constraints, **hand-rolling a DI container remains the best choice**. While several frameworks are well-designed, each introduces unnecessary complexity or constraints that don't align with the plugin's needs.

**Recommendation:** Proceed with the hand-rolled container design documented in `composable-hook-registry-di.md` (Section 3).

---

## Evaluation Criteria

The plugin has specific constraints that drive the evaluation:

1. **No decorators required** — avoid `experimentalDecorators` and `reflect-metadata`
2. **Async factory support** — some services need async initialization
3. **Minimal footprint** — plugin, not app; lightweight is critical
4. **Explicit wiring** — prefer explicit registration over auto-discovery
5. **TypeScript-native** — good type inference, not `any` everywhere
6. **Actively maintained** — not abandoned
7. **Bundle-friendly** — works with ESM, no CommonJS-only packages

---

## Candidate Evaluation

### 1. awilix (v13.0.3)

**Repository:** https://github.com/jeffijoe/awilix  
**Last Release:** 1 day ago (actively maintained)  
**Weekly Downloads:** 373,369  
**Bundle Size:** ~327 kB unpacked

#### Decorator Requirement
✅ **No decorators required** — uses explicit registration with `asClass()`, `asFunction()`, `asValue()`

#### Async Factory Support
✅ **Full async support** — factories can be async functions

```typescript
container.register({
  config: asFunction(async () => {
    const cfg = await loadConfig()
    return cfg
  }).singleton()
})
```

#### Type Safety
⚠️ **Partial** — Uses cradle proxy pattern which provides runtime type safety but requires manual type inference for complex scenarios. TypeScript inference works well for simple cases but can be verbose for complex dependency graphs.

#### Registration Pattern
```typescript
const container = createContainer()
container.register({
  projectManager: asClass(ProjectManager).singleton(),
  delegationManager: asClass(DelegationManager).singleton(),
  logger: asValue(logger),
})

// Resolution
const pm = container.cradle.projectManager
```

#### Pros
- Mature, battle-tested (373k weekly downloads)
- No decorators or reflect-metadata
- Excellent documentation
- Supports scopes and lifetimes
- Cradle proxy is intuitive once understood
- Auto-loading modules via glob (though not needed here)

#### Cons
- **Overkill for this use case** — supports features we don't need (scopes, auto-loading, interception)
- Cradle proxy adds indirection (though minimal)
- ~327 kB unpacked (vs ~50 lines for hand-rolled)
- More complex API than needed
- Auto-loading doesn't work with bundlers (not an issue since we're explicit)

#### Verdict
**Not recommended.** While excellent, awilix is over-engineered for a plugin with ~10 services. The cradle proxy pattern, while elegant, adds unnecessary indirection. The hand-rolled container is simpler and more transparent.

---

### 2. typed-inject (v5.0.0)

**Repository:** https://github.com/nicojs/typed-inject  
**Last Release:** 1 year ago (maintenance mode)  
**Weekly Downloads:** 307,159  
**Bundle Size:** ~103 kB unpacked

#### Decorator Requirement
✅ **No decorators required** — uses static `inject` property on classes

#### Async Factory Support
❌ **No native async support** — factories must be synchronous. Async initialization requires workarounds:

```typescript
// Workaround: wrap async in a factory that returns a promise
const injector = createInjector()
  .provideFactory('config', async () => {
    return await loadConfig()
  })

// But then resolution is awkward:
const config = await injector.resolve('config')
```

#### Type Safety
✅ **Excellent** — Compile-time type checking via mapped types and conditional types. If it compiles, dependencies are correct.

```typescript
class MyService {
  constructor(logger: Logger, config: Config) {}
  static inject = ['logger', 'config'] as const
}

// Compiler error if tokens don't match constructor parameters
```

#### Registration Pattern
```typescript
const injector = createInjector()
  .provideValue('logger', logger)
  .provideClass('projectManager', ProjectManager)
  .provideFactory('config', () => new Config())

const service = injector.injectClass(MyService)
```

#### Pros
- Excellent type safety (compile-time verification)
- No decorators or reflect-metadata
- Lightweight (~103 kB)
- Clean API with fluent chaining
- Good error messages with dependency path

#### Cons
- **No async factory support** — critical blocker for this plugin
- Last release 1 year ago (maintenance mode, not abandoned but slower updates)
- Requires static `inject` property on every class (boilerplate)
- Child injectors pattern is less intuitive than container.register()
- Smaller ecosystem (307k downloads vs awilix's 373k)

#### Verdict
**Not recommended.** The lack of native async factory support is a critical blocker. The plugin needs async initialization for VCS detection and other services. While the type safety is excellent, the async limitation makes it unsuitable.

---

### 3. brandi (v5.1.0)

**Repository:** https://github.com/vovaspace/brandi  
**Last Release:** 2 months ago (actively maintained)  
**Weekly Downloads:** 12,066  
**Bundle Size:** ~183 kB unpacked

#### Decorator Requirement
✅ **No decorators required** — uses token-based registration

#### Async Factory Support
✅ **Full async support** — factories can be async

```typescript
const TOKENS = {
  config: token<Config>('config'),
}

container
  .bind(TOKENS.config)
  .toFactory(async () => {
    return await loadConfig()
  })
  .inSingletonScope()
```

#### Type Safety
✅ **Good** — Token-based system provides type safety through TypeScript's type system

```typescript
const TOKENS = {
  projectManager: token<ProjectManager>('projectManager'),
  logger: token<Logger>('logger'),
}

// Type-safe resolution
const pm = container.get(TOKENS.projectManager)
```

#### Registration Pattern
```typescript
const container = new Container()

container
  .bind(TOKENS.projectManager)
  .toClass(ProjectManager)
  .inSingletonScope()

container
  .bind(TOKENS.logger)
  .toConstant(logger)

const pm = container.get(TOKENS.projectManager)
```

#### Pros
- No decorators or reflect-metadata
- Full async support
- Token-based (similar to hand-rolled approach)
- Lightweight (~183 kB)
- Good documentation
- Supports hierarchical containers
- Actively maintained

#### Cons
- **Requires token definitions** — adds boilerplate (must define TOKENS object)
- Smaller ecosystem (12k downloads)
- Less mature than awilix
- Fluent API is verbose compared to object-based registration
- Still more features than needed (hierarchical containers, capture/restore)

#### Verdict
**Possible alternative, but hand-rolled is better.** Brandi is well-designed and meets all requirements. However, the token-based approach adds boilerplate that the hand-rolled container avoids. For a plugin with ~10 services, the hand-rolled approach is simpler and more transparent.

---

### 4. iti (v0.8.0)

**Repository:** https://github.com/molszanski/iti  
**Last Release:** 5 months ago (actively maintained)  
**Weekly Downloads:** 3,165  
**Bundle Size:** ~110 kB unpacked

#### Decorator Requirement
✅ **No decorators required** — uses plain functions and objects

#### Async Factory Support
✅ **Excellent async-first design** — async is a first-class citizen

```typescript
const container = createContainer()
  .add({
    config: async () => await loadConfig(),
    projectManager: async (items) => new ProjectManager(items.config),
  })

// Resolution
const config = await container.get('config')
const pm = await container.get('projectManager')
```

#### Type Safety
✅ **Good** — TypeScript inference works well with plain objects

```typescript
const container = createContainer()
  .add({
    logger: () => new Logger(),
    projectManager: (items) => new ProjectManager(items.logger),
  })

// Type inference works automatically
const pm = container.get('projectManager') // ProjectManager
```

#### Registration Pattern
```typescript
const container = createContainer()
  .add({
    logger: () => new Logger(),
    config: async () => await loadConfig(),
  })
  .add((items) => ({
    projectManager: async () => new ProjectManager(items.logger, items.config),
  }))

const pm = await container.get('projectManager')
```

#### Pros
- **Async-first design** — perfect for plugin's async needs
- Minimal (~110 kB, <1kB core)
- No decorators or reflect-metadata
- Plain functions and objects (very transparent)
- Good TypeScript inference
- Supports dynamic imports
- Actively maintained

#### Cons
- **Smallest ecosystem** (3k downloads) — less battle-tested
- Async-first means all resolutions return promises (even sync factories)
- Less mature than awilix/brandi
- Smaller community for support
- Requires `await` for all resolutions (even simple values)

#### Verdict
**Interesting but not ideal.** Iti's async-first design is appealing, but forcing all resolutions to be async (even for simple values like loggers) adds unnecessary complexity. The plugin has a mix of sync and async services, and iti doesn't handle this elegantly.

---

### 5. tsyringe (v4.10.0)

**Repository:** https://github.com/Microsoft/tsyringe  
**Last Release:** 1 year ago (maintenance mode)  
**Weekly Downloads:** 3,252,679  
**Bundle Size:** ~149 kB unpacked

#### Decorator Requirement
❌ **Requires decorators** — mandatory `@injectable()`, `@inject()` decorators

```typescript
@injectable()
class ProjectManager {
  constructor(
    @inject("Logger") private logger: Logger,
    @inject("Config") private config: Config,
  ) {}
}
```

#### Async Factory Support
✅ **Full async support** — factories can be async

#### Type Safety
⚠️ **Partial** — Decorators provide some type safety, but string-based tokens are not type-checked

#### Verdict
**Ruled out.** Requires `experimentalDecorators` and `reflect-metadata` polyfill, which violates the core constraint of "no decorators required."

---

### 6. inversify (not evaluated in detail)

**Status:** Ruled out immediately  
**Reason:** Decorator-based (requires `@injectable()`, `@inject()`) and reflect-metadata, same as tsyringe

---

## Comparison Table

| Criterion | awilix | typed-inject | brandi | iti | hand-rolled |
|-----------|--------|--------------|--------|-----|-------------|
| **No decorators** | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Async factories** | ✅ | ❌ | ✅ | ✅ | ✅ |
| **Minimal footprint** | ⚠️ (327 kB) | ⚠️ (103 kB) | ⚠️ (183 kB) | ✅ (110 kB) | ✅ (~50 lines) |
| **Explicit wiring** | ✅ | ✅ | ✅ | ✅ | ✅ |
| **TypeScript-native** | ✅ | ✅✅ | ✅ | ✅ | ✅ |
| **Actively maintained** | ✅ | ⚠️ (1 yr) | ✅ | ✅ | N/A |
| **Bundle-friendly** | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Ecosystem size** | ✅✅ (373k) | ✅ (307k) | ⚠️ (12k) | ⚠️ (3k) | N/A |
| **Complexity** | ⚠️ (overkill) | ⚠️ (boilerplate) | ⚠️ (tokens) | ⚠️ (all async) | ✅ (minimal) |
| **Learning curve** | Medium | Medium | Low | Low | Very low |

---

## Detailed Analysis: Why Hand-Rolled Wins

### 1. Perfect Fit for Constraints

The hand-rolled container is designed specifically for this plugin's needs:
- ~10 services (not 100+)
- Mix of sync and async initialization
- Explicit registration (no auto-discovery)
- No need for scopes or hierarchical containers
- No need for interception or decorators

### 2. Transparency and Debuggability

```typescript
// Hand-rolled: crystal clear
const container = new Container()
container.register(Tokens.ProjectManager, projectManager)
container.registerFactory(Tokens.Config, async () => loadConfig())

// vs awilix: requires understanding cradle proxy
container.register({
  projectManager: asValue(projectManager),
  config: asFunction(async () => loadConfig()).singleton(),
})
```

### 3. Bundle Size

- **Hand-rolled:** ~50 lines of code (< 1 kB)
- **awilix:** 327 kB unpacked
- **brandi:** 183 kB unpacked
- **typed-inject:** 103 kB unpacked
- **iti:** 110 kB unpacked

For a plugin, every kilobyte matters.

### 4. Zero Dependencies

Hand-rolled has zero external dependencies. All frameworks add at least one dependency (even if small).

### 5. Async Handling

The hand-rolled container handles async naturally:

```typescript
// Async factory
container.registerFactory(Tokens.Config, async () => loadConfig())

// Sync factory
container.registerFactory(Tokens.Logger, () => new Logger())

// Both work seamlessly
const config = await container.resolve(Tokens.Config)
const logger = container.resolve(Tokens.Logger)
```

### 6. Type Safety

The hand-rolled container with typed tokens provides excellent type safety:

```typescript
// Tokens with types
interface ServiceTypes {
  [Tokens.ProjectManager]: ProjectManager
  [Tokens.Logger]: Logger
  [Tokens.Config]: Config
}

// Type-safe resolution
resolve<K extends keyof ServiceTypes>(token: K): ServiceTypes[K]

// Compiler catches mismatches
const pm: ProjectManager = container.resolve(Tokens.ProjectManager) // ✅
const pm: Logger = container.resolve(Tokens.ProjectManager) // ❌ Type error
```

---

## Risk Assessment

### Risks of Hand-Rolling

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|-----------|
| Registration order bugs | Medium | High | Document order, add validation |
| Circular dependencies | Low | High | Container detects cycles, clear module boundaries |
| Performance overhead | Low | Low | Container is simple Map lookup |
| Testing complexity | Low | Medium | Each module testable in isolation |

### Risks of Using External Framework

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|-----------|
| Framework abandonment | Low | High | Choose actively maintained (awilix, brandi) |
| Unnecessary complexity | High | Medium | Adds cognitive load, harder to debug |
| Bundle size bloat | High | Medium | Plugin size increases |
| Dependency updates | Medium | Low | More maintenance burden |
| Learning curve | Medium | Low | Team must learn framework patterns |

---

## Recommendation

**Proceed with hand-rolled container.**

### Rationale

1. **Perfect fit** — The hand-rolled design in `composable-hook-registry-di.md` is tailored to the plugin's exact needs
2. **Minimal footprint** — ~50 lines vs 100+ kB for frameworks
3. **Zero dependencies** — No external packages to maintain
4. **Transparency** — Code is simple and debuggable
5. **Type safety** — Typed tokens provide compile-time safety
6. **Async support** — Handles both sync and async factories naturally
7. **No decorators** — Meets the core constraint

### If Circumstances Change

If the plugin grows significantly (100+ services) or needs advanced features (scopes, hierarchical containers, interception), **awilix** would be the recommended migration path:
- Most mature ecosystem
- Best documentation
- Actively maintained
- Supports all advanced features
- Can be adopted incrementally

---

## Conclusion

The evaluation confirms that hand-rolling a DI container is the right choice for this plugin. While frameworks like awilix and brandi are well-designed, they introduce unnecessary complexity and overhead. The hand-rolled approach is simpler, more transparent, and perfectly suited to the plugin's constraints.

The design documented in `composable-hook-registry-di.md` (Section 3) should be implemented as planned.
