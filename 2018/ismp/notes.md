
First Things First
- Who am I
- What do I work on
- What we're going to talk about today: AD in Julia, where it's at, where I want it to go, and how to get there

The Present Landscape: Packages
- Multiple dispatch + method invocation JIT + metaprogramming make Julia a fairly ideal
language for AD; few theoretical limits compared to fully static or fully dynamic languages
- ForwardDiff: native Julia forward-mode with stack-allocated perturbation vectors
- ReverseDiff: native Julia reverse-mode with dynamic OO-based taping and static compilation to Julia source code
- JuMP: modeling language with Julia-like syntax with an AD intepreter for it's expression graph
- ReverseDiffTape: experimental edge-pushing AD for JuMP
- XGrad: native Julia Source-to-source reverse-mode AD
- Nabla: Operator overloading reverse-mode AD
- AutoGrad: Port of the python autograd package to Julia
- Flux: Julia Machine Learning Framework with built-in AD (heavily PyTorch/ReverseDiff inspired)

The Present Landscape: Problems
- it's not obvious to users what code is AD'able and what code is not for any given framework
- multiple dispatch is great, ambiguity resolution is not
- only a few frameworks explicitly supports generic mode nesting (ForwardDiff + ReverseDiff, JuMP + ForwardDiff)
- only one non-experimental framework supports sparsity optimizations (JuMP, experimental: ReverseDiffTape)
- perturbation/sensitivity confusion runs rampant (ForwardDiff has compile-time tagging, but not completely safe)
- essentially no work on differentiation for non-smooth problems
- very little official complex number support
- many public derivative kernels are not AD'able themselves
- little work put into memory optimization (e.g. checkpointing) most of which is tape preallocation (ReverseDiff, XGrad)
- slow scalar support outside of ForwardDiff/JuMP

Goals for Capstan:
    - don't force users to work with cumbersome custom array/number types
    - works even with Julia code containing concrete dispatch/structural type constraints
    - complex differentiation
    - safe nested/higher-order differentiation
    - API for custom perturbation/sensitivity seeding
    - user-extensible scalar and tensor derivative definitions
    - live variable caching optimizations
    - GPU support
    - extra future goodies:
        - mixed-mode fused broadcast optimizations
        - higher-order sparsity exploitation (edge-pushing)
        - mixed dynamic/static execution

Goals for Capstan:
    - How are we going to get there?

[enter cassette slides from beginning to the overdub -> execute/recurse mental model, skipping examples]

Cassette: Tagging arbitrary Julia objects with metadata
