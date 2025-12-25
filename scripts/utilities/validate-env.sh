#!/bin/bash

echo "⚙️  Validating environment configuration..."

ENV_FILE="$(dirname "$0")/../../docker/.env"

if [ ! -f "${ENV_FILE}" ]; then
    echo "❌ .env file not found at ${ENV_FILE}"
    echo "   Create from template: cp docker/.env.example docker/.env"
    exit 1
fi

echo "✅ .env file exists"
echo ""

# Check required variables
required_vars=(
    "JWT_SECRET"
)

all_valid=true

for var in "${required_vars[@]}"; do
    value=$(grep "^${var}=" "${ENV_FILE}" | cut -d '=' -f2-)
    
    if [ -z "${value}" ]; then
        echo "⚠️  ${var} is not set"
        all_valid=false
    elif [ "${var}" = "JWT_SECRET" ] && [ "${value}" = "dev-secret-change-in-production" ]; then
        echo "⚠️  ${var} is using default value (should be changed for production)"
    else
        echo "✅ ${var} is set"
    fi
done

echo ""

# Check optional variables
echo "Optional variables:"
optional_vars=(
    "SMTP_HOST"
    "SMTP_USERNAME"
    "SMTP_PASSWORD"
    "GRAFANA_PASSWORD"
)

for var in "${optional_vars[@]}"; do
    value=$(grep "^${var}=" "${ENV_FILE}" | cut -d '=' -f2-)
    
    if [ -z "${value}" ]; then
        echo "ℹ️  ${var} is not set (optional)"
    else
        echo "✅ ${var} is set"
    fi
done

echo ""

if [ "$all_valid" = true ]; then
    echo "✅ Environment configuration is valid"
    exit 0
else
    echo "⚠️  Please review and update ${ENV_FILE}"
    exit 1
fi
