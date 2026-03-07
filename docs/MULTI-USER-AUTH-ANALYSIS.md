# Multi-User Authentication & Management Analysis

> **Status:** Analysis Document
> **Date:** 2026-03-07
> **Purpose:** Analyze current state and inform specification for multi-user substrate access

---

## Executive Summary

The RAGE substrate has a **sophisticated, well-architected foundation** for multi-user support. The three-tier identity model (User → Agent → Session), authentication system, and addressing schema are largely implemented. However, **the architecture remains single-user in practice** — the shared database and unfiltered queries mean multi-user deployment would leak data between users.

This document analyzes the current state to inform a specification for:
1. Multi-user substrate hosting (shared and isolated)
2. User and agent registration
3. Addressing schema extensions for database/world references

---

## 1. Current Identity Model

### 1.1 Three-Tier Hierarchy

```
┌─────────────────────────────────────────────────────────────┐
│                         User                                 │
│  - user_id (stable, permanent)                               │
│  - created_at                                                │
│  - metadata (optional profile)                               │
├─────────────────────────────────────────────────────────────┤
│                         Agent                                │
│  - agent_id (format: user_id:agent_name, e.g., "julian:spot")│
│  - user_id (FK → belongs to user)                            │
│  - agent_type (e.g., "claude", "custom")                     │
├─────────────────────────────────────────────────────────────┤
│                        Session                               │
│  - session_id (ephemeral, per conversation)                  │
│  - agent_id (FK)                                             │
│  - started_at, last_active                                   │
└─────────────────────────────────────────────────────────────┘
```

| Level | Persistence | Use Case |
|-------|-------------|----------|
| `user_id` | Permanent | Cross-agent memory, trust relationships, subscriptions |
| `agent_id` | Long-lived | Agent-specific preferences, attention patterns |
| `session_id` | Ephemeral | Conversation-local context, scratch frames |

### 1.2 Implementation Status

**Location:** `rage_substrate/auth/`

| Component | File | Status |
|-----------|------|--------|
| User/Agent/Session models | `auth/models.py` | ✅ Implemented |
| Auth database (CRUD) | `auth/database.py` | ✅ Implemented |
| JWT token management | `auth/tokens.py` | ✅ Implemented |
| API keys (rec_ prefix) | `auth/api_keys.py` | ✅ Implemented |
| WebSocket middleware | `auth/middleware.py` | ✅ Implemented |

**Database Schema (`auth.db`):**
```sql
users (user_id, created_at, metadata)
agents (agent_id, user_id, agent_type, created_at)
sessions (session_id, agent_id, started_at, last_active)
subscriptions (subscriber_id, publisher_id, created_at, scope)
trust_edges (from_user, to_user, trust_level, phase_alignment)
```

---

## 2. Substrate Session Management

### 2.1 Dual Session Model

There are **two separate session systems** that work together:

#### Auth Sessions (`auth/models.py`)
- Track agent login sessions
- Ephemeral authentication context
- Schema: `session_id → agent_id → user_id`

#### Substrate Sessions (`core/session.py`)
- Group related frames and attention events
- Auto-expiration via inactivity timeout (30 min default)
- Features: soft/hard delete, undo capability, progressive title generation

**Session Manager Features:**
- `create_session(user_id, agent_id)` → new session with UUID
- `close_session(session_id)` → soft close
- `expire_inactive_sessions(timeout)` → auto-cleanup
- `undo_session(session_id)` → rollback session's frames
- Session-scoped frames via `frame_memberships`

### 2.2 Creator Tracking in Frames

The substrate schema already tracks frame ownership:

```sql
ALTER TABLE frames ADD COLUMN creator_user_id TEXT;
ALTER TABLE frames ADD COLUMN creator_agent_id TEXT;
ALTER TABLE frames ADD COLUMN creator_session_id TEXT;
```

**Assessment:** Columns exist but queries don't filter by `creator_user_id` — isolation not enforced.

---

## 3. Current Addressing Schema

### 3.1 Three Orthogonal Concepts

| Concept | Purpose | Example |
|---------|---------|---------|
| **Address (Frame ID)** | Where frame LIVES | `/events/support-group` |
| **parent_id** | Where content CAME FROM (provenance) | `frm_abc123` (source message) |
| **Memberships** | Multiple access paths | `/persons/caroline/events` |

### 3.2 Address Formats

**Territorial Addresses (Flat Model):**
```
/{type}/{slug}
/events/lgbtq-support-group
/persons/caroline
/claims/therapy-helpful
/documents/divergence-engines-part-1
```

