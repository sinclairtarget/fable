import subprocess


def run(subcommand, *args):
    args = [*args]
    completed = subprocess.run(
        ["git", subcommand] + args,
        check=True,
        capture_output=True,
        text=True,
    )

    return completed.stdout
