#!/bin/sh

echo "Running startup script..."

# =============================================================================
# Sync shared files from dp_airflow_pipelines
# =============================================================================
if [ -d /usr/local/airflow/dp_source_dags ]; then
    echo "Syncing shared files from dp_airflow_pipelines..."
    
    # Copy constants.py (used by many DAGs)
    if [ -f /usr/local/airflow/dp_source_dags/constants.py ]; then
        cp /usr/local/airflow/dp_source_dags/constants.py /usr/local/airflow/dags/constants.py
        echo "  ✓ constants.py"
    fi
    
    # Copy __init__.py if it exists
    if [ -f /usr/local/airflow/dp_source_dags/__init__.py ]; then
        cp /usr/local/airflow/dp_source_dags/__init__.py /usr/local/airflow/dags/__init__.py
        echo "  ✓ __init__.py"
    fi
    
    echo "Sync complete."
else
    echo "Warning: dp_source_dags not mounted. Some imports may fail."
fi

# =============================================================================
# Install requirements from dp_airflow_pipelines (if mounted)
# =============================================================================
if [ -d /usr/local/airflow/dp_requirements ]; then
    echo "Installing requirements from dp_airflow_pipelines..."
    
    # Install MWAA requirements (main dependencies)
    if [ -f /usr/local/airflow/dp_requirements/mwaa-requirements.txt ]; then
        pip install --quiet --no-cache-dir -r /usr/local/airflow/dp_requirements/mwaa-requirements.txt
        echo "  ✓ mwaa-requirements.txt"
    fi
    
    echo "Requirements installed."
else
    echo "Warning: dp_requirements not mounted. Using local requirements only."
fi
