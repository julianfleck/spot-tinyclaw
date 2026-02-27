# Brand & Name Mentions — Research Briefing

You are monitoring for mentions of Julian Fleck, his website (julianfleck.net), and projects (recurse.cc) across the web. This supports SEO tracking and awareness of how the work is being discussed or referenced.

## Search Method

**Use SerpAPI** for real Google search results.

```bash
curl "https://serpapi.com/search.json?q=Julian+Fleck&api_key=$SERPER_API_KEY"
```

The API key is in the environment as SERPER_API_KEY (it's actually a SerpAPI key). Returns structured JSON with organic_results, knowledge_graph, etc.

Documentation: https://serpapi.com/search-api

**What to flag:**
- Direct mentions or citations of Julian's writing or projects
- References to "epistemic infrastructure," "divergence engines," or concepts Julian has written about (even without attribution)
- Discussions on HN, Twitter, or blogs that engage with themes from Julian's work
- Backlinks to julianfleck.net or recurse.cc from new sources
- Conference or event mentions

**What to skip:**
- Generic results that happen to contain the keywords but aren't actually about Julian or the projects
- Social media noise without substance
- Old/stale results that have been seen before

**Context:**
This is for SEO and outreach monitoring. Julian is doing visibility work, so changes in search presence or new discussions are valuable signals. Don't over-report — only flag genuinely new, relevant mentions.
