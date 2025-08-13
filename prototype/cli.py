import argparse
import sys

from . import VERSION
from . import subcommands
from .lib.errors import FableError


def run():
    args = _parse_args()

    if args.version:
        print(VERSION)
        return

    try:
        if args.subcommand:
            args.run_subcommand()
        else:
            _run_status()
    except FableError as e:
        print(f"Error: {e}.", file=sys.stderr)


def _parse_args():
    parser = argparse.ArgumentParser(
        prog="fable",
        description="The VCS for storytelling",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    )
    parser.add_argument("--version", action="store_true")

    subparsers = parser.add_subparsers(
        title="subcommands",
        description="valid subcommands",
        dest="subcommand",
    )

    _add_init_subparser(subparsers)
    _add_status_subparser(subparsers)
    _add_tree_subparser(subparsers)
    _add_weave_subparser(subparsers)

    return parser.parse_args()


def _run_init():
    subcommands.init.run_subcommand()


def _add_init_subparser(subparsers):
    subparser = subparsers.add_parser(
        "init",
        help="Create a new repository",
    )

    subparser.set_defaults(run_subcommand=_run_init)


def _run_status():
    subcommands.status.run_subcommand()


def _add_status_subparser(subparsers):
    subparser = subparsers.add_parser(
        "status",
        aliases=["s"],
        help="Show repository status",
    )

    subparser.set_defaults(run_subcommand=_run_status)


def _run_tree():
    subcommands.tree.run_subcommand()


def _add_tree_subparser(subparsers):
    subparser = subparsers.add_parser(
        "tree",
        aliases=["t"],
        help="Show patch tree",
    )

    subparser.set_defaults(run_subcommand=_run_tree)


def _run_weave():
    subcommands.weave.run_subcommand()


def _add_weave_subparser(subparsers):
    subparser = subparsers.add_parser(
        "weave",
        aliases=["w"],
        help="Show documentation based on patch tree",
    )

    subparser.set_defaults(run_subcommand=_run_weave)
