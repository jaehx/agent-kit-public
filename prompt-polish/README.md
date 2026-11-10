# prompt-polish

모델별 공식 프롬프팅 가이드의 작업 규칙을 Claude Code 세션마다 자동으로 넣고, 대충 쓴 요청을 가이드에 맞게 다듬어 실행하는 플러그인입니다.

[oh-my-fable](https://github.com/Junhan2/oh-my-fable) 2.7.4(Junhan2, MIT)를 fork했습니다. 원본과 다른 점은 [FORK.md](FORK.md)에 있습니다.

## 설치

Claude Code에서 실행합니다.

```
/plugin marketplace add jaehx/agent-kit-public
/plugin install prompt-polish@agent-kit
```

- 새 세션부터 적용됩니다. 설치한 세션에서 바로 쓰려면 `/reload-plugins`를 실행한 다음 `/clear`를 실행하세요.
- 원본 oh-my-fable과 같이 켜지 마세요. 공통 규칙이 두 번 들어갑니다. 원본을 쓰고 있었다면 먼저 `claude plugin uninstall oh-my-fable@oh-my-fable`을 실행하세요.
- 요구 사항: Claude Code 2.1.258 이상. Windows는 훅이 bash로 실행되므로 Git for Windows(Git Bash)가 필요합니다.

## 설치하면 자동으로 되는 것

세션이 시작될 때와 `/model`로 모델을 바꿀 때 훅이 규칙을 넣습니다. 파일은 만들지 않습니다.

| 층 | 내용 | 언제 |
|---|---|---|
| 공통 규칙 | 끝까지 하기, 범위 제한, 부분 편집, 진행 보고, 서식, 도구 일괄 호출 | 항상 |
| 무인 실행 문단 | «사용자가 지켜보고 있지 않다», «중간 보고로 멈추지 말라» | `claude -p`, Agent SDK 같은 무인 세션 |
| 높은 effort 문단 | 검사가 통과하면 멈추고, 스스로 검토를 반복하지 않기 | effort가 `xhigh`·`max`일 때 |
| 모델별 규칙 | 세션 모델의 공식 가이드에서 가져온 규칙 | Fable 5.2, Opus 5.5, Sonnet 5.5, Haiku 5.5, Opus 5, Sonnet 5 |

- 표에 없는 모델은 공통 규칙만 받고, 시작 줄에 `model rules: none for <모델>`이 표시됩니다.
- 하위 에이전트는 짧은 공통 규칙만 받습니다.

## 스킬

| 명령 | 하는 일 | 파일 수정 |
|---|---|---|
| `/guide-rewrite <요청>` | 짧거나 막연한 요청을 목표·맥락·범위·완료 기준으로 채워 보여 주고 바로 실행합니다. 뒤에 `프롬프트만`을 붙이면 보여 주기만 합니다 | 없음 |
| `/guide-status` | 지금 적용 중인 규칙을 표 하나로 보여 줍니다 (버전, 규칙 위치, 모드, effort, 모델별 규칙) | 없음 |
| `/guide-audit [대상]` | CLAUDE.md·규칙 파일·에이전트 프롬프트를 가이드와 대조해 빠진 것과 충돌하는 것을 보여 줍니다 | 없음 |
| `/guide-setup [인자]` | 기본값을 바꿀 때만 씁니다. 규칙을 파일로 두기, 모드 고정, `remove`로 되돌리기 | 있음 |

`guide-rewrite`는 슬래시 명령으로만 실행됩니다. 다른 스킬과 이름이 겹치면 `/prompt-polish:guide-rewrite`처럼 플러그인 이름을 붙이세요.

## 더 읽을 것

- [FORK.md](FORK.md): 원본과 다른 점, Codex에서 쓰는 법, 새 모델이 나왔을 때 할 일.
- [원본 README](https://github.com/Junhan2/oh-my-fable#readme): 작동 원리, 증상별 처방, FAQ. 원본의 `/fable`은 여기서 `/guide-rewrite`이고, `/fable-*`은 `/guide-*`입니다. 설치 명령은 원본 것이니 따라 하지 마세요.

## 검사

```bash
bash tests/guide-verbatim.sh   # 모델 규칙의 문단을 가이드 원문과 대조 (네트워크 필요)
bash tests/context-size.sh     # 훅이 넣는 글의 크기 (10,000자 한도)
bash tests/hook-speed.sh       # 훅 실행 시간, 외부 명령이 다시 들어왔는지
```

## 라이선스

MIT. 원본 © Junhan2. 가이드 원문의 저작권은 Anthropic에 있습니다.
