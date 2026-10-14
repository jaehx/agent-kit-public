# agent-kit-public

직접 만들어 쓰는 Claude Code 플러그인 모음입니다. 필요한 플러그인만 골라 설치할 수 있습니다.

| 플러그인 | 한 줄 설명 |
|---|---|
| [`prompt-polish`](#prompt-polish) | 모델별 공식 프롬프팅 가이드 규칙을 세션마다 자동 적용하고, 대충 쓴 요청을 가이드에 맞게 다듬어 실행 |
| [`project-handoff`](#project-handoff) | 다음 세션이나 다른 에이전트가 이어받을 수 있게 작업 상태를 저장소에 기록하고, 재개할 때 현재 파일과 대조 |

## 설치

Claude Code에서 실행합니다.

```
/plugin marketplace add jaehx/agent-kit-public
/plugin install prompt-polish@agent-kit
/plugin install project-handoff@agent-kit
```

- 설치한 세션에서 바로 쓰려면 `/reload-plugins` 다음 `/clear`를 실행합니다. 새 세션은 그대로 적용됩니다.
- 요구 사항: Claude Code 2.1.258 이상. Windows는 훅이 bash로 실행되므로 Git for Windows(Git Bash)가 필요합니다.

### 갱신과 제거

```
/plugin marketplace update agent-kit        # 새 버전 받기
/plugin uninstall prompt-polish@agent-kit   # 제거
```

서드파티 마켓플레이스는 자동 갱신이 기본으로 꺼져 있습니다.
자동으로 받으려면 `/plugin` → Marketplaces → `agent-kit` → Enable auto-update를 켭니다.

---

## prompt-polish

[oh-my-fable](https://github.com/Junhan2/oh-my-fable) 2.2.0을 fork한 플러그인입니다.
원본과 다른 점은 [FORK.md](prompt-polish/FORK.md)에 있습니다.

> [prompt-polish/README.md](prompt-polish/README.md)는 원본 설명서를 그대로 둔 것입니다.
> 작동 원리와 FAQ는 그 문서를 참고하되, 설치는 위의 `agent-kit` 명령으로 하세요.
> 원본 설치 명령(`Junhan2/oh-my-fable`)으로 설치하면 이 fork가 아닌 원본이 설치됩니다.

### 설치만 하면 자동으로 되는 것

세션이 시작될 때와 `/model`로 모델을 바꿀 때 훅이 규칙을 넣습니다. 파일은 만들지 않습니다.

- **공통 작업 규칙:** 자율 진행, 범위 제한, 시킨 범위 끝까지 하기, 부분 편집, 진행 보고, 서식, 도구 일괄 호출.
- **모델별 규칙:** 세션 모델에 맞는 공식 가이드 규칙을 하나 더 넣습니다.
  지원 모델은 Fable 5.1, Opus 5.5, Opus 5, Sonnet 5이고, 그 밖의 모델은 공통 규칙만 받습니다.
- **무인 실행 감지:** `claude -p`, Agent SDK 같은 무인 세션이면 "중간 보고로 멈추지 말라" 문단을 더합니다.
- **서브에이전트:** 짧은 공통 규칙만 받습니다. 모델별 규칙은 넣지 않습니다.

### 스킬

| 명령 | 하는 일 | 파일 수정 |
|---|---|---|
| `/guide-rewrite <요청>` | 짧거나 막연한 요청을 목표·맥락·범위·완료 기준으로 채워 보여 주고 바로 실행 | 없음 |
| `/guide-status` | 지금 적용 중인 규칙을 표 하나로 보여 줌 (버전, 규칙 위치, 모드, effort와 그 출처, CLAUDE.md 충돌) | 없음 |
| `/guide-audit [대상]` | CLAUDE.md·rules·에이전트 프롬프트를 가이드 16개 항목과 대조해 빠진 것·충돌하는 것을 보여 주고 고칠 문구를 제안 | 없음 |
| `/guide-setup [인자]` | 기본값을 바꿀 때만 사용. 규칙 전달 방식, 모드 고정, `remove`로 되돌리기 | 있음 |

#### `/guide-rewrite` 예시

```
/guide-rewrite 로그인 버튼 눌러도 반응 없어 고쳐줘
```

"이거", "그 파일" 같은 말은 대화 맥락에서 실제 경로나 오류로 바꿔 채웁니다.
그 결과 이런 요청이 만들어져 실행됩니다.

```
목표: 로그인 버튼을 누르면 /api/login이 호출되고, 성공하면 /dashboard로 이동하게 한다
맥락: src/components/LoginButton.tsx, 콘솔 오류 "TypeError: onSubmit is not a function"
범위: 이 버튼과 그 핸들러만. 다른 오류는 고치지 말고 후속 과제로 보고
완료 기준: 실제 클릭으로 /dashboard 이동 확인, 콘솔 오류 0
```

실행하지 않고 다듬은 요청만 보려면 끝에 `프롬프트만`을 붙입니다.

```
/guide-rewrite 이 함수 성능 개선해줘 프롬프트만
```

#### `/guide-audit` 대상

| 인자 | 대상 |
|---|---|
| (없음) | 이 기기에서 적용 중인 지침 전체 |
| `global` | `~/.claude`만 |
| `project` | 현재 프로젝트만 |
| `<경로>` | 특정 파일이나 폴더 (예: 에이전트 프롬프트 폴더) |
| `section <번호>` | 가이드의 한 항목만 자세히 |

#### `/guide-setup` 인자

인자 없이 실행하면 질문 두 개(규칙 위치, 작업 방식)로 설정합니다. 설정하지 않아도 기본값으로 동작합니다.

| 인자 | 의미 |
|---|---|
| `auto` | 질문 없이 기본값 유지 |
| `hook` / `rules-file` / `claude-md` | 규칙 전달 방식. 기본은 `hook`, 에이전트 팀을 쓰면 `rules-file` |
| `interactive` / `unattended` | 모드 고정. 기본은 세션마다 자동 감지 |
| `refresh` | rules 파일만 최신 내용으로 다시 복사 |
| `remove` | 이 스킬로 바꾼 설정을 모두 되돌림 |

### Codex에서 쓰기

`guide-rewrite`는 Codex 스킬로도 쓸 수 있습니다. 실행 모델이 GPT면 OpenAI 공식 가이드를 따릅니다.

```bash
git clone https://github.com/jaehx/agent-kit-public.git
ln -s "$PWD/agent-kit-public/prompt-polish/skills/guide-rewrite" ~/.codex/skills/guide-rewrite
```

Codex에서는 `$guide-rewrite <요청>`으로 부릅니다.
Codex에는 훅이 없어서 상시 규칙은 적용되지 않고, 요청 다듬기만 동작합니다.

---

## project-handoff

대화 요약에 기대지 않고, 저장소의 실제 파일·실행 결과·Git 상태를 근거로 인수인계를 남깁니다.
다음 세션이나 다른 에이전트(Codex 포함)가 맥락 없이 이어받을 수 있게 하는 것이 목적입니다.

### 저장

```
/project-handoff 다음 세션용으로 정리해줘
```

"다른 LLM도 이어갈 수 있게 정리해줘", "인수인계 남겨줘"처럼 말해도 됩니다.

만들어지는 파일:

| 파일 | 내용 |
|---|---|
| `docs/handoffs/<날짜-시간-주제>.md` | 인수인계 기록. 기존 기록은 덮어쓰지 않음 |
| `docs/HANDOFF.md` | 최신 기록으로 가는 짧은 안내 |
| `AGENTS.md` (필요할 때만) | 최신 인수인계를 읽으라는 짧은 안내 |

이미 인수인계 문서 구조가 있는 프로젝트라면 새로 만들지 않고 그 구조를 따릅니다.

기록에 들어가는 항목:

- 목적과 현재 상태 (완료 / 진행 중 / 막힘)
- 확인된 결론과 근거, 실패한 시도와 되풀이하지 않을 이유
- 다음 세션이 읽을 파일 순서
- 재현 명령과 실행 환경, 실제 검사 결과, 실행하지 않은 검사
- Git 상태 (브랜치, HEAD, 커밋하지 않은 파일)
- 남은 일과 완료 기준
- 다음 세션에 그대로 붙여 넣을 요청문

저장만 하고 커밋이나 push는 하지 않습니다. 커밋하지 않은 파일은 다른 기기의 clone에 전달되지 않는다는 점도 기록에 적습니다.

### 재개

```
/project-handoff 재개
```

"인수인계 읽고 이어가줘"라고 말해도 됩니다.

1. 최신 인수인계를 읽습니다.
2. 기록된 파일·Git HEAD·결과 지문(SHA256)을 현재 상태와 대조합니다. 바뀐 부분은 과거 결과로 취급합니다.
3. 목표, 완료된 것, 남은 것, 다음 행동을 짧게 정리합니다.

목표를 지정하지 않으면 현황 정리와 다음 단계 제안까지만 합니다. 기록에 있다는 이유만으로 작업을 자동으로 시작하지 않습니다.

### 상태 수집 도우미 (선택)

파일 내용 대신 Git 상태와 지정한 결과 파일의 SHA256을 JSON으로 출력하는 읽기 전용 스크립트입니다.
보통은 스킬이 필요할 때 직접 실행합니다. 사람이 직접 쓸 때는 다음과 같습니다.

```bash
python3 project-handoff/skills/project-handoff/scripts/collect_state.py \
  --repo /프로젝트/경로 --artifact results/output.csv
```

### Codex에서 쓰기

```bash
ln -s "$PWD/agent-kit-public/project-handoff/skills/project-handoff" ~/.codex/skills/project-handoff
```

Codex에서는 `$project-handoff`로 부릅니다. Claude Code에서 저장한 인수인계를 Codex에서 재개할 수 있고, 반대도 됩니다.

---

## 팁

플러그인은 아니지만 Claude Code로 작업하면서 정리한 내용입니다.

| 문서 | 내용 |
|---|---|
| [AI로 감각 있는 디자인 만들기](tips/design-references.md) | 제품 UI·랜딩 페이지 참고 사이트, 레퍼런스를 Claude에게 전달하는 법(토큰 고정, 금지 목록, 스크린샷 루프) |

---

## 라이선스

MIT. 단, `prompt-polish/`는 원본 저작자(Junhan2)의 MIT 라이선스를 따릅니다.
