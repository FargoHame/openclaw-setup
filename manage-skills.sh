#!/bin/bash
set -e

# Secure Skill Management for OpenClaw
# Audits and installs skills safely

echo "=== OpenClaw Skill Manager ==="
echo ""

# Function to audit a skill
audit_skill() {
    local skill_name=$1
    local skill_path="$HOME/.openclaw/skills/$skill_name"
    
    if [ ! -d "$skill_path" ]; then
        echo "ERROR: Skill not found: $skill_name"
        return 1
    fi
    
    echo "Auditing skill: $skill_name"
    echo "Location: $skill_path"
    echo ""
    
    # Check for suspicious patterns
    echo "Security scan:"
    
    # Check for shell execution
    if grep -r "exec\|spawn\|system" "$skill_path" --include="*.js" --include="*.ts" 2>/dev/null; then
        echo "⚠ WARNING: Found shell execution code"
    fi
    
    # Check for network calls
    if grep -r "fetch\|axios\|request\|http\." "$skill_path" --include="*.js" --include="*.ts" 2>/dev/null; then
        echo "⚠ INFO: Found network calls"
    fi
    
    # Check for file system access
    if grep -r "fs\.\|readFile\|writeFile" "$skill_path" --include="*.js" --include="*.ts" 2>/dev/null; then
        echo "⚠ INFO: Found filesystem access"
    fi
    
    # Check for eval
    if grep -r "eval(" "$skill_path" --include="*.js" --include="*.ts" 2>/dev/null; then
        echo "⚠ DANGER: Found eval() - high security risk"
    fi
    
    echo ""
    echo "Skill code preview:"
    find "$skill_path" -name "*.js" -o -name "*.ts" | head -n 1 | while read -r file; do
        echo "File: $file"
        head -n 20 "$file"
    done
    
    echo ""
}

# Function to install skill securely
install_skill() {
    local skill_id=$1
    
    echo "Installing skill: $skill_id"
    echo ""
    
    # Create temporary directory for inspection
    TEMP_DIR=$(mktemp -d)
    trap "rm -rf $TEMP_DIR" EXIT
    
    # Install to temp location first
    echo "Downloading to temporary location for inspection..."
    cd "$TEMP_DIR"
    npm pack "$skill_id"
    
    # Extract and inspect
    tar -xzf *.tgz
    
    echo ""
    echo "=== SECURITY REVIEW REQUIRED ==="
    echo "Package contents:"
    find package -type f
    
    echo ""
    read -p "Review the code in: $TEMP_DIR/package. Continue with installation? [y/N] " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        openclaw skill install "$skill_id"
        echo "Skill installed: $skill_id"
        
        # Extract skill name from package
        SKILL_NAME=$(echo "$skill_id" | sed 's|@.*/||' | sed 's|^skill-||')
        audit_skill "$SKILL_NAME"
    else
        echo "Installation cancelled"
    fi
}

# Main menu
echo "Choose action:"
echo "1) List installed skills"
echo "2) Audit an installed skill"
echo "3) Install new skill (with security review)"
echo "4) Remove a skill"
echo "5) Audit all installed skills"
echo ""
read -p "Selection [1-5]: " ACTION

case $ACTION in
    1)
        echo ""
        openclaw skill list
        ;;
    2)
        echo ""
        read -p "Skill name to audit: " SKILL_NAME
        audit_skill "$SKILL_NAME"
        ;;
    3)
        echo ""
        echo "Examples:"
        echo "  @openclaw/skill-gmail"
        echo "  @openclaw/skill-calendar"
        echo "  @openclaw/skill-todoist"
        echo ""
        read -p "Skill package to install: " SKILL_PKG
        install_skill "$SKILL_PKG"
        ;;
    4)
        echo ""
        openclaw skill list
        echo ""
        read -p "Skill name to remove: " SKILL_NAME
        openclaw skill remove "$SKILL_NAME"
        echo "Skill removed: $SKILL_NAME"
        ;;
    5)
        echo ""
        SKILLS_DIR="$HOME/.openclaw/skills"
        if [ -d "$SKILLS_DIR" ]; then
            for skill_dir in "$SKILLS_DIR"/*; do
                if [ -d "$skill_dir" ]; then
                    SKILL_NAME=$(basename "$skill_dir")
                    echo "================================"
                    audit_skill "$SKILL_NAME"
                    echo ""
                fi
            done
        else
            echo "No skills directory found"
        fi
        ;;
    *)
        echo "Invalid selection"
        exit 1
        ;;
esac

echo ""
echo "=== Recommended Minimal Skills ==="
echo ""
echo "For personal assistant use case:"
echo "  @openclaw/skill-gmail       - Email management"
echo "  @openclaw/skill-calendar    - Calendar integration"
echo "  @openclaw/skill-notes       - Note-taking"
echo "  @openclaw/skill-todoist     - Task management"
echo ""
echo "Install ONLY what you need. Each skill increases attack surface."
