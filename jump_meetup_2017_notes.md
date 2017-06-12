1. Intro
    * Hi, I'm Jarrett!
        - Recently started an engineering position under Juan Pablo Vielma
        - Previously worked in CSAIL's Julia group under Alan Edelman
        - Started writing Julia code in 2013, working on AD since 2015
        - Authored most of Julia's performance regressions testing facilities (BenchmarkTools, Nanosoldier)
    * My users are all smarter than me
        - No formal optimization background (B.S. in Physics, 2014)
        - A lot of my work targets other Julia developers, not domain experts directly
        - Downstream packages: JuMP, Celeste, Optim, DifferentialEquations, RigidBodyDynamics, ValidatedNumerics, etc...
2. Setting the Stage: JuliaOpt-Related Automatic Differentiation Tools
    * Before My Time
        - ReverseDiffSparse
            - reverse-mode AD tailored to JuMP-generated ASTs
            - Hessian sparsity exploitation
        - DualNumbers
            - implements a Julia type for numbers of the form `x + ϵ`...
            - a naive implementation of operating-overloading forward-mode AD
    * ForwardDiff
        - operating-overloading forward-mode AD for native Julia code
        - ForwardDiff is built on it's own `Dual` type
            - more complete primitive coverage
            - primitives are more aggressively inlined
            - can track multiple partial derivatives at once (while still fully stack-allocated)
            - SIMD-able partial derivative operations
            - Tagging system: fixed perturbation confusion, resolved nested differentiation ambiguities
        - Used by JuMP
            - differentiating user-provided Julia functions
            - extracting specific partial derivatives for sparse Hessian computation ("forward-over-reverse" or "mixed-mode" AD)
    * ReverseDiff
        - operating-overloading reverse-mode AD for native Julia code
        - dynamically records computation graph to a topologically sorted representation (the "instruction tape").
        - dynamic re-recording allows for complex control flow (loops, recursion, etc.)
        - enables array primitives (ForwardDiff only supports scalar primitives)
        - multiple dispatch + JIT + run-time type information enables compiled, specialized primitive execution methods
        - instruction tape allows for static optimizations
            - precomputed dispatch (we'll cover this later)
            - preallocated instruction caches
        - mixed-mode AD support - intermediary derivatives of a primitive can be computed via ForwardDiff - more efficient for scalar     operations, including kernels for elementwise higher-order functions (map/broadcast).
        - can support most `AbstractArray` types
2. A Few Realizations
    * Potential ReverseDiff improvements
        - ReverseDiff offers a bunch of advantages over ReverseDiffSparse, but isn't as performant for sparse Hessian calculation or devectorized scalar graph.
        - ReverseDiff's taping/execution mechanism needs to be generalized to support arbitrary metadata propagation (e.g. for edge-pushing).
        - ReverseDiff's API/taping strategy is fine for traditional optimization, but isn't great for ML people.
    * Julia is very well-suited for this kind of thing
        - Multiple dispatch + JIT compilation enables fast, precise, and versatile operator overloading
        - Autodifferentiable Julia code doesn't need to "know" about ForwardDiff/ReverseDiff, as long as it is type generic.
        - Writing data-flow semantics in Julia over a Julia-represented DAG means grants efficient nested data-flow semantics for free
        - Since primitive definition and execution is performed via normal Julia dispatch, no magic is required to write your own primitives.
        - Since ReverseDiff and ForwardDiff wrap arbitrary `Real`s/`AbstractArray`s, we get heterogeneous device support for "free" (e.g. via `GPUArray`s), and more hardware-specialized primitive definitions can easily be added via dispatch.
    * A native-Julia-to-DAG package would be generally useful outside of AD
        - static analysis
        - parallel operation scheduling
        - automated preallocation
        - interval constraint programming
        - serialization of raw Julia code to e.g. TensorFlow graph
3. Cassette.jl
    * What is Cassette?
        - A native-Julia-to-DAG data-flow package that supports forward/backward-propagation of values and arbitrary metadata.
        - Inspired by both deep learning and traditional optimization worlds - different representations are supported for static and dynamic graphs
        - Exposes taping/execution mechanisms to downstream library authors as a hijackable pipeline of "transport-like" operations
        - ReverseDiff is Cassette's prototypical application, and the current stress test for Cassette's approach and implementation
    * Primary goals
        - Make Cassette's operations on primitives easy to define, overload, and extend
        - Reduce traversal and record overhead as much as possible
        - Shoehorn in as many audio-related puns as I can reasonably get away with
    * Genres
    * Hooks
    * Notes
    * Tapes
        - `@intercept`
        - recursive BFS vs. iterative BFS
        - Dynamic vs. Static Regimes
            - Dynamic Regime: Fewer "fatter" nodes (e.g. vectorized tensor operations) and nontrivial control flow
            - Static Regime: Many "leaner" nodes (e.g. devectorized scalar operations) and benefits from preallocated node caches
        - Implementation Problems:
            - locality
            - dynamic dispatch
                - function barriers
                - union splitting
                - precomputed dispatch
4. Endgame
