# prompt-polish

[oh-my-fable](https://github.com/Junhan2/oh-my-fable) 2.7.4(Junhan2, MIT)를 개인용으로 fork한 플러그인입니다. 원본 LICENSE는 그대로 두었습니다. README는 이 fork에 맞게 새로 썼고, 작동 원리와 FAQ는 원본 README를 가리킵니다.

원본과 같이 켜지 마세요. 두 플러그인이 같은 공통 규칙을 넣으므로 규칙이 두 번 들어갑니다. 원본을 쓰고 있었다면 먼저 `claude plugin uninstall oh-my-fable@oh-my-fable`을 실행하세요.

## 원본과 다른 점

- `hooks/models/*.md`: 모델별 규칙 6개. 문단은 두 종류뿐이고 `tests/guide-verbatim.sh`가 실제 가이드와 대조합니다.
  - 가이드의 예시 프롬프트를 글자 그대로 옮긴 문단.
  - 가이드가 프롬프트 문구 없이 조언만 주는 절을 규칙으로 풀어 쓴 문단. 문단 위에 `<!-- adapted: <절 이름> -->`을 답니다. 이 줄은 주입되지 않습니다.

  가이드에 근거가 없는 문단은 넣지 않습니다.

  | 세션 모델 | 규칙 파일 | 내용 |
  |---|---|---|
  | Fable 5.2, Mythos 5.2 | `fable-5-2.md` | 평범한 장애는 뚫고 가고 의도적으로 막아 둔 것은 건드리지 않기, 맥락 없는 독자가 읽을 수 있게 보고하기 |
  | Opus 5.5 | `opus-5-5.md` | 하위 에이전트 남용 금지, 정정은 필요할 때만, 문서 길이, 프런트엔드 기본 스타일 피하기, 그림은 잘라서 읽기 |
  | Sonnet 5.5 | `sonnet-5-5.md` | Sonnet 5 규칙에 더해: 아이디어를 물으면 만들지 않기, 코드 변경 뒤 실제 검사, 바뀌었을 수 있는 사실은 검색 |
  | Haiku 5.5 | `haiku-5-5.md` | 끝까지 하기, 코드 변경 뒤 실제 검사, 최신 정보는 검색 |
  | Opus 5, Sonnet 5 (구형) | `opus-5.md`, `sonnet-5.md` | 각 가이드의 처방 |
  | Fable 5.1 (구형) | 없음 | 가이드의 예시 프롬프트가 모두 공통 규칙에 들어 있습니다 |

  2.2.0-my.2까지 있던 `fable-5-1.md`는 지웠습니다. 다섯 문단 모두 Fable 5.1 가이드에 없었습니다(현재 문서와 2026-09-25 보관본에서 확인).

- `hooks/session-start.sh`: 세션 시작 때 `model` 입력으로 해당 파일을 덧붙이고, `/model`로 모델이 바뀌면(PostModelSwitch) 새 모델의 규칙을 넣으면서 이전 모델 규칙은 더 적용되지 않는다고 알립니다.
  - 버전은 정확히 일치해야 합니다(`model_file` 함수). 표에 없는 모델은 공통 규칙만 받고, 시작 줄에 `model rules: none for <모델>`이 뜹니다. 새 모델이 옛 모델의 규칙을 조용히 받는 일을 막기 위해서입니다.
  - `model` 입력이 빠지면 `settings.json`의 `model` 값(또는 `ANTHROPIC_MODEL`)으로 규칙을 고릅니다. `/clear` 직후와 헤드리스 시작(`claude -p`, Agent SDK)이 여기에 해당합니다. 헤드리스 시작 입력에는 `--model`을 줘도 모델이 없습니다(2.1.316에서 측정). 이때는 앞 문장이 «설정에 적힌 모델은 X다. 네가 X가 아니면 무시하라»로 바뀌고, 시작 줄에 `(model from settings)`가 붙습니다. 설정에 모델이 없으면 모델별 규칙은 나가지 않습니다.
  - 모든 모델 규칙의 앞 문장은 «네가 X인 동안에만 적용된다»고 적습니다. 세션 도중 모델을 바꿔도 먼저 들어간 규칙은 지울 수 없기 때문입니다.
  - 모델별 규칙은 훅이 말하는 두 전달 방식(훅만, 규칙 파일 + 훅)에서만 나갑니다. CLAUDE.md 구간이나 직접 만든 규칙 파일을 쓰면 훅은 원본처럼 조용합니다.
  - 하위 에이전트에는 모델별 규칙이 가지 않고 공통 규칙만 갑니다(SubagentStart 입력에 모델이 없습니다).
  - Fable 5.2의 Claude Code 기본 effort(`medium`)와 `fable` 별칭(5.2)을 반영했습니다.
  - `--status <모델 ID>`가 `model_rules` 줄을 보여 줍니다.
- 스킬 이름: 원본의 `fable-*`를 `guide-*`로 바꿨습니다 (`fable` → `guide-rewrite`, `fable-audit` → `guide-audit`, `fable-setup` → `guide-setup`, `fable-status` → `guide-status`). 이 fork가 Fable 전용이 아니기 때문입니다. `oh-my-fable.json`, `oh-my-fable:rules` 마커, `rules/oh-my-fable.md` 같은 내부 식별자는 원본과의 호환을 위해 그대로 둡니다.
- `skills/guide-rewrite`:
  - `references/openai-blocks.md`: OpenAI 공식 가이드("Using GPT-6", Codex "Best practices", AGENTS.md 문서)의 블록 O1~O8. 실행 중인 모델이 GPT면 이 파일을, Claude면 `prompt-blocks.md`를 씁니다.
  - 블록 P(코드 소유권 문장, Fable 5.2 가이드 "Say who owns the code"): 사용자가 구조 정리를 요청했을 때만 붙입니다. 상시 규칙에는 넣지 않습니다.
  - 승인이 필요한 단계는 범주가 아니라 정확한 행동으로 적고, «덜 생각해라» 류 문장은 쓰지 않습니다(Fable 5.2 가이드).
- `skills/guide-audit`: Fable 5.2 가이드의 점검 항목 N18~N26(상시 위임 지시, 쌓인 금지 규칙, 범주로 쓴 승인 규칙, 숫자로 된 문체 한도 등). 메모리·노트 파일도 읽습니다.
- `hooks/session-start.sh`는 bash 내장 기능만 씁니다(`grep`, `sed`, `tr`, `awk`, `cat`, 명령 치환 없음). Windows(Git Bash)에서는 프로세스나 하위 셸 하나를 띄우는 데 수십 밀리초가 들어서, 원본 방식으로는 실제 세션에서 4.6초가 걸렸습니다(2.1.316에서 측정, 제한 5초). 지금은 0.2~0.4초입니다. 도우미 함수는 결과를 출력하지 않고 `REPLY` 변수에 담습니다. `tests/hook-speed.sh`가 명령 치환이 다시 들어오는지와 실행 시간을 검사합니다. 바꾸기 전후의 출력은 설정·이벤트·모델 조합 60가지에서 바이트 단위로 같았습니다. macOS 기본 bash 3.2에서는 돌려 보지 못했습니다.
- `hooks/hooks.json`: 훅 제한 시간은 여유를 두어 15초입니다(원본 5초).
- `tests/guide-verbatim.sh`: 가이드 원문을 받아 `hooks/models/`의 모든 문단을 대조합니다. 가이드가 바뀌거나 근거 없는 문단이 들어오면 실패합니다. `curl`, `perl`, 네트워크가 필요합니다.
- `tests/context-size.sh`: 모델별 규칙을 붙인 최악 경우(무인 + max effort)의 크기도 잽니다. 훅이 넣는 글은 10,000자를 넘으면 잘립니다.

## Codex에서 쓰기

`guide-rewrite`는 Codex 스킬로도 연결되어 있습니다 (`$guide-rewrite <요청>`).

```bash
ln -s <clone 경로>/prompt-polish/skills/guide-rewrite ~/.codex/skills/guide-rewrite
```

이 폴더를 직접 가리키므로 수정하면 Claude Code와 Codex 양쪽에 바로 반영됩니다(Claude Code는 플러그인 버전을 올리고 재설치해야 캐시가 바뀝니다). 나머지 세 스킬은 Claude Code 훅과 CLAUDE.md를 다루므로 Codex에 연결하지 않습니다.

## 새 모델이 나왔을 때

1. 그 모델의 프롬프팅 가이드를 읽고 `hooks/models/<이름>.md`를 만듭니다. 파일 이름은 가이드 주소의 끝부분과 같아야 합니다(`prompting-claude-<이름>`). 가이드의 예시 프롬프트를 그대로 쓰고, 공통 규칙(`hooks/always-on.md`)과 겹치는 문장은 뺍니다. 원문은 주소 끝에 `.md`를 붙여 직접 받습니다. 요약 도구가 돌려준 인용문을 옮기지 않습니다.
2. `hooks/session-start.sh`의 `model_file`에 한 줄을 넣습니다. 기본 effort가 다르면 `model_traits`도, 별칭이 옮겨 갔으면 `model_from_settings`도 고칩니다.
3. `tests/context-size.sh`의 모델 목록에 넣고 `bash tests/context-size.sh`, `bash tests/guide-verbatim.sh`, `bash tests/hook-speed.sh`를 돌립니다.
4. 가이드가 «이전 모델용 지시를 지워라»고 하는 항목은 `skills/guide-audit/references/guide-sections.md`의 모델별 주의점에 넣습니다.

## 원본 업데이트 반영

원본이 새 버전을 내면 `~/.claude/plugins/marketplaces/oh-my-fable`(없으면 원본 저장소 clone)과 이 폴더를 diff 해서 옮깁니다. 2.7.4로 올릴 때는 원본을 통째로 복사한 뒤 fork 변경분을 다시 넣었습니다. 이 fork가 바꾼 파일은 위 목록과 `.claude-plugin/plugin.json`, `hooks/hooks.json`, `hooks/card/parse.ts`(블록 P 인식 한 줄), `skills/guide-rewrite/SKILL.md`, `skills/guide-rewrite/references/{examples,prompt-blocks}.md`, `skills/guide-status/SKILL.md`, 그리고 이름 변경이 닿은 파일들입니다. 원본 파일을 옮길 때는 `fable-*` 이름을 `guide-*`로, `/fable`을 `/guide-rewrite`로 바꿔서 옮깁니다. 원본의 `README*.md`, `.claude-plugin/marketplace.json`, `_config.yml`, 사이트 인증용 html은 가져오지 않습니다.
