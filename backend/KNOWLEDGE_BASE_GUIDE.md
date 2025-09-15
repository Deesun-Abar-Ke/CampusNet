# CampusNet Knowledge Base System - Complete Guide

## 📚 Database Tables Explanation

### 1. **`institutional_knowledge`** - Main Knowledge Repository
```sql
-- This is THE PRIMARY table for all MIST knowledge
CREATE TABLE institutional_knowledge (
    id SERIAL PRIMARY KEY,
    title VARCHAR(255),                    -- Document/webpage title
    content_type VARCHAR(50),              -- 'website', 'pdf', 'manual', 'text'
    source_url VARCHAR(500),               -- Original URL (for web scraping)
    file_path VARCHAR(500),                -- Local file path (for uploaded files)
    content TEXT,                          -- Full text content
    summary TEXT,                          -- Brief summary
    category VARCHAR(100),                 -- 'academic', 'admission', 'campus', 'research'
    subcategory VARCHAR(100),              -- More specific categorization
    is_processed BOOLEAN,                  -- Whether RAG processing completed
    last_updated TIMESTAMP,               -- When content was last updated
    version VARCHAR(50)                    -- Version control for updates
);
```

### 2. **`document_embeddings`** - Vector Storage for Search
```sql
-- This table stores the vector embeddings for semantic search
CREATE TABLE document_embeddings (
    id SERIAL PRIMARY KEY,
    user_id INTEGER,                       -- NULL for institutional content
    document_id INTEGER,                   -- NULL for institutional content
    content_chunk TEXT,                    -- Text chunk for embedding
    chunk_index INTEGER,                   -- Order of chunks in document
    embedding_vector VECTOR(384),          -- pgvector embedding
    source_type VARCHAR(20),               -- 'institutional' or 'user_document'
    source_metadata TEXT,                  -- JSON with additional info
    created_at TIMESTAMP
);
```

### 3. **How They Work Together:**
```
Text Content → institutional_knowledge (storage)
     ↓
RAG Processing → Chunking → Embedding
     ↓
Vector Storage → document_embeddings (search)
     ↓
User Query → Similarity Search → Relevant Chunks → AI Response
```

## 🗂️ Folder Structure Cleanup

### **KEEP THIS FOLDER STRUCTURE:**
```
backend/
├── knowledge_base/                       # ✅ KEEP - Current active folder
│   └── institutional_data/
│       ├── mist_academics.txt           # ✅ Academic information
│       └── mist_general_info.txt        # ✅ General MIST info
├── services/                            # ✅ KEEP - All service files
├── routes/                              # ✅ KEEP - API routes
└── test_files/                          # ✅ KEEP - Test files only
```

### **REMOVE THESE DUPLICATE FOLDERS:**
```
❌ mist_knowledge/                        # REMOVE - duplicate
❌ mist_knowledge_base/                   # REMOVE - duplicate  
❌ vector_store/                          # REMOVE - not used
❌ ubuntu/                                # REMOVE - not needed
```

## 🌐 Web Scraping Setup

### **1. Where to Put URLs:**
📁 `knowledge_base/urls_to_scrape.json` ✅ (Already created)

### **2. Which File to Run for Web Scraping:**
🚀 `python run_web_scraper.py` (Interactive scraper)

### **3. Which File to Run for Text Files:**
📄 `python process_text_files.py` (Process existing .txt files)

## 📂 Current File Organization

### **✅ CORRECT STRUCTURE:**
```
backend/
├── knowledge_base/                       # 🎯 MAIN KNOWLEDGE FOLDER
│   ├── urls_to_scrape.json              # 🌐 Web scraping configuration
│   └── institutional_data/              # 📄 Text files storage
│       ├── mist_academics.txt           # Academic information  
│       └── mist_general_info.txt        # General MIST info
├── run_web_scraper.py                   # 🚀 WEB SCRAPING TOOL
├── process_text_files.py                # 📄 TEXT FILE PROCESSOR
├── services/                            # Service layer
│   ├── knowledge_base_manager.py        # Web scraping logic
│   └── rag_service.py                   # Vector processing
└── test_files/                          # All test files
```

### **❌ REMOVED DUPLICATE FOLDERS:**
- ~~mist_knowledge/~~ (removed)
- ~~mist_knowledge_base/~~ (removed)
- ~~vector_store/~~ (removed)

## 🔄 How the System Works

### **Step 1: Content Storage**
```
Text Files → institutional_knowledge table
Web Pages → institutional_knowledge table
```

### **Step 2: RAG Processing** 
```
institutional_knowledge → Text Chunking → Vector Embeddings → document_embeddings table
```

### **Step 3: Search & Retrieval**
```
User Query → Vector Search → document_embeddings → Relevant Chunks → AI Response
```

## 🎯 Usage Instructions

### **For Web Scraping:**
1. **Edit URLs**: Modify `knowledge_base/urls_to_scrape.json`
2. **Run Scraper**: `python run_web_scraper.py`
3. **Monitor Progress**: Watch console output and logs

### **For Text Files:**
1. **Add Files**: Place .txt files in `knowledge_base/institutional_data/`
2. **Run Processor**: `python process_text_files.py`
3. **Verify**: Check database for new entries

### **Example URL Configuration:**
```json
{
  "mist_urls": [
    {
      "url": "https://www.mist.ac.bd/",
      "category": "institutional",
      "subcategory": "homepage",
      "description": "MIST main homepage"
    }
  ]
}
```

## 🗄️ Database Tables in Detail

### **1. `institutional_knowledge` - The Storage Table**
- **Purpose**: Stores all text content (web + files)
- **Content**: Full text, title, category, source info
- **Processing**: Tracks whether RAG processing completed

### **2. `document_embeddings` - The Search Table** 
- **Purpose**: Stores vector embeddings for semantic search
- **Content**: Text chunks + vector embeddings
- **Search**: Used by RAG system for similarity search

### **3. Data Flow:**
```
Raw Content → institutional_knowledge (storage)
      ↓
RAG Processing → Chunking + Embedding  
      ↓
Vector Storage → document_embeddings (search)
      ↓
User Query → Similarity Search → Relevant Content → AI Response
```

## ⚡ Quick Commands

```bash
# Process existing text files
python process_text_files.py

# Scrape web URLs  
python run_web_scraper.py

# Check knowledge base status
python -c "from services.knowledge_base_manager import get_knowledge_manager; print(get_knowledge_manager().get_knowledge_base_status())"

# Test the enhanced chatbot
python test_files/test_enhanced_flask_context.py
```
