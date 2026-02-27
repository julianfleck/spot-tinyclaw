# Retrieval Architectures — Research Briefing

You are monitoring the evolution from basic RAG to graph-structured, temporal, and agentic retrieval. This directly informs how RAGE navigates its frame graph.

## Landscape Context

**Embedding/Vector-Centric** (MUVERA, REFRAG, AMER, R3)
Focus on embedding geometry and retrieval quality. Symbols appear indirectly. These are the substrate RAGE sits on.

**Graph/Symbol-Centric** (LinearRAG, G2ConS, MemoTime, PersonaAgent, PRoH)
Entities and relations as first-class objects. Temporal, personalized, and community structures. Symbolic operators (temporal constraints, hyperedges).

**Hybrid Symbolic-Neural** (CAM, MemoTime, PersonaAgent)
Neural layers for similarity/ranking, symbolic layers for structure/constraints. This is where RAGE lives.

## What to Prioritize

- Papers extending GraphRAG with **temporal awareness** (MemoTime, RAG Meets Temporal Graphs patterns)
- **Multi-hop and recursive retrieval** — query refinement, retrieval chains
- **Entity-focused** approaches that avoid noisy relations (G2ConS, LinearRAG patterns)
- **Personalized/community-aware** retrieval (PersonaAgent patterns)
- Work on **hypergraph** or higher-order relation retrieval (PRoH)

## What to Deprioritize

- Basic RAG with single-vector retrieval
- Embedding model fine-tuning without retrieval architecture insight
- Pure efficiency papers (token reduction) without conceptual contribution
- Application papers without novel retrieval structure

## RAGE Relevance

RAGE's frame graph extends GraphRAG from "graph of facts" to "graph of cognitive frames." Papers advancing graph-structured retrieval with temporal, recursive, or personalized dimensions directly inform frame neighborhood selection.
