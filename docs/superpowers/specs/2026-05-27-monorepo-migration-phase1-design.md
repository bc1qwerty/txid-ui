# Monorepo Migration Phase 1 — Design Spec

**Date:** 2026-05-27
**Author:** seo + Claude
**Status:** Approved by user (brainstorming complete)

## Goal

9 repo (txid-ui + 8 Astro consumer sites)를 단일 monorepo `bc1qwerty/txid`로 전환. Phase 1은 가장 안전한 1 lib + 1 사이트로 패턴 검증 (libs/ui + apps/sim). Phase 2/3은 별도 spec.

## Why

[[feedback_multi_repo_git_consistency]] 에서 "txid-ui PR + 8 consumer main commit 혼재로 drift 위험" 명시. 오늘 (2026-05-27) Pill Capsule 작업 중 실제로 drift 발생 (PR #2 머지 후 Header.astro 의도치 않은 scoped 회귀). monorepo로 single source-of-truth + atomic cross-package 변경 가능.

## Architecture

### 도구
- **Package manager**: pnpm 9+ (현 npm 사용 → pnpm 전환)
- **Workspace orchestrator**: nx 20+ (`nx.json` + 각 project `project.json`)
- **Workspace recognition**: `pnpm-workspace.yaml` (apps/*, libs/*)
- **Node**: 22 (현 사용 버전 유지)
- **Astro plugin**: `@nx/astro` 우선 검증, 없으면 plain nx executor + pnpm script

### 디렉토리 구조

```
github.com/bc1qwerty/txid (신규)
├── apps/
│   └── sim/                     # sim.txid.uk-astro에서 마이그레이션 (history 보존)
├── libs/
│   └── ui/                      # txid-ui에서 마이그레이션 (history 보존)
├── nx.json                      # nx workspace 설정
├── pnpm-workspace.yaml          # apps/*, libs/* 인식
├── package.json                 # root deps, scripts
├── .github/workflows/
│   └── deploy-sim.yml           # sim 빌드 + wrangler deploy → sim-txid-uk project
├── docs/superpowers/specs/      # 이 spec doc 이동
└── CLAUDE.md                    # monorepo 안내, 4 머신 mesh 정책
```

### Phase 2 확장 예고 (out of scope이지만 참고)
- apps/id, apps/apps-showcase, apps/dev, apps/tools, apps/tx, apps/map, apps/portfolio
- Phase 2 끝나면 sync.sh 폐기 + 구 txid-ui repo archive

## Migration Steps (Phase 1)

1. **새 repo 생성**: `gh repo create bc1qwerty/txid --private --description "txid.uk monorepo"` (private 시작, 안정화 후 public 검토)
2. **monorepo 셋업**: 
   - `pnpm dlx create-nx-workspace@latest txid --preset=empty --packageManager=pnpm`
   - `nx init` (또는 위 명령으로 자동)
   - `pnpm-workspace.yaml` 생성 (`packages: - 'apps/*' - 'libs/*'`)
   - `nx.json` 기본 설정 + Astro target 정의
3. **txid-ui → libs/ui 마이그레이션** (history 보존):
   ```bash
   git clone --bare https://github.com/bc1qwerty/txid-ui /tmp/txid-ui-bare
   cd /tmp/txid-ui-bare
   git filter-repo --to-subdirectory-filter libs/ui
   cd /home/seo/txid (new monorepo clone)
   git remote add txid-ui /tmp/txid-ui-bare
   git fetch txid-ui
   git merge txid-ui/main --allow-unrelated-histories
   ```
4. **sim → apps/sim 마이그레이션** (동일 패턴, sim.txid.uk-astro → apps/sim/)
5. **의존성 해결**:
   - sim의 `package.json`에서 `"@txid/ui": "file:./packages/txid-ui"` → `"@txid/ui": "workspace:*"`
   - sim 내 `packages/txid-ui/` 디렉토리 삭제 (workspace dep으로 대체)
   - sim의 `src/components/ui/*` (sync.sh 복사본) 삭제 → import 경로를 `@txid/ui`로 변경
6. **빌드 검증**: `pnpm install` → `pnpm --filter sim build` 또는 `nx build sim`. dist 출력 확인.
7. **GHA workflow 생성** (`.github/workflows/deploy-sim.yml`):
   - 트리거: `push: paths: ['apps/sim/**', 'libs/ui/**', 'pnpm-lock.yaml']`
   - actions/checkout + pnpm/action-setup + pnpm install + nx build sim
   - cloudflare/wrangler-action: `pages deploy apps/sim/dist --project-name=sim-txid-uk --branch=main`
8. **Secret 설정**: `gh secret set CLOUDFLARE_API_TOKEN` + `gh secret set CLOUDFLARE_ACCOUNT_ID` (다른 사이트 repo와 동일 값)
9. **첫 push → 라이브 검증**: `curl -sI https://sim.txid.uk/ko/` 응답 확인 + GHA success
10. **구 sim.txid.uk-astro repo archive**: README에 "moved to bc1qwerty/txid (apps/sim/)" 노트 + GitHub Settings → Archive
11. **4 머신 mesh 갱신**: office (현 머신) + acer/dell/gram에서 새 monorepo clone, 구 sim repo는 read-only

## Out of Scope (Phase 2/3)

- 나머지 7 사이트 (id/apps/dev/tools/tx/map/portfolio) 마이그레이션 → **Phase 2 별도 spec**
- 기존 txid-ui repo archive → Phase 2 종료 후 (그 때까지는 sync.sh로 나머지 7 사이트에 변경 propagate)
- nx affected build/cache 최적화 → Phase 2 후 별도
- monorepo CLAUDE.md 작성 (4 머신 정책, sync.sh 폐기 안내) → Phase 1 마지막 단계로 포함 가능

## Risks

| # | Risk | Mitigation |
|---|------|------------|
| 1 | nx Astro plugin 호환성 (Astro 6) | Phase 1에서 nx 공식/제3자 plugin 검증, 안 되면 plain nx executor + pnpm script로 폴백 |
| 2 | CF Pages secret 누락 | 새 monorepo repo에 `CLOUDFLARE_API_TOKEN` + `CLOUDFLARE_ACCOUNT_ID` 미리 설정 (`gh secret set`, id repo와 동일 값) |
| 3 | 기존 sim-txid-uk CF Pages project 충돌 | 새 monorepo에서 동일 `--project-name=sim-txid-uk` 사용 (브랜치 명 main 유지). CF 단일 project에 commit가 두 repo에서 오는 형태는 잠시 OK이지만, 구 repo archived 후 단일 source |
| 4 | git filter-repo SHA 변경 → 외부 참조 (feedback memory commit hash) 깨짐 | 일부 메모리의 commit hash stale. README에 "Moved from bc1qwerty/txid-ui at SHA X / bc1qwerty/sim.txid.uk-astro at SHA Y" 명시. 구 repo archive로 history 조회 가능 |
| 5 | 4 머신 mesh drift | 마이그레이션 직후 4 머신에서 구 sim repo `git fetch` 금지 + 새 monorepo clone. CLAUDE.md에 명시. 마이그레이션 commit 전에 사용자에게 4 머신 git status 확인 요청 |
| 6 | sync.sh 부분 종료 (Phase 1 중) | Phase 1 직후 sync.sh는 **나머지 7 사이트에만** 작동 (sim 제외). libs/ui로 옮긴 monorepo는 workspace dep로 native sync. 구 txid-ui repo는 Phase 2 종료까지 **계속 active** (7 사이트 source) — read-only 전환은 Phase 3에서 |
| 7 | 점진 마이그레이션 중 txid-ui 양쪽 존재 (구 repo + monorepo libs/ui) | **방향성 규칙**: Phase 1~2 동안 모든 변경은 monorepo libs/ui에서 시작 → 변경 commit 후 사용자가 구 txid-ui repo에 `git cherry-pick <SHA>` 수동 동기화 (또는 patch 파일로 적용). 반대 방향(구 txid-ui에서 monorepo로)은 금지. CLAUDE.md에 규칙 명시 |

## Rollback

- **새 monorepo deploy 실패**: GitHub에서 sim.txid.uk-astro repo unarchive → 그 repo의 main에서 push → GHA로 라이브 복구 (1분 내)
- **nx 설정 오류**: 새 monorepo에서 nx config revert commit + 재 push
- **CF Pages 빌드 실패**: secret/wrangler 명령 확인 + 안 되면 임시 수동 `npx wrangler pages deploy apps/sim/dist --project-name=sim-txid-uk --branch=main`
- **점진 단계 자체 포기**: 새 monorepo `bc1qwerty/txid` archive + 구 sim repo unarchive + 일상 복귀 (변경 commit 손실 없음 — 구 repo SHA로 추적 가능)

## Success Criteria

1. 새 `bc1qwerty/txid` repo 생성 + Phase 1 끝 시점 main에 libs/ui + apps/sim 둘 다 존재
2. `pnpm install` + `pnpm --filter sim build` 성공
3. GHA Deploy success + 라이브 `https://sim.txid.uk/ko/` 응답 정상 (chrome/wiring 동작)
4. 구 sim.txid.uk-astro repo archived + README에 monorepo 위치 명시
5. 4 머신에서 새 monorepo clone 가능 (사용자 수동 진행)
6. Phase 2 plan 후속 진행 가능 상태 (구조 일관, sync.sh 부분 작동)

## References

- [[feedback_multi_repo_git_consistency]] (원래 motivation)
- [[project_txid_ui_chrome_pill_unification_2026_05_27]] (PR #2 머지 후 drift 발생 = monorepo 필요성 입증)
- [[project_txid_ui_header_unification_2026_05_27]] (Phase 2 wiring 통합)
- nx docs: https://nx.dev/getting-started
- pnpm workspaces: https://pnpm.io/workspaces
- git filter-repo: https://github.com/newren/git-filter-repo
