# MongoDB Setup for Space Scraper

## Start MongoDB with Docker

```bash
docker run --name mongodb-space \
  -p 27017:27017 \
  -e MONGO_INITDB_ROOT_USERNAME=admin \
  -e MONGO_INITDB_ROOT_PASSWORD=imigty88 \
  -d mongo:latest
```

## Connection String

```
mongodb://admin:imigty88@localhost:27017/space_scraper?authSource=admin
```

## Collections

### space_content
Main collection for scraped content:
```json
{
  "_id": ObjectId,
  "url": String,
  "site_name": String,
  "category": String,
  "collection_timestamp": ISODate,
  "title": String,
  "description": String,
  "meta_tags": Object,
  "keywords": Array,
  "content_hash": String,
  "content_length": Number,
  "text_preview": String,
  "local_links_count": Number,
  "local_links": Array,
  "status_code": Number,
  "created_at": ISODate
}
```

### content_changes
Tracks when content changes:
```json
{
  "_id": ObjectId,
  "url": String,
  "previous_hash": String,
  "new_hash": String,
  "change_detected_at": ISODate,
  "change_type": String,
  "created_at": ISODate
}
```

### site_statistics
Aggregated statistics per site:
```json
{
  "_id": ObjectId,
  "site_name": String,
  "category": String,
  "total_scrapes": Number,
  "last_scrape": ISODate,
  "total_changes": Number,
  "average_content_length": Number,
  "updated_at": ISODate
}
```

## Create Indexes

```javascript
// Connect to MongoDB
use space_scraper

// Create indexes for space_content
db.space_content.createIndex({ "url": 1 })
db.space_content.createIndex({ "content_hash": 1 })
db.space_content.createIndex({ "collection_timestamp": -1 })
db.space_content.createIndex({ "category": 1 })
db.space_content.createIndex({ "site_name": 1 })

// Create indexes for content_changes
db.content_changes.createIndex({ "url": 1 })
db.content_changes.createIndex({ "change_detected_at": -1 })

// Create indexes for site_statistics
db.site_statistics.createIndex({ "site_name": 1 }, { unique: true })
db.site_statistics.createIndex({ "category": 1 })
```

## Useful Queries

### Get latest content for each URL
```javascript
db.space_content.aggregate([
  { $sort: { "collection_timestamp": -1 } },
  { $group: {
    _id: "$url",
    latest: { $first: "$$ROOT" }
  }},
  { $replaceRoot: { newRoot: "$latest" } }
])
```

### Find recent changes
```javascript
db.content_changes.find({
  change_detected_at: {
    $gte: new Date(Date.now() - 24*60*60*1000)
  }
}).sort({ change_detected_at: -1 })
```

### Get site statistics
```javascript
db.site_statistics.find().sort({ total_changes: -1 })
```

## Setup Script

Run this in MongoDB shell to set up indexes:

```bash
docker exec -it mongodb-space mongosh -u admin -p imigty88 --authenticationDatabase admin
```

Then paste the index creation commands above.
