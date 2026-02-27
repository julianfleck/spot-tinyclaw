# Evaluation & Governance — Research Briefing

You are monitoring how memory-augmented agents are evaluated, what failure modes emerge, and how governance/safety concerns are being addressed. This forms the boundary conditions for any serious RAG successor.

## Landscape Context

**Memory & Long-Horizon Benchmarks** (MemoryBench, HaluMem, MEMTRACK, BEAM, Agent-ScanKit)
Assume agents with persistent, updatable memory. Test hallucinations, cross-platform consistency, continual learning stability, perturbation robustness.

**Interaction Geometry & Reward** (TRACE, Reasoning Path Divergence)
Shift from static labels to dynamic interaction signals. Reward tied to trajectory quality, not just final answers.

**Security, Bias, Ecosystem Misalignment** (Autonomy-Induced Security Risks, Unbiased Collective Memory, Moloch's Bargain)
Recognize that autonomy + memory create new attack surfaces. Bias correction and failure weighting as first-class design targets.

## What to Prioritize

- **Novel benchmarks** for memory systems (not just QA accuracy)
- **Hallucination taxonomies** — fabrication, errors, conflicts, omissions at memory level
- **Trajectory-based evaluation** — interaction geometry, path diversity metrics
- **Security/adversarial work** on memory-augmented agents
- **Bias mitigation** in retrieval and memory formation
- Ecosystem-level concerns (competition-induced misalignment)

## What to Deprioritize

- Standard LLM benchmarks without memory dimension
- Pure accuracy metrics on single-turn tasks
- Security work on non-agentic systems
- Alignment work without memory/retrieval angle

## RAGE Relevance

RAGE needs evaluation on: hallucination types per frame, cross-platform consistency, continual learning stability, robustness to perturbations. Frame traversal geometry and conversation trajectories can signal which frames are stabilizing vs. destabilizing.
