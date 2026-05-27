# Monorepo Migration Phase 1 — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** `bc1qwerty/txid` monorepo를 새로 생성하고 txid-ui (→ `libs/ui`) + sim.txid.uk-astro (→ `apps/sim`) 두 repo의 history를 보존하며 마이그레이션 + sim 라이브 deploy 동작 검증.

**Architecture:** pnpm 9+ workspaces + nx 20+ orchestrator. `apps/<short-name>` + `libs/<name>` 디렉토리 표준. git filter-repo로 history 보존 + subtree merge. CF Pages는 기존 sim-txid-uk project를 새 monorepo의 GHA에서 deploy.

**Tech Stack:** pnpm 9+, nx 20+, @nx/astro plugin (또는 plain nx executor), git filter-repo, gh CLI, cloudflare/wrangler-action@v3.

**Spec:** `docs/superpowers/specs/2026-05-27-monorepo-migration-phase1-design.md` (branch `spec/monorepo-migration-phase1`)

---

## 사전 도구 점검

### Task 0: pnpm + git filter-repo 설치 확인

**Files:** N/A (시스템 도구 확인)

- [ ] **Step 1: pnpm 버전 확인**

```bash
pnpm --version
```

Expected: `9.x.x` 이상. 없으면: `npm install -g pnpm@latest`.

- [ ] **Step 2: git filter-repo 확인**

```bash
git filter-repo --version
```

Expected: 버전 출력. 없으면 Ubuntu: `sudo apt install git-filter-repo`. 또는 pip: `pip install git-filter-repo`.

- [ ] **Step 3: nx 확인 (선택, 워크스페이스 생성 시 자동 받음)**

```bash
pnpm dlx nx --version 2>&1 | head -3
```

Expected: latest version 사용 가능 (caching이라 download 발생).

---

## Phase A — monorepo 셋업

### Task 1: 새 `bc1qwerty/txid` repo 생성

**Files:** N/A (GitHub repo 생성)

- [ ] **Step 1: GitHub repo 생성 (private 시작)**

```bash
gh repo create bc1qwerty/txid --private --description "txid.uk monorepo (pnpm + nx)"
```

Expected: `https://github.com/bc1qwerty/txid` 출력.

- [ ] **Step 2: 로컬 clone**

```bash
cd /home/seo && gh repo clone bc1qwerty/txid
```

Expected: `Cloning into 'txid'...` `warning: You appear to have cloned an empty repository.`

### Task 2: nx workspace 초기화

**Files:**
- Create: `/home/seo/txid/nx.json`
- Create: `/home/seo/txid/package.json`
- Create: `/home/seo/txid/.gitignore`

- [ ] **Step 1: nx workspace 생성 (empty preset, pnpm package manager)**

```bash
cd /home/seo
pnpm dlx create-nx-workspace@latest txid-tmp --preset=npm --packageManager=pnpm --workspaceType=integrated --formatter=prettier --ci=skip --nxCloud=skip
```

Expected: `txid-tmp/` 디렉토리에 nx skeleton 생성.

`--preset=npm` (또는 `package-based`): 가장 가벼운 nx + pnpm workspaces 구조. 추후 Astro 빌드는 plain pnpm script로 처리하고 nx는 task orchestrator로만 사용.

- [ ] **Step 2: 생성된 파일을 새 monorepo로 이동**

```bash
cd /home/seo/txid-tmp
cp -r nx.json package.json pnpm-workspace.yaml .gitignore .prettierrc .editorconfig /home/seo/txid/ 2>/dev/null || true
# tsconfig.base.json 등도 있으면 같이 복사
ls /home/seo/txid/
rm -rf /home/seo/txid-tmp
```

Expected: `/home/seo/txid/` 에 `nx.json`, `package.json`, `pnpm-workspace.yaml`, `.gitignore` 등 존재.

