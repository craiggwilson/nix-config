//! Information Retrieval evaluation metrics and benchmarks.

#![allow(dead_code)]

/// Recall@K: fraction of relevant docs found in top-K results.
///
/// # Arguments
/// - `relevant`: set of relevant document indices (0-based position in corpus)
/// - `retrieved`: ordered list of retrieved document indices
/// - `k`: cutoff position
///
/// # Returns
/// Fraction in [0.0, 1.0]. Returns 0.0 if no relevant documents exist.
pub fn recall_at_k(relevant: &[usize], retrieved: &[usize], k: usize) -> f64 {
    if relevant.is_empty() {
        return 0.0;
    }

    let relevant_set: std::collections::HashSet<_> = relevant.iter().copied().collect();
    let top_k_relevant = retrieved
        .iter()
        .take(k)
        .filter(|doc_id| relevant_set.contains(doc_id))
        .count();

    top_k_relevant as f64 / relevant.len() as f64
}

/// Mean Reciprocal Rank: average of 1/rank of first relevant result per query.
///
/// # Arguments
/// - `relevant_per_query`: for each query, list of relevant document indices
/// - `retrieved_per_query`: for each query, ordered list of retrieved document indices
///
/// # Returns
/// Mean reciprocal rank in [0.0, 1.0]. Returns 0.0 if no queries have relevant results.
pub fn mrr(relevant_per_query: &[Vec<usize>], retrieved_per_query: &[Vec<usize>]) -> f64 {
    if relevant_per_query.is_empty() {
        return 0.0;
    }

    let rr_sum: f64 = relevant_per_query
        .iter()
        .zip(retrieved_per_query.iter())
        .map(|(relevant, retrieved)| {
            let relevant_set: std::collections::HashSet<_> = relevant.iter().copied().collect();
            retrieved
                .iter()
                .position(|doc_id| relevant_set.contains(doc_id))
                .map(|rank| 1.0 / (rank as f64 + 1.0))
                .unwrap_or(0.0)
        })
        .sum();

    rr_sum / relevant_per_query.len() as f64
}

