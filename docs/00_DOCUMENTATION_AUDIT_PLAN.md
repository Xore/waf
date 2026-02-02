# Documentation Audit and README Creation Plan
**Created:** February 2, 2026  
**Updated:** February 2, 2026  
- Added Phase 6.3: Script-Field Reference Matrix
- Added Phase 2.4: Update Chapter/File References to Actual Names

**Repository:** NinjaRMM WAF (Windows Automation Framework)  
**Status:** Planning Phase

---

## Objective

Create a comprehensive audit of all markdown documentation in the repository to ensure:
1. All script references are accurate and match actual script numbers
2. All custom field references are accurate and match field definitions
3. All cross-references between documents are valid
4. **All chapter/file references updated to actual file names with folder paths**
5. Every folder has a structured README.md with complete information
6. All files follow the naming schema consistently
7. Script-to-Field relationships are fully documented with use cases

---

## Phase 1: Repository Structure Analysis

### Folders to Analyze

```
/docs/
├── core/              (00-18)  - Core custom fields
├── advanced/          (01-04)  - Advanced topics (RCA, ML)
├── automation/        (150-152) - Automation and conditions
├── health-checks/     (115-117) - Health check documentation
├── patching/          (TBD)     - Patching documentation
├── reference/         (TBD)     - Reference materials
├── roi/               (TBD)     - ROI documentation
├── scripts/           (TBD)     - Script documentation
└── training/          (TBD)     - Training materials
```

### Tasks:
- [ ] Map complete folder structure
- [ ] Count total markdown files
- [ ] Document naming schema per folder
- [ ] Identify all file categories/prefixes

---

## Phase 2: Read All Markdown Files

### Scan Strategy

#### 2.1 Extract Metadata from Each File
For every markdown file, extract:
- File path and name
- Number prefix (NN)
- Category prefix (PREFIX)
- Description
- File size
- Last modified date

#### 2.2 Extract Internal References
Scan each file for:
- **Script References:** `Script NN`, `Script ##`, patterns like `**Script 4**`
- **Custom Field References:** Field names like `OPSHealthScore`, `BASEBaselineEstablished`
- **File Cross-References:** Links to other docs, markdown links
- **Section Headers:** All ## and ### headers for index creation
- **Use Cases:** Descriptions of how scripts use fields and vice versa
- **Generic References:** "Chapter X", "See documentation", file names without paths

#### 2.3 Build Reference Database
Create master lists:
- All script numbers mentioned across all docs
- All custom field names mentioned across all docs
- All internal document links
- All external references
- Script-to-Field relationships with use cases
- Field-to-Script relationships with use cases
- **All generic/outdated file references needing updates**

#### 2.4 Update Chapter/File References (NEW)
Scan each file for outdated chapter or file references and update them to match actual file names and folder structure.

**Patterns to Find and Fix:**

1. **Generic Chapter References:**
   - Find: "See Chapter X" or "Chapter Y" 
   - Update to: "See [NN_PREFIX_Description.md](folder/NN_PREFIX_Description.md)"
   - Example: "Chapter 5" → "[05_UX_User_Experience.md](../core/05_UX_User_Experience.md)"

2. **Generic Document References:**
   - Find: "Refer to Operational Scores documentation"
   - Update to: "Refer to [01_OPS_Operational_Scores.md](../core/01_OPS_Operational_Scores.md)"
   - Find: "Details in Security Monitoring"
   - Update to: "Details in [09_SEC_Security_Monitoring.md](../core/09_SEC_Security_Monitoring.md)"

3. **Old File Names (Pre-Renumbering):**
   - Find: References to old file names
   - Example: "290_RCA_Advanced.md" → "01_RCA_Advanced.md"
   - Example: "293_ML_RCA_Integration.md" → "04_ML_Integration.md"
   - Update to: Current file names with proper paths

4. **Missing Folder Paths:**
   - Find: References without folder context (e.g., "OPS_Operational_Scores.md")
   - Update to: Include full relative path from current file
   - Example: "OPS_Operational_Scores.md" → "../core/01_OPS_Operational_Scores.md"

5. **Section References:**
   - Find: "See Section X" without file context
   - Update to: "[Section Name](folder/file.md#section-name)"
   - Example: "See Health Score Calculation" → "[Health Score Calculation](../core/01_OPS_Operational_Scores.md#health-score-calculation)"