- [ ] **Step 3: pnpm-workspace.yaml 갱신 (apps/* + libs/* 인식)**

`/home/seo/txid/pnpm-workspace.yaml` 내용:

```yaml
packages:
  - 'apps/*'
  - 'libs/*'
```

- [ ] **Step 4: package.json root 정리**

`/home/seo/txid/package.json` (이름/private 확인 + nx scripts):

```json
{
  "name": "txid",
  "version": "0.0.1",
  "private": true,
  "scripts": {
    "build": "nx run-many -t build",
    "lint": "nx run-many -t lint",
    "test": "nx run-many -t test"
  },
  "devDependencies": {
    "nx": "latest"
  }
}
```

(create-nx-workspace가 생성한 내용을 위 형태로 맞추거나 그대로 둠. nx version은 그대로.)

- [ ] **Step 5: 초기 commit**

```bash
cd /home/seo/txid
git add .
git commit -m "chore(monorepo): bootstrap nx + pnpm workspaces

Empty nx workspace, package-based preset. Ready for libs/ui and
apps/sim migration (Phase 1).

Spec: see Phase 1 design doc (will be migrated from txid-ui)."
git push -u origin main
```

Expected: 첫 commit push 완료, GitHub에 노출.

### Task 3: 디렉토리 골격 + 기본 docs

**Files:**
- Create: `/home/seo/txid/apps/.gitkeep`
- Create: `/home/seo/txid/libs/.gitkeep`
- Create: `/home/seo/txid/CLAUDE.md`
- Create: `/home/seo/txid/README.md`

- [ ] **Step 1: 빈 디렉토리 생성 + .gitkeep**

```bash
cd /home/seo/txid
mkdir -p apps libs docs/superpowers/{specs,plans}
touch apps/.gitkeep libs/.gitkeep
```

- [ ] **Step 2: CLAUDE.md 작성**

`/home/seo/txid/CLAUDE.md`:

```markdown
# txid monorepo

## Language
- Respond in Korean (한국어로 응답)

## Tech Stack
- **Package manager**: pnpm 9+
- **Workspace orchestrator**: nx 20+
- **Node**: 22

## Structure
- `apps/*` — Astro sites (각 사이트당 1개)
- `libs/*` — 공용 라이브러리 (txid-ui 등)

## Phase 1 Migration Status
Phase 1: libs/ui + apps/sim — in progress

Other 7 sites (id/apps-showcase/dev/tools/tx/map/portfolio) still in
their own repos (bc1qwerty/<name>.txid.uk-astro). They use sync.sh
from bc1qwerty/txid-ui (still active until Phase 2 ends).

## Multi-Machine Mesh Policy (Phase 1 fragile period)
- During Phase 1, do NOT push to bc1qwerty/sim.txid.uk-astro from any
  machine. Use this monorepo's apps/sim/ exclusively.
- Each of 4 machines (office/acer/dell/gram) must clone this repo via
  `gh repo clone bc1qwerty/txid` before working on sim.
- For other 7 sites, continue using their own repos until Phase 2.

## Change Direction Rule (libs/ui ↔ bc1qwerty/txid-ui)
- All UI changes start here in libs/ui.
- After commit, manually cherry-pick into bc1qwerty/txid-ui (for sync.sh
  consumers). Reverse direction (txid-ui → libs/ui) is FORBIDDEN.
- This rule ends when Phase 2 completes and txid-ui is archived.
```

- [ ] **Step 3: README.md 작성**

`/home/seo/txid/README.md`:

```markdown
# txid monorepo

txid.uk platform monorepo.

## Status
- Phase 1: libs/ui + apps/sim migrated. Other sites pending.

## Setup
```bash
pnpm install
nx build sim
```

## Layout
- `apps/sim/` — sim.txid.uk
- `libs/ui/` — @txid/ui shared components

See `docs/superpowers/specs/` for migration design.
```

- [ ] **Step 4: Commit**

```bash
git add apps/.gitkeep libs/.gitkeep CLAUDE.md README.md docs/
git commit -m "docs(monorepo): CLAUDE.md + README + dir skeleton

Multi-machine mesh policy and change direction rule documented to
prevent drift during Phase 1 (when both monorepo and old repos coexist)."
git push
```

### Task 4: Spec/plan doc을 monorepo로 이동

**Files:**
- Move: `/home/seo/txid-ui/docs/superpowers/specs/2026-05-27-monorepo-migration-phase1-design.md` → `/home/seo/txid/docs/superpowers/specs/`
- Move: `/home/seo/txid-ui/docs/superpowers/plans/2026-05-27-monorepo-migration-phase1.md` → `/home/seo/txid/docs/superpowers/plans/`

- [ ] **Step 1: 파일 복사**

```bash
cp /home/seo/txid-ui/docs/superpowers/specs/2026-05-27-monorepo-migration-phase1-design.md /home/seo/txid/docs/superpowers/specs/
cp /home/seo/txid-ui/docs/superpowers/plans/2026-05-27-monorepo-migration-phase1.md /home/seo/txid/docs/superpowers/plans/
```

- [ ] **Step 2: monorepo commit**

```bash
cd /home/seo/txid
git add docs/superpowers/
git commit -m "docs(spec): copy phase 1 migration spec + plan from txid-ui

Originals stay in txid-ui's spec/monorepo-migration-phase1 branch for
reference. This monorepo is now the canonical location."
git push
```

(원본은 그대로 둠. Phase 1 종료 후 txid-ui repo cleanup 시 제거.)

---

## Phase B — txid-ui → libs/ui 마이그레이션

### Task 5: git filter-repo로 txid-ui history 변환

**Files:**
- Create: `/tmp/txid-ui-bare` (작업용 bare clone, 끝에 삭제)

- [ ] **Step 1: 작업용 bare clone**

```bash
git clone --bare https://github.com/bc1qwerty/txid-ui /tmp/txid-ui-bare
```

Expected: `Cloning into bare repository '/tmp/txid-ui-bare'...`

- [ ] **Step 2: 모든 파일을 libs/ui/ subdirectory로 옮김 (filter-repo)**

```bash
cd /tmp/txid-ui-bare
git filter-repo --to-subdirectory-filter libs/ui --force
```

Expected: `Parsed N commits` + history rewrite 완료.

- [ ] **Step 3: 결과 확인**

```bash
git log --oneline | head -5
# 각 commit이 그대로지만 모든 파일이 libs/ui/ 안에 있어야 함
git ls-tree HEAD | head -3
```

Expected: `libs` directory 한 줄만 보임.

### Task 6: monorepo에 subtree merge

**Files:** monorepo의 `libs/ui/` 디렉토리 채워짐

- [ ] **Step 1: 새 remote 추가 + fetch**

```bash
cd /home/seo/txid
git remote add txid-ui-import /tmp/txid-ui-bare
git fetch txid-ui-import
```

- [ ] **Step 2: unrelated histories merge**

```bash
git merge txid-ui-import/main --allow-unrelated-histories -m "feat(libs/ui): import bc1qwerty/txid-ui (history preserved via git filter-repo)

Original repo: github.com/bc1qwerty/txid-ui
Imported via: git filter-repo --to-subdirectory-filter libs/ui

All commits + blame preserved with SHAs rewritten under libs/ui/ prefix.
Old repo remains active during Phase 1~2 (sync.sh consumers); will be
archived after Phase 2 completes."
```

Expected: merge commit 생성. `libs/ui/` 디렉토리에 components/, styles/, data/, package.json 등 보임.

- [ ] **Step 3: 검증 + push**

```bash
ls libs/ui/  # components/, styles/, data/, package.json 등
cat libs/ui/package.json | head -5  # name: @txid/ui
git remote remove txid-ui-import
git push
```

### Task 7: libs/ui workspace dep 등록 + 빌드 검증

**Files:**
- Modify: `/home/seo/txid/libs/ui/package.json` (이미 존재, name 확인)

- [ ] **Step 1: libs/ui/package.json name 확인**

```bash
grep '"name"' /home/seo/txid/libs/ui/package.json
```

Expected: `"name": "@txid/ui"`. 다르면 그대로 둠 (txid-ui 원본 유지).

- [ ] **Step 2: pnpm install (workspace dep 등록)**

```bash
cd /home/seo/txid
pnpm install
```

Expected: `Done` + `libs/ui` 가 workspace로 인식됨. node_modules/.pnpm 안에 link.

- [ ] **Step 3: 검증 + commit (lockfile)**

```bash
ls -la node_modules/@txid/ui  # symlink → libs/ui
git add pnpm-lock.yaml
git commit -m "chore(deps): pnpm install — @txid/ui workspace link verified

libs/ui registered as @txid/ui workspace package. Consumers (apps/sim
coming next) can declare workspace:* dependency."
git push
```

---

## Phase C — sim → apps/sim 마이그레이션

### Task 8: git filter-repo로 sim history 변환

**Files:**
- Create: `/tmp/sim-bare`

- [ ] **Step 1: bare clone**

```bash
git clone --bare https://github.com/bc1qwerty/sim.txid.uk-astro /tmp/sim-bare
```

- [ ] **Step 2: apps/sim/ subdirectory로 변환**

```bash
cd /tmp/sim-bare
git filter-repo --to-subdirectory-filter apps/sim --force
```

- [ ] **Step 3: 검증**

```bash
git log --oneline | head -3
git ls-tree HEAD  # apps만 보여야 함
```

### Task 9: monorepo에 subtree merge

- [ ] **Step 1: remote + fetch + merge**

```bash
cd /home/seo/txid
git remote add sim-import /tmp/sim-bare
git fetch sim-import
git merge sim-import/main --allow-unrelated-histories -m "feat(apps/sim): import bc1qwerty/sim.txid.uk-astro (history preserved)

Original repo: github.com/bc1qwerty/sim.txid.uk-astro
Imported via: git filter-repo --to-subdirectory-filter apps/sim

All commits + blame preserved under apps/sim/ prefix. Old repo will be
archived after Phase 1 deploy verification."
```

- [ ] **Step 2: 검증**

```bash
ls apps/sim/  # src/, public/, package.json, astro.config.mjs 등
cat apps/sim/package.json | grep '"name"'
git remote remove sim-import
```

- [ ] **Step 3: 중간 push**

```bash
git push
```

### Task 10: sim의 file: 의존을 workspace 의존으로 전환 + 중복 제거

**Files:**
- Modify: `/home/seo/txid/apps/sim/package.json` (의존 변경)
- Delete: `/home/seo/txid/apps/sim/packages/txid-ui/` (구 sync.sh 복사본)
- Delete: `/home/seo/txid/apps/sim/src/components/ui/` (구 sync.sh 복사본 — Header.astro, Footer.astro 등)

- [ ] **Step 1: apps/sim/package.json의 @txid/ui 의존 변경**

`/home/seo/txid/apps/sim/package.json` 의 `dependencies` 안:

```json
"@txid/ui": "workspace:*"
```

(기존 값 `"file:./packages/txid-ui"` 또는 비슷한 형태)

- [ ] **Step 2: sync된 packages/txid-ui 디렉토리 삭제**

```bash
rm -rf /home/seo/txid/apps/sim/packages/txid-ui
# packages 디렉토리가 비면 함께 삭제
rmdir /home/seo/txid/apps/sim/packages 2>/dev/null || true
```

- [ ] **Step 3: src/components/ui/* sync 복사본 삭제 (Header/Footer/SharedLayout)**

```bash
ls /home/seo/txid/apps/sim/src/components/ui/
rm -rf /home/seo/txid/apps/sim/src/components/ui/
```

Expected: 디렉토리 사라짐. import 경로는 `@txid/ui/components/Header.astro` 형태라 workspace dep으로 자동 resolve.

- [ ] **Step 4: pnpm install 재실행**

```bash
cd /home/seo/txid
pnpm install
```

Expected: 의존 해결, workspace symlink 생성.

- [ ] **Step 5: 빌드 검증**

```bash
cd /home/seo/txid/apps/sim
pnpm build
```

Expected: `[build] Complete!` + `dist/` 생성 + `[csp-hash]` 정상 출력.

만약 빌드 실패: import 경로 누락된 곳 찾아서 수정 (예: 일부 페이지가 상대 경로로 `../components/ui/Header.astro` 참조하던 경우 `@txid/ui/components/Header.astro`로 변경).

- [ ] **Step 6: commit + push**

```bash
cd /home/seo/txid
git add apps/sim/package.json pnpm-lock.yaml
git rm -rf apps/sim/packages apps/sim/src/components/ui
git commit -m "refactor(apps/sim): drop sync.sh copies, use workspace:* dep

- @txid/ui dependency: file:./packages/txid-ui → workspace:*
- Removed apps/sim/packages/txid-ui (sync.sh copy)
- Removed apps/sim/src/components/ui (sync.sh copy of Header/Footer/SharedLayout)

Build verified: pnpm --filter sim build succeeds + dist generates."
git push
```

---

## Phase D — CI/CD + 배포

### Task 11: nx project 등록 (sim 빌드 명령 정의)

**Files:**
- Create: `/home/seo/txid/apps/sim/project.json`

- [ ] **Step 1: project.json 생성**

`/home/seo/txid/apps/sim/project.json`:

```json
{
  "name": "sim",
  "$schema": "../../node_modules/nx/schemas/project-schema.json",
  "sourceRoot": "apps/sim/src",
  "projectType": "application",
  "targets": {
    "build": {
      "executor": "nx:run-commands",
      "options": {
        "command": "pnpm --filter sim build",
        "cwd": "."
      },
      "outputs": ["{projectRoot}/dist"]
    },
    "preview": {
      "executor": "nx:run-commands",
      "options": {
        "command": "pnpm --filter sim preview",
        "cwd": "."
      }
    },
    "dev": {
      "executor": "nx:run-commands",
      "options": {
        "command": "pnpm --filter sim dev",
        "cwd": "."
      }
    }
  }
}
```

- [ ] **Step 2: nx graph로 인식 확인**

```bash
cd /home/seo/txid
npx nx show projects
```

Expected: `sim` (그리고 ui도 libs/ui/package.json 있으면 자동 인식).

- [ ] **Step 3: nx build로 실행 가능 확인**

```bash
npx nx build sim
```

Expected: pnpm --filter sim build 통해 빌드 성공.

- [ ] **Step 4: commit**

```bash
git add apps/sim/project.json
git commit -m "feat(nx): apps/sim project.json — build/dev/preview targets

Plain nx run-commands executor delegating to pnpm --filter sim. Keeps
build logic in apps/sim/package.json (Astro toolchain unchanged) and
lets nx orchestrate without needing @nx/astro plugin lock-in."
git push
```

### Task 12: GHA workflow + secret 설정

**Files:**
- Create: `/home/seo/txid/.github/workflows/deploy-sim.yml`

- [ ] **Step 1: secret 설정**

```bash
cd /home/seo/txid
gh secret set CLOUDFLARE_API_TOKEN --body "$CLOUDFLARE_API_TOKEN"
gh secret set CLOUDFLARE_ACCOUNT_ID --body "0be0b40c530d79edcb5d069fe308bb4a"
gh secret list  # 두 항목 확인
```

Expected:
- CLOUDFLARE_API_TOKEN: ...
- CLOUDFLARE_ACCOUNT_ID: ...

(env에 `CLOUDFLARE_API_TOKEN` 이미 있어야 함 — 오늘 세션 dev 작업에서 검증됨. 없으면 사용자가 wrangler login 또는 token 제공.)

- [ ] **Step 2: deploy-sim.yml 작성**

`/home/seo/txid/.github/workflows/deploy-sim.yml`:

```yaml
name: Deploy sim to Cloudflare Pages
on:
  push:
    branches: ["main"]
    paths:
      - 'apps/sim/**'
      - 'libs/ui/**'
      - 'pnpm-lock.yaml'
      - '.github/workflows/deploy-sim.yml'
  workflow_dispatch:

permissions:
  contents: read

env:
  FORCE_JAVASCRIPT_ACTIONS_TO_NODE24: true

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: pnpm/action-setup@v4
        with:
          version: 9

      - uses: actions/setup-node@v4
        with:
          node-version: 22
          cache: pnpm

      - run: pnpm install --frozen-lockfile

      - run: pnpm --filter sim build

      - uses: cloudflare/wrangler-action@v3
        with:
          apiToken: ${{ secrets.CLOUDFLARE_API_TOKEN }}
          accountId: ${{ secrets.CLOUDFLARE_ACCOUNT_ID }}
          command: pages deploy apps/sim/dist --project-name=sim-txid-uk --branch=main --commit-message="deploy"
```

`paths` 필터로 sim/ui 변경 시에만 트리거. 다른 사이트 (Phase 2 이후) 추가 시 각자 workflow 가짐.

- [ ] **Step 3: commit + push**

```bash
git add .github/workflows/deploy-sim.yml
git commit -m "ci(sim): GHA deploy workflow

Triggers on apps/sim/** or libs/ui/** changes. pnpm install + filter
build + wrangler-action to sim-txid-uk CF Pages project (same project
used by bc1qwerty/sim.txid.uk-astro — single source after that repo
is archived).

Secrets CLOUDFLARE_API_TOKEN + CLOUDFLARE_ACCOUNT_ID assumed set."
git push
```

### Task 13: 첫 자동 deploy + 라이브 검증

- [ ] **Step 1: GHA 트리거 확인**

```bash
cd /home/seo/txid
sleep 5
gh run list --limit 1 --json status,conclusion,name --jq '.[0]'
```

Expected: `status: in_progress` + `name: Deploy sim to Cloudflare Pages`.

- [ ] **Step 2: 완료 대기 (background)**

```bash
until gh run list --limit 1 --json status --jq '.[0].status' | grep -q completed; do sleep 8; done
gh run list --limit 1 --json status,conclusion,databaseId --jq '.[0]'
```

Expected: `conclusion: success`.

만약 failure → log 확인:

```bash
gh run view <databaseId> --log-failed | tail -40
```

흔한 실패 원인 + 대응:
- pnpm-lock.yaml 미생성 → 로컬에서 pnpm install + commit
- `@nx/astro` 또는 nx 의존 누락 → root package.json devDependencies 추가
- Astro 빌드 실패 → import 경로 확인

- [ ] **Step 3: 라이브 검증**

```bash
curl -sI https://sim.txid.uk/ko/ | head -3
curl -sL https://sim.txid.uk/ko/ | grep -oE 'id="txid-auth-mount"|class="lang-btn"' | sort -u
```

Expected: 200 OK + `id="txid-auth-mount"` + `class="lang-btn"` 모두 출력 (chrome 정상).

- [ ] **Step 4: lang 버튼 동작 확인 (사용자 수동)**

브라우저 https://sim.txid.uk/ko/ 접속 → 우측 EN 버튼 클릭 → 메뉴 열림 → KO/JA 클릭 → `/en/` 또는 `/ja/`로 라우팅 확인.

라이브 검증 통과해야 다음 step 진행.

### Task 14: 구 sim.txid.uk-astro repo archive

- [ ] **Step 1: 구 repo README에 monorepo 위치 명시**

먼저 구 repo clone (있으면 skip):

```bash
cd /home/seo/sim.txid.uk-astro
echo "" >> README.md
echo "## 🗄 Migrated" >> README.md
echo "" >> README.md
echo "This repo was migrated to **bc1qwerty/txid** monorepo on 2026-05-27." >> README.md
echo "Active development: https://github.com/bc1qwerty/txid (apps/sim/)" >> README.md
echo "" >> README.md
echo "History preserved via \`git filter-repo --to-subdirectory-filter apps/sim\`." >> README.md
git add README.md
git commit -m "docs: migrated to bc1qwerty/txid monorepo (apps/sim/)"
git push
```

- [ ] **Step 2: GitHub archive**

```bash
gh repo archive bc1qwerty/sim.txid.uk-astro --yes
```

Expected: `✓ Archived repository bc1qwerty/sim.txid.uk-astro`.

(언제든 unarchive 가능 — rollback 보장.)

- [ ] **Step 3: 로컬 작업트리 마킹**

```bash
cd /home/seo/sim.txid.uk-astro
echo "ARCHIVED on 2026-05-27 — moved to bc1qwerty/txid (apps/sim/)" > .ARCHIVED
git add .ARCHIVED
git commit -m "chore: mark local working tree as archived"
# Push 안 함 (repo이미 archived)
```

또는 단순히 `mv /home/seo/sim.txid.uk-astro /home/seo/sim.txid.uk-astro.archived-20260527`.

---

## Phase E — 4 머신 mesh 갱신 + 메모리

### Task 15: 4 머신 안내 메모 작성

**Files:**
- Modify: `/home/seo/.claude/projects/-home-seo/memory/MEMORY.md` + 새 메모리 file

- [ ] **Step 1: 새 project 메모리 작성**

`/home/seo/.claude/projects/-home-seo/memory/project_monorepo_txid_phase1_2026_05_27.md`:

```markdown
---
name: project-monorepo-txid-phase1-2026-05-27
description: "bc1qwerty/txid monorepo Phase 1 완료 — libs/ui + apps/sim 마이그레이션, history 보존, sim 라이브 검증 통과"
metadata:
  type: project
---

2026-05-27 Phase 1 마이그레이션 완료. nx + pnpm workspaces 기반.

**Result:**
- 새 repo: github.com/bc1qwerty/txid
- libs/ui (from bc1qwerty/txid-ui, history 보존)
- apps/sim (from bc1qwerty/sim.txid.uk-astro, history 보존)
- 구 sim repo archived (rollback 가능, history는 그대로)
- 구 txid-ui repo 계속 active (Phase 2 종료까지 — 나머지 7 사이트 sync.sh source)
- CF Pages sim-txid-uk project가 새 monorepo의 GHA에서 deploy

**Multi-machine policy (Phase 1 fragile 구간):**
- 4 머신 (office/acer/dell/gram) 모두 새 monorepo clone (`gh repo clone bc1qwerty/txid`)
- sim 작업은 monorepo apps/sim/ 에서만 (구 repo는 archived, push 안 됨)
- 다른 7 사이트는 각자 repo + sync.sh 계속 사용

**Change direction rule:**
- libs/ui 변경 → cherry-pick으로 bc1qwerty/txid-ui에 sync (7 사이트가 받아감)
- 반대 방향 금지 (txid-ui → libs/ui)

**Phase 2 예고:** 나머지 7 사이트 마이그레이션 (별도 spec). Phase 3: 구 txid-ui archive.

관련: [[project-txid-ui-chrome-pill-unification-2026-05-27]] (drift 사건이 monorepo 필요성 입증)
```

- [ ] **Step 2: MEMORY.md에 인덱스 추가**

`/home/seo/.claude/projects/-home-seo/memory/MEMORY.md` 의 "디버깅 교훈" 섹션 끝쪽에 추가:

```markdown
- [bc1qwerty/txid monorepo Phase 1 완료 2026-05-27](project_monorepo_txid_phase1_2026_05_27.md) — nx + pnpm. libs/ui + apps/sim history 보존 마이그레이션. CF Pages 재사용. 4 머신 mesh 정책 + change direction rule
```

- [ ] **Step 3: feedback_multi_repo_git_consistency 업데이트**

`/home/seo/.claude/projects/-home-seo/memory/feedback_multi_repo_git_consistency.md` 의 "Considerations for unification" 섹션 끝에 추가:

```markdown
**Phase 1 진행 완료 (2026-05-27)**: Option D (Workspace monorepo) 채택. bc1qwerty/txid 생성 + libs/ui + apps/sim 마이그레이션. 점진 — 나머지 7 사이트는 Phase 2/3 예정. 상세: [[project_monorepo_txid_phase1_2026_05_27]]
```

### Task 16: 다른 머신 안내 + 세션 마무리

- [ ] **Step 1: 사용자에게 4 머신 안내**

다음 메시지를 사용자에게 표시:

> Phase 1 완료. 다른 3 머신 (acer/dell/gram)에서 작업할 때:
> 1. `gh repo clone bc1qwerty/txid` — 새 monorepo
> 2. `cd ~/sim.txid.uk-astro && git remote get-url origin` → archived임을 인지
> 3. sim 작업은 무조건 `~/txid/apps/sim/` 에서만 진행
> 4. 다른 7 사이트는 그대로 (각자 repo + sync.sh)

- [ ] **Step 2: tmp 정리**

```bash
rm -rf /tmp/txid-ui-bare /tmp/sim-bare
```

- [ ] **Step 3: 최종 git 상태 확인**

```bash
cd /home/seo/txid && git log --oneline | head -10
gh run list --limit 3 --json status,conclusion,name
```

Expected: 최근 commit들 + GHA all success.

---

## Self-Review

**1. Spec coverage:**
- ✅ 도구 (nx + pnpm) → Task 2
- ✅ 디렉토리 구조 (apps/<name> + libs/ui) → Task 3
- ✅ git filter-repo + subtree merge → Task 5-9
- ✅ workspace dep 전환 + 중복 제거 → Task 10
- ✅ GHA workflow + secret → Task 12
- ✅ 라이브 검증 → Task 13
- ✅ 구 repo archive + 4 머신 정책 → Task 14-16
- ✅ Risks (7): Task 12 secret 미리 설정, Task 13 failure 대응, Task 14 rollback, Task 15 multi-machine policy 메모리

**2. Placeholder scan:** TBD/TODO 없음. 모든 step에 구체적 명령 + 예상 출력.

**3. Type consistency:** project 이름 `sim` 일관 사용. workspace dep `@txid/ui` 일관. CF Pages project `sim-txid-uk` 일관.

**Known minor risk in plan:** Task 2의 `create-nx-workspace` 후 cp -r 패턴이 약간 복잡. 안 되면 fallback: 빈 디렉토리에서 직접 `nx.json` + `package.json` 수동 작성.

---

## Execution Handoff

Plan 작성 완료 — `/home/seo/txid-ui/docs/superpowers/plans/2026-05-27-monorepo-migration-phase1.md`.

두 실행 방식:

1. **Subagent-Driven (추천)** — task당 fresh subagent, task 사이 review, 빠른 반복. monorepo 작업처럼 step 많고 검증 단계 많을 때 유리.
2. **Inline Execution** — 이 세션에서 task batch + checkpoint. 오늘 Phase 1-3 작업에서 검증된 방식.

어느 쪽으로 진행할까요?
