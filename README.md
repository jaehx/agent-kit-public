# agent-kit-public

직접 만들어 쓰는 Claude Code 플러그인·스킬 모음입니다.

## 구성

| 플러그인 | 내용 |
|---|---|
| `my-prompting` | [oh-my-fable](https://github.com/Junhan2/oh-my-fable)을 fork한 모델별 프롬프팅 규칙. 요청을 공식 프롬프팅 가이드에 맞게 다듬는 `guide-rewrite` 스킬 포함 ([FORK.md](my-prompting/FORK.md)) |
| `my-skills` | `project-handoff`: 다음 세션·다른 에이전트용 인수인계를 저장소에 기록하고 재개 |

## 설치 (Claude Code)

```
/plugin marketplace add morest432/agent-kit-public
/plugin install my-prompting@my-plugins
/plugin install my-skills@my-plugins
```

갱신은 `/plugin marketplace update my-plugins`로 받습니다.

## 라이선스

MIT. 단, `my-prompting/`은 원본 저작자(Junhan2)의 MIT 라이선스를 따릅니다.
