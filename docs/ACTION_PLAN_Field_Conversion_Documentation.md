# WAF Field Type Conversion & Documentation Completeness Plan

**Date:** February 3, 2026  
**Status:** Planning Phase  
**Priority:** High

---

## Executive Summary

This plan outlines the systematic conversion of all dropdown custom fields to text fields and ensures complete documentation coverage for all 48+ scripts in the Windows Automation Framework. The goal is to eliminate dropdown field dependencies while creating a comprehensive documentation suite.

---

## Phase 1: Custom Field Type Conversion (Dropdown to Text)

### Objective
Remove all dropdown custom field dependencies and convert to text/string fields while preserving existing value logic.

### Scripts Requiring Field Type Changes

#### Monitoring Scripts (15 scripts)
1. Script_01_Apache_Web_Server_Monitor.ps1
2. Script_02_DHCP_Server_Monitor.ps1
3. Script_03_DNS_Server_Monitor.ps1
4. Script_37_IIS_Web_Server_Monitor.ps1
5. Script_38_MSSQL_Server_Monitor.ps1
6. Script_39_MySQL_Server_Monitor.ps1
7. Script_40_Network_Monitor.ps1
8. Script_41_Battery_Health_Monitor.ps1
9. Script_42_Active_Directory_Monitor.ps1
10. Script_43_Group_Policy_Monitor.ps1
11. Script_44_Event_Log_Monitor.ps1
12. Script_45_File_Server_Monitor.ps1
13. Script_46_Print_Server_Monitor.ps1
14. Script_47_FlexLM_License_Monitor.ps1
15. Script_48_Veeam_Backup_Monitor.ps1

#### Legacy Scripts (6 scripts)
1. 05_File_Server_Monitor.ps1
2. 08_HyperV_Host_Monitor.ps1
3. 17_BitLocker_Monitor.ps1
4. 18_Profile_Hygiene_Cleanup_Advisor.ps1
5. 20_Server_Role_Identifier.ps1
6. 20_FlexLM_License_Monitor.ps1

**Estimated Dropdown Instances:** ~78 field references

### Conversion Tasks Per Script

For each script:
1. Identify all Ninja-Property-Set calls using dropdown fields
2. Change field type from Dropdown to Text
3. Keep existing value logic (same strings, just as text input)
4. Update field documentation comments
5. Add validation comments where dropdown values were previously enforced
6. Test script logic remains intact

### Conversion Standards

**Before:**
```powershell
Ninja-Property-Set fieldname "Value" -Type Dropdown
```

**After:**
```powershell
Ninja-Property-Set fieldname "Value"
# Expected values: Value1, Value2, Value3
# Format: Text string
```

---

## Phase 2: Documentation Audit & Creation

### Objective
Ensure every script has corresponding markdown documentation in /docs/ folder with proper structure.

### Task 2.1: Verify Existing Documentation

Check for matching docs for each script:
- `/docs/scripts/` folder should contain one .md file per script
- Naming convention should match script number/name

**Current Documentation Structure:**
```
/docs/
├── scripts/
├── core/
├── patching/
├── reference/
├── training/
├── advanced/
├── automation/
├── health-checks/
└── roi/
```

### Task 2.2: Create Missing Documentation Files

**Required Documentation Template:**

```markdown
# Script XX: [Script Name]

## Overview
[Purpose and functionality]

## Custom Fields

### Field Mappings
| Field Name | Type | Description | Expected Values |
|------------|------|-------------|-----------------|
| fieldname | Text | Purpose | Format/Examples |

## Logic Flow

### Main Processing Steps
1. Initialization and environment validation
2. Data collection
3. Analysis and calculations
4. Field updates
5. Error handling and cleanup

### Compound Conditions
[Document all multi-condition logic with pseudo-code]

## Error Handling
- Scenario 1: Description and response
- Scenario 2: Description and response

## Dependencies
- Required PowerShell modules
- Required permissions
- System requirements
- External dependencies

## Usage Examples
[Practical deployment examples]

## Troubleshooting
[Common issues and solutions]

## Performance Considerations
- Execution time
- Resource usage
- Optimization notes

## Change Log
| Date | Version | Changes |
|------|---------|---------|
| YYYY-MM-DD | 1.0 | Initial release |
```

