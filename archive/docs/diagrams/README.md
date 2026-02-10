# WAF Diagrams Directory

**Purpose:** Visual documentation for Windows Automation Framework  
**Created:** February 8, 2026  
**Format:** Mermaid diagrams (renders natively in GitHub)

---

## Available Diagrams

### 1. Framework Architecture Overview
**File:** [01_Framework_Architecture.md](01_Framework_Architecture.md)  
**Purpose:** High-level view of WAF structure and component relationships  
**Shows:** Scripts, custom fields, dashboards, data flow

### 2. Script Organization Structure
**File:** [02_Script_Organization.md](02_Script_Organization.md)  
**Purpose:** Repository directory structure and file organization  
**Shows:** Main scripts, monitoring scripts, documentation hierarchy

### 3. Data Flow - Script to Dashboard
**File:** [03_Data_Flow.md](03_Data_Flow.md)  
**Purpose:** How data moves from script execution to dashboard visibility  
**Shows:** Execution, collection, processing, storage, display, alerts

### 4. Field Type Conversion Journey
**File:** [04_Field_Conversion_Journey.md](04_Field_Conversion_Journey.md)  
**Purpose:** Visual timeline of Phase 1 dropdown-to-text conversion  
**Shows:** Before/after states, benefits, process steps

### 5. Pre-Phase Technical Foundation
**File:** [05_PrePhase_Foundation.md](05_PrePhase_Foundation.md)  
**Purpose:** How pre-phases built the technical foundation  
**Shows:** Layered architecture from LDAP to production scripts

### 6. Script Dependency Map
**File:** [06_Script_Dependencies.md](06_Script_Dependencies.md)  
**Purpose:** Script relationships and dependencies  
**Shows:** Independent scripts, baseline deps, AD deps, shared fields

### 7. Health Status Classification
**File:** [07_Health_Status_Classification.md](07_Health_Status_Classification.md)  
**Purpose:** How scripts determine health status values  
**Shows:** Decision tree, thresholds, common patterns

---

## Viewing Diagrams

### In GitHub
1. Click any diagram file above
2. GitHub renders Mermaid automatically
3. Diagrams display inline in markdown

### In VS Code
1. Install "Markdown Preview Mermaid Support" extension
2. Open any diagram .md file
3. Use Preview pane (Ctrl+Shift+V)

### In Other Editors
- Copy mermaid code to [Mermaid Live Editor](https://mermaid.live)
- Most modern markdown viewers support Mermaid

---

## Diagram Format

All diagrams use Mermaid syntax:
- Text-based, version-control friendly
- Native GitHub rendering
- Easy to update and maintain
- Multiple diagram types (flowchart, sequence, Gantt, etc.)

---

## Usage Context

**For New Users:**
- Start with Diagram 1 (Framework Architecture)
- Review Diagram 3 (Data Flow) for execution understanding
- Check Diagram 6 (Dependencies) before modifying scripts

**For Developers:**
- Reference Diagram 5 (PrePhase Foundation) for design decisions
- Use Diagram 6 (Dependencies) to understand script relationships
- Follow Diagram 7 (Health Status) for consistent classification

**For Documentation:**
- Link diagrams from related documentation
- Update diagrams when architecture changes
- Keep diagrams in sync with code

---

## Maintenance

**When to Update:**
- New scripts added to framework
- Architecture changes
- New dependencies introduced
- Field structure modifications
- Process changes

**How to Update:**
1. Edit the .md file with diagram code
2. Modify Mermaid syntax
3. Preview changes
4. Commit with descriptive message
5. Verify rendering in GitHub

---

**Total Diagrams:** 7  
**Format:** Mermaid markdown  
**Status:** Complete  
**Last Updated:** February 8, 2026
