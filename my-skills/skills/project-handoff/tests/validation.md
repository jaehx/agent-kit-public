# 검증 기록 — 2026-10-07

## 실행해 확인한 항목

- Codex `skill-creator`의 `quick_validate.py`: PASS. 공통 frontmatter는 name·description만 사용했다.
  MoAI 템플릿의 version은 현재 Codex 검증기가 지원하지 않아 본문과 테스트 정의에 기록했다.
- `uv run ruff check my-skills/skills/project-handoff`: PASS.
- 상태 수집기 unittest: 3개 PASS. Git 없는 폴더·미커밋 저장소·한글/공백 경로·변경 지문·없는 파일·외부 경로를 확인했다.
  실제 저장소에 대한 수집기는 읽기 전용 JSON 출력이며 커밋·설정 변경을 수행하지 않는다.
- 현재 자동매매 연구 저장소에서 본 스킬의 저장 절차를 적용해 인수인계·진입점·상태 기록을 작성했다.
- 공식 문서의 로컬 경로와 링크 지원을 확인했고, Claude 경로와 Codex 원본이 동일 파일을 읽는지 대조했다.

## 미실행 항목

- Claude Code 신규 세션에서 `/project-handoff` 메뉴 발견 및 전체 저장/재개 실행: NOT-RUN.
- Codex 신규 세션에서 `$project-handoff` 선택 및 전체 저장/재개 실행: NOT-RUN.
- 동일 모델·조건의 baseline 대비 스킬 A/B, 토큰 효율 측정, 독립 에이전트 검증: NOT-RUN.
- tests/test-cases.yaml의 에이전트 판단 결과 전체: NOT-RUN. 도우미 함수 테스트로 대체됐다고 말하지 않는다.

실행하지 않은 항목에는 품질 점수를 붙이지 않았다. 파일 형식·도우미 실행과 앱의 실제 호출을 구분한다.