### Task 2.3: Document Compound Conditions

For each script with complex logic:

1. Identify all compound conditional statements
2. Create flowchart-style documentation
3. Add pseudo-code representation
4. Document decision trees

**Pseudo-Condition Format:**
```
CONDITION: Complex_Decision_Logic_1

IF (Condition_A) AND (Condition_B) THEN
    IF (Condition_C) OR (Condition_D) THEN
        Execute: Action_X
        Set: Field_1 = "Value_X"
    ELSE
        Execute: Action_Y
        Set: Field_1 = "Value_Y"
    END IF
ELSE IF (Condition_E) THEN
    Execute: Action_Z
    Set: Field_1 = "Value_Z"
ELSE
    Execute: Default_Action
    Set: Field_1 = "Unknown"
END IF

DEPENDENCIES: Condition_A, Condition_B, Condition_C
FIELDS AFFECTED: Field_1, Field_2
ERROR PATHS: [Document error scenarios]
```

---

## Phase 3: Diagram Updates

### Objective
Update all existing diagrams to reflect text field changes and complete documentation.

### Diagrams to Update

#### 1. Field Mapping Diagrams
- Update field type indicators (Dropdown → Text)
- Show text input format expectations
- Add validation notes

#### 2. Workflow Diagrams
- Verify accuracy with new field types
- Add missing monitoring scripts to flows
- Update data flow paths

#### 3. Condition Flow Diagrams
- Create flowchart for each compound condition
- Use standardized notation:
  - Diamond: Decision point
  - Rectangle: Action
  - Parallelogram: Input/Output
  - Rounded rectangle: Start/End

#### 4. Architecture Diagrams
- Update to show complete script ecosystem
- Include all 277 custom fields
- Show script categories and relationships
- Map field usage across scripts

#### 5. Deployment Diagrams
- Show script execution order
- Indicate dependencies
- Document scheduling recommendations

---

## Phase 4: Comprehensive Documentation Suite

### Objective
Create complete reference materials for the entire framework.

### Task 4.1: Quick Reference Documents

#### 1. Field Quick Reference
**Location:** `/docs/reference/Field_Quick_Reference.md`

**Content:**
- All 277 fields alphabetically sorted
- Field type, purpose, script usage
- Expected values/format
- Related fields
- NinjaOne configuration

**Format:**
```markdown
## Field: apache_status
- **Type:** Text
- **Purpose:** Apache service operational status
- **Used By:** Script_01_Apache_Web_Server_Monitor
- **Values:** Running, Stopped, Not Installed, Error
- **Related Fields:** apache_version, apache_uptime
```

#### 2. Script Quick Reference
**Location:** `/docs/reference/Script_Quick_Reference.md`

**Content:**
- All scripts categorized
- One-line description
- Field count per script
- Execution frequency recommendations
- Resource requirements

#### 3. Condition Quick Reference
**Location:** `/docs/reference/Condition_Quick_Reference.md`

**Content:**
- All compound conditions catalog
- Complexity rating (Simple/Medium/Complex)
- Cross-reference to scripts
- Decision tree summary

### Task 4.2: Training Documents

Create in `/docs/training/`:

#### 1. Getting Started Guide
**File:** `01_Getting_Started.md`

**Sections:**
- Framework overview
- Architecture introduction
- First-time setup
- Basic concepts
- Running your first script
- Understanding custom fields

#### 2. Advanced Topics Guide
**File:** `02_Advanced_Topics.md`

**Sections:**
- Complex condition logic
- Performance optimization
- Custom field best practices
- Script chaining
- Error handling strategies
- Extending the framework

#### 3. Administrator Training Manual
**File:** `03_Administrator_Guide.md`

**Sections:**
- Complete operational guide
- Deployment procedures
- Monitoring and alerting
- Troubleshooting procedures
- Maintenance schedules
- Backup and recovery
- Security considerations