**Session Paths:**
```
/sessions/{source}/{date}/{session_id}
/sessions/telegram/2026-03-07/ses_abc123
```

**User/Agent Paths:**
```
@{user_id}           → User territory
agent:{agent_id}     → Agent frame
session:{session_id} → Session frame
```

### 3.3 Membership-Based Multi-Path Access

Frames can appear in multiple locations:

```python
# Event lives at /events/support-group
# But also visible at:
memberships = [
    ("/events/support-group", "/events"),                   # Primary
    ("/events/support-group", "/persons/caroline/events"),  # Context
    ("/events/support-group", "/documents/diary/events"),   # Document
]
```

**Key Architectural Decision:**
- Addresses are **flat** (not nested hierarchies)
- Relationships expressed via **membership edges**
- Single frame visible in **multiple locations**

---

## 4. Multi-User Design Options

### 4.1 Documented Approach (from `multi-user-design.md`)

**Recommended: Per-User SQLite Files**

```
~/.rage/
  auth.db                    # Shared auth (all users)
  substrates/
    julian/
      default.db             # Main workspace
      research.db            # Research workspace
      divergence-engines.db  # Specific project
    maria/
      default.db
      shared-project.db      # Collaborative
```

**Benefits:**
- Complete isolation by default
- Simple backup/restore per user
- No query filtering needed for isolation
- Familiar SQLite file semantics

**Challenges:**
- Cross-user references need special handling
- Shared substrates require different approach
- Admin queries across users need multi-DB access

### 4.2 Workspaces (Multiple Substrates per User)

Users can maintain multiple isolated substrates:

**Selection:**
- CLI: `RAGE_USER=julian RAGE_WORKSPACE=research rage add ...`
- WebSocket: Workspace specified in auth handshake, connection bound for duration

**Full Address Format:**
```
@{user}/{workspace}/{territory}/{path}
@julian/research/documents/paper-draft
```

### 4.3 Shared Substrates (Multi-User)

For collaborative substrates, documented options include:
1. **Shared database file** with per-user permissions via `territory_access` table
2. **Federated references** — frames in user A's DB can reference user B's frames
3. **Pub/sub permeability** — trust-based visibility computed dynamically

---

## 5. Proposed Addressing Extensions

### 5.1 Database/World Prefix

To reference specific databases (substrates/worlds/knowledge bases), we could extend addressing:

**Option A: @ Prefix (User-Owned)**
```
@julian:/divergence-engines/documents
@julian:divergence-engines/documents     (alternative syntax)
```
- Implies: database owned by user `julian`
- Path: database `divergence-engines`, path `/documents`

**Option B: # Prefix (Shared/Named)**
```
#divergence-engines/documents
#research-collab/claims
```
- Implies: named shared database
- Can be inhabited by multiple users
- No ownership implied in path

**Option C: URI-Style**
```
rage://julian/divergence-engines/documents
rage://shared/research-collab/claims
```
- More explicit, less compact
- Better for external references

### 5.2 Addressing Conflicts

**Current Use of # (Content Slices):**
- `#` is currently used for content slices/fragments
- Need to differentiate: `frm_abc123#section-2` vs `#database/path`

**Proposed Resolution:**
1. Content slices use `#` after frame ID: `frm_abc123#slice`
2. Database prefix uses `#` at path start: `#database/path`
3. Context disambiguates (frame reference vs path)

**Alternative:** Use different character for databases
- `~divergence-engines/documents` (tilde)
- `$divergence-engines/documents` (dollar)
- `%divergence-engines/documents` (percent)

### 5.3 Full Address Grammar (Draft)

```
address := database_ref? path

database_ref := '@' user_id ':' workspace_name '/'   # User-owned
              | '#' database_name '/'                 # Shared/named

path := '/' segment ('/' segment)*

segment := identifier | frame_ref

frame_ref := 'frm_' hex_chars

slice_ref := address '#' slice_id
```

**Examples:**
```
/documents/divergence-engines           # Current DB, path
@julian:/documents/divergence-engines   # Julian's default DB
@julian:research/documents/paper        # Julian's research workspace
#team-knowledge/claims/ai-fatigue       # Shared database
frm_abc123#section-2                    # Frame with slice
```

---

## 6. Registration Flow

### 6.1 User Registration

**Current Implementation (`auth/database.py`):**
```python
def register_user(self, user_id: str, metadata: dict = None) -> User:
    """Create a new user and sync to substrate."""
    # Creates user in auth.db
    # Also creates user frame in substrate.db at user:{user_id}
```

**Missing:**
- Self-registration flow (currently admin-only)
- Email/password or OAuth integration
- User verification

