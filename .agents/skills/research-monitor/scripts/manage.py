#!/usr/bin/env python3
"""
Research Monitor management script.
Usage:
  python manage.py list              List all research areas
  python manage.py status <slug>     Show area details
  python manage.py set-last-run <slug> <date>  Update lastRun date
"""

import argparse
import json
import os
from datetime import datetime
from pathlib import Path

SKILL_DIR = Path(__file__).parent.parent
AREAS_DIR = SKILL_DIR / "areas"
# Reports are now in workspace/research, not in the skill directory
WORKSPACE_DIR = Path.home() / ".openclaw" / "workspace"
RESEARCH_DIR = WORKSPACE_DIR / "research"


def load_area_config(slug: str) -> dict:
    config_path = AREAS_DIR / slug / "config.json"
    if not config_path.exists():
        raise FileNotFoundError(f"Area not found: {slug}")
    with open(config_path) as f:
        return json.load(f)


def save_area_config(slug: str, config: dict):
    config_path = AREAS_DIR / slug / "config.json"
    with open(config_path, "w") as f:
        json.dump(config, f, indent=2)


def list_areas():
    print("Research Areas:\n")
    for area_dir in sorted(AREAS_DIR.iterdir()):
        if area_dir.is_dir() and (area_dir / "config.json").exists():
            config = load_area_config(area_dir.name)
            status = "✓" if config.get("enabled", True) else "✗"
            last_run = config.get("lastRun") or "never"
            cadence = config.get("cadence", "?")
            print(f"  {status} {area_dir.name}")
            print(f"    {config.get('name', 'Unnamed')}")
            print(f"    Cadence: {cadence} | Last run: {last_run}")
            print()


def show_status(slug: str):
    config = load_area_config(slug)
    briefing_path = AREAS_DIR / slug / "briefing.md"
    format_path = AREAS_DIR / slug / "format.md"
    
    print(f"Area: {slug}")
    print(f"Name: {config.get('name', 'Unnamed')}")
    print(f"Enabled: {config.get('enabled', True)}")
    print(f"Cadence: {config.get('cadence', 'not set')}")
    print(f"Last Run: {config.get('lastRun') or 'never'}")
    print(f"Deliver Empty: {config.get('deliverEmpty', False)}")
    print()
    print("Keywords:")
    for kw in config.get("keywords", []):
        print(f"  - {kw}")
    print()
    print("Sources:")
    for src in config.get("sources", []):
        print(f"  - {src}")
    print()
    print(f"Briefing: {'exists' if briefing_path.exists() else 'MISSING'}")
    print(f"Format: {'exists' if format_path.exists() else 'MISSING'}")


def set_last_run(slug: str, date_str: str):
    config = load_area_config(slug)
    # Validate date format
    try:
        datetime.strptime(date_str, "%Y-%m-%d")
    except ValueError:
        print(f"Invalid date format: {date_str} (expected YYYY-MM-DD)")
        return
    config["lastRun"] = date_str
    save_area_config(slug, config)
    print(f"Updated {slug} lastRun to {date_str}")


def main():
    parser = argparse.ArgumentParser(description="Research Monitor management")
    subparsers = parser.add_subparsers(dest="command", required=True)
    
    subparsers.add_parser("list", help="List all research areas")
    
    status_parser = subparsers.add_parser("status", help="Show area details")
    status_parser.add_argument("slug", help="Area slug")
    
    set_parser = subparsers.add_parser("set-last-run", help="Set lastRun date")
    set_parser.add_argument("slug", help="Area slug")
    set_parser.add_argument("date", help="Date in YYYY-MM-DD format")
    
    args = parser.parse_args()
    
    if args.command == "list":
        list_areas()
    elif args.command == "status":
        show_status(args.slug)
    elif args.command == "set-last-run":
        set_last_run(args.slug, args.date)


if __name__ == "__main__":
    main()