/// NDCG@K: normalized discounted cumulative gain at cutoff K.
///
/// Uses binary relevance (relevant=1, irrelevant=0).
/// DCG = sum of (rel_i / log2(i+1)) for i in 1..k
/// IDCG = DCG for perfect ranking (sorted by relevance)
/// NDCG = DCG / IDCG
///
/// # Arguments
/// - `relevant`: set of relevant document indices
/// - `retrieved`: ordered list of retrieved document indices
/// - `k`: cutoff position
///
/// # Returns
/// NDCG score in [0.0, 1.0]. Returns 1.0 if no relevant documents (perfect ranking of nothing).
pub fn ndcg_at_k(relevant: &[usize], retrieved: &[usize], k: usize) -> f64 {
    let relevant_set: std::collections::HashSet<_> = relevant.iter().copied().collect();

    // Compute DCG
    let dcg: f64 = retrieved
        .iter()
        .take(k)
        .enumerate()
        .map(|(rank, doc_id)| {
            if relevant_set.contains(doc_id) {
                1.0 / (rank as f64 + 2.0).log2()
            } else {
                0.0
            }
        })
        .sum();

    // Compute IDCG (perfect ranking: all relevant docs first)
    let idcg: f64 = (0..relevant.len().min(k))
        .map(|rank| 1.0 / (rank as f64 + 2.0).log2())
        .sum();

    if idcg == 0.0 {
        1.0 // Perfect ranking of no relevant documents
    } else {
        dcg / idcg
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::db::UpsertOptions;
    use crate::embed;
    use rusqlite::Connection;

    /// Test documents covering diverse topics (20 substantial documents with realistic content)
    const DOCUMENTS: &[(&str, &str)] = &[
        ("MongoDB Fiscal Calendar",
         "MongoDB operates on a non-standard fiscal year that begins February 1st and ends January 31st of the following calendar year. This means MongoDB's fiscal year 2026 (FY26) runs from February 1, 2025 through January 31, 2026.\n\nThe fiscal quarters are structured as follows: Q1 runs from February through April, Q2 runs from May through July, Q3 runs from August through October, and Q4 runs from November through January. This fiscal calendar affects earnings reports, budget cycles, and planning horizons.\n\nKey fiscal calendar dates include: Q1 close at end of April, Q2 close at end of July, Q3 close at end of October, and Q4/fiscal year close at end of January. Earnings calls typically occur 4-6 weeks after each quarter close. Annual planning cycles begin in Q3 for the following fiscal year.\n\nWhen working with MongoDB teams, always clarify whether dates refer to the fiscal calendar or the standard Gregorian calendar, as they are offset by one month. For example, the start of fiscal Q1 is February 1st, not January 1st as in a standard calendar year."),

        ("Rust Ownership and Borrowing",
         "Rust's ownership system is its most distinctive feature and the foundation of its memory safety guarantees. Every value in Rust has exactly one owner — the variable binding that holds it. When the owner goes out of scope, Rust automatically drops the value and frees the associated memory.\n\nBorrowing allows code to use a value without taking ownership of it. Immutable borrows (using &T) allow multiple concurrent readers but no mutation. Mutable borrows (using &mut T) allow exactly one writer with exclusive access. The borrow checker enforces these rules at compile time.\n\nLifetimes are annotations that tell the compiler how long references are valid. They prevent dangling references and use-after-free bugs. Explicit lifetime annotations use the syntax 'a and appear in function signatures and struct definitions when the relationship between input and output lifetimes is ambiguous.\n\nThe ownership model eliminates entire classes of bugs: null pointer dereferences, use-after-free, double-free, and data races. This comes at the cost of a steeper learning curve but enables Rust programs to be both safe and fast without garbage collection."),

        ("NixOS Module System",
         "NixOS uses a declarative configuration system built around the concept of modules. A module is a Nix file that defines options (the configuration interface) and config (the implementation). Modules are composed through the imports attribute and merged using attribute set recursion.\n\nThe module system provides type checking for options through the types.* namespace. Common types include types.str, types.int, types.bool, types.listOf, types.attrsOf, and types.submodule. Type checking catches configuration errors before they become runtime failures.\n\nOptions are defined with mkOption and can have defaults, descriptions, examples, and type constraints. The config section maps option values to system configuration — installing packages, writing files, enabling services. The mkIf, mkMerge, and mkDefault functions provide conditional and priority-based configuration.\n\nHome Manager extends this system to user-level configuration, allowing dotfiles and user services to be managed declaratively. The same module composition patterns apply, enabling reusable configurations for development environments, shell setups, and application settings."),

        ("PostgreSQL Performance Tuning",
         "PostgreSQL query performance depends heavily on proper index usage. B-tree indexes are the default and work well for equality and range queries. GIN indexes suit full-text search and array containment. GiST indexes handle geometric data and nearest-neighbor queries. Partial indexes on filtered subsets of rows reduce index size and improve selectivity.\n\nThe query planner uses statistics collected by ANALYZE to choose between sequential scans, index scans, bitmap scans, and nested loop, hash, or merge joins. Use EXPLAIN ANALYZE to see the actual execution plan with row counts and timing. Set enable_seqscan=off in a session to force index usage for testing.\n\nVACUUM reclaims storage from dead rows created by UPDATE and DELETE operations. AUTOVACUUM handles this automatically but may need tuning for high-write tables. VACUUM ANALYZE combines dead row cleanup with statistics refresh. VACUUM FULL rewrites the table but locks it exclusively and should be used sparingly.\n\nConnection pooling with PgBouncer reduces overhead from connection establishment. Configure work_mem for sort and hash operations, shared_buffers for the buffer cache, and max_connections based on available memory. Partitioning large tables improves query performance and maintenance operations."),

        ("Machine Learning Fundamentals",
         "Gradient descent is the fundamental optimization algorithm for training machine learning models. It iteratively adjusts model parameters in the direction that reduces the loss function. Stochastic gradient descent (SGD) computes gradients on random mini-batches rather than the full dataset, enabling faster iteration and better generalization.\n\nThe loss function measures how wrong the model's predictions are. Common choices include mean squared error for regression, binary cross-entropy for binary classification, and categorical cross-entropy for multi-class problems. The choice of loss function should match the problem structure and output distribution.\n\nBackpropagation computes gradients efficiently by applying the chain rule through the computational graph. Modern deep learning frameworks like PyTorch and JAX use automatic differentiation to handle this automatically. The gradient tells each parameter which direction to move and by how much.\n\nRegularization techniques prevent overfitting. L1 regularization encourages sparsity. L2 regularization (weight decay) keeps weights small. Dropout randomly zeros activations during training. Batch normalization stabilizes training by normalizing layer activations. Early stopping halts training when validation loss stops improving."),

        ("Kubernetes Pod Scheduling",
         "Kubernetes scheduler places pods onto nodes based on resource requests, node capacity, and scheduling constraints. Node selectors and node affinity rules restrict which nodes can run a pod based on node labels. Pod affinity and anti-affinity rules colocate or separate pods based on what's already running.\n\nTaints and tolerations work together to repel pods from nodes unless the pod explicitly tolerates the taint. Taints are applied to nodes with kubectl taint. Tolerations are specified in pod specs. Common use cases include dedicating nodes to specific workloads or marking nodes as special-purpose.\n\nResource requests and limits control scheduling and runtime behavior. Requests are used by the scheduler to find nodes with sufficient capacity. Limits enforce runtime constraints via cgroups. Setting requests equal to limits creates Guaranteed QoS class. Burstable pods have requests lower than limits. Best-effort pods have no requests or limits.\n\nPriority classes determine scheduling order when resources are scarce. Higher-priority pods preempt lower-priority pods. PodDisruptionBudgets protect against simultaneous eviction of too many pods during voluntary disruptions like node drains."),

        ("Git Branching Strategies",
         "Trunk-based development keeps all developers working on a single main branch with short-lived feature branches that merge back within a day or two. Feature flags control whether incomplete features are active. This approach minimizes merge conflicts and keeps the main branch always releasable.\n\nGitFlow uses long-lived develop and main branches with supporting branches for features, releases, and hotfixes. Features branch from develop and merge back to develop. Releases branch from develop, get stabilized, and merge to both main and develop. Hotfixes branch from main and merge to both main and develop. This suits projects with explicit release cycles.\n\nGithub Flow simplifies GitFlow: the main branch is always deployable, features branch from main and merge back via pull requests with required reviews. Continuous deployment triggers from merges to main. This works well for web services with continuous delivery.\n\nGood branching strategies include: protected main branch requiring pull request reviews, automated CI checks on all pull requests, squash merges to keep history clean, semantic versioning for releases, and conventional commits to enable automated changelogs."),

        ("HTTP/2 and HTTP/3 Protocols",
         "HTTP/2 introduced multiplexing over a single TCP connection, eliminating the head-of-line blocking problem of HTTP/1.1 where requests were processed serially. Multiple streams can be in flight simultaneously, each with its own priority. A single connection per origin handles all resource fetching.\n\nHeader compression using HPACK reduces overhead from repeated headers across requests. Static and dynamic Huffman tables compress header values. The dynamic table builds up commonly-used headers over the lifetime of the connection, achieving significant compression for typical web traffic patterns.\n\nHTTP/2 server push allows the server to proactively send resources the client will need before the client requests them. The server sends a PUSH_PROMISE frame followed by the pushed response. In practice, server push is being deprecated in favor of 103 Early Hints responses.\n\nHTTP/3 replaces TCP with QUIC, a UDP-based transport that solves TCP head-of-line blocking at the transport layer. QUIC connections survive IP address changes (connection migration), making it suitable for mobile clients. The TLS handshake is integrated into the QUIC handshake, reducing connection establishment latency."),

        ("React Hooks and State Management",
         "React Hooks were introduced in React 16.8 to allow functional components to use state and other React features previously only available in class components. The useState hook returns a state value and a setter function. The setter can accept a new value or an updater function that receives the current state.\n\nuseEffect handles side effects: data fetching, subscriptions, manual DOM manipulation, and timers. The second argument is a dependency array — the effect only re-runs when its dependencies change. Returning a cleanup function from useEffect handles subscription teardown and prevents memory leaks.\n\nuseContext accepts a Context object and returns the current context value, enabling components deep in the tree to access values without prop drilling. useReducer is an alternative to useState for complex state logic, following the Redux pattern of dispatching actions to a reducer function.\n\nCustom hooks extract component logic into reusable functions. By convention, custom hook names start with 'use'. They can call other hooks and return any value. Common custom hooks include useDebounce, useFetch, useLocalStorage, and useEventListener. The react-query and SWR libraries build sophisticated data fetching patterns on top of custom hooks."),

        ("Python Asyncio and Async Programming",
         "Python's asyncio library implements an event loop for concurrent I/O-bound operations. Coroutines defined with async def are the building blocks of asyncio programs. The await keyword suspends the current coroutine until an awaitable completes, yielding control back to the event loop.\n\nasyncio.gather() runs multiple coroutines concurrently and collects their results. asyncio.create_task() schedules a coroutine to run as a task, allowing it to run in the background while other code executes. asyncio.wait_for() adds a timeout to a coroutine, raising TimeoutError if it exceeds the limit.\n\nAsync generators and comprehensions extend the async model to iteration. Async context managers use __aenter__ and __aexit__ for resources that need async acquisition and release, like database connections or HTTP sessions. aiohttp provides an async HTTP client and server built on asyncio.\n\nThe distinction between CPU-bound and I/O-bound work is critical: asyncio excels at I/O-bound concurrency but provides no benefit for CPU-bound work. For CPU parallelism, use multiprocessing or ProcessPoolExecutor. The asyncio.run_in_executor function offloads blocking calls to a thread or process pool without blocking the event loop."),

        ("Docker Networking",
         "Docker creates isolated network namespaces for containers by default. The bridge driver creates a private internal network on the host, with containers connected via a virtual Ethernet bridge. Containers on the same bridge network communicate using container names as hostnames through Docker's embedded DNS resolver.\n\nThe host network driver removes network isolation, sharing the host's network stack directly. Containers using host networking see the same interfaces and IP addresses as the host. This eliminates NAT overhead but reduces isolation and can cause port conflicts.\n\nOverlay networks span multiple Docker hosts, enabling container-to-container communication across a Swarm cluster or Kubernetes deployment. VXLAN encapsulation tunnels traffic between hosts. Service discovery maps service names to VIPs that load-balance across healthy container instances.\n\nNetwork policies control traffic between containers. iptables rules implement ingress and egress filtering. User-defined bridge networks provide automatic DNS resolution and network isolation. Macvlan networks give containers their own MAC address on the physical network, making them appear as separate physical hosts."),

        ("Obsidian Knowledge Management",
         "Obsidian is a local-first knowledge management application that stores notes as plain markdown files. Wikilinks using [[double brackets]] create links between notes, building a bidirectional knowledge graph. The graph view visualizes connections between notes, revealing clusters of related knowledge.\n\nBacklinks show every note that links to the current note, enabling bottom-up knowledge organization. Unlike folders and tags which impose top-down hierarchy, backlinks emerge naturally from writing. This makes Obsidian well-suited for Zettelkasten and evergreen note-taking methodologies.\n\nObsidian supports a rich plugin ecosystem through its community plugins. Dataview enables SQL-like queries over note metadata and content. Templater provides templating with JavaScript expressions. Calendar integrates daily notes into a calendar interface. QuickAdd enables rapid note creation with customizable templates.\n\nFrontmatter YAML adds structured metadata to notes: dates, tags, types, aliases, and custom properties. The core Properties plugin provides a UI for editing frontmatter. The Bases feature enables database-like views grouping notes by properties, turning a vault into a personal knowledge database."),

        ("SQL Window Functions",
         "Window functions perform calculations across a set of rows related to the current row without collapsing them into a single group like aggregate functions do. The OVER clause defines the window — the set of rows the function operates on. PARTITION BY divides rows into groups; ORDER BY specifies the sort order within each partition.\n\nROW_NUMBER() assigns sequential integers starting from 1 within each partition. RANK() assigns the same rank to ties but leaves gaps (1, 1, 3). DENSE_RANK() assigns the same rank to ties without gaps (1, 1, 2). These functions are essential for top-N-per-group queries.\n\nLAG() accesses data from previous rows without self-joins. LEAD() accesses data from subsequent rows. Both accept an offset and default value. These are invaluable for calculating period-over-period changes, running differences, and sequential comparisons in time-series data.\n\nFrame specifications control which rows are included in the window calculation: ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW for a running total, ROWS BETWEEN 6 PRECEDING AND CURRENT ROW for a 7-day rolling average. RANGE uses logical ranges based on ORDER BY values rather than physical row positions."),

        ("Terraform Infrastructure as Code",
         "Terraform manages infrastructure through declarative configuration files describing the desired state. The plan phase computes the diff between current and desired state, showing what will be created, modified, or destroyed. The apply phase executes the plan. The state file records the current state of managed resources.\n\nProviders are plugins that interact with infrastructure APIs: AWS, GCP, Azure, Kubernetes, GitHub, and hundreds more. Each provider exposes resources and data sources. Resources represent managed infrastructure objects. Data sources query existing infrastructure without managing it.\n\nModules encapsulate reusable infrastructure patterns. The root module is the main configuration. Child modules are called with module blocks. Published modules on the Terraform Registry provide community-maintained patterns for common infrastructure components.\n\nState management is critical for team workflows. Remote state in S3, GCS, or Terraform Cloud enables collaboration and prevents conflicts. State locking prevents concurrent modifications. Workspaces manage multiple environments with shared configuration but separate state. Import brings existing infrastructure under Terraform management."),

        ("VSCode Extension Development",
         "VSCode extensions use the Extension API to add languages, debuggers, themes, and custom functionality. The extension manifest (package.json) declares activation events that control when the extension loads — on specific file types, commands, or language identifiers. Lazy activation keeps startup time fast.\n\nThe Language Server Protocol (LSP) separates language tooling from the editor. A language server process communicates with VSCode's language client over JSON-RPC, providing completions, hover documentation, go-to-definition, and diagnostics. Any editor supporting LSP can use the same language server.\n\nTreeDataProvider implements custom sidebar tree views. WebviewPanel creates embedded web content using HTML/CSS/JavaScript. TextEditorDecorationType adds inline decorations to the editor. These APIs enable rich custom interfaces beyond simple commands.\n\nExtension testing uses the @vscode/test-electron framework to run tests in a real VSCode instance. The Extension Host process runs extension code in isolation from the main VSCode window process. Extension packs bundle multiple related extensions for one-click installation of complete toolchains."),

        ("GraphQL API Design",
         "GraphQL is a query language and runtime for APIs that gives clients the ability to request exactly the data they need. The schema defines types, queries, mutations, and subscriptions using the Schema Definition Language. Strong typing enables powerful tooling: code generation, validation, and introspection.\n\nResolvers implement the logic for each field in the schema. Each field has a resolver function that receives parent data, query arguments, and context. The execution engine calls resolvers depth-first, enabling parallel resolution of sibling fields. DataLoader batches and deduplicates database queries to solve the N+1 problem.\n\nMutations modify server-side data and return the modified resources. Subscriptions maintain a long-lived connection for real-time updates. The resolver receives a source argument for subscription event filtering. WebSocket transport is common for subscriptions, though SSE is an alternative.\n\nPagination patterns in GraphQL include offset-based (skip and take), cursor-based (using opaque cursors for stable pagination through changing datasets), and connection-based pagination following the Relay specification with edges, nodes, and pageInfo."),

        ("Redis Caching Patterns",
         "Cache-aside (lazy loading) is the most common caching pattern. The application checks the cache first; on a miss, it loads from the database, stores in cache, and returns the result. This pattern is resilient to cache failures and only caches actually-requested data, but has cold-start latency.\n\nWrite-through caching updates the cache synchronously when data changes. Every write goes to both cache and database. This keeps the cache always fresh but adds write latency and may cache data that's never read. Combined with cache-aside for reads, write-through provides strong consistency.\n\nTTL (time-to-live) strategies control cache expiration. Short TTLs suit frequently-changing data. Long TTLs suit static reference data. Cache stampede occurs when a popular key expires and many requests simultaneously miss and reload from the database. Probabilistic early expiration and mutex locking prevent stampedes.\n\nRedis data structures enable sophisticated caching patterns beyond simple key-value. Sorted sets implement leaderboards and rate limiting. HyperLogLog estimates unique visitor counts with minimal memory. Pub/Sub enables cache invalidation across application instances. Lua scripts provide atomic operations across multiple keys."),

        ("Linux Systemd Service Management",
         "Systemd is the init system and service manager for modern Linux distributions. Unit files describe services, sockets, devices, mounts, and other system resources. Service units define how to start, stop, and monitor long-running processes. The systemctl command manages units: start, stop, restart, enable, disable, and status.\n\nUnit file sections include [Unit] for metadata and dependencies, [Service] for service configuration, and [Install] for enabling at boot. The After= and Requires= directives declare ordering and dependency relationships. WantedBy=multi-user.target enables the service to start at boot in multi-user mode.\n\nSystemd handles process supervision automatically. Restart= controls restart behavior on failure. RestartSec= sets the delay between restart attempts. WatchdogSec= enables watchdog monitoring for services that send keepalive notifications. ExecStartPre= and ExecStartPost= run commands before and after the main process starts.\n\nJournald collects logs from all systemd services. journalctl queries the journal with powerful filters: by unit, time range, priority, and executable. journalctl -fu service-name follows a service log in real time. Log retention is configured in journald.conf with SystemMaxUse and MaxRetentionSec."),

        ("TypeScript Type System",
         "TypeScript's type system adds static typing to JavaScript. Generic type parameters enable reusable components that work with multiple types while preserving type information. A generic function <T>(arg: T): T accepts and returns the same type T. Constraints using extends restrict what types T can be: <T extends object> requires T to be an object type.\n\nConditional types use the extends keyword in a ternary-like expression: T extends U ? X : Y. Distributive conditional types distribute over union types automatically. The infer keyword extracts types from within conditional types: T extends Promise<infer U> ? U : never extracts the resolved type of a Promise.\n\nMapped types transform existing types: { [K in keyof T]: T[K] } iterates over all keys. Partial<T> makes all properties optional. Required<T> makes all required. Readonly<T> prevents mutation. Pick<T, K> selects a subset of properties. These utility types compose to create complex transformations.\n\nTemplate literal types enable string manipulation at the type level. Capitalize<T>, Lowercase<T>, and custom patterns like `${string}:${string}` create precise string types. Discriminated unions use a common literal property to narrow union members in type guards and switch statements."),

        ("OAuth2 and OpenID Connect",
         "OAuth2 is an authorization framework that enables third-party applications to obtain limited access to user accounts. The authorization code flow is the most secure for server-side applications: the client redirects to the authorization server, the user authenticates and consents, and the server returns an authorization code that the client exchanges for tokens.\n\nAccess tokens authorize API requests. They are short-lived (minutes to hours) and should be passed as Bearer tokens in the Authorization header. Refresh tokens are long-lived and used to obtain new access tokens without user interaction. Refresh token rotation invalidates the old refresh token on use, limiting the impact of theft.\n\nScopes define the specific permissions the access token grants. The principle of least privilege recommends requesting only required scopes. Resource servers validate tokens by checking the signature (for JWTs) or calling the introspection endpoint. The audience claim ensures tokens are only accepted by their intended resource server.\n\nOpenID Connect (OIDC) extends OAuth2 with an identity layer. The ID token is a JWT containing user identity claims: sub (subject identifier), email, name, and profile information. The UserInfo endpoint provides additional claims. PKCE (Proof Key for Code Exchange) prevents authorization code interception in public clients like mobile apps."),
    ];

    /// Query and its relevant document indices
    struct QueryCase {
        query: &'static str,
        relevant: &'static [usize],
    }

    const QUERIES: &[QueryCase] = &[
        QueryCase { query: "mongodb fiscal year quarters", relevant: &[0] },
        QueryCase { query: "when does mongodb fiscal q1 start", relevant: &[0] },
        QueryCase { query: "fiscal calendar year end january", relevant: &[0] },
        QueryCase { query: "rust memory ownership borrowing", relevant: &[1] },
        QueryCase { query: "nix module configuration system", relevant: &[2] },
        QueryCase { query: "postgres index query performance", relevant: &[3] },
        QueryCase { query: "gradient descent neural network training", relevant: &[4] },
        QueryCase { query: "kubernetes pod scheduling node affinity", relevant: &[5] },
        QueryCase { query: "git branching trunk based development", relevant: &[6] },
        QueryCase { query: "react hooks usestate useeffect", relevant: &[8] },
        QueryCase { query: "docker overlay network containers", relevant: &[10] },
        QueryCase { query: "sql window functions row number lag", relevant: &[12] },
        QueryCase { query: "redis cache ttl expiration patterns", relevant: &[16] },
        QueryCase { query: "systemd service unit file management", relevant: &[17] },
        QueryCase { query: "oauth2 authorization code flow tokens", relevant: &[19] },
    ];

    #[test]
    #[ignore] // run with: cargo test bench_retrieval -- --include-ignored
    fn bench_retrieval() {
        // Initialize embedding model
        embed::init(None).expect("embed init failed");

        // Create in-memory database
        let conn = Connection::open_in_memory().expect("failed to create in-memory db");
        crate::db::create_schema(&conn).expect("failed to create schema");

        // Index all documents
        println!("\n=== INDEXING DOCUMENTS ===");
        for (idx, (title, content)) in DOCUMENTS.iter().enumerate() {
            let doc_path = format!("doc_{}", idx);
            
            // Embed document with title weight
            let doc_embedding = embed::embed_passage_with_title(title, content, "")
                .expect("failed to embed document");

            // Insert document
            crate::db::upsert(
                &conn,
                &doc_path,
                Some(title),
                content,
                0,
                Some("test"),
                None,
                "test",
                false,
                0.5,
                0.5,
                0.0,
                0.0,
                &doc_embedding,
                &UpsertOptions {
                    force_metadata: true,
                },
            )
            .expect("failed to upsert document");

            // Get inserted document ID by querying for the path we just inserted
            let doc_id: i64 = conn
                .query_row(
                    "SELECT id FROM documents WHERE path = ?1",
                    [&doc_path],
                    |row| row.get(0),
                )
                .expect("failed to find inserted document");

            // Chunk the document and insert chunks
            let chunks = crate::chunk::chunk_text(title, content, 128, 64, 20);
            let chunk_embeddings: Vec<(usize, String, Vec<f32>)> = chunks.iter()
                .map(|c| {
                    let emb = embed::embed_passage(&c.content, "").expect("chunk embed failed");
                    (c.index, c.content.clone(), emb)
                })
                .collect();

            if !chunk_embeddings.is_empty() {
                crate::db::upsert_chunks(&conn, doc_id, &chunk_embeddings)
                    .expect("failed to upsert chunks");
            }

            println!("  [{}] {} ({} chunks)", idx + 1, title, chunks.len());
        }

        // Update corpus mean
        crate::db::update_corpus_mean(&conn).expect("failed to update corpus mean");

        // Run queries and evaluate
        println!("\n=== RUNNING QUERIES ===");
        let mut all_retrieved = Vec::new();
        let mut recall_at_1 = Vec::new();
        let mut recall_at_3 = Vec::new();
        let mut recall_at_5 = Vec::new();
        let mut ndcg_at_5_scores = Vec::new();
        let mut mrr_scores = Vec::new();

        for qcase in QUERIES {
            let query_embedding = embed::embed_query(qcase.query, "")
                .expect("failed to embed query");

            // Search with default parameters
            let results = crate::db::search(
                &conn,
                &query_embedding,
                10,
                1.0,  // semantic_weight
                0.5,  // strength_weight
                -1.0, // semantic_threshold (allow all)
                true, // use_chunking
                false, // use_corpus_centering
                false, // use_mmr (no diversity, pure relevance)
                1.0,  // mmr_lambda (no diversity)
                true, // use_bm25
                0.5,  // bm25_weight
                0.5,  // dense_weight
                60.0, // rrf_k
                qcase.query,
            )
            .expect("failed to search");

            let retrieved_ids: Vec<usize> = results
                .iter()
                .filter_map(|(result, _score)| {
                    // Map path back to document index
                    result.path.strip_prefix("doc_").and_then(|s| s.parse().ok())
                })
                .collect();

            println!(
                "  Q: {} | Top result: {}",
                qcase.query,
                retrieved_ids
                    .first()
                    .and_then(|&id| DOCUMENTS.get(id).map(|(t, _)| *t))
                    .unwrap_or("N/A")
            );

            all_retrieved.push(retrieved_ids.clone());

            // Compute metrics for this query
            let r1 = recall_at_k(qcase.relevant, &retrieved_ids, 1);
            let r3 = recall_at_k(qcase.relevant, &retrieved_ids, 3);
            let r5 = recall_at_k(qcase.relevant, &retrieved_ids, 5);
            let ndcg5 = ndcg_at_k(qcase.relevant, &retrieved_ids, 5);

            recall_at_1.push(r1);
            recall_at_3.push(r3);
            recall_at_5.push(r5);
            ndcg_at_5_scores.push(ndcg5);

            // MRR: 1/rank of first relevant result
            let rank = retrieved_ids
                .iter()
                .position(|&id| qcase.relevant.contains(&id));
            let rr = rank.map(|r| 1.0 / (r as f64 + 1.0)).unwrap_or(0.0);
            mrr_scores.push(rr);
        }

        // Compute aggregate metrics
        let avg_recall_at_1: f64 = recall_at_1.iter().sum::<f64>() / recall_at_1.len() as f64;
        let avg_recall_at_3: f64 = recall_at_3.iter().sum::<f64>() / recall_at_3.len() as f64;
        let avg_recall_at_5: f64 = recall_at_5.iter().sum::<f64>() / recall_at_5.len() as f64;
        let avg_ndcg_at_5: f64 = ndcg_at_5_scores.iter().sum::<f64>() / ndcg_at_5_scores.len() as f64;
        let avg_mrr: f64 = mrr_scores.iter().sum::<f64>() / mrr_scores.len() as f64;

        // Print score report
        println!("\n=== RETRIEVAL BENCHMARK RESULTS ===");
        println!("Queries: {}", QUERIES.len());
        println!("Documents: {}", DOCUMENTS.len());
        println!();
        println!("Metric                      | Score  | Interpretation");
        println!("----------------------------|--------|------------------------------------");
        println!(
            "Recall@1                    | {:.3}  | % relevant docs in top-1",
            avg_recall_at_1
        );
        println!(
            "Recall@3                    | {:.3}  | % relevant docs in top-3",
            avg_recall_at_3
        );
        println!(
            "Recall@5                    | {:.3}  | % relevant docs in top-5",
            avg_recall_at_5
        );
        println!(
            "MRR                         | {:.3}  | 1/rank of first relevant (avg)",
            avg_mrr
        );
        println!(
            "NDCG@5                      | {:.3}  | Normalized gain (perfect=1.0)",
            avg_ndcg_at_5
        );
        println!();

        // Assert minimum thresholds to detect regressions
        assert!(
            avg_mrr >= 0.3,
            "MRR {:.3} below threshold 0.3 — retrieval quality degraded",
            avg_mrr
        );
        assert!(
            avg_recall_at_5 >= 0.5,
            "Recall@5 {:.3} below threshold 0.5 — coverage degraded",
            avg_recall_at_5
        );

        println!("✓ All assertions passed");
    }
}
