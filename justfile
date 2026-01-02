# MWAA Local Runner Commands

# Default recipe - show available commands
default:
    @just --list

# Project name for docker compose
project := "aws-mwaa-local-runner-2_10_3"
compose_file := "./docker/docker-compose-local.yml"
override_file := "./docker/docker-compose-local.override.yml"

# =============================================================================
# First-Time Setup
# =============================================================================

# First-time setup for new teammates
setup:
    @echo "🚀 Setting up MWAA local runner..."
    @echo ""
    @# Create personal env config from template
    @if [ ! -f docker/config/.env.localrunner ]; then \
        cp docker/config/.env.example docker/config/.env.localrunner; \
        echo "✅ Created docker/config/.env.localrunner from template"; \
    else \
        echo "⏭️  docker/config/.env.localrunner already exists"; \
    fi
    @# Create personal DAG mounts from template
    @if [ ! -f docker/docker-compose-local.override.yml ]; then \
        cp docker/docker-compose-local.override.example.yml docker/docker-compose-local.override.yml; \
        echo "✅ Created docker/docker-compose-local.override.yml from template"; \
    else \
        echo "⏭️  docker/docker-compose-local.override.yml already exists"; \
    fi
    @echo ""
    @just setup-zscaler
    @echo ""
    @echo "📝 Next steps:"
    @echo "   1. Edit docker/config/.env.localrunner with your personal values:"
    @echo "      - PIPELINE_AWS_PROFILE (your AWS SSO profile name)"
    @echo "      - AWS_PROFILE (same as above)"
    @echo "      - SNOWFLAKE_USERNAME (your email)"
    @echo ""
    @echo "   2. Edit docker/docker-compose-local.override.yml to mount your DAGs"
    @echo ""
    @echo "   3. Run: just sso-login"
    @echo "   4. Run: just build"
    @echo "   5. Run: just start"

# Export Zscaler certificate for SSL in Docker
setup-zscaler:
    @echo "🔐 Setting up Zscaler certificate..."
    @if security find-certificate -a -c "Zscaler" -p /Library/Keychains/System.keychain > docker/config/zscaler-root-ca.crt 2>/dev/null; then \
        echo "✅ Zscaler certificate exported to docker/config/zscaler-root-ca.crt"; \
    else \
        echo "⚠️  No Zscaler certificate found (OK if not on corporate network)"; \
        rm -f docker/config/zscaler-root-ca.crt; \
    fi

# =============================================================================
# Build & Run
# =============================================================================

# Build the MWAA local runner image
build:
    ./mwaa-local-env build-image

# Helper to build compose command with optional override file
[private]
compose *args:
    #!/usr/bin/env bash
    if [ -f {{override_file}} ]; then
        docker compose -p {{project}} -f {{compose_file}} -f {{override_file}} {{args}}
    else
        echo "⚠️  No override file found. Run 'just setup' first to create one."
        echo "   Or create manually: cp docker/docker-compose-local.override.example.yml docker/docker-compose-local.override.yml"
        exit 1
    fi

# Start the local runner (includes postgres)
start:
    @just compose up -d

# Stop the local runner
stop:
    @just compose down

# Restart the local runner (picks up env file changes)
restart:
    @just compose up -d --force-recreate local-runner
    @echo "Waiting for Airflow to start..."
    @sleep 15
    @echo "Ready at http://localhost:8080"

# Quick restart (no recreate, just restart)
restart-quick:
    @just compose restart local-runner
    @echo "Waiting for Airflow to start..."
    @sleep 10
    @echo "Ready at http://localhost:8080"

# View logs from the local runner
logs:
    @just compose logs -f local-runner

# Reset database and restart fresh
reset:
    @just compose down
    rm -rf db-data
    @just compose up -d

# Open Airflow UI in browser
open:
    open http://localhost:8080

# Shell into the running container
shell:
    docker exec -it {{project}}-local-runner-1 bash

# Check container status
status:
    @just compose ps

# AWS SSO login (run before starting if session expired)
sso-login profile="siham-dev":
    aws sso login --profile {{profile}}

# Get a secret from AWS Secrets Manager
get-secret secret_name profile="siham-dev":
    aws secretsmanager get-secret-value --secret-id {{secret_name}} --profile {{profile}} --query SecretString --output text | jq .

