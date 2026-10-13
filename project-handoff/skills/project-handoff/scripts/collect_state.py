#!/usr/bin/env python3
"""프로젝트 상태와 지정된 파일의 지문을 읽기 전용으로 수집한다."""

import argparse
import hashlib
import json
import subprocess
from datetime import UTC, datetime
from pathlib import Path


def git(repo: Path, *args: str) -> str | None:
    """Git 정보를 얻되 쉘이나 원격 통신은 사용하지 않는다."""
    try:
        result = subprocess.run(["git", "-C", str(repo), *args], capture_output=True,
                                text=True, timeout=10, check=False)
    except FileNotFoundError:
        return None
    return result.stdout.rstrip("\r\n") if result.returncode == 0 else None


def collect(repo: Path, artifacts: list[str]) -> dict:
    repo = repo.resolve(strict=True)
    if not repo.is_dir():
        raise ValueError("프로젝트 경로는 디렉터리여야 합니다")
    git_root = git(repo, "rev-parse", "--show-toplevel")
    root = Path(git_root).resolve() if git_root else repo
    records = {}
    for name in artifacts:
        path = (repo / name).resolve()
        if not path.is_relative_to(root):
            raise ValueError(f"저장소 밖의 파일은 별도로 기록하세요: {name}")
        key = str(path.relative_to(root))
        if not path.is_file():
            records[key] = {"exists": False}
            continue
        digest = hashlib.sha256()
        with path.open("rb") as stream:
            for chunk in iter(lambda: stream.read(1024 * 1024), b""):
                digest.update(chunk)
        records[key] = {"exists": True, "bytes": path.stat().st_size,
                        "sha256": digest.hexdigest()}
    return {"schema_version": 1, "captured_at": datetime.now(UTC).isoformat(),
            "project_root": str(root), "git_available": git_root is not None,
            "branch": git(root, "branch", "--show-current") if git_root else None,
            "head": git(root, "rev-parse", "HEAD") if git_root else None,
            "status_short": git(root, "status", "--short", "--untracked-files=all")
                            if git_root else None,
            "artifacts": records}


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--repo", type=Path, default=Path.cwd())
    parser.add_argument("--artifact", action="append", default=[])
    args = parser.parse_args()
    print(json.dumps(collect(args.repo, args.artifact), ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
