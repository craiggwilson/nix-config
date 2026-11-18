#!@PYTHON@
"""Guarded, Jujutsu-native bridge to Graphite's gt CLI."""

import argparse
import json
import re
import shlex
import subprocess
import sys
from dataclasses import dataclass

JJ_BIN = "@JUJUTSU@"
GT_BIN = "@GRAPHITE@"

CHANGE_ID = re.compile(r"^[a-z0-9]{32}$")


def commit_template(private_revset="none()", signing_revset="none()"):
    return f"""json({{
  "change_id" => change_id,
  "commit_id" => commit_id,
  "description" => description,
  "empty" => empty,
  "conflict" => conflict,
  "divergent" => divergent,
  "private" => self.contained_in({json.dumps(private_revset or "none()")}),
  "mine" => mine,
  "parent_commits" => parents.map(|p| p.commit_id()),
  "bookmarks" => local_bookmarks.map(|b| b.name()),
  "sign_required" => self.contained_in({json.dumps(signing_revset or "none()")}),
  "signed" => self.contained_in("signed()")
}}) ++ "\\n"
"""


COMMIT_TEMPLATE = commit_template()

DESCRIPTION = """Submit Jujutsu changes through a guarded Graphite bridge.

Graphite uses the repository's configured origin for both the remote branch and
pull-request destination. The wrapper never selects or changes that remote.
Only the commands and flags shown below are accepted; all other gt operations
are intentionally blocked. A dry run reads previously captured JJ state without
snapshotting @ and prints planned commands without invoking jj mutations or gt.
Bypassing this wrapper by invoking the underlying binary directly is outside
its guard.
"""


class Failure(Exception):
    """A user-facing failure with a process exit status."""

    def __init__(self, message, status=1):
        super().__init__(message)
        self.status = status


class Parser(argparse.ArgumentParser):
    def __init__(self, *args, **kwargs):
        kwargs.setdefault("allow_abbrev", False)
        super().__init__(*args, **kwargs)

    def error(self, message):
        raise Failure(f"{self.prog}: {message}", 2)


@dataclass(frozen=True)
class Commit:
    bookmarks: tuple
    change_id: str
    commit_id: str
    conflict: bool
    description: str
    divergent: bool
    empty: bool
    mine: bool
    parent_commits: tuple
    private: bool
    sign_required: bool
    signed: bool


@dataclass(frozen=True)
class PlannedChange:
    branch: str
    change_id: str
    commit_id: str
    create: bool
    parent: str


@dataclass(frozen=True)
class Plan:
    changes: tuple
    trunk: Commit
    trunk_name: str


