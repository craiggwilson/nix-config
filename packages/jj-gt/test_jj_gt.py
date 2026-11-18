"""Focused integration tests: real jj, constructor-injected fake gt."""

import contextlib
import io
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile
import unittest

SOURCE = Path(__file__).with_name("jj-gt.py")
NAMESPACE = {"__name__": "jj_gt_under_test", "__file__": str(SOURCE)}
exec(compile(SOURCE.read_text(), str(SOURCE), "exec"), NAMESPACE)
Bridge = NAMESPACE["Bridge"]
COMMIT_TEMPLATE = NAMESPACE["COMMIT_TEMPLATE"]
JJ = shutil.which("jj")
if JJ is None:
    raise RuntimeError("jj must be on PATH for the jj-gt tests")


class Repo:
    def __init__(self, root, colocated=True):
        self.path = root / "repo"
        self.config = root / "config.toml"
        self.fake_log = root / "gt.jsonl"
        fake = root / "fake-gt"
        fake.write_text(
            f"""#!{sys.executable}
import json, os, sys
with open(os.environ["FAKE_GT_LOG"], "a") as stream:
    stream.write(json.dumps(sys.argv[1:]) + "\\n")
"""
        )
        fake.chmod(0o755)
        driver = root / "bridge-driver"
        driver.write_text(
            f"""#!{sys.executable}
import sys
source = {str(SOURCE)!r}
namespace = {{"__name__": "jj_gt_under_test", "__file__": source}}
exec(compile(open(source).read(), source, "exec"), namespace)
bridge = namespace["Bridge"](jj_path={JJ!r}, gt_path={str(fake)!r})
raise SystemExit(bridge.execute(sys.argv[1:]))
"""
        )
        driver.chmod(0o755)
        self.config.write_text(
            f"""[user]
name = "Test User"
email = "test@example.com"

[git]
private-commits = "private()"

[aliases]
gt = ["util", "exec", "--", {json.dumps(str(driver))}]

[revset-aliases]
"trunk()" = "main"
"private()" = "description(glob:'private:*')"
"""
        )
        self.env = os.environ.copy()
        self.env.update(
            HOME=str(root / "home"),
            JJ_CONFIG=str(self.config),
            FAKE_GT_LOG=str(self.fake_log),
        )
        self.env.pop("JJ_WORKSPACE", None)
        colocation = "--colocate" if colocated else "--no-colocate"
        self._run([JJ, "git", "init", colocation, str(self.path)], root)
        self.jj("describe", "-m", "base")
        self.jj("bookmark", "create", "main", "-r", "@")
        self.jj("new")
        self.bridge = Bridge(jj_path=JJ, gt_path=str(fake))

    def _run(self, command, cwd=None):
        return subprocess.run(
            command,
            cwd=cwd or self.path,
            env=self.env,
            text=True,
            capture_output=True,
            check=True,
        )

    def jj(self, *args, readonly=False):
        command = [JJ, "--color=never"]
        if readonly:
            command.append("--ignore-working-copy")
        result = self._run(command + list(args))
        return result.stdout

    def many(self, revset):
        output = self.jj(
            "log", "--no-graph", "-r", revset, "-T", COMMIT_TEMPLATE, readonly=True
        )
        return [json.loads(line) for line in output.splitlines() if line.strip()]

    def one(self, revset="@"):
        values = self.many(revset)
        assert len(values) == 1, values
        return values[0]

    def change(self, description, filename, contents=None):
        if description is not None:
            self.jj("describe", "-m", description)
        target = self.path / filename
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(contents if contents is not None else f"{filename}\n")
        self.jj("log", "-r", "@", "--no-graph")
        return self.one()

    def invoke(self, *args):
        stdout = io.StringIO()
        stderr = io.StringIO()
        old_environ = os.environ.copy()
        old_cwd = os.getcwd()
        os.environ.clear()
        os.environ.update(self.env)
        os.chdir(self.path)
        try:
            with contextlib.redirect_stdout(stdout), contextlib.redirect_stderr(stderr):
                status = self.bridge.execute(list(args))
        finally:
            os.chdir(old_cwd)
            os.environ.clear()
            os.environ.update(old_environ)
        return status, stdout.getvalue(), stderr.getvalue()

    def gt_calls(self):
        if not self.fake_log.exists():
            return []
        return [json.loads(line) for line in self.fake_log.read_text().splitlines()]

    def clear_gt(self):
        self.fake_log.write_text("")

    def op_id(self):
        line = self.jj("op", "log", "-n", "1", "--no-graph", readonly=True).splitlines()[0]
        return re.search(r"\b[0-9a-f]{12,64}\b", line).group(0)

    def bookmark_state(self):
        result = self._run(
            [JJ, "--ignore-working-copy", "--color=never", "bookmark", "list", "--all-remotes"]
        )
        return result.stdout + result.stderr