6. **Ambiguous References:**
   - Find: "See above", "mentioned earlier", "as discussed"
   - Flag for manual review
   - Suggest specific file/section links where possible

**Reference Update Process:**

```
FOR each markdown file:
  FOR each reference in file:
    IF reference matches pattern (Chapter X, generic name, old file name) THEN
      1. Identify target file:
         - By chapter number (if "Chapter X")
         - By file description/topic (if generic)
         - By old-to-new mapping (if renamed file)
      
      2. Determine relative path:
         - Calculate path from current file to target
         - Use ../ for parent directory navigation
         - Example: docs/advanced/01_RCA.md → ../core/01_OPS.md
      
      3. Create markdown link:
         - Format: [Display Text](relative/path/to/file.md)
         - Display text: Actual file name or descriptive text
         - Path: Relative path from current file
      
      4. Validate:
         - Verify target file exists
         - Check if section anchor exists (if specified)
         - Add to cross-reference database
      
      5. Replace:
         - Update reference in file
         - Log change for review
         - Track in reference update report
    END IF
  END FOR
END FOR
```

**Examples of Reference Updates:**

**Example 1: Generic Chapter Reference**
```markdown
BEFORE (in docs/automation/150_Compound_Conditions.md):
"For more information, see Chapter 5."

AFTER:
"For more information, see [05_UX_User_Experience.md](../core/05_UX_User_Experience.md)."
```

**Example 2: Generic Topic Reference**
```markdown
BEFORE (in docs/advanced/01_RCA_Advanced.md):
"Refer to the Operational Scores documentation for details."

AFTER:
"Refer to [01_OPS_Operational_Scores.md](../core/01_OPS_Operational_Scores.md) for details."
```

**Example 3: Old File Name (After Renumbering)**
```markdown
BEFORE:
"See 290_RCA_Advanced.md for advanced topics."

AFTER:
"See [01_RCA_Advanced.md](../advanced/01_RCA_Advanced.md) for advanced topics."
```

**Example 4: Section-Specific Reference**
```markdown
BEFORE:
"The health score calculation is explained in the OPS documentation."

AFTER:
"The health score calculation is explained in [01_OPS_Operational_Scores.md#health-score-calculation](../core/01_OPS_Operational_Scores.md#health-score-calculation)."
```

**Validation Rules:**
```
FOR each updated reference:
  1. Target file must exist at specified path
  2. If section anchor specified, section must exist in target
  3. Relative path must be correct from source to target
  4. No circular references allowed
  5. Link must be properly formatted markdown
END FOR
```

**Output:**
- **Reference Update Report** (`reports/reference_updates_report.md`):
  - Total references found: [count]
  - References updated: [count]
  - Ambiguous references needing manual review: [count]
  - Broken references fixed: [count]
  - List of all changes per file

- **Old-to-New Mapping** (`reference/file_name_mapping.md`):
  - Complete mapping of old file names to new
  - Useful for redirects and historical reference

- **Ambiguous References List** (`reports/ambiguous_references.md`):
  - References that couldn't be automatically resolved
  - Suggested targets for manual review
  - Context for each ambiguous reference

### Tasks:
- [ ] Read all files in docs/core/
- [ ] Read all files in docs/advanced/
- [ ] Read all files in docs/automation/
- [ ] Read all files in docs/health-checks/
- [ ] Read all files in docs/patching/
- [ ] Read all files in docs/reference/
- [ ] Read all files in docs/roi/
- [ ] Read all files in docs/scripts/
- [ ] Read all files in docs/training/
- [ ] Extract all script references
- [ ] Extract all custom field references
- [ ] Extract all cross-references
- [ ] Extract script-field relationships and use cases
- [ ] **Scan for generic chapter/file references**
- [ ] **Identify old file name references**
- [ ] **Update references to actual file names with paths**
- [ ] **Validate all updated references**
- [ ] **Generate reference update report**
- [ ] Build reference database

---

## Phase 3: Validation and Cross-Referencing

### 3.1 Script Reference Validation

**Objective:** Ensure all script references are valid

#### Process:
1. Extract all unique script numbers mentioned (e.g., Script 4, Script 18, Script 23)
2. Verify against actual script inventory
3. Check for:
   - Missing script references
   - Incorrect script numbers
   - Scripts mentioned but not documented
   - Scripts documented but never referenced

#### Validation Rules:
```
IF file mentions "Script NN"
  THEN verify Script NN exists in script inventory
  AND verify Script NN is documented in docs/scripts/
  AND verify Script NN description matches
```

#### Output:
- List of all valid script references
- List of broken script references
- List of orphaned scripts (exist but not referenced)
- List of phantom scripts (referenced but don't exist)

### 3.2 Custom Field Reference Validation

**Objective:** Ensure all custom field references match definitions

#### Process:
1. Extract all unique field names from docs/core/ (source of truth)
2. Build master field database with:
   - Field name
   - Category prefix
   - Field type
   - Defined in which file
   - Populated by which script(s)
   - Required by which scripts (consumers)
   - Use case for each relationship
3. Scan all other docs for field references
4. Validate each reference against master database

#### Validation Rules:
```
IF file mentions field "OPSHealthScore"
  THEN verify field is defined in docs/core/
  AND verify prefix "OPS" matches category
  AND verify field type is correct
  AND verify script reference is correct
  AND document which scripts populate it
  AND document which scripts consume it
  AND document use case for each relationship
```

#### Output:
- Master field database (all fields, definitions, scripts)
- List of all valid field references
- List of broken field references
- List of misspelled field names
- List of fields defined but never used
- List of fields used but not defined
- Script-to-Field relationship matrix
- Field-to-Script dependency map

### 3.3 Cross-Reference Validation

**Objective:** Ensure all internal document links are valid

#### Process:
1. Extract all markdown links: `[text](path.md)`, `[text](path.md#section)`
2. Verify target file exists
3. Verify target section exists (if specified)
4. Check for broken links
5. **Verify all updated references from Phase 2.4**

#### Validation Rules:
```
IF file contains link [Text](../other/file.md)
  THEN verify ../other/file.md exists
  AND verify link resolves correctly
  AND verify no circular references
```

#### Output:
- List of all internal links
- List of broken links
- List of redirect opportunities
- Link health score per file
- **Validation of all Phase 2.4 reference updates**

### Tasks:
- [ ] Validate all script references
- [ ] Validate all custom field references
- [ ] Validate all cross-references
- [ ] **Validate all updated chapter/file references**
- [ ] Build script-field relationship matrix
- [ ] Generate validation report
- [ ] Create issue list for broken references

---

## Phase 4: Naming Schema Documentation

### 4.1 Per-Folder Naming Schema

#### Document for Each Folder:

**Format:**
```markdown
## Naming Schema: [Folder Name]

### Pattern:
NN_PREFIX_Description.md

### Number Range:
[Start] - [End]

### Prefixes Used:
- PREFIX1: Description
- PREFIX2: Description

### Examples:
- 01_PREFIX_Example.md
- 02_PREFIX_Example2.md

### Rules:
1. Sequential numbering
2. Single-prefix only
3. Descriptive names
4. No special characters
```

#### Folders to Document:

**docs/core/** (00-18)
- Prefixes: OPS, AUTO, STAT, RISK, UX, SRV, BASE, SEC, DRIFT, UPD, CAP, ROLE, BAT, NET, GPO, AD
- Purpose: Core custom field definitions
- Naming: NN_PREFIX_Description.md

**docs/advanced/** (01-04)
- Prefixes: RCA, ML
- Purpose: Advanced topics and integrations
- Naming: NN_PREFIX_Description.md

**docs/automation/** (150-152)
- Purpose: Automation framework documentation
- Naming: NNN_Description.md

**docs/health-checks/** (115-117)
- Purpose: Health check documentation
- Naming: NNN_Description.md

### Tasks:
- [ ] Document naming schema for docs/core/
- [ ] Document naming schema for docs/advanced/
- [ ] Document naming schema for docs/automation/
- [ ] Document naming schema for docs/health-checks/
- [ ] Document naming schema for all remaining folders

---

## Phase 5: README.md Creation

### 5.1 README Template Structure

```markdown
# [Folder Name]

## Overview
[Brief description of folder purpose]

## Naming Schema
**Pattern:** NN_PREFIX_Description.md  
**Range:** [Start]-[End]  
**Total Files:** [Count]

## Prefixes
| Prefix | Category | Description |
|--------|----------|-------------|
| PREFIX | Category | Purpose |

## Files in This Folder

### [Category 1]
- **[NN_PREFIX_Description.md](./NN_PREFIX_Description.md)**  
  Purpose: [Brief description]  
  Key Topics: [List]

### [Category 2]
- **[NN_PREFIX_Description.md](./NN_PREFIX_Description.md)**  
  Purpose: [Brief description]  
  Key Topics: [List]

## Quick Reference

### Scripts Referenced
- Script ##: [Description]
- Script ##: [Description]

### Custom Fields Defined
- FieldName: [Description]
- FieldName: [Description]

## Related Documentation
- [Link to related folder](../folder/)
- [Link to related file](../folder/file.md)

## Navigation
- [← Back to Documentation Root](../)
- [→ Next Section](../next-folder/)

---
**Last Updated:** [Date]  
**Maintained By:** [Team/Person]
```

### 5.2 README Generation Process

For each folder:
1. Read all markdown files in folder
2. Extract metadata (count, prefixes, categories)
3. Generate file listing with descriptions
4. Extract script and field references
5. Create cross-reference links
6. Generate README.md from template
7. Validate README completeness

### 5.3 Folders Requiring READMEs

- [ ] docs/README.md (Root documentation index)
- [ ] docs/core/README.md
- [ ] docs/advanced/README.md
- [ ] docs/automation/README.md
- [ ] docs/health-checks/README.md
- [ ] docs/patching/README.md
- [ ] docs/reference/README.md
- [ ] docs/roi/README.md
- [ ] docs/scripts/README.md
- [ ] docs/training/README.md

### Tasks:
- [ ] Create README template
- [ ] Generate docs/README.md (root)
- [ ] Generate README for each subfolder
- [ ] Validate all README files
- [ ] Test all links in READMEs

---

## Phase 6: Master Documentation Index

### 6.1 Create Master Index File

**File:** `docs/00_MASTER_INDEX.md`

**Contents:**
- Complete file listing across all folders
- Organized by category/prefix
- Searchable reference
- Quick links to common topics
- Script → Field → Document mapping

### 6.2 Index Structure

```markdown
# Master Documentation Index

## By Category
### Core Custom Fields
- Link to file
- Link to file

### Scripts
- Link to file
- Link to file

## By Script Number
- Script 1: [Links to all documents mentioning Script 1]
- Script 2: [Links to all documents mentioning Script 2]

## By Custom Field
- FieldName: Defined in [file], Used in [files]

## By Topic
### Security
- Links to security-related docs

### Automation
- Links to automation docs
```

### 6.3 Script-Field Reference Matrix

**File:** `docs/00_SCRIPT_FIELD_REFERENCE.md`

#### Objective:
Create comprehensive reference showing bidirectional relationships between scripts and custom fields with use cases.

#### Matrix Structure:

##### View 1: By Script (Which fields does each script use?)

```markdown
# Script-to-Field Reference Matrix

## Script 1: [Script Name]
**Purpose:** [What the script does]

### Fields POPULATED by this script:
| Field Name | Type | Use Case | Documentation |
|------------|------|----------|---------------|
| FieldName1 | Text | Stores X for purpose Y | [Link to field doc](path) |
| FieldName2 | Number | Calculates Z based on... | [Link to field doc](path) |

### Fields REQUIRED by this script (Dependencies):
| Field Name | Type | Why Required | Populated By |
|------------|------|--------------|-------------|
| FieldName3 | Bool | Used to determine if... | Script 5 |
| FieldName4 | Date | Used to calculate age... | Script 12 |

### Use Cases:
1. **Primary Use Case:** [Description]
2. **Secondary Use Case:** [Description]
```

##### View 2: By Field (Which scripts use each field?)

```markdown
# Field-to-Script Reference Matrix

## OPSHealthScore
**Type:** Number (0-100)  
**Category:** Operational Scores  
**Defined In:** [01_OPS_Operational_Scores.md](core/01_OPS_Operational_Scores.md)

### POPULATED BY:
| Script | Purpose | How It's Calculated |
|--------|---------|--------------------|
| Script 4 | Calculate health score | Weighted average of CPU, Memory, Disk |

### CONSUMED BY (Dependencies):
| Script | Purpose | How It's Used |
|--------|---------|---------------|
| Script 18 | Generate alerts | Triggers alert if < 70 |
| Script 23 | Create reports | Includes in weekly health report |
| Script 45 | Automation trigger | Auto-remediation if < 50 |
```

##### View 3: Relationship Map (Visual overview)

```markdown
# Script-Field Relationship Map

## Legend:
- [P] = Populates/Writes to field
- [R] = Requires/Reads from field
- [P+R] = Both populates and reads

## Visual Map:

### Operational Scores (OPS)
Script 4 [P] → OPSHealthScore → [R] Script 18, 23, 45
Script 4 [P] → OPSPerformanceScore → [R] Script 19, 24
Script 4 [P] → OPSRiskScore → [R] Script 20, 25
```

#### Output Files:

1. **00_SCRIPT_FIELD_REFERENCE.md** - Main reference document
2. **00_SCRIPT_TO_FIELD_MATRIX.md** - Script-centric view
3. **00_FIELD_TO_SCRIPT_MATRIX.md** - Field-centric view
4. **00_DEPENDENCY_MAP.md** - Visual dependency chains
5. **script_field_relationships.json** - Machine-readable database
6. **reference/file_name_mapping.md** - Old-to-new file name mapping

### Tasks:
- [ ] Create master index structure
- [ ] Generate category-based index
- [ ] Generate script-based index
- [ ] Generate field-based index
- [ ] Generate topic-based index
- [ ] Create script-to-field matrix
- [ ] Create field-to-script matrix
- [ ] Create relationship map with use cases
- [ ] Generate JSON database of relationships
- [ ] **Create file name mapping document**
- [ ] Validate all index links
- [ ] Validate bidirectional consistency

---

## Phase 7: Validation Report Generation

### 7.1 Generate Validation Reports

#### Report 1: Script Reference Report
**File:** `docs/reports/script_reference_report.md`

- Total scripts referenced: [count]
- Valid references: [count]
- Broken references: [count]
- Orphaned scripts: [count]
- Details of all issues

#### Report 2: Custom Field Report
**File:** `docs/reports/field_reference_report.md`

- Total fields defined: [count]
- Total field references: [count]
- Valid references: [count]
- Broken references: [count]
- Misspelled fields: [count]
- Fields without populators: [count]
- Fields never consumed: [count]
- Details of all issues

#### Report 3: Cross-Reference Report
**File:** `docs/reports/link_health_report.md`

- Total internal links: [count]
- Valid links: [count]
- Broken links: [count]
- Redirect opportunities: [count]
- Link health percentage: [percent]

#### Report 4: Documentation Coverage Report
**File:** `docs/reports/coverage_report.md`

- Scripts documented: [count]/[total]
- Fields documented: [count]/[total]
- Topics covered: [list]
- Gaps identified: [list]

#### Report 5: Script-Field Relationship Report
**File:** `docs/reports/script_field_relationship_report.md`

- Total script-field relationships: [count]
- Scripts with no field interactions: [count]
- Fields with no scripts: [count]
- Circular dependencies found: [count]
- Missing dependencies: [count]
- Orphaned fields: [count]
- Required fields without populators: [count]
- Relationship health score: [percent]

#### Report 6: Reference Update Report (NEW)
**File:** `docs/reports/reference_updates_report.md`

- Total generic references found: [count]
- References successfully updated: [count]
- Ambiguous references needing review: [count]
- Old file names updated: [count]
- Chapter references converted: [count]
- Section-specific links created: [count]
- List of all changes per file

### Tasks:
- [ ] Generate script reference report
- [ ] Generate custom field report
- [ ] Generate cross-reference report
- [ ] Generate documentation coverage report
- [ ] Generate script-field relationship report
- [ ] **Generate reference update report**
- [ ] Create executive summary

---

## Phase 8: Automated Maintenance Tools

### 8.1 Create Validation Scripts

#### Script: validate_docs.ps1
**Purpose:** Automated validation of all documentation

**Features:**
- Scan all markdown files
- Validate script references
- Validate field references
- Validate links
- Validate script-field relationships
- **Validate updated chapter/file references**
- Generate reports
- Exit with error if issues found

#### Script: generate_readmes.ps1
**Purpose:** Auto-generate README files

**Features:**
- Read folder contents
- Extract metadata
- Generate README from template
- Update existing READMEs

#### Script: update_index.ps1
**Purpose:** Update master index

**Features:**
- Scan all docs
- Rebuild master index
- Update cross-references
- Validate all links

#### Script: build_relationship_matrix.ps1
**Purpose:** Build and maintain script-field relationship matrices

**Features:**
- Extract script-field relationships from docs
- Build relationship database
- Generate all matrix views
- Validate bidirectional consistency
- Generate dependency maps
- Export to JSON/CSV
- Detect circular dependencies
- Identify orphaned fields

#### Script: update_file_references.ps1 (NEW)
**Purpose:** Update generic/outdated file references to actual paths

**Features:**
- Scan for generic chapter references ("Chapter X")
- Scan for topic references without file names
- Scan for old file names (pre-renumbering)
- Map references to actual files
- Calculate relative paths
- Generate markdown links
- Validate all updated links
- Generate update report
- Flag ambiguous references for manual review

### 8.2 CI/CD Integration

**GitHub Actions Workflow:**
```yaml
name: Documentation Validation
on: [push, pull_request]
jobs:
  validate-docs:
    runs-on: windows-latest
    steps:
      - Checkout code
      - Run validation script
      - Validate file references
      - Generate reports
      - Build relationship matrix
      - Validate relationships
      - Fail if errors found
```

### Tasks:
- [ ] Create validation script
- [ ] Create README generation script
- [ ] Create index update script
- [ ] Create relationship matrix builder
- [ ] **Create file reference updater script**
- [ ] Create GitHub Actions workflow
- [ ] Test automation

---

## Timeline

### Week 1: Structure and Reading
- Phase 1: Repository structure analysis
- Phase 2: Read all markdown files
- **Phase 2.4: Update chapter/file references**
- Build reference database
- Extract script-field relationships

### Week 2: Validation
- Phase 3: Validate all references
- Validate updated file references
- Build script-field relationship matrix
- Generate issue lists
- Begin fixing broken references

### Week 3: Documentation
- Phase 4: Document naming schemas
- Phase 5: Create all READMEs
- Phase 6: Create master index
- Phase 6.3: Create relationship matrices

### Week 4: Reporting and Automation
- Phase 7: Generate validation reports
- Phase 8: Create automation tools
- Build relationship matrix automation
- **Create file reference updater**
- Final review and testing

---

## Success Criteria

✅ All markdown files read and analyzed  
✅ All script references validated  
✅ All custom field references validated  
✅ All cross-references validated  
✅ **All chapter/file references updated to actual file names with paths**  
✅ **Old file name references updated to new names**  
✅ **Ambiguous references flagged for review**  
✅ Naming schema documented for every folder  
✅ README.md created for every folder  
✅ Master index created  
✅ Script-to-Field reference matrix created  
✅ Field-to-Script reference matrix created  
✅ Use cases documented for all relationships  
✅ Bidirectional consistency validated  
✅ Validation reports generated  
✅ Automation tools created  
✅ CI/CD integration complete  

---

## Deliverables

1. **Reference Database** - Complete mapping of all scripts, fields, and references
2. **Validation Reports** - Detailed reports on all broken references
3. **README Files** - One per folder with complete information
4. **Master Index** - Comprehensive index of all documentation
5. **Script-Field Reference Matrices**:
   - Script-to-Field matrix with use cases
   - Field-to-Script matrix with dependencies
   - Visual relationship map
   - Machine-readable JSON database
6. **File Reference Mappings** (NEW):
   - Old-to-new file name mapping
   - Chapter-to-file mapping
   - Reference update report
7. **Automation Tools** - Scripts to maintain documentation quality
8. **CI/CD Pipeline** - Automated validation on every commit

---

**Plan Created:** February 2, 2026  
**Last Updated:** February 2, 2026  
- Added Script-Field Reference Matrix (Phase 6.3)  
- Added Update Chapter/File References (Phase 2.4)  

**Status:** Ready for Execution  
**Next Step:** Begin Phase 1 - Repository Structure Analysis
