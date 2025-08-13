import argparse

from . import VERSION
from .subcommands import init


def run():
    args = _parse_args()

    if args.version:
        print(VERSION)
        return

    if args.subcommand:
        args.run_subcommand()
    else:
        _run_status()


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

    return parser.parse_args()


def _run_init():
    init.run_subcommand()


def _add_init_subparser(subparsers):
    subparser = subparsers.add_parser(
        "init",
        help="Create a new repository",
    )

    subparser.set_defaults(run_subcommand=_run_init)


def _run_status():
    raise NotImplementedError


def _add_status_subparser(subparsers):
    subparser = subparsers.add_parser(
        "status",
        aliases=["s"],
        help="Show repository status",
    )

    subparser.set_defaults(run_subcommand=_run_status)
