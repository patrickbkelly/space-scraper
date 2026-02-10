# Space Website Scraper

An n8n workflow that automatically scrapes and monitors 39 leading space information websites, storing content in a MySQL database with intelligent change detection.

## Features

- **Automated Scraping**: Monitors 39 curated space websites across 8 categories
- **Change Detection**: SHA-256 hashing to detect content updates
- **Metadata Extraction**: Captures titles, descriptions, meta tags, and keywords
- **Link Discovery**: Optionally follows local links for deeper crawling
- **MySQL Storage**: Structured database with indexing for fast queries
- **Statistics Tracking**: Aggregates scraping metrics per site
- **Configurable**: Set number of sites to check and link-following behavior

## Websites Covered

### Categories
- **Official Space Agencies** (7): NASA, ESA, JAXA, Roscosmos, ISRO, CNSA, CSA
- **Launch Schedules** (4): SpaceflightNow, NextSpaceflight, and more
- **Missions** (4): NASA Missions, Planetary Society, Space.com
- **Astronaut Info** (3): NASA Astronauts, Astronaut Database, Spacefacts
- **Budget & Management** (4): NASA Budget, Congressional Budget Office
- **Commercial Space** (4): SpaceX, Blue Origin, Rocket Lab
- **Technical Data** (4): Jonathan's Space Report, Gunter's Space Page
- **News & Analysis** (4): SpaceNews, The Space Review, Ars Technica
- **Visualization** (4): NASA Eyes, Celestrak, N2YO, ISS Tracker

See [space_websites.md](space_websites.md) for the complete list with links.

## Requirements

- **n8n**: Workflow automation platform
- **MySQL**: 5.7+ or 8.0+ (or compatible MariaDB)
- **Docker** (optional): For running MySQL

## Setup

### 1. Database Setup

Create the MySQL database:

```bash
# Using Docker
docker run --name mysqldev -e MYSQL_ROOT_PASSWORD=yourpassword -p 3306:3306 -d mysql

# Create database and import schema
mysql -u root -p -e "CREATE DATABASE space_scraper CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
mysql -u root -p space_scraper < space_scraper_schema.sql
```

Or using Docker:

```bash
docker exec -i mysqldev mysql -uroot -pyourpassword -e "CREATE DATABASE space_scraper CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
docker exec -i mysqldev mysql -uroot -pyourpassword space_scraper < space_scraper_schema.sql
```

### 2. n8n Setup

1. Import the workflow:
   - Open n8n
   - Click **Import from File**
   - Select `space_scraper_workflow_mysql.json`

2. Configure MySQL credentials:
   - Name: `MySQL Space DB`
   - Host: `localhost` (or your MySQL host)
   - Port: `3306`
   - Database: `space_scraper`
   - User: `root` (or your MySQL user)
   - Password: Your MySQL password

### 3. Run the Workflow

Execute with custom parameters:
- **sites_to_check**: Number of sites to scrape (1-39, default: 10)
- **follow_local_links**: Follow links on pages (default: false)
- **follow_links_depth**: How deep to follow links (default: 1)

## Database Schema

### Tables

**`space_content`** - Main content storage
- URL, site name, category
- Collection timestamp
- Title, description, meta tags
- Keywords (JSON array)
- Content hash (SHA-256)
- Local links (JSON array)
- Full text preview

**`content_changes`** - Change tracking log
- URL, previous/new hash
- Change detection timestamp
- Change type

**`site_statistics`** - Aggregated metrics
- Total scrapes per site
- Last scrape timestamp
- Average content length
- Total changes detected

**`latest_content`** (View) - Most recent version of each URL

### Queries

Get latest content for all sites:
```sql
SELECT * FROM latest_content;
```

Find recently changed pages:
```sql
SELECT * FROM content_changes
WHERE change_detected_at > NOW() - INTERVAL 24 HOUR
ORDER BY change_detected_at DESC;
```

View site statistics:
```sql
SELECT * FROM site_statistics
ORDER BY total_changes DESC;
```

## How It Works

1. **Load Websites**: Reads curated list of 39 space websites
2. **Fetch Pages**: Downloads HTML content with 30s timeout
3. **Extract Metadata**: Parses title, meta tags, keywords
4. **Detect Changes**: Compares SHA-256 hash with previous scrape
5. **Store Data**: Inserts into MySQL with timestamp
6. **Follow Links** (optional): Discovers and scrapes local links
7. **Update Stats**: Aggregates statistics per site

## Change Detection

The workflow uses SHA-256 hashing to detect content changes:
- First scrape: Status = `new`
- Content unchanged: Status = `unchanged`
- Content modified: Status = `modified` + logged in `content_changes`

## Workflow Files

- `space_scraper_workflow_mysql.json` - MySQL workflow (recommended)
- `space_scraper_workflow.json` - Original SQLite workflow
- `space_scraper_schema.sql` - MySQL database schema
- `space_websites.md` - Curated website list with descriptions

## License

MIT

## Contributing

Contributions welcome! Please submit pull requests or open issues for:
- Additional space websites to monitor
- Workflow improvements
- Bug fixes
- Documentation updates
