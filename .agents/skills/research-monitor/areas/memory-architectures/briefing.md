# Memory Architectures — Research Briefing

You are monitoring the evolution of memory systems for LLMs and agents. This is a core area for RAGE/Recurse — how memory "lives" determines what kinds of cognition are possible.

## Landscape Context

The field currently clusters into three paradigms:

**Tiered External Memory** (LightMem, BEAM, Auto-scaling Continuous Memory)
Multi-stage inspired by human STM/LTM. Heavy compression, offline consolidation. Treats memory as "logs + summaries over time."

**Constructivist/Schema-Based Memory** (CAM, ReasoningBank, LEGOMem, SAGE)
Memory as schemata, trajectories, or compositional structures that evolve with experience. Learning from failure. Memory as cognitive layer, not storage.

**Latent/Generative Memory** (MemGen)
Memory tokens generated when needed, woven into reasoning stream. Breaks separation between store and context.

## What to Prioritize

- Papers advancing **structured, compositional memory** (schemata, frames, modular procedures)
- Work on **memory consolidation mechanics** — how and when to compress, merge, forget
- **Learning from failure** patterns — systems that improve memory based on outcomes
- Anything treating memory as **active cognitive infrastructure** rather than passive retrieval
- Papers from BAAI, Tsinghua, Alibaba DAMO (active in this space)

## What to Deprioritize

- Simple context window extensions without architectural insight
- "We added a vector database" papers
- Pure efficiency improvements without conceptual contribution
- Conversation history management without memory structure

## RAGE Relevance

RAGE treats memory as explicit frames on a graph — consolidation is structural (frame evolution and linking), not only compressive. Papers that move toward structured, schema-based memory directly inform RAGE's design.