#### 4. Developer Guide
**File:** `04_Developer_Guide.md`

**Sections:**
- How to extend the framework
- Coding standards
- Testing procedures
- Contributing guidelines
- Version control practices
- Documentation requirements

### Task 4.3: README Files

#### 1. Main README.md (Repository Root)
**Content:**
- Project overview
- Key features
- Quick start guide
- Link to all documentation
- License information
- Contribution guidelines

#### 2. Scripts README
**Location:** `/scripts/README.md`

**Content:**
- Script categories overview
- Execution guidelines
- Prerequisites
- Links to detailed documentation
- Deployment recommendations

#### 3. Scripts/Monitoring README
**Location:** `/scripts/monitoring/README.md`

**Content:**
- Monitoring-specific guide
- All 15 monitoring scripts listed with descriptions
- Setup instructions
- Scheduling recommendations
- Alert configuration

#### 4. Docs README
**Location:** `/docs/README.md`

**Content:**
- Documentation structure explanation
- How to navigate documentation
- Finding specific information
- Contribution guidelines
- Documentation standards

### Task 4.4: Index Documents

#### 1. Master Index
**Location:** `/docs/00_MASTER_INDEX.md`

**Content:**
- Complete framework inventory
- All files with descriptions
- Full navigation tree
- Quick links to key documents

#### 2. Script Index
**Location:** `/docs/reference/Script_Index.md`

**Content:**
- Scripts categorized by function
- Scripts categorized by role
- Scripts by complexity level
- Alphabetical listing
- Dependency matrix

#### 3. Field Index
**Location:** `/docs/reference/Field_Index.md`

**Content:**
- All 277 custom fields
- Grouped by category
- Cross-reference to scripts
- Field relationship map
- Data type reference

#### 4. Condition Index
**Location:** `/docs/reference/Condition_Index.md`

**Content:**
- All compound conditions
- Complexity rating
- Usage frequency
- Performance impact
- Testing requirements

---

## Phase 5: Quality Assurance

### Objective
Verify completeness and accuracy of all changes.

### Task 5.1: Documentation Completeness Check

**Verification Checklist:**
- [ ] Every script has corresponding .md file
- [ ] All 277 fields documented in at least one place
- [ ] All compound conditions documented with pseudo-code
- [ ] All diagrams updated to reflect current state
- [ ] Cross-references are accurate and functional
- [ ] No broken links in documentation
- [ ] All code examples tested
- [ ] All tables properly formatted

### Task 5.2: Field Type Validation

**Verification Checklist:**
- [ ] No dropdown references remain in any script
- [ ] All Ninja-Property-Set calls updated
- [ ] All fields converted to Text type in documentation
- [ ] Values/logic preserved correctly
- [ ] NinjaOne custom field configuration matches documentation
- [ ] Field validation comments added where needed
- [ ] No breaking changes to existing functionality

### Task 5.3: Documentation Standards Check

**All documentation must have:**
- [ ] Proper markdown formatting
- [ ] Consistent heading hierarchy
- [ ] Code blocks with language specification
- [ ] Tables properly aligned
- [ ] Consistent naming conventions
- [ ] Proper capitalization
- [ ] No spelling errors
- [ ] Version information
- [ ] Last updated date

### Task 5.4: Script Testing

**For each modified script:**
- [ ] Syntax validation passed
- [ ] Test execution in isolated environment
- [ ] Field updates verified in NinjaOne
- [ ] Error handling tested
- [ ] Performance acceptable
- [ ] No regression issues
- [ ] Documentation matches actual behavior

---

## Phase 6: Final Deliverables

### Create Completion Documents

#### 1. Field Conversion Report
**Location:** `/docs/FIELD_CONVERSION_REPORT.md`

**Content:**
- Summary of all changes
- Before/after comparison table
- Testing results per script
- Known issues and workarounds
- Migration notes for existing deployments

#### 2. Documentation Completeness Certificate
**Location:** `/docs/DOCUMENTATION_COMPLETENESS_CERTIFICATE.md`

