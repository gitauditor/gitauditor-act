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

# Check for secrets configuration (environment and .secrets file)

check_secrets_file() {
    print_header "Checking Secrets Configuration"
    
    local secrets_file=".secrets"
    local gitauditor_token_ok=false
    local github_token_ok=false
    
    # Check GITAUDITOR_TOKEN
    if [[ -n "$GITAUDITOR_TOKEN" && "$GITAUDITOR_TOKEN" != "your_gitauditor_token_here" ]]; then
        print_success "GITAUDITOR_TOKEN found in environment"
        gitauditor_token_ok=true
    elif [[ -f "$secrets_file" ]] && grep -q "GITAUDITOR_TOKEN" "$secrets_file"; then
        local token_line=$(grep "GITAUDITOR_TOKEN" "$secrets_file")
        if [[ "$token_line" =~ GITAUDITOR_TOKEN=.+ && ! "$token_line" =~ your_gitauditor_token_here ]]; then
            print_success "GITAUDITOR_TOKEN found in $secrets_file"
            gitauditor_token_ok=true
        else
            print_warning "GITAUDITOR_TOKEN found in $secrets_file but appears to be placeholder"
        fi
    else
        print_warning "GITAUDITOR_TOKEN not configured"
        print_status "Set it via environment: export GITAUDITOR_TOKEN=your_token_here"
        print_status "Or add to $secrets_file: echo 'GITAUDITOR_TOKEN=your_token_here' > $secrets_file"
    fi
    
    # Check GITHUB_TOKEN (optional)
    if [[ -n "$GITHUB_TOKEN" && "$GITHUB_TOKEN" != "your_github_token_here" ]]; then
        print_success "GITHUB_TOKEN found in environment (optional)"
        github_token_ok=true
    elif [[ -f "$secrets_file" ]] && grep -q "GITHUB_TOKEN" "$secrets_file"; then
        local token_line=$(grep "GITHUB_TOKEN" "$secrets_file")
        if [[ "$token_line" =~ GITHUB_TOKEN=.+ && ! "$token_line" =~ your_github_token_here ]]; then
            print_success "GITHUB_TOKEN found in $secrets_file (optional)"
            github_token_ok=true
        fi
    fi
    
    # Show token hashes if any tokens are available
    local show_hashes=false
    local gitauditor_token_value=""
    local github_token_value=""
    
    # Get GITAUDITOR_TOKEN value (from environment or file)
    if [[ -n "$GITAUDITOR_TOKEN" && "$GITAUDITOR_TOKEN" != "your_gitauditor_token_here" ]]; then
        gitauditor_token_value="$GITAUDITOR_TOKEN"
        show_hashes=true
    elif [[ -f "$secrets_file" ]] && grep -q "GITAUDITOR_TOKEN" "$secrets_file"; then
        gitauditor_token_value=$(grep "GITAUDITOR_TOKEN" "$secrets_file" | cut -d'=' -f2-)
        if [[ -n "$gitauditor_token_value" && "$gitauditor_token_value" != "your_gitauditor_token_here" ]]; then
            show_hashes=true
        fi
    fi
    
    # Get GITHUB_TOKEN value (from environment or file)
    if [[ -n "$GITHUB_TOKEN" && "$GITHUB_TOKEN" != "your_github_token_here" ]]; then
        github_token_value="$GITHUB_TOKEN"
        show_hashes=true
    elif [[ -f "$secrets_file" ]] && grep -q "GITHUB_TOKEN" "$secrets_file"; then
        github_token_value=$(grep "GITHUB_TOKEN" "$secrets_file" | cut -d'=' -f2-)
        if [[ -n "$github_token_value" && "$github_token_value" != "your_github_token_here" ]]; then
            show_hashes=true
        fi
    fi
    
    # Show token verification hashes if any tokens are available
    if [[ "$show_hashes" = true ]]; then
        print_status ""
        print_status "Token verification hashes:"
        
        if [[ -n "$gitauditor_token_value" && "$gitauditor_token_value" != "your_gitauditor_token_here" ]]; then
            local full_hash=$(echo "$gitauditor_token_value" | shasum -a 256 | cut -d' ' -f1)
            print_status "  GITAUDITOR_TOKEN SHA256: $full_hash"
        fi
        
        if [[ -n "$github_token_value" && "$github_token_value" != "your_github_token_here" ]]; then
            local full_hash=$(echo "$github_token_value" | shasum -a 256 | cut -d' ' -f1)
            print_status "  GITHUB_TOKEN SHA256: $full_hash"
        fi
    fi
    
    # Summary and guidance
    if [[ "$gitauditor_token_ok" = true ]]; then
        print_success "GitAuditor token configured - ready for testing"
        return 0
    else
        print_error "GITAUDITOR_TOKEN not properly configured"
        print_status ""
        print_status "Setup options:"
        print_status "1. Environment variable: export GITAUDITOR_TOKEN=your_token_here"
        print_status "2. Create $secrets_file with: GITAUDITOR_TOKEN=your_token_here"
        if [[ ! -f "$secrets_file" ]]; then
            print_status "3. Copy template: cp .secrets.example $secrets_file"
        fi
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


# Detect the best event for a workflow
detect_workflow_event() {
    local workflow_file="$1"
    
    # Check for workflow_dispatch (preferred for testing)
    if grep -q "workflow_dispatch:" "$workflow_file"; then
        echo "workflow_dispatch"
    # Check for pull_request
    elif grep -q "pull_request:" "$workflow_file"; then
        echo "pull_request"
    # Check for push
    elif grep -q "push:" "$workflow_file"; then
        echo "push"
    # Default to push if nothing else found
    else
        echo "push"
    fi
}

# Generate SHA256 hash of a token for display
hash_token() {
    local token="$1"
    if [[ -n "$token" ]]; then
        echo "$token" | shasum -a 256 | cut -d' ' -f1 | cut -c1-8
    else
        echo "none"
    fi
}

# Build secrets arguments for act command
build_secrets_args() {
    local secrets_args=""
    
    # Add environment variables as secrets
    if [[ -n "$GITAUDITOR_TOKEN" && "$GITAUDITOR_TOKEN" != "your_gitauditor_token_here" ]]; then
        secrets_args="$secrets_args --secret GITAUDITOR_TOKEN=\"$GITAUDITOR_TOKEN\""
    fi
    
    if [[ -n "$GITHUB_TOKEN" && "$GITHUB_TOKEN" != "your_github_token_here" ]]; then
        secrets_args="$secrets_args --secret GITHUB_TOKEN=\"$GITHUB_TOKEN\""
    fi
    
    # Add .secrets file if it exists (act will merge with individual secrets)
    if [[ -f ".secrets" ]]; then
        secrets_args="$secrets_args --secret-file .secrets"
    fi
    
    echo "$secrets_args"
}

# Build display version of secrets args with hashed tokens
build_secrets_args_display() {
    local secrets_args=""
    
    # Add environment variables as secrets with hashed values
    if [[ -n "$GITAUDITOR_TOKEN" && "$GITAUDITOR_TOKEN" != "your_gitauditor_token_here" ]]; then
        local hash=$(hash_token "$GITAUDITOR_TOKEN")
        secrets_args="$secrets_args --secret GITAUDITOR_TOKEN=\"sha256:$hash...\""
    fi
    
    if [[ -n "$GITHUB_TOKEN" && "$GITHUB_TOKEN" != "your_github_token_here" ]]; then
        local hash=$(hash_token "$GITHUB_TOKEN")
        secrets_args="$secrets_args --secret GITHUB_TOKEN=\"sha256:$hash...\""
    fi
    
    # Add .secrets file if it exists
    if [[ -f ".secrets" ]]; then
        secrets_args="$secrets_args --secret-file .secrets"
    fi
    
    echo "$secrets_args"
}


# Run workflow dry-run
run_workflow_dry_run() {
    local workflow_name="$1"
    local workflow_file=".github/workflows/${workflow_name}.yml"
    
    if [[ ! -f "$workflow_file" ]]; then
        print_error "Workflow file not found: $workflow_file"
        return 1
    fi
    
    # Detect the best event to use for this workflow
    local event=$(detect_workflow_event "$workflow_file")
    
    # Build secrets arguments (actual and display versions)
    local secrets_args=$(build_secrets_args)
    local secrets_args_display=$(build_secrets_args_display)
    
    print_header "Running Dry-Run for: $workflow_name"
    print_status "Detected event type: $event"
    
    # Show token sources with hashes
    if [[ -n "$GITAUDITOR_TOKEN" && "$GITAUDITOR_TOKEN" != "your_gitauditor_token_here" ]]; then
        local hash=$(hash_token "$GITAUDITOR_TOKEN")
        print_status "Using GITAUDITOR_TOKEN from environment (sha256:$hash...)"
    fi
    if [[ -n "$GITHUB_TOKEN" && "$GITHUB_TOKEN" != "your_github_token_here" ]]; then
        local hash=$(hash_token "$GITHUB_TOKEN")
        print_status "Using GITHUB_TOKEN from environment (sha256:$hash...)"
    fi
    if [[ -f ".secrets" ]]; then
        print_status "Using additional secrets from .secrets file"
    fi
    
    print_status "Executing: act $event --dryrun -W \"$workflow_file\" $secrets_args_display"
    
    # Run act with dry-run flag for detected event and collected secrets
    if eval "act \"$event\" --dryrun -W \"$workflow_file\" $secrets_args" 2>&1; then

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
    local has_some_token=false
    
    if ! check_secrets_file; then
        secrets_ok=false
        # Check if we at least have GITHUB_TOKEN for basic testing
        if [[ -n "$GITHUB_TOKEN" && "$GITHUB_TOKEN" != "your_github_token_here" ]]; then
            has_some_token=true
            print_warning "GITAUDITOR_TOKEN missing but GITHUB_TOKEN available for basic testing"
        else
            print_warning "No tokens configured - workflows may fail"
        fi

    fi
    
    # Step 3: List workflows
    if ! list_workflows; then
        exit 1
    fi
    
    # Step 4: Direct workflow testing (no redundant question)
    echo ""
    if [[ "$secrets_ok" = false && "$has_some_token" = false ]]; then
        print_warning "Testing without any tokens may cause failures"
        read -p "Continue anyway? (y/n): " continue_choice
        case "$continue_choice" in
            y|Y|yes|YES) ;;
            *) print_status "Exiting..."; exit 0 ;;
        esac
    fi
    
    select_workflow

    
    print_success "Script completed!"
}

# Run main function
main "$@"