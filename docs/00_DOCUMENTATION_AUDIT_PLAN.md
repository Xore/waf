# Documentation Audit and README Creation Plan
**Created:** February 2, 2026  
**Repository:** NinjaRMM WAF (Windows Automation Framework)  
**Status:** Planning Phase

---

## Objective

Create a comprehensive audit of all markdown documentation in the repository to ensure:
1. All script references are accurate and match actual script numbers
2. All custom field references are accurate and match field definitions
3. All cross-references between documents are valid
4. Every folder has a structured README.md with complete information
5. All files follow the naming schema consistently

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

#### 2.3 Build Reference Database
Create master lists:
- All script numbers mentioned across all docs
- All custom field names mentioned across all docs
- All internal document links
- All external references

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
3. Scan all other docs for field references
4. Validate each reference against master database

#### Validation Rules:
```
IF file mentions field "OPSHealthScore"
  THEN verify field is defined in docs/core/
  AND verify prefix "OPS" matches category
  AND verify field type is correct
  AND verify script reference is correct
```

#### Output:
- Master field database (all fields, definitions, scripts)
- List of all valid field references
- List of broken field references
- List of misspelled field names
- List of fields defined but never used
- List of fields used but not defined

### 3.3 Cross-Reference Validation

**Objective:** Ensure all internal document links are valid

#### Process:
1. Extract all markdown links: `[text](path.md)`, `[text](path.md#section)`
2. Verify target file exists
3. Verify target section exists (if specified)
4. Check for broken links

#### Validation Rules:
```
IF file contains link [Text](../other/file.md)
  THEN verify ../other/file.md exists
  AND verify link resolves correctly
```

#### Output:
- List of all internal links
- List of broken links
- List of redirect opportunities
- Link health score per file

### Tasks:
- [ ] Validate all script references
- [ ] Validate all custom field references
- [ ] Validate all cross-references
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

### Tasks:
- [ ] Create master index structure
- [ ] Generate category-based index
- [ ] Generate script-based index
- [ ] Generate field-based index
- [ ] Generate topic-based index
- [ ] Validate all index links

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

### Tasks:
- [ ] Generate script reference report
- [ ] Generate custom field report
- [ ] Generate cross-reference report
- [ ] Generate documentation coverage report
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
      - Generate reports
      - Fail if errors found
```

### Tasks:
- [ ] Create validation script
- [ ] Create README generation script
- [ ] Create index update script
- [ ] Create GitHub Actions workflow
- [ ] Test automation

---

## Timeline

### Week 1: Structure and Reading
- Phase 1: Repository structure analysis
- Phase 2: Read all markdown files
- Build reference database

### Week 2: Validation
- Phase 3: Validate all references
- Generate issue lists
- Begin fixing broken references

### Week 3: Documentation
- Phase 4: Document naming schemas
- Phase 5: Create all READMEs
- Phase 6: Create master index

### Week 4: Reporting and Automation
- Phase 7: Generate validation reports
- Phase 8: Create automation tools
- Final review and testing

---

## Success Criteria

✅ All markdown files read and analyzed  
✅ All script references validated  
✅ All custom field references validated  
✅ All cross-references validated  
✅ Naming schema documented for every folder  
✅ README.md created for every folder  
✅ Master index created  
✅ Validation reports generated  
✅ Automation tools created  
✅ CI/CD integration complete  

---

## Deliverables

1. **Reference Database** - Complete mapping of all scripts, fields, and references
2. **Validation Reports** - Detailed reports on all broken references
3. **README Files** - One per folder with complete information
4. **Master Index** - Comprehensive index of all documentation
5. **Automation Tools** - Scripts to maintain documentation quality
6. **CI/CD Pipeline** - Automated validation on every commit

---

**Plan Created:** February 2, 2026  
**Status:** Ready for Execution  
**Next Step:** Begin Phase 1 - Repository Structure Analysis
