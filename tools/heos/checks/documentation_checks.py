"""Documentation freshness checks."""

from pathlib import Path


# Reuse from structure_checks
from .structure_checks import file_exists, file_not_empty, any_file_exists, directory_not_empty

__all__ = ["file_exists", "file_not_empty", "any_file_exists", "directory_not_empty"]
