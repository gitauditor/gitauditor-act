#!/bin/bash

# GitAuditor Action Workflow Testing Script
# This script checks for 'act' installation, validates secrets, and runs workflow dry-runs

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "\n${BLUE}=== $1 ===${NC}\n"
}

# Detect OS
detect_os() {
    case "$(uname -s)" in
        Darwin*)    echo "macos" ;;
        Linux*)     echo "linux" ;;
        *)          echo "unsupported" ;;
    esac
}

# Check if act is installed
check_act_installation() {
    print_header "Checking act Installation"
    
    if command -v act &> /dev/null; then
        local act_version=$(act --version 2>/dev/null || echo "unknown")
        print_success "act is installed: $act_version"
        return 0
    else
        print_error "act is not installed"
        
        local os=$(detect_os)
        case $os in
            "macos")
                print_status "To install act on macOS, run:"
                echo "  brew install act"
                ;;
            "linux")
                print_status "To install act on Linux, run:"
                echo "  # Using Homebrew (recommended):"
                echo "  brew install act"
                echo ""
                echo "  # Or using curl:"
                echo "  curl https://raw.githubusercontent.com/nektos/act/master/install.sh | sudo bash"
                ;;
            *)
                print_error "Unsupported operating system: $(uname -s)"
                print_status "Please visit https://github.com/nektos/act for installation instructions"
                ;;
        esac
        
        return 1
    fi
}

# Check for .secrets file
check_secrets_file() {
    print_header "Checking Secrets Configuration"
    
    local secrets_file=".secrets"
    
    if [[ -f "$secrets_file" ]]; then
        print_success "Found $secrets_file"
        
        # Check if GITAUDITOR_TOKEN is present
        if grep -q "GITAUDITOR_TOKEN" "$secrets_file"; then
            print_success "GITAUDITOR_TOKEN found in $secrets_file"
            
            # Check if token is not empty
            local token_line=$(grep "GITAUDITOR_TOKEN" "$secrets_file")
            if [[ "$token_line" =~ GITAUDITOR_TOKEN=.+ ]]; then
                print_success "GITAUDITOR_TOKEN appears to have a value"
            else
                print_warning "GITAUDITOR_TOKEN found but appears to be empty"
                print_status "Please ensure your token has a value: GITAUDITOR_TOKEN=your_token_here"
            fi
        else
            print_warning "GITAUDITOR_TOKEN not found in $secrets_file"
            print_status "Please add your GitAuditor token to $secrets_file:"
            echo "  GITAUDITOR_TOKEN=your_token_here"
        fi
        
        return 0
    else
        print_error "$secrets_file not found"
        print_status "Create $secrets_file with your GitAuditor token:"
        echo "  echo 'GITAUDITOR_TOKEN=your_token_here' > $secrets_file"
        print_warning "Make sure to add $secrets_file to .gitignore to avoid committing secrets!"
        
        return 1
    fi
}

# List available workflows
list_workflows() {
    print_header "Available Test Workflows"
    
    local workflow_dir=".github/workflows"
    if [[ -d "$workflow_dir" ]]; then
        print_status "Found example workflows for testing:"
        local found_example=false
        for workflow in "$workflow_dir"/example-*.yml; do
            if [[ -f "$workflow" ]]; then
                local name=$(basename "$workflow" .yml)
                echo "  - $name"
                found_example=true
            fi
        done
        
        if [[ "$found_example" = false ]]; then
            print_warning "No example workflows found (looking for example-*.yml files)"
            print_status "All workflows in directory:"
            for workflow in "$workflow_dir"/*.yml; do
                if [[ -f "$workflow" ]]; then
                    local name=$(basename "$workflow" .yml)
                    echo "  - $name (CI workflow - not for local testing)"
                fi
            done
            return 1
        fi
    else
        print_error "No .github/workflows directory found"
        return 1
    fi
}

# Run workflow dry-run
run_workflow_dry_run() {
    local workflow_name="$1"
    local workflow_file=".github/workflows/${workflow_name}.yml"
    
    if [[ ! -f "$workflow_file" ]]; then
        print_error "Workflow file not found: $workflow_file"
        return 1
    fi
    
    print_header "Running Dry-Run for: $workflow_name"
    
    print_status "Executing: act --dry-run -W \"$workflow_file\""
    
    # Run act with dry-run flag
    if act --dry-run -W "$workflow_file" --secret-file .secrets 2>&1; then
        print_success "Dry-run completed successfully for $workflow_name"
        return 0
    else
        print_error "Dry-run failed for $workflow_name"
        return 1
    fi
}

# Interactive workflow selection
select_workflow() {
    local workflows=()
    local workflow_dir=".github/workflows"
    
    # Build array of example workflow names only
    for workflow in "$workflow_dir"/example-*.yml; do
        if [[ -f "$workflow" ]]; then
            local name=$(basename "$workflow" .yml)
            workflows+=("$name")
        fi
    done
    
    if [[ ${#workflows[@]} -eq 0 ]]; then
        print_error "No example workflows found for testing"
        print_status "Looking for workflows matching pattern: example-*.yml"
        return 1
    fi
    
    echo "Select a workflow to test:"
    for i in "${!workflows[@]}"; do
        echo "  $((i+1)). ${workflows[i]}"
    done
    echo "  $((${#workflows[@]}+1)). Test all workflows"
    echo "  q. Quit"
    
    read -p "Enter your choice: " choice
    
    case "$choice" in
        q|Q)
            print_status "Exiting..."
            return 1
            ;;
        $((${#workflows[@]}+1)))
            print_status "Testing all workflows..."
            for workflow in "${workflows[@]}"; do
                run_workflow_dry_run "$workflow"
                echo ""
            done
            ;;
        *)
            if [[ "$choice" -ge 1 ]] && [[ "$choice" -le ${#workflows[@]} ]]; then
                local selected_workflow="${workflows[$((choice-1))]}"
                run_workflow_dry_run "$selected_workflow"
            else
                print_error "Invalid choice: $choice"
                return 1
            fi
            ;;
    esac
}

# Main function
main() {
    print_header "GitAuditor Action Workflow Testing"
    
    print_status "Operating System: $(uname -s) $(uname -m)"
    print_status "Current Directory: $(pwd)"
    
    # Step 1: Check act installation
    if ! check_act_installation; then
        print_error "Please install act before continuing"
        exit 1
    fi
    
    # Step 2: Check secrets file
    local secrets_ok=true
    if ! check_secrets_file; then
        secrets_ok=false
        print_warning "Continuing without proper secrets configuration"
        print_warning "Some workflows may fail without proper GITAUDITOR_TOKEN"
    fi
    
    # Step 3: List workflows
    if ! list_workflows; then
        exit 1
    fi
    
    # Step 4: Interactive workflow testing
    echo ""
    read -p "Would you like to test workflows? (y/n): " test_choice
    
    case "$test_choice" in
        y|Y|yes|YES)
            if [[ "$secrets_ok" = false ]]; then
                print_warning "Testing without proper secrets may cause failures"
                read -p "Continue anyway? (y/n): " continue_choice
                case "$continue_choice" in
                    y|Y|yes|YES) ;;
                    *) print_status "Exiting..."; exit 0 ;;
                esac
            fi
            
            select_workflow
            ;;
        *)
            print_status "Skipping workflow testing"
            ;;
    esac
    
    print_success "Script completed!"
}

# Run main function
main "$@"