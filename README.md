# Space Website Scraper

An n8n workflow that automatically scrapes and monitors 39 leading space information websites, storing content in MySQL or MongoDB with intelligent change detection.

## Features

- **Automated Scraping**: Monitors 39 curated space websites across 8 categories
- **Change Detection**: SHA-256 hashing to detect content updates
- **Metadata Extraction**: Captures titles, descriptions, meta tags, and keywords
- **Link Discovery**: Optionally follows local links for deeper crawling
- **Database Storage**: MySQL or MongoDB with indexing for fast queries
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

- **n8n**: Workflow automation platform (v2.0+)
- **Database** (choose one):
  - **MySQL**: 5.7+ or 8.0+ (or compatible MariaDB)
  - **MongoDB**: 4.0+ (recommended for flexibility)
- **Docker** (optional): For running databases

## Setup

### 1. Database Setup

Choose either MySQL or MongoDB (MongoDB recommended for easier setup):

#### Option A: MongoDB (Recommended)

```bash
# Start MongoDB with Docker
docker run --name mongodb-space \
  -p 27017:27017 \
  -e MONGO_INITDB_ROOT_USERNAME=admin \
  -e MONGO_INITDB_ROOT_PASSWORD=yourpassword \
  -d mongo:latest

# Create indexes
docker exec -it mongodb-space mongosh -u admin -p yourpassword --authenticationDatabase admin
```

Then in MongoDB shell:
```javascript
use space_scraper

db.space_content.createIndex({ "url": 1 })
db.space_content.createIndex({ "content_hash": 1 })
db.space_content.createIndex({ "collection_timestamp": -1 })
db.content_changes.createIndex({ "url": 1 })
```

See [mongodb-setup.md](mongodb-setup.md) for complete MongoDB documentation.

#### Option B: MySQL

```bash
# Using Docker
docker run --name mysqldev -e MYSQL_ROOT_PASSWORD=yourpassword -p 3306:3306 -d mysql

# Create database and import schema
docker exec -i mysqldev mysql -uroot -pyourpassword -e "CREATE DATABASE space_scraper CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
docker exec -i mysqldev mysql -uroot -pyourpassword space_scraper < space_scraper_schema.sql
```

### 2. n8n Setup

1. Import the workflow:
   - Open n8n
   - Click **Import from File**
   - Select your workflow:
     - `space_scraper_workflow_mongodb.json` (for MongoDB)
     - `space_scraper_workflow_mysql.json` (for MySQL)

2. Configure database credentials:

   **For MongoDB:**
   - Name: `MongoDB Space DB`
   - Connection String: `mongodb://admin:yourpassword@localhost:27017/space_scraper?authSource=admin`

   **For MySQL:**
   - Name: `MySQL Space DB`
   - Host: `localhost`
   - Port: `3306`
   - Database: `space_scraper`
   - User: `root`
   - Password: Your MySQL password

### 3. Run the Workflow

Execute with custom parameters:
- **sites_to_check**: Number of sites to scrape (1-39, default: 10)
- **follow_local_links**: Follow links on pages (default: false)
- **follow_links_depth**: How deep to follow links (default: 1)

## Database Schema

### Collections/Tables

**`space_content`** - Main content storage
- URL, site name, category
- Collection timestamp
- Title, description, meta tags
- Keywords (array/JSON)
- Content hash (SHA-256)
- Local links (array/JSON)
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

### Example Queries

**MongoDB:**
```javascript
// Get latest content for each URL
db.space_content.aggregate([
  { $sort: { "collection_timestamp": -1 } },
  { $group: { _id: "$url", latest: { $first: "$$ROOT" } }},
  { $replaceRoot: { newRoot: "$latest" } }
])

// Find recent changes (last 24 hours)
db.content_changes.find({
  change_detected_at: { $gte: new Date(Date.now() - 24*60*60*1000) }
}).sort({ change_detected_at: -1 })
```

**MySQL:**
```sql
-- Get latest content
SELECT * FROM latest_content;

-- Find recent changes
SELECT * FROM content_changes
WHERE change_detected_at > NOW() - INTERVAL 24 HOUR
ORDER BY change_detected_at DESC;

-- View statistics
SELECT * FROM site_statistics ORDER BY total_changes DESC;
```

## How It Works

1. **Load Websites**: Reads curated list of 39 space websites
2. **Fetch Pages**: Downloads HTML content with 30s timeout
3. **Extract Metadata**: Parses title, meta tags, keywords
4. **Detect Changes**: Compares SHA-256 hash with previous scrape
5. **Store Data**: Inserts into database with timestamp
6. **Follow Links** (optional): Discovers and scrapes local links
7. **Update Stats**: Aggregates statistics per site

## Change Detection

The workflow uses SHA-256 hashing to detect content changes:
- First scrape: Status = `new`
- Content unchanged: Status = `unchanged`
- Content modified: Status = `modified` + logged in `content_changes`

## Workflow Files

- `space_scraper_workflow_mongodb.json` - MongoDB workflow (recommended)
- `space_scraper_workflow_mysql.json` - MySQL workflow
- `space_scraper_workflow.json` - Original SQLite workflow
- `mongodb-setup.md` - MongoDB setup guide and queries
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
