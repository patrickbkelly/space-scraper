# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is an n8n workflow project (not a traditional codebase) that scrapes 39 space information websites and stores content in MySQL or MongoDB. There are no build, test, or lint commands — the workflows run inside n8n.

## Architecture

Three parallel n8n workflow JSON files implement the same scraping logic for different backends:
- `space_scraper_workflow_mongodb.json` — MongoDB version (recommended)
- `space_scraper_workflow_mysql.json` — MySQL version
- `space_scraper_workflow.json` — Original SQLite version

### Workflow Pipeline (shared across all variants)

1. **Manual Trigger** → **Set Parameters** (sites_to_check, follow_local_links, follow_links_depth)
2. **Load Websites** — Code node with hardcoded array of 39 websites (url, category, name)
3. **Fetch Page** — HTTP Request with 30s timeout, follows redirects, continueOnFail
4. **Extract Content & Metadata** — Code node: parses HTML for title, meta tags, keywords (both from meta and content-matching against a fixed space keyword list), local links, and SHA-256 content hash
5. **Check Previous Hash** → **Detect Changes** — Queries DB for previous hash, sets status to `new`/`unchanged`/`modified`
6. **Store Content** → **Log Change** (if modified) → **Update Statistics**
7. **Follow Links** (optional branch) — If enabled, discovers and scrapes local links from each page

### Key Difference Between Variants

- **MongoDB workflow**: Stores `meta_tags`, `keywords`, `local_links` as native objects/arrays
- **MySQL workflow**: JSON-serializes these fields (`JSON.stringify`) before storage
- **SQLite workflow**: Same as MySQL but targets SQLite; lacks error handling on fetch (no `continueOnFail`)

### Database Schema

Three collections/tables: `space_content` (main), `content_changes` (change log), `site_statistics` (aggregated metrics). Schema defined in `space_scraper_schema.sql` (MySQL) and `mongodb-setup.md` (MongoDB).

## Working with the Workflows

- Workflow JSON files are n8n export format. Edit via n8n UI then re-export, or edit JSON directly.
- The website list is duplicated in each workflow's "Load Websites" Code node — changes must be synced across all three files.
- `space_websites.md` is the canonical reference list but is not used by the workflows at runtime.

## Infrastructure

- **n8n** v2.0+ required
- **MongoDB** 4.0+ or **MySQL** 5.7+/8.0+ (Docker commands in README.md)
- MySQL schema: `space_scraper_schema.sql` (includes a stored procedure `update_site_statistics` and a `latest_content` view)