class Bridge:
    """Execute guarded commands; test construction may inject both binaries."""

    def __init__(self, jj_path=JJ_BIN, gt_path=GT_BIN):
        self.jj_path = jj_path
        self.gt_path = gt_path

    def execute(self, argv):
        parser = self._parser()
        try:
            if argv in (["--version"], ["version"]):
                return self._gt(["--version"])
            args = parser.parse_args(argv)
            if args.command == "help":
                parser.print_help()
                return 0
            if args.command == "auth":
                return self._gt(["auth", "--token", args.token])
            if args.command == "log":
                return self._gt(["log"])
            if args.command in ("push", "submit"):
                return self._push(args.revset, args.dry_run, args.publish)
            if args.command in ("pr", "info"):
                return self._read_branch(args.command, args.revset)
            raise Failure(f"unsupported command: {args.command}", 2)
        except Failure as error:
            print(f"jj-gt: {error}", file=sys.stderr)
            return error.status
        except SystemExit as exit_error:
            return int(exit_error.code or 0)

    def _parser(self):
        parser = Parser(prog="jj-gt", description=DESCRIPTION, formatter_class=argparse.RawDescriptionHelpFormatter)
        commands = parser.add_subparsers(dest="command", required=True)
        commands.add_parser("help", help="show this guarded command reference")

        auth = commands.add_parser("auth", help="configure Graphite authentication")
        auth.add_argument("--token", required=True, action=_Once, type=_nonempty)

        for name in ("push", "submit"):
            push = commands.add_parser(name, help="submit the selected linear JJ stack")
            push.add_argument("-r", dest="revset", action=_Once, type=_nonempty, metavar="REVSET")
            push.add_argument("--dry-run", action="store_true")
            visibility = push.add_mutually_exclusive_group()
            visibility.add_argument("--draft", action="store_true", help="create new PRs as drafts (default)")
            visibility.add_argument("--publish", action="store_true", help="publish PRs explicitly")

        commands.add_parser("log", help="show Graphite's tracked-branch log")
        for name in ("pr", "info"):
            read = commands.add_parser(name, help=f"show the selected change's Graphite {name}")
            read.add_argument("-r", dest="revset", action=_Once, type=_nonempty, metavar="REVSET")
        return parser

    @staticmethod
    def _run_process(command, **kwargs):
        try:
            return subprocess.run(command, **kwargs)
        except OSError as error:
            raise Failure(f"cannot execute {command[0]}: {error}") from error

    def _jj(self, args, snapshot):
        command = [self.jj_path, "--color=never", "--no-pager"]
        if not snapshot:
            command.append("--ignore-working-copy")
        result = self._run_process(command + args, text=True, capture_output=True, check=False)
        if result.returncode:
            detail = result.stderr.strip() or result.stdout.strip()
            raise Failure(f"jj {args[0]} failed: {detail}")
        return result.stdout

    def _config_get(self, name, snapshot):
        command = [self.jj_path, "--color=never", "--no-pager"]
        if not snapshot:
            command.append("--ignore-working-copy")
        result = self._run_process(
            command + ["config", "get", name],
            text=True,
            capture_output=True,
            check=False,
        )
        if result.returncode:
            if "Value not found for" in result.stderr:
                return "none()"
            detail = result.stderr.strip() or result.stdout.strip()
            raise Failure(f"cannot read jj setting {name}: {detail}")
        return result.stdout.strip() or "none()"

    def _commits(self, revset, snapshot, private_revset="none()", signing_revset="none()"):
        output = self._jj(
            [
                "log",
                "--no-graph",
                "-r",
                revset,
                "-T",
                commit_template(private_revset, signing_revset),
            ],
            snapshot,
        )
        commits = []
        for line in output.splitlines():
            if not line.strip():
                continue
            value = json.loads(line)
            commits.append(
                Commit(
                    bookmarks=tuple(value["bookmarks"]),
                    change_id=value["change_id"],
                    commit_id=value["commit_id"],
                    conflict=value["conflict"],
                    description=value["description"],
                    divergent=value["divergent"],
                    empty=value["empty"],
                    mine=value["mine"],
                    parent_commits=tuple(value["parent_commits"]),
                    private=value["private"],
                    sign_required=value["sign_required"],
                    signed=value["signed"],
                )
            )
        return commits

    def _require_colocated(self, snapshot):
        status = self._jj(["git", "colocation", "status"], snapshot)
        if "is currently colocated with Git." not in status:
            raise Failure("a colocated Git repository is required")

    def _plan(self, revset, snapshot):
        self._require_colocated(snapshot)
        private_revset = self._config_get("git.private-commits", snapshot)
        signing_revset = self._config_get("revsets.git-sign-on-push", snapshot)

        def commits(selected):
            return self._commits(selected, snapshot, private_revset, signing_revset)

        trunks = commits("trunk()")
        if len(trunks) != 1:
            raise Failure(f"trunk() must resolve to one revision, found {len(trunks)}")
        trunk = trunks[0]
        if trunk.conflict or trunk.divergent:
            raise Failure("the local trunk is conflicted or divergent")
        if len(trunk.bookmarks) != 1:
            raise Failure("trunk() must have exactly one local bookmark")
        trunk_name = trunk.bookmarks[0]

        # A tracked trunk different from any remote copy must not be reused as a base.
        remote_trunks = commits(f"remote_bookmarks(exact:{json.dumps(trunk_name)})")
        if any(remote.commit_id != trunk.commit_id for remote in remote_trunks):
            raise Failure("the local trunk is stale or divergent from its remote bookmark")

        selected = revset or "heads(ancestors(@) & ~empty() & ~trunk())"
        tips = commits(selected)
        if len(tips) > 1 and len({tip.change_id for tip in tips}) == 1:
            raise Failure(f"selected change ID {tips[0].change_id} is divergent")
        if len(tips) != 1:
            raise Failure(f"selection must resolve to one nonempty revision, found {len(tips)}")
        tip = tips[0]
        if tip.empty:
            raise Failure("the selected revision is empty")
        if not CHANGE_ID.fullmatch(tip.change_id):
            raise Failure("jj did not provide a full 32-character change ID")

        changes = commits(f"trunk()..{tip.change_id}")
        if not changes or all(change.commit_id != tip.commit_id for change in changes):
            raise Failure("the selected revision must be a nonempty descendant of trunk()")
        self._validate_changes(changes)
        ordered = self._linear_order(trunk, changes)
        if ordered[-1].commit_id != tip.commit_id:
            raise Failure("the stack contains revisions unrelated to the selected tip")

        planned = []
        parent = trunk_name
        for change in ordered:
            if change.empty:
                continue
            if not CHANGE_ID.fullmatch(change.change_id):
                raise Failure("jj did not provide a full 32-character change ID")
            branch = f"jj/{change.change_id}"
            existing = commits(f'bookmarks(exact:"{branch}")')
            if len(existing) > 1:
                raise Failure(f"bookmark {branch} is conflicted")
            if existing and existing[0].commit_id != change.commit_id:
                raise Failure(
                    f"refusing to move generated bookmark {branch} from another revision"
                )
            planned.append(
                PlannedChange(
                    branch=branch,
                    change_id=change.change_id,
                    commit_id=change.commit_id,
                    create=not existing,
                    parent=parent,
                )
            )
            parent = branch
        if not planned or planned[-1].commit_id != tip.commit_id:
            raise Failure("the selected revision is empty")
        return Plan(changes=tuple(planned), trunk=trunk, trunk_name=trunk_name)

    @staticmethod
    def _validate_changes(changes):
        seen = set()
        for change in changes:
            if len(change.parent_commits) != 1:
                raise Failure(f"merge revision {change.change_id} is not supported")
            if change.conflict:
                raise Failure(f"revision {change.change_id} contains conflicts")
            if change.divergent:
                raise Failure(f"revision {change.change_id} has a divergent change ID")
            if change.private:
                raise Failure(f"revision {change.change_id} is private")
            if not change.mine:
                raise Failure(f"revision {change.change_id} is not authored by the current user")
            if not change.description.strip():
                raise Failure(f"revision {change.change_id} has no description")
            if change.change_id in seen or change.divergent:
                raise Failure(f"duplicate or divergent change ID {change.change_id}")
            seen.add(change.change_id)
        unsigned = [
            change for change in changes if change.sign_required and not change.signed
        ]
        if unsigned:
            revisions = " | ".join(change.change_id for change in unsigned)
            raise Failure(
                "revsets.git-sign-on-push requires signatures; "
                f"run jj sign -r '{revisions}' then retry"
            )

    @staticmethod
    def _linear_order(trunk, changes):
        remaining = {change.commit_id: change for change in changes}
        if len(remaining) != len(changes):
            raise Failure("the stack contains duplicate commits")
        ordered = []
        parent = trunk.commit_id
        while remaining:
            children = [
                change
                for change in remaining.values()
                if change.parent_commits == (parent,)
            ]
            if len(children) != 1:
                raise Failure("the selected stack is nonlinear or not based on trunk()")
            child = children[0]
            ordered.append(child)
            del remaining[child.commit_id]
            parent = child.commit_id
        return ordered

    def _commands(self, plan, publish):
        commands = [[self.gt_path, "init", f"--trunk={plan.trunk_name}"]]
        for change in plan.changes:
            if change.create:
                commands.append(
                    [
                        self.jj_path,
                        "bookmark",
                        "create",
                        change.branch,
                        "-r",
                        change.change_id,
                    ]
                )
            commands.append(
                [self.gt_path, "track", change.branch, f"--parent={change.parent}"]
            )
        commands.append(
            [
                self.gt_path,
                "submit",
                "--branch",
                plan.changes[-1].branch,
                "--no-stack",
                "--no-restack",
                "--no-edit",
                "--no-ai",
                "--publish" if publish else "--draft",
            ]
        )
        return commands

    def _push(self, revset, dry_run, publish):
        # A real push may snapshot @. A dry run sees only previously captured JJ state.
        plan = self._plan(revset, snapshot=not dry_run)
        commands = self._commands(plan, publish)
        if dry_run:
            print("Dry run: using previously captured JJ state; nothing will be executed.")
            print(f"Trunk: {plan.trunk_name} ({plan.trunk.commit_id})")
            for change in plan.changes:
                action = "create" if change.create else "reuse"
                print(
                    f"Bookmark: {action} {change.branch} -> {change.commit_id}; parent {change.parent}"
                )
            for command in commands:
                print(f"$ {shlex.join(command)}")
            return 0

        self._gt_checked(commands[0])
        index = 1
        for change in plan.changes:
            if change.create:
                self._jj(
                    [
                        "bookmark",
                        "create",
                        change.branch,
                        "-r",
                        change.change_id,
                    ],
                    snapshot=True,
                )
                index += 1
            self._gt_checked(commands[index])
            index += 1
        self._gt_checked(commands[index])
        return 0

    def _read_branch(self, command, revset):
        plan = self._plan(revset, snapshot=False)
        selected = plan.changes[-1]
        if selected.create:
            raise Failure(f"selected change has no submitted bookmark {selected.branch}")
        args = [command]
        if command == "info":
            args.append("--branch")
        args.append(selected.branch)
        return self._gt(args)

    def _gt(self, args):
        return self._run_process([self.gt_path] + args, check=False).returncode

    def _gt_checked(self, command):
        status = self._run_process(command, check=False).returncode
        if status:
            raise Failure(f"gt {command[1]} failed with status {status}", status)


class _Once(argparse.Action):
    def __call__(self, parser, namespace, values, option_string=None):
        if getattr(namespace, self.dest, None) is not None:
            parser.error(f"{option_string} may only be supplied once")
        setattr(namespace, self.dest, values)


def _nonempty(value):
    if not value.strip():
        raise argparse.ArgumentTypeError("value must not be empty")
    return value


def main(argv=None):
    return Bridge().execute(sys.argv[1:] if argv is None else argv)


if __name__ == "__main__":
    sys.exit(main())
