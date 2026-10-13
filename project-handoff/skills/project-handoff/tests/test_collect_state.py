"""인수인계 수집기의 읽기 전용 동작과 실제 파일 변경 감지를 확인한다."""

import importlib.util
import subprocess
import tempfile
import unittest
from pathlib import Path

PATH = Path(__file__).resolve().parents[1] / "scripts" / "collect_state.py"
SPEC = importlib.util.spec_from_file_location("collect_state", PATH)
MODULE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(MODULE)


class StateTests(unittest.TestCase):
    def test_non_git_and_changed_artifact(self):
        with tempfile.TemporaryDirectory() as tmp:
            repo = Path(tmp)
            path = repo / "결과 비교.csv"
            path.write_text("first")
            before = set(repo.iterdir())
            state = MODULE.collect(repo, [path.name, "missing.csv"])
            self.assertFalse(state["git_available"])
            self.assertIsNone(state["head"])
            self.assertEqual(state["artifacts"]["missing.csv"], {"exists": False})
            self.assertEqual(before, set(repo.iterdir()))
            path.write_text("changed")
            after = MODULE.collect(repo, [path.name])
            self.assertNotEqual(state["artifacts"][path.name]["sha256"],
                                after["artifacts"][path.name]["sha256"])

    def test_dirty_repo_has_no_invented_commit_and_does_not_modify_git(self):
        with tempfile.TemporaryDirectory() as tmp:
            repo = Path(tmp)
            subprocess.run(["git", "init", "-q", str(repo)], check=True)
            (repo / "pending.md").write_text("pending")
            before = subprocess.check_output(["git", "-C", tmp, "status", "--short"])
            state = MODULE.collect(repo, ["pending.md"])
            self.assertTrue(state["git_available"])
            self.assertIsNone(state["head"])
            self.assertIn("pending.md", state["status_short"])
            after = subprocess.check_output(["git", "-C", tmp, "status", "--short"])
            self.assertEqual(before, after)

    def test_outside_artifact_is_not_silently_read(self):
        with tempfile.TemporaryDirectory() as tmp:
            repo = Path(tmp) / "project"
            repo.mkdir()
            with self.assertRaises(ValueError):
                MODULE.collect(repo, ["../outside.csv"])


if __name__ == "__main__":
    unittest.main()
