# prompt-polish

[oh-my-fable](https://github.com/Junhan2/oh-my-fable) 2.2.0(Junhan2, MIT)을 개인용으로 fork한 플러그인입니다. 원본 LICENSE와 README는 그대로 두었습니다.

## 원본과 다른 점

- `hooks/models/*.md`: 모델별 규칙 4개 (Fable 5.1, Opus 5.5, Opus 5, Sonnet 5). 각 모델의 Anthropic 공식 프롬프팅 가이드 문구에서 가져왔습니다.
- `hooks/session-start.sh`: 세션 시작 때 `model` 입력으로 해당 파일을 덧붙이고, `/model`로 모델이 바뀌면(PostModelSwitch) 새 모델의 규칙으로 교체합니다. 모르는 모델은 공통 규칙만 적용합니다.
- 마지막으로 본 모델은 `~/.claude/prompt-polish.last-model`에 기억합니다 (`/clear` 직후처럼 model 입력이 빠질 때 사용).
- 하위 에이전트에는 모델별 규칙이 가지 않고 공통 규칙만 갑니다.
- 스킬 이름: 원본의 `fable-*`를 `guide-*`로 바꿨습니다 (`fable-prompt` → `guide-rewrite`, `fable-audit` → `guide-audit`, `fable-setup` → `guide-setup`, `fable-status` → `guide-status`). 이 fork가 Fable 전용이 아니기 때문입니다. `oh-my-fable.json`, `oh-my-fable:rules` 마커 같은 내부 식별자는 원본과의 호환을 위해 그대로 둡니다. README 3종의 명령 이름도 같이 바꿨습니다.
- `skills/guide-rewrite/references/openai-blocks.md`: OpenAI 공식 가이드("Using GPT-6", Codex "Best practices", AGENTS.md 문서)의 블록 O1~O8. `guide-rewrite`는 실행 중인 모델이 GPT면 이 파일을, Claude면 `prompt-blocks.md`를 씁니다.

## Codex에서 쓰기

`guide-rewrite`는 Codex 스킬로도 연결되어 있습니다 (`$guide-rewrite <요청>`).

```bash
ln -s <clone 경로>/prompt-polish/skills/guide-rewrite ~/.codex/skills/guide-rewrite
```

이 폴더를 직접 가리키므로 수정하면 Claude Code와 Codex 양쪽에 바로 반영됩니다(Claude Code는 플러그인 버전을 올리고 재설치해야 캐시가 바뀝니다). 나머지 세 스킬은 Claude Code 훅과 CLAUDE.md를 다루므로 Codex에 연결하지 않습니다.

## 원본 업데이트 반영

원본이 새 버전을 내면 `~/.claude/plugins/marketplaces/oh-my-fable`과 이 폴더를 diff 해서 필요한 변경만 옮깁니다. 이 fork에서 바꾼 파일은 위 목록과 `.claude-plugin/plugin.json`, `hooks/hooks.json`, `skills/guide-rewrite/SKILL.md`, `skills/guide-rewrite/references/examples.md`, 그리고 이름 변경이 닿은 파일들입니다. 원본 파일을 옮길 때는 `fable-*` 이름을 `guide-*`로 바꿔서 옮깁니다.