class BridgeTest(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory(prefix="jjgt-test-")
        self.repo = Repo(Path(self.temporary.name))

    def tearDown(self):
        self.temporary.cleanup()

    def assert_refusal(self, *args):
        before = self.repo.bookmark_state()
        status, _, error = self.repo.invoke(*args)
        self.assertNotEqual(status, 0, error)
        self.assertEqual(self.repo.gt_calls(), [])
        self.assertEqual(self.repo.bookmark_state(), before)
        return error

    def test_stack_full_ids_parents_and_draft(self):
        first = self.repo.change("first change", "one.txt")
        self.repo.jj("new")
        second = self.repo.change("second change", "two.txt")
        status, _, error = self.repo.invoke("push")
        self.assertEqual(status, 0, error)
        first_name = f"jj/{first['change_id']}"
        second_name = f"jj/{second['change_id']}"
        self.assertRegex(first_name, r"^jj/[a-z0-9]{32}$")
        self.assertEqual(
            self.repo.gt_calls(),
            [
                ["init", "--trunk=main"],
                ["track", first_name, "--parent=main"],
                ["track", second_name, f"--parent={first_name}"],
                [
                    "submit",
                    "--branch",
                    second_name,
                    "--no-stack",
                    "--no-restack",
                    "--no-edit",
                    "--no-ai",
                    "--draft",
                ],
            ],
        )
        self.assertIn(first_name, self.repo.jj("log", "-r", first["change_id"], "--no-graph"))
        self.assertIn(second_name, self.repo.jj("log", "-r", second["change_id"], "--no-graph"))

    def test_rewrite_reuses_ids_and_retracks_without_creating(self):
        first = self.repo.change("first change", "one.txt")
        self.repo.jj("new")
        second = self.repo.change("second change", "two.txt")
        self.assertEqual(self.repo.invoke("push")[0], 0)
        old_commit = self.repo.one(first["change_id"])["commit_id"]
        self.repo.clear_gt()
        self.repo.jj("describe", "-r", first["change_id"], "-m", "first revised")
        self.assertNotEqual(self.repo.one(first["change_id"])["commit_id"], old_commit)
        self.assertEqual(self.repo.one(second["change_id"])["parent_commits"], [self.repo.one(first["change_id"])["commit_id"]])
        status, _, error = self.repo.invoke("submit", "--publish")
        self.assertEqual(status, 0, error)
        calls = self.repo.gt_calls()
        self.assertEqual(
            calls,
            [
                ["init", "--trunk=main"],
                ["track", f"jj/{first['change_id']}", "--parent=main"],
                ["track", f"jj/{second['change_id']}", f"--parent=jj/{first['change_id']}"],
                ["submit", "--branch", f"jj/{second['change_id']}", "--no-stack", "--no-restack", "--no-edit", "--no-ai", "--publish"],
            ],
        )
        self.assertEqual(self.repo.jj("bookmark", "list", "jj/*").count("jj/"), 2)

    def test_empty_working_copy_selects_nonempty_parent(self):
        change = self.repo.change("captured change", "one.txt")
        self.repo.jj("new")
        self.assertTrue(self.repo.one()["empty"])
        status, _, error = self.repo.invoke("push")
        self.assertEqual(status, 0, error)
        self.assertEqual(self.repo.gt_calls()[-1][2], f"jj/{change['change_id']}")

    def test_explicit_revision_excludes_unrelated_descendant(self):
        first = self.repo.change("first change", "one.txt")
        self.repo.jj("new")
        second = self.repo.change("second change", "two.txt")
        status, _, error = self.repo.invoke("push", "-r", first["change_id"])
        self.assertEqual(status, 0, error)
        self.assertEqual(len([call for call in self.repo.gt_calls() if call[0] == "track"]), 1)
        self.assertIn(f"jj/{first['change_id']}", self.repo.bookmark_state())
        self.assertNotIn(f"jj/{second['change_id']}", self.repo.bookmark_state())
        self.assertEqual(self.repo.gt_calls()[-1][2], f"jj/{first['change_id']}")

    def test_dry_run_has_zero_jj_or_gt_mutation(self):
        change = self.repo.change("captured change", "one.txt")
        (self.repo.path / "uncaptured.txt").write_text("must not be snapshotted\n")
        before_op = self.repo.op_id()
        before_bookmarks = self.repo.bookmark_state()
        status, output, error = self.repo.invoke("push", "--dry-run")
        self.assertEqual(status, 0, error)
        self.assertIn("previously captured JJ state", output)
        self.assertIn(f"create jj/{change['change_id']}", output)
        self.assertIn("submit", output)
        self.assertEqual(self.repo.op_id(), before_op)
        self.assertEqual(self.repo.bookmark_state(), before_bookmarks)
        self.assertEqual(self.repo.gt_calls(), [])

    def test_strict_allowlist_blocks_unsafe_commands_and_flags(self):
        denied = [
            ("init",), ("init", "--reset"), ("track", "x"), ("re-track",),
            ("restack",), ("sync",), ("move",), ("create",), ("modify",),
            ("delete", "x"), ("merge",), ("git", "push"), ("co", "main"),
            ("push", "--force"), ("push", "--force=true"), ("push", "--force-with-lease"),
            ("push", "--no-verify"), ("push", "--verify=false"), ("push", "--restack"),
            ("push", "--no-restack"), ("push", "--always"), ("push", "--ignore-out-of-sync-trunk"),
            ("push", "--stack"), ("push", "--no-stack"), ("push", "--no-edit"),
            ("push", "--ai"), ("push", "--no-ai"), ("push", "--confirm"),
            ("push", "--dry-run=false"), ("push", "--draft", "--publish"),
            ("--cwd", "/tmp", "log"), ("log", "--cwd=/tmp"), ("log", "short"),
            ("log", "--show-untracked"), ("info", "--patch"), ("pr", "main"),
            ("auth",), ("auth", "--token=one", "--token=two"),
            ("push", "-r", "@", "-r", "@-"), ("unknown",), ("--debug", "log"),
        ]
        for args in denied:
            with self.subTest(args=args):
                status, _, _ = self.repo.invoke(*args)
                self.assertEqual(status, 2)
        self.assertEqual(self.repo.gt_calls(), [])

    def test_auth_log_version_help_pr_and_info(self):
        change = self.repo.change("review change", "one.txt")
        self.assertEqual(self.repo.invoke("push")[0], 0)
        self.repo.clear_gt()
        for args, expected in [
            (("auth", "--token", "secret-test-token"), ["auth", "--token", "secret-test-token"]),
            (("log",), ["log"]),
            (("--version",), ["--version"]),
            (("version",), ["--version"]),
            (("pr",), ["pr", f"jj/{change['change_id']}"]),
            (("info", "-r", change["change_id"]), ["info", "--branch", f"jj/{change['change_id']}"]),
        ]:
            with self.subTest(args=args):
                status, _, error = self.repo.invoke(*args)
                self.assertEqual(status, 0, error)
                self.assertEqual(self.repo.gt_calls()[-1], expected)
        status, output, _ = self.repo.invoke("help")
        self.assertEqual(status, 0)
        self.assertIn("never selects or changes that remote", output)
        self.assertIn("previously captured JJ state", output)
        self.assertIn("invoking the underlying", output)

    def test_private_refuses_before_gt_or_bookmarks(self):
        self.repo.change("private: do not submit", "one.txt")
        error = self.assert_refusal("push")
        self.assertIn("private", error)

    def test_other_author_refuses_before_gt_or_bookmarks(self):
        original = self.repo.config.read_text()
        self.repo.config.write_text(original.replace("Test User", "Other User").replace("test@example.com", "other@example.com"))
        self.repo.jj("new", "main", "-m", "other author")
        (self.repo.path / "one.txt").write_text("other\n")
        self.repo.jj("log", "-r", "@", "--no-graph")
        self.repo.config.write_text(original)
        error = self.assert_refusal("push")
        self.assertIn("not authored", error)

    def test_merge_and_nonlinear_stack_refuse(self):
        first = self.repo.change("first side", "one.txt")
        self.repo.jj("new", "main")
        second = self.repo.change("second side", "two.txt")
        self.repo.jj("new", first["change_id"], second["change_id"], "-m", "merge change")
        merge = self.repo.change(None, "merge.txt")
        error = self.assert_refusal("push", "-r", merge["change_id"])
        self.assertTrue("merge" in error or "nonlinear" in error, error)

    def test_conflicted_nonmerge_refuses(self):
        first = self.repo.change("first side", "shared.txt", "one\n")
        self.repo.jj("new", "main")
        second = self.repo.change("second side", "shared.txt", "two\n")
        self.repo.jj("rebase", "-r", second["change_id"], "-d", first["change_id"])
        self.assertTrue(self.repo.one(second["change_id"])["conflict"])
        error = self.assert_refusal("push", "-r", second["change_id"])
        self.assertIn("conflict", error)

    def test_missing_description_and_explicit_empty_target_refuse(self):
        self.repo.change(None, "one.txt")
        error = self.assert_refusal("push")
        self.assertIn("no description", error)
        self.repo.jj("new")
        self.assertTrue(self.repo.one()["empty"])
        error = self.assert_refusal("push", "-r", "@")
        self.assertIn("empty", error)

    def test_generated_bookmark_collision_refuses_without_moving_it(self):
        change = self.repo.change("collision", "one.txt")
        self.repo.jj("new", "main")
        self.repo.change("other change", "two.txt")
        branch = f"jj/{change['change_id']}"
        self.repo.jj("bookmark", "create", branch, "-r", "@")
        before_target = self.repo.one(branch)["commit_id"]
        error = self.assert_refusal("push", "-r", change["change_id"])
        self.assertIn("refusing to move", error)
        self.assertEqual(self.repo.one(branch)["commit_id"], before_target)

    def test_selected_revision_not_descended_from_trunk_refuses(self):
        self.repo.jj("new", "root()")
        change = self.repo.change("unrelated", "other.txt")
        error = self.assert_refusal("push", "-r", change["change_id"])
        self.assertTrue("trunk" in error or "nonlinear" in error, error)

    def test_non_colocated_repository_refuses(self):
        root = Path(self.temporary.name) / "non-colocated"
        root.mkdir()
        repo = Repo(root, colocated=False)
        repo.change("non-colocated", "one.txt")
        before = repo.bookmark_state()
        status, _, error = repo.invoke("push")
        self.assertNotEqual(status, 0)
        self.assertIn("colocated", error)
        self.assertEqual(repo.gt_calls(), [])
        self.assertEqual(repo.bookmark_state(), before)

    def test_custom_private_revset_and_undefined_private_alias(self):
        original = self.repo.config.read_text()
        self.repo.config.write_text(
            original.replace(
                'private-commits = "private()"',
                "private-commits = 'description(glob:\"secret:*\")'",
            ).replace('"private()" = "description(glob:\'private:*\')"\n', "")
        )
        self.repo.change("secret: custom private selector", "one.txt")
        error = self.assert_refusal("push")
        self.assertIn("private", error)

    def test_no_private_config_or_alias_allows_ordinary_change(self):
        original = self.repo.config.read_text()
        self.repo.config.write_text(
            original.replace('[git]\nprivate-commits = "private()"\n\n', "").replace(
                '"private()" = "description(glob:\'private:*\')"\n', ""
            )
        )
        self.repo.change("private: just text without private configuration", "one.txt")
        status, _, error = self.repo.invoke("push")
        self.assertEqual(status, 0, error)

    def test_signing_revset_refuses_unsigned_before_mutation(self):
        self.repo.config.write_text(
            self.repo.config.read_text()
            + '\n[revsets]\ngit-sign-on-push = "~signed() & mine()"\n'
        )
        change = self.repo.change("needs signature", "one.txt")
        error = self.assert_refusal("push")
        self.assertIn("revsets.git-sign-on-push", error)
        self.assertIn(f"jj sign -r '{change['change_id']}'", error)
        self.assertIn("retry", error)

    def test_divergent_selected_change_refuses(self):
        change = self.repo.change("divergent original", "one.txt")
        operation = self.repo.op_id()
        for description in ("divergent one", "divergent two"):
            self.repo._run(
                [
                    JJ,
                    "--color=never",
                    "--at-operation",
                    operation,
                    "describe",
                    "-r",
                    change["change_id"],
                    "-m",
                    description,
                ]
            )
        versions = [
            version
            for version in self.repo.many("all()")
            if version["change_id"] == change["change_id"]
        ]
        self.assertEqual(len(versions), 2)
        self.assertTrue(all(version["divergent"] for version in versions))
        error = self.assert_refusal("push", "-r", change["change_id"])
        self.assertIn("divergent", error)

    def test_empty_private_intermediary_refuses(self):
        self.repo.change("first change", "one.txt")
        self.repo.jj("new", "-m", "private: empty intermediary")
        intermediary = self.repo.one()
        self.assertTrue(intermediary["empty"])
        self.repo.jj("new")
        self.repo.change("second change", "two.txt")
        error = self.assert_refusal("push")
        self.assertIn("private", error)

    def test_real_jj_util_exec_alias_dry_run_does_not_snapshot(self):
        change = self.repo.change("captured alias change", "one.txt")
        (self.repo.path / "uncaptured-alias.txt").write_text("do not snapshot\n")
        before_op = self.repo.op_id()
        before_bookmarks = self.repo.bookmark_state()
        result = self.repo._run([JJ, "--color=never", "gt", "push", "--dry-run"])
        self.assertIn("previously captured JJ state", result.stdout)
        self.assertIn(f"create jj/{change['change_id']}", result.stdout)
        self.assertEqual(self.repo.op_id(), before_op)
        self.assertEqual(self.repo.bookmark_state(), before_bookmarks)
        self.assertEqual(self.repo.gt_calls(), [])

    def test_missing_executables_have_context_without_traceback(self):
        for kind in ("jj", "gt"):
            with self.subTest(kind=kind):
                missing = str(Path(self.temporary.name) / f"missing-{kind}")
                if kind == "jj":
                    self.repo.bridge = Bridge(jj_path=missing, gt_path=self.repo.bridge.gt_path)
                    args = ("push",)
                else:
                    self.repo.bridge = Bridge(jj_path=JJ, gt_path=missing)
                    args = ("auth", "--token", "test-token")
                status, _, error = self.repo.invoke(*args)
                self.assertNotEqual(status, 0)
                self.assertIn(missing, error)
                self.assertIn("cannot execute", error)
                self.assertNotIn("Traceback", error)


if __name__ == "__main__":
    unittest.main(verbosity=2)
