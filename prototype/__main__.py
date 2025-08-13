from .git import run


output = run("git", "status")
print(output, end='')
