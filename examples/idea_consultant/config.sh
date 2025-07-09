#!/bin/bash
# Configuration for Idea Consultant
# This file demonstrates how to externalize configuration from pattern implementation

# LLM Settings
export LLM_COMMAND="${LLM_COMMAND:-claude -p}"
export LLM_TIMEOUT=30

# Pattern Settings
export MAX_ITERATIONS="${MAX_ITERATIONS:-10}"
export MIN_ITERATIONS="${MIN_ITERATIONS:-3}"
export CONFIDENCE_THRESHOLD="${CONFIDENCE_THRESHOLD:-80}"

# Canvas Elements
# Add or remove elements by modifying this array
export CANVAS_ELEMENTS=(
  "problem"
  "solution"
  "target_audience"
  "unique_value"
  "monetization"
  "competition"
)

# Output Settings
export OUTPUT_FORMAT="${OUTPUT_FORMAT:-json}"  # json|markdown|both
export SAVE_INTERMEDIATE="${SAVE_INTERMEDIATE:-false}"
export OUTPUT_DIR="${OUTPUT_DIR:-.}"

# UI Settings
export USE_COLORS="${USE_COLORS:-true}"
export SHOW_ANALYSIS="${SHOW_ANALYSIS:-true}"
export SHOW_CANVAS="${SHOW_CANVAS:-true}"

# Advanced Settings
export RETRY_ON_ERROR="${RETRY_ON_ERROR:-true}"
export MAX_RETRIES="${MAX_RETRIES:-3}"
export RETRY_DELAY="${RETRY_DELAY:-2}"

# Logging
export LOG_LEVEL="${LOG_LEVEL:-INFO}"  # DEBUG|INFO|WARN|ERROR
export LOG_FILE="${LOG_FILE:-}"  # Empty means no logging to file

# Feature Flags
export ENABLE_SAVE_RESUME="${ENABLE_SAVE_RESUME:-false}"
export ENABLE_MULTI_ADVISOR="${ENABLE_MULTI_ADVISOR:-false}"
export ENABLE_WEB_RESEARCH="${ENABLE_WEB_RESEARCH:-false}"