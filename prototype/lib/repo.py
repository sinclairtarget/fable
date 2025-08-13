from pathlib import Path

from . import git


def create():
    fable_db_path = Path(".fable")
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
