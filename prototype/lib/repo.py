from pathlib import Path
import sys

from . import git
from .errors import NotInitializedError


FABLE_DB_DIRNAME = ".fable"


def create():
    fable_db_path = Path(FABLE_DB_DIRNAME)
    if fable_db_path.exists():
        print(
            "Warning: Fable repository already exists. Doing nothing.",
            file=sys.stderr,
        )
        return

    git_db_path = Path(".git")
    if not git_db_path.exists():
        git.run("init")

    fable_db_path.mkdir()
    keep_file_path = fable_db_path / ".keep"
    keep_file_path.touch()

    git.run("add", ".fable/")
    git.run("commit", "-m", "Root Fable commit.")


def status():
    fable_db_path = Path(FABLE_DB_DIRNAME)
    if not fable_db_path.exists():
        raise NotInitializedError

    print("ok")