**Content:**
- 100% coverage verification
- Complete file inventory
- Quality metrics
- Compliance checklist
- Sign-off information

#### 3. Updated Architecture Overview
**Location:** `/docs/ARCHITECTURE_OVERVIEW.md`

**Content:**
- Complete system architecture diagram
- All components documented
- Relationship maps
- Data flow diagrams
- Integration points
- Security architecture

#### 4. Implementation Guide
**Location:** `/docs/IMPLEMENTATION_GUIDE.md`

**Content:**
- Step-by-step deployment procedures
- Field creation in NinjaOne (all 277 fields)
- Script deployment sequence
- Testing procedures
- Rollback procedures
- Post-deployment validation

---

## Execution Sequence

### Recommended Implementation Order

**Week 1: Assessment and Setup**
1. Phase 2.1: Documentation Audit (identify what exists)
2. Create tracking spreadsheet for all tasks
3. Set up testing environment

**Week 2: Core Changes**
4. Phase 1: Field Conversion (update all scripts)
5. Script testing and validation
6. Create backup of all modified files

**Week 3: Documentation Creation**
7. Phase 2.2: Create Missing Documentation (fill gaps)
8. Phase 2.3: Document Conditions (detail logic)
9. Initial review of created documentation

**Week 4: Visual and Reference Materials**
10. Phase 3: Update Diagrams (visual representation)
11. Phase 4.1-4.2: Quick References and Training Docs
12. Phase 4.3-4.4: README files and Indexes

**Week 5: Quality Assurance**
13. Phase 5: Complete QA checks
14. Fix identified issues
15. Second round of testing

**Week 6: Finalization**
16. Phase 6: Create final deliverables
17. Final review and approval
18. Repository cleanup and organization

---

## Success Criteria

### Project Complete When

**Technical Requirements:**
- All dropdown field references converted to text
- All scripts function correctly with text fields
- No breaking changes to existing deployments
- All automated tests passing

**Documentation Requirements:**
- Every script has corresponding documentation
- All compound conditions documented with pseudo-code
- All diagrams reflect current state
- Complete index and reference suite exists
- 100% documentation coverage verified
- All quality checks passed

**Quality Requirements:**
- No broken links in any documentation
- All code examples tested and working
- Consistent formatting throughout
- Professional presentation quality
- All cross-references accurate

---

## Resource Estimates

### Time Estimates by Phase

| Phase | Estimated Hours | Complexity |
|-------|----------------|------------|
| Phase 1: Field Conversion | 4-6 hours | Medium |
| Phase 2: Documentation Audit & Creation | 6-8 hours | High |
| Phase 3: Diagram Updates | 2-3 hours | Medium |
| Phase 4: Comprehensive Suite | 4-6 hours | Medium |
| Phase 5: Quality Assurance | 2-3 hours | Low |
| Phase 6: Final Deliverables | 1-2 hours | Low |

**Total Estimated Effort:** 20-28 hours

### Required Tools

- PowerShell ISE or VS Code
- Git for version control
- Markdown editor
- Diagram creation tool (Draw.io, Mermaid, etc.)
- NinjaOne test instance
- Documentation review tools

---

## Risk Management

### Potential Risks

1. **Breaking Changes Risk**
   - Mitigation: Extensive testing before deployment
   - Backup: Version control and rollback procedures

2. **Documentation Drift Risk**
   - Mitigation: Include documentation in code review process
   - Control: Automated documentation validation

3. **Time Overrun Risk**
   - Mitigation: Phased approach allows adjustment
   - Buffer: 20-30% time buffer included

4. **Incomplete Coverage Risk**
   - Mitigation: Automated completeness checks
   - Validation: Multiple review passes

---

## Change Log

| Date | Version | Author | Changes |
|------|---------|--------|---------|
| 2026-02-03 | 1.0 | WAF Team | Initial action plan created |

---

## Approval and Sign-off

**Plan Reviewed By:** _______________  
**Date:** _______________  
**Approved By:** _______________  
**Date:** _______________

---

**END OF ACTION PLAN**