### 6.2 Agent Registration

**Current Implementation:**
```python
def create_agent(self, agent_id: str, user_id: str, agent_type: str) -> Agent:
    """Create agent owned by user."""
    # Agent ID format: "user_id:agent_name" (e.g., "julian:spot")
```

**Agent Addressing:**
- Format enforced: `{user_id}:{agent_name}`
- Parsed and validated in addressing module
- Unique across system

### 6.3 API Key Registration

**Current Implementation (`auth/api_keys.py`):**
- `rec_` prefix format for renewable keys
- Base58 encoding, bcrypt hashing
- Per-key expiration and revocation

---

## 7. What's Missing for Multi-User

### 7.1 Critical Gaps

| Gap | Status | Impact |
|-----|--------|--------|
| Per-user database routing | Designed, not deployed | Data isolation |
| Query isolation (WHERE filters) | Not implemented | Data leakage |
| SubstratePool in WebSocket server | Not integrated | Performance |
| Per-user EventBus | Not implemented | Event leakage |
| Cross-user admin queries | Not implemented | Admin tools |

### 7.2 Partially Implemented

| Feature | Status | Notes |
|---------|--------|-------|
| Creator tracking in frames | Columns exist | Queries don't filter |
| Subscription model | Database ready | Permeability not integrated |
| Trust relationships | Schema defined | compute_permeability() exists but unused |
| Territory access control | Schema defined | Not enforced |

### 7.3 Well-Designed, Needs Execution

- Substrate pooling architecture (full reference implementation in docs)
- Permeability computation functions
- Multi-user database design
- Workspace selection flow

---

## 8. Recommendations for Specification

### 8.1 Phase 1: Single-User Hardening
1. Activate `creator_user_id` filtering in all queries
2. Test with mock multi-user data
3. Implement SubstratePool in WSServer
4. Add per-user EventBus isolation

### 8.2 Phase 2: Multi-User Infrastructure
1. Implement per-user database routing in `Substrate.__init__()`
2. Define workspace selection protocol
3. Create migration script for existing data → default user
4. Build admin commands for user management

### 8.3 Phase 3: Shared Substrates
1. Define shared database ownership model
2. Implement database prefix addressing (`#name/path` or similar)
3. Build cross-database reference resolution
4. Add permeability-based visibility

### 8.4 Addressing Schema Decision Points

**Need to resolve:**
1. Character for database prefix (`#`, `~`, `$`, or URI-style)
2. Ownership semantics (user-owned vs shared)
3. Cross-database reference format
4. Conflict with existing `#` usage for slices

---

## 9. Key Files Reference

**Authentication:**
- `rage_substrate/auth/models.py` — User, Agent, Session, Subscription
- `rage_substrate/auth/database.py` — AuthDatabase CRUD
- `rage_substrate/auth/api_keys.py` — API key management

**Session Management:**
- `rage_substrate/core/session.py` — SessionManager
- `rage_substrate/core/models.py` — Frame, UserFrame, AgentFrame

**Addressing:**
- `rage_substrate/ingestion/territory.py` — Territory derivation
- `rage_substrate/addressing/resolver.py` — Address parsing

**Architecture Documentation:**
- `docs/architecture/multi-user-design.md` — Full implementation blueprint
- `docs/architecture/rage-auth-collaboration-spec.md` — Identity & trust model
- `docs/architecture/addressing-and-structure.md` — Path & membership model

---

## 10. Open Questions for Spec

1. **Database naming:** How do users name their databases/workspaces?
2. **Shared database creation:** Who can create shared databases? Invite flow?
3. **Permission model:** Beyond read/write/admin, do we need finer granularity?
4. **Cross-DB references:** How to handle frames that reference other databases?
5. **Addressing prefix:** Which character(s) for database prefixes?
6. **Migration:** How to move frames between databases?
7. **Quotas:** Per-user storage limits? Rate limiting?
8. **Federation:** Can databases be hosted on different servers?

---

## Summary

The RAGE substrate has comprehensive multi-user architecture **designed but not deployed**. The three-tier identity model, authentication system, session management, and addressing schema provide a solid foundation. The main gaps are:

1. **Database isolation** — Single shared DB in practice
2. **Query filtering** — No `creator_user_id` enforcement
3. **Event isolation** — Global EventBus leaks between users
4. **Addressing extensions** — No database/world prefix yet

The specification should focus on:
1. Deciding addressing syntax for database references
2. Defining the shared vs user-owned database model
3. Prioritizing which isolation features to implement first
4. Creating migration path from single-user to multi-user
