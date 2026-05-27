# Header/Footer Pill Capsule Unification — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** @txid/ui Header.astro와 Footer.astro를 시각 SSOT로 만들고, 8개 사이트(id/apps/dev/tools/tx/map/sim/portfolio) `src/styles/global.css`에서 헤더/푸터 셀렉터 정의를 제거하여 chrome 외관 drift를 종결한다.

**Architecture:** Header.astro에 scoped `<style>` 블록 신규 추가 (Pill Capsule 디자인). Footer.astro는 이미 가진 scoped style을 새 토큰 사용으로 갱신. tokens.css에 header/footer 토큰 추가. sync.sh로 11 consumer에 propagate 후 8 사이트 cleanup. Phase 2와 동일 워크플로우 (txid-ui PR + 8 consumer main commit).

**Tech Stack:** Astro 6 컴포넌트 scoped `<style>`, CSS Custom Properties, `sync.sh` (cp -r), Cloudflare Pages GHA auto-deploy.

**Spec:** `docs/superpowers/specs/2026-05-27-header-footer-pill-unification-design.md` (branch `spec/header-footer-pill-unification`, commit `f78d41f`)

**Scoped vs is:global decision:** Spec은 `<style is:global>`을 명시했으나 plan에선 **scoped `<style>` 우선** 사용한다. Astro scoped style은 컴포넌트의 모든 descendant 클래스에 자동 prefix를 붙여 사이트 global.css가 같은 셀렉터를 정의해도 충돌이 없다. SSOT 보장 + 안전 마진 + cleanup이 누락된 사이트도 시각이 깨지지 않는다. 만약 scoped가 동작하지 않는 셀렉터(예: 동적 추가되는 hamburger panel 안 요소)가 있으면 그 셀렉터만 `:global(...)` 래퍼로 처리.

---

## Phase A — txid-ui SSOT 구축

### Task 1: tokens.css에 header/footer 토큰 추가

**Files:**
- Modify: `/home/seo/txid-ui/styles/tokens.css`

- [ ] **Step 1: 현재 tokens.css 끝부분 확인**

```bash
tail -20 /home/seo/txid-ui/styles/tokens.css
```

Expected: 기존 토큰 정의 종료 위치 파악.

- [ ] **Step 2: header/footer 토큰 블록 추가**

`:root` 블록의 마지막에 추가:

```css
  /* ── Header chrome (pill capsule, BTC orange active) ── */
  --header-btn-bg:        rgba(139, 148, 158, 0.12);
  --header-btn-bg-hover:  rgba(139, 148, 158, 0.18);
  --header-btn-fg:        #c9d1d9;
  --header-btn-radius:    999px;
  --header-btn-pad-text:  0.4rem 0.95rem;
  --header-btn-pad-icon:  0.4rem 0.55rem;
  --header-active-bg:     var(--color-bitcoin);
  --header-active-fg:     #0d1117;
  --header-login-bg:      rgba(247, 147, 26, 0.18);
  --header-login-border:  rgba(247, 147, 26, 0.4);
  --header-login-fg:      var(--color-bitcoin);
  --header-gap:           0.5rem;
  --header-font-size:     0.78rem;

  /* ── Footer chrome ── */
  --footer-fg:            #6e7681;
  --footer-link:          #8b949e;
  --footer-link-hover:    #c9d1d9;
  --footer-border:        #21262d;
  --footer-font-size:     0.75rem;
  --footer-pad:           0.85rem 1.25rem;
  --footer-gap:           1rem;
```

그 다음 라이트 모드 페어를 파일 끝쪽 (또는 기존 `[data-theme='light']` 블록이 있으면 거기에) 추가:

```css
[data-theme='light'] {
  --header-btn-bg:        rgba(13, 17, 23, 0.05);
  --header-btn-bg-hover:  rgba(13, 17, 23, 0.08);
  --header-btn-fg:        #1f2328;
  --header-active-bg:     var(--color-bitcoin);
  --header-active-fg:     #0d1117;
  --header-login-bg:      rgba(247, 147, 26, 0.12);
  --header-login-border:  rgba(247, 147, 26, 0.5);
  --header-login-fg:      var(--color-bitcoin-on-light);

  --footer-fg:            #6e7681;
  --footer-link:          #57606a;
  --footer-link-hover:    #1f2328;
  --footer-border:        #d1d9e0;
}
```

- [ ] **Step 3: 변경 검증**

```bash
grep -c "header-btn-bg\|footer-fg" /home/seo/txid-ui/styles/tokens.css
```

Expected: 4 이상 (dark 4 + light 변형까지)

- [ ] **Step 4: Commit**

```bash
cd /home/seo/txid-ui
git add styles/tokens.css
git commit -m "feat(tokens): add header/footer chrome tokens (dark + light pairs)

Adds canonical CSS custom properties for the upcoming pill-capsule
header/footer unification. Both [data-theme='light'] pairs included so
the chrome stays readable in light mode without per-site overrides.

Spec: docs/superpowers/specs/2026-05-27-header-footer-pill-unification-design.md"
```

### Task 2: Header.astro에 Pill Capsule scoped style 추가

**Files:**
- Modify: `/home/seo/txid-ui/components/Header.astro`

- [ ] **Step 1: 현재 Header.astro 마지막 위치 확인 (style/script 사이)**

```bash
grep -n "^<\|^{" /home/seo/txid-ui/components/Header.astro | tail -10
```

Expected: `<header>...`, `{!skipWiring && (...)}` 블록 위치. style을 마크업 직후 `<script>` 앞 또는 파일 끝에 추가.

- [ ] **Step 2: scoped `<style>` 블록 추가 (파일 끝에)**

```astro
<style>
  /* === Pill Capsule chrome — synced via @txid/ui sync.sh === */
  header[data-default-lang] {
    font-family: var(--font-sans-ko, 'Pretendard Variable', Pretendard, Inter, system-ui, sans-serif);
  }

  .nav-top {
    display: flex;
    align-items: center;
    gap: var(--header-gap, 0.5rem);
    padding: 0.75rem 1.25rem;
    border-bottom: 1px solid var(--footer-border, #21262d);
  }

  .logo {
    color: var(--color-bitcoin, #f7931a);
    font-weight: 700;
    font-size: 0.95rem;
    text-decoration: none;
    display: inline-flex;
    align-items: center;
    gap: 0.4rem;
  }

  .logo-icon { flex-shrink: 0; }
  .logo-sep { color: var(--footer-border, #30363d); }
  .logo-sub { color: var(--footer-fg, #8b949e); font-size: 0.9rem; }
  .nav-right { display: inline-flex; align-items: center; gap: var(--header-gap, 0.5rem); margin-left: auto; }

  .lang-dropdown { position: relative; }

  .lang-btn,
  .theme-btn {
    background: var(--header-btn-bg);
    border: none;
    color: var(--header-btn-fg);
    border-radius: var(--header-btn-radius);
    cursor: pointer;
    font-family: inherit;
    font-size: var(--header-font-size);
    line-height: 1;
    transition: background 0.15s, color 0.15s;
  }

  .lang-btn { padding: var(--header-btn-pad-text); }
  .theme-btn { padding: var(--header-btn-pad-icon); display: inline-flex; align-items: center; justify-content: center; }

  .lang-btn:hover,
  .theme-btn:hover { background: var(--header-btn-bg-hover); }

  .lang-menu {
    position: absolute;
    top: calc(100% + 0.35rem);
    right: 0;
    background: var(--card-bg, #161b22);
    border: 1px solid var(--card-border, #21262d);
    border-radius: 8px;
    padding: 0.25rem;
    display: none;
    flex-direction: column;
    min-width: 110px;
    z-index: 50;
  }
  .lang-menu.open { display: flex; }
  .lang-menu button {
    background: transparent;
    border: none;
    color: var(--header-btn-fg);
    padding: 0.45rem 0.75rem;
    text-align: left;
    border-radius: 6px;
    cursor: pointer;
    font-size: var(--header-font-size);
    font-family: inherit;
  }
  .lang-menu button:hover { background: var(--header-btn-bg-hover); }

  /* Active lang state — applied by wiring when current lang matches */
  .lang-btn.is-active,
  .settings-lang-btn.active {
    background: var(--header-active-bg);
    color: var(--header-active-fg);
  }

  /* === Mobile hamburger === */
  .hamburger-wrap { position: relative; }
  .desktop-only { display: inline-flex; }
  .mobile-only { display: none; }

  @media (max-width: 640px) {
    .desktop-only { display: none; }
    .mobile-only { display: inline-flex; }
  }

  .hamburger-panel {
    position: absolute;
    top: calc(100% + 0.35rem);
    right: 0;
    background: var(--card-bg, #161b22);
    border: 1px solid var(--card-border, #21262d);
    border-radius: 10px;
    padding: 0.75rem;
    display: none;
    flex-direction: column;
    gap: 0.5rem;
    min-width: 180px;
    z-index: 50;
  }
  .hamburger-panel.open { display: flex; }

  .settings-section {
    display: flex;
    flex-direction: column;
    gap: 0.4rem;
  }
  .settings-section--border {
    border-top: 1px solid var(--card-border, #21262d);
    padding-top: 0.6rem;
  }
  .settings-label {
    font-size: 0.7rem;
    text-transform: uppercase;
    letter-spacing: 0.08em;
    color: var(--footer-fg, #8b949e);
  }
  .settings-lang-row {
    display: inline-flex;
    gap: 0.35rem;
  }
  .settings-lang-btn {
    background: var(--header-btn-bg);
    border: none;
    color: var(--header-btn-fg);
    border-radius: var(--header-btn-radius);
    padding: var(--header-btn-pad-text);
    cursor: pointer;
    font-family: inherit;
    font-size: var(--header-font-size);
  }
  .settings-lang-btn:hover { background: var(--header-btn-bg-hover); }

  .settings-item {
    background: transparent;
    border: none;
    color: var(--header-btn-fg);
    padding: 0.45rem 0.4rem;
    border-radius: 6px;
    cursor: pointer;
    text-align: left;
    display: inline-flex;
    align-items: center;
    gap: 0.5rem;
    font-family: inherit;
    font-size: var(--header-font-size);
  }
  .settings-item:hover { background: var(--header-btn-bg-hover); }

  /* === Login mount slot (txid-auth-mount injects a button) === */
  .auth-mount :global(button),
  .auth-mount :global(a) {
    background: var(--header-login-bg);
    border: 1px solid var(--header-login-border);
    color: var(--header-login-fg);
    border-radius: var(--header-btn-radius);
    padding: var(--header-btn-pad-text);
    font-size: var(--header-font-size);
    font-weight: 600;
    cursor: pointer;
    font-family: inherit;
    text-decoration: none;
    display: inline-flex;
    align-items: center;
    gap: 0.35rem;
    transition: background 0.15s;
  }
  .auth-mount :global(button:hover),
  .auth-mount :global(a:hover) {
    background: rgba(247, 147, 26, 0.28);
  }
</style>
```

`:global()` 래퍼는 `#txid-auth-mount` 안에 외부 스크립트가 동적으로 button을 주입하는 경우에 필요 (마크업이 빌드 시 존재하지 않으므로 Astro가 prefix 못 함). 위 lang/theme/hamburger 셀렉터는 마크업이 정적이라 scoped로 자동 동작.

- [ ] **Step 3: 사이트별 inline `<style>` 충돌 가능성 사전 검사**

```bash
grep -lE "\.lang-btn\s*\{|\.theme-btn\s*\{" /home/seo/{id,apps,dev,tools,tx,map,sim,portfolio}.txid.uk-astro/src/styles/global.css 2>/dev/null
```

Expected: 모든 사이트 (id 제외 0건, 나머지 7개) 출력 — 다음 Phase B에서 제거 대상.

- [ ] **Step 4: Commit**

```bash
cd /home/seo/txid-ui
git add components/Header.astro
git commit -m "feat(header): pill-capsule scoped style (visual SSOT)

Adds a <style> block to Header.astro using the new header tokens.
Astro scopes the selectors to this component, so sites with their own
.lang-btn/.theme-btn definitions in global.css won't conflict — and
the SSOT lives here from now on. Per-site cleanup happens in the
consumer commits.

#txid-auth-mount uses :global() because the login button is injected
by an external script after build, and Astro can't prefix selectors
it doesn't see.

Spec: docs/superpowers/specs/2026-05-27-header-footer-pill-unification-design.md"
```

### Task 3: Footer.astro의 하드코딩 색상을 새 토큰으로 교체

**Files:**
- Modify: `/home/seo/txid-ui/components/Footer.astro`

- [ ] **Step 1: 현재 Footer.astro의 `<style>` 블록 토큰 사용 확인**

```bash
grep -n "var(--\|#[0-9a-f]\{6\}" /home/seo/txid-ui/components/Footer.astro
```

Expected: 일부는 `var(--accent)`, 일부는 `#21262d`/`#8b949e` 하드코딩.

- [ ] **Step 2: Footer.astro `<style>` 블록 안의 하드코딩 값을 새 토큰으로 교체**

각각의 Edit 항목 (1줄씩):
- `border-top: 1px solid var(--border, #21262d);` → `border-top: 1px solid var(--footer-border, #21262d);`
- `padding: 24px 16px 32px;` → `padding: 24px 16px 32px;` (그대로)
- `color: var(--text2, #8b949e);` → `color: var(--footer-fg, #8b949e);`
- `font-size: .75rem;` (footer-site-link) → `font-size: var(--footer-font-size, .75rem);`
- `border: 1px solid var(--border, #21262d);` (footer-site-link) → `border: 1px solid var(--footer-border, #21262d);`
- `color: var(--text2, #8b949e);` (footer-site-link) → `color: var(--footer-link, #8b949e);`
- `color: var(--text2, #8b949e);` (footer-links a) → `color: var(--footer-link, #8b949e);`
- `color: var(--accent, #f7931a);` (hover) → 그대로 (BTC 오렌지 hover는 양 모드 공통)

Find/Replace 두 단계로 가능:
1. `var(--border, #21262d)` → `var(--footer-border, #21262d)` (replace_all)
2. `var(--text2, #8b949e)` → `var(--footer-link, #8b949e)` (replace_all, 단 .site-footer 본체의 color는 `--footer-fg`로 별도)

수동으로 5분 안에 마무리.

- [ ] **Step 3: 시각 검증 (build로 산출물 grep)**

```bash
cd /home/seo/id.txid.uk-astro && grep -c "var(--footer-fg\|var(--footer-link" src/components/ui/Footer.astro
```

Expected: 0 (아직 sync 안 됨, 다음 task에서 sync)

- [ ] **Step 4: Commit**

```bash
cd /home/seo/txid-ui
git add components/Footer.astro
git commit -m "refactor(footer): swap hardcoded colors for new footer tokens

Footer already had a scoped <style> block (so it's been the visual
SSOT for footer markup), but it used --border/--text2 fallbacks that
each consumer site could override differently. Switch to the new
--footer-* tokens which sit alongside --header-* in tokens.css, so
both halves of the chrome share the same theming surface.

No visual change in dark mode; light mode now resolves the right pair.

Spec: docs/superpowers/specs/2026-05-27-header-footer-pill-unification-design.md"
```

### Task 4: sync.sh 실행하여 11 consumer로 propagate

**Files:**
- Run: `/home/seo/txid-ui/sync.sh`

- [ ] **Step 1: sync 실행**

```bash
cd /home/seo/txid-ui && bash sync.sh 2>&1 | tail -15
```

Expected: 11개 사이트 모두 `✓ ... (tokens + components)` 출력, `Done. All projects synchronized.`

- [ ] **Step 2: 한 사이트 (id)에서 sync 결과 확인**

```bash
grep -c "header-btn-bg\|footer-fg" /home/seo/id.txid.uk-astro/src/styles/tokens.css
```

Expected: 4 이상 (방금 sync된 토큰)

```bash
grep -c "Pill Capsule chrome\|header-btn-bg" /home/seo/id.txid.uk-astro/src/components/ui/Header.astro
```

Expected: ≥ 1 (Header에 새 style 들어옴)

- [ ] **Step 3: id repo에서 sync 결과 commit 준비 (아직 commit X — 다음 Phase에서)**

이 task는 sync만. commit은 사이트별 cleanup task에 묶어서.

---

## Phase B — 8개 사이트 cleanup

각 사이트마다 동일 패턴. 사이트당 ~5분.

### Task 5: id 사이트 global.css 헤더/푸터 셀렉터 제거

**Files:**
- Modify: `/home/seo/id.txid.uk-astro/src/styles/global.css`

- [ ] **Step 1: 제거 대상 셀렉터 grep으로 위치 확인**

```bash
grep -nE "^\.(nav-top|logo|logo-sep|logo-sub|nav-right|auth-mount|lang-dropdown|lang-btn|lang-menu|theme-btn|desktop-only|mobile-only|hamburger-wrap|hamburger-panel|settings-section|settings-label|settings-lang-row|settings-lang-btn|settings-item|site-footer|footer-inner|footer-sites|footer-site-link|footer-bottom|footer-copy|footer-links|footer-sep)( |\{|\.|,)" /home/seo/id.txid.uk-astro/src/styles/global.css
```

Expected: 셀렉터 라인 번호 목록.

- [ ] **Step 2: 해당 셀렉터의 정의 블록 (`{ ... }` 포함) 삭제**

각 셀렉터의 시작 라인부터 매칭 `}` 까지 삭제. media query (`@media (max-width: 640px) { ... }`) 안에 헤더/푸터 셀렉터만 있으면 해당 media query 블록 전체 삭제. 다른 셀렉터와 섞여있으면 헤더/푸터 셀렉터 라인만 제거.

Edit tool로 한 셀렉터씩 처리. 또는 직접 라인 범위 잘라내기.

- [ ] **Step 3: 빌드 green 검증**

```bash
cd /home/seo/id.txid.uk-astro && npm run build 2>&1 | tail -5
```

Expected: `[build] Complete!` + `[csp-hash] ...` 정상 출력. 에러 없음.

- [ ] **Step 4: dev 서버로 visual 빠른 확인 (선택, id는 가장 중요한 시나리오)**

```bash
cd /home/seo/id.txid.uk-astro && npm run dev > /tmp/id-dev.log 2>&1 &
sleep 5
echo "Visit http://localhost:4321 to verify header looks correct"
# 검증 후 kill: pkill -f "id.txid.uk-astro.*dev"
```

수동 확인: 헤더 버튼이 둥근 알약형, 회색 default + BTC 오렌지 active, 햄버거 패널 정상 toggle.

- [ ] **Step 5: Commit (id main)**

```bash
cd /home/seo/id.txid.uk-astro && git checkout main && git pull origin main && \
git add src/components/ui/Header.astro src/components/ui/Footer.astro src/styles/tokens.css src/styles/global.css && \
git commit -m "refactor(chrome): adopt pill-capsule header/footer SSOT

@txid/ui Header.astro + Footer.astro now hold all chrome visual rules
(spec/header-footer-pill-unification). Removed duplicate selectors
from src/styles/global.css; tokens.css refreshed with new --header-*
and --footer-* pairs.

No functional change. Visual: buttons unified to pill capsule
(border-radius 999px), active lang in BTC orange.

Related: docs/superpowers/specs/2026-05-27-header-footer-pill-unification-design.md"
```

### Task 6: apps 사이트 cleanup

**Files:**
- Modify: `/home/seo/apps.txid.uk-astro/src/styles/global.css`

- [ ] **Step 1: 같은 grep 패턴으로 위치 확인**

```bash
grep -nE "^\.(nav-top|logo|logo-sep|logo-sub|nav-right|auth-mount|lang-dropdown|lang-btn|lang-menu|theme-btn|desktop-only|mobile-only|hamburger-wrap|hamburger-panel|settings-section|settings-label|settings-lang-row|settings-lang-btn|settings-item|site-footer|footer-inner|footer-sites|footer-site-link|footer-bottom|footer-copy|footer-links|footer-sep)( |\{|\.|,)" /home/seo/apps.txid.uk-astro/src/styles/global.css
```

- [ ] **Step 2: 블록 삭제 (Task 5와 동일 방법)**

- [ ] **Step 3: Build green 검증**

```bash
cd /home/seo/apps.txid.uk-astro && npm run build 2>&1 | tail -5
```

Expected: `[build] Complete!`

- [ ] **Step 4: Commit**

```bash
cd /home/seo/apps.txid.uk-astro && git checkout main && git pull origin main && \
git add src/components/ui/Header.astro src/components/ui/Footer.astro src/styles/tokens.css src/styles/global.css && \
git commit -m "refactor(chrome): adopt pill-capsule header/footer SSOT

@txid/ui Header/Footer 가 chrome 시각 SSOT가 되도록 sync 후 global.css
중복 셀렉터 제거. Visual 통일 - id와 동일 변화.

Spec: txid-ui/docs/superpowers/specs/2026-05-27-header-footer-pill-unification-design.md"
```

### Task 7: dev 사이트 cleanup (헤더 셀렉터 0건이지만 sync 변경만 commit)

**Files:**
- Modify: `/home/seo/dev.txid.uk-astro/src/styles/global.css` (변경 없을 가능성)
- Sync changes commit only

- [ ] **Step 1: grep 0건 확인 (이전 분석 결과 dev = 0 matches)**

```bash
grep -cE "\.lang-btn|\.theme-btn|\.nav-top|\.lang-dropdown|\.hamburger" /home/seo/dev.txid.uk-astro/src/styles/global.css
```

Expected: 0

- [ ] **Step 2: sync된 파일들만 commit 준비**

```bash
cd /home/seo/dev.txid.uk-astro && git status -s
```

Expected: `src/components/ui/Header.astro`, `src/components/ui/Footer.astro`, `src/styles/tokens.css` 정도만 modified (global.css 변경 없음).

- [ ] **Step 3: Build green 검증**

```bash
cd /home/seo/dev.txid.uk-astro && npm run build 2>&1 | tail -5
```

Expected: `[build] Complete!`

- [ ] **Step 4: Commit**

```bash
cd /home/seo/dev.txid.uk-astro && git checkout main && git pull origin main && \
git add src/components/ui/Header.astro src/components/ui/Footer.astro src/styles/tokens.css && \
git commit -m "chore(chrome): sync pill-capsule header/footer SSOT

dev은 자체 global.css에 헤더/푸터 셀렉터가 없어서 sync만 반영.
SharedHeader skipWiring={true} 호출은 이미 유지 — 자체 BaseLayout
IIFE가 wiring 담당."
```

### Task 8: tools 사이트 cleanup

Task 6과 동일 패턴. 경로만 다름: `/home/seo/tools.txid.uk-astro/`

(상세 step는 Task 6 복사)

### Task 9: tx 사이트 cleanup

Task 6과 동일 패턴. 경로: `/home/seo/tx.txid.uk-astro/`

### Task 10: map 사이트 cleanup

Task 6과 동일 패턴. 경로: `/home/seo/map.txid.uk-astro/`

### Task 11: sim 사이트 cleanup

Task 6과 동일 패턴. 경로: `/home/seo/sim.txid.uk-astro/`

### Task 12: portfolio 사이트 cleanup

Task 6과 동일 패턴. 경로: `/home/seo/portfolio.txid.uk-astro/`

---

## Phase C — Integration & deploy

### Task 13: txid-ui spec/header-footer-pill-unification branch에 code commit 추가

이미 spec branch에 spec commit `f78d41f`만 있는 상태. Phase A에서 만든 Task 1-3 commit이 이 branch에 추가되어야 함.

- [ ] **Step 1: branch 확인**

```bash
cd /home/seo/txid-ui && git branch --show-current
```

Expected: `spec/header-footer-pill-unification`

- [ ] **Step 2: log 확인**

```bash
git log --oneline -5
```

Expected: 최신 commit이 Task 3의 footer refactor, 그 다음 Task 2의 header style, Task 1의 tokens, spec doc 순.

- [ ] **Step 3: branch 이름 의미 확장 (선택)**

이미 spec 외 code도 들어갔으므로 branch 이름을 `feat/header-footer-pill-unification` 로 rename:

```bash
git branch -m spec/header-footer-pill-unification feat/header-footer-pill-unification
```

- [ ] **Step 4: push**

```bash
git push -u origin feat/header-footer-pill-unification 2>&1 | tail -5
```

Expected: 새 branch 생성 + PR URL 안내.

- [ ] **Step 5: PR 생성**

```bash
gh pr create --title "feat(chrome): pill-capsule header/footer SSOT" --body "$(cat <<'EOF'
## Summary
- Header.astro에 scoped <style> 추가 (Pill Capsule 디자인)
- Footer.astro 하드코딩 색상 → 새 --footer-* 토큰
- tokens.css에 --header-* / --footer-* 토큰 페어 (dark + light)
- Spec doc 동봉

## Why
사용자 보고: "로그인/언어/테마 버튼들이 사이트마다 생긴게 달라". Phase 2에서 마크업/wiring은 SSOT 묶었지만, 시각 스타일은 8 사이트 각자 global.css에 분산. drift의 직접 원인.

## Visual change
- 헤더 버튼: 둥근 알약형 (border-radius 999px)
- 비액티브: 부드러운 회색
- 액티브 lang: BTC 오렌지 fill
- 로그인: 오렌지 ghost button

## Consumer migration
8 사이트 main에 별도 commit (이전 Phase 2와 동일 워크플로우):
- id/apps/tools/tx/map/sim/portfolio: global.css 헤더/푸터 셀렉터 제거
- dev: 헤더 셀렉터 0건, sync만 commit

## Test plan
- [x] 8 사이트 `npm run build` green
- [ ] id `npm run dev` visual 수동 (개발자)
- [ ] 사용자 라이브 8 사이트 visual 통일 확인 (배포 후)

Spec: `docs/superpowers/specs/2026-05-27-header-footer-pill-unification-design.md`

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)" 2>&1 | tail -3
```

Expected: PR URL.

### Task 14: 8 사이트 main commit push

Phase B에서 각 사이트 commit 만들어진 상태. push만 묶어서 진행.

- [ ] **Step 1: 각 사이트 push**

```bash
for site in id apps dev tools tx map sim portfolio; do
  echo "=== pushing $site ==="
  cd /home/seo/${site}.txid.uk-astro && git push 2>&1 | tail -2
done
```

Expected: 8개 모두 `... -> main` 성공.

- [ ] **Step 2: GHA 트리거 확인**

```bash
for site in id apps dev tools tx map sim portfolio; do
  echo "=== $site GHA latest ==="
  cd /home/seo/${site}.txid.uk-astro && gh run list --limit 1 --json status,conclusion --jq '.[0]'
done
```

Expected: 모두 status `in_progress` 또는 새로 트리거된 상태.

### Task 15: txid-ui PR 머지 + 라이브 검증

- [ ] **Step 1: txid-ui PR 머지 (사용자 승인 필요 시 확인)**

```bash
cd /home/seo/txid-ui && gh pr merge --squash --delete-branch 2>&1 | tail -3
```

- [ ] **Step 2: 8 사이트 GHA 모두 success 대기**

```bash
for site in id apps dev tools tx map sim portfolio; do
  cd /home/seo/${site}.txid.uk-astro
  until gh run list --limit 1 --json status --jq '.[0].status' | grep -q completed; do sleep 8; done
  echo "$site: $(gh run list --limit 1 --json conclusion --jq '.[0].conclusion')"
done
```

Expected: 모두 `success`.

- [ ] **Step 3: 라이브 visual 검증 (사용자 영역)**

다음 사이트를 데스크탑 + 모바일 폭으로 1번씩 보고 헤더/푸터 동일성 확인:
- https://id.txid.uk
- https://apps.txid.uk
- https://dev.txid.uk
- https://tools.txid.uk
- https://tx.txid.uk
- https://map.txid.uk
- https://sim.txid.uk
- https://portfolio.txid.uk

체크리스트:
- 버튼 모양: 둥근 알약형 동일
- 액티브 lang: BTC 오렌지 fill 동일
- 로그인 버튼 (id/apps 등): 오렌지 ghost 동일
- 햄버거 패널 토글 정상
- 라이트 모드 토글 시 가독성 유지

회귀 발견 시: 해당 사이트의 global.css에 누락된 셀렉터 cleanup이 있는지 grep으로 재확인.

---

## Self-Review

이미 인라인으로 정리한 항목:
- scoped vs is:global 선택 명시 (scoped + :global() 래퍼 보조)
- dev 사이트 (헤더 0건)의 cleanup 비대칭 처리 명시 (Task 7)
- Task 8-12는 Task 6 복사 안내 (반복 step 생략, "동일 패턴" 명시)

**Spec coverage:**
- Spec의 Token Decisions → Task 1 ✓
- Spec의 SSOT Header.astro <style> → Task 2 ✓
- Spec의 Footer 토큰화 → Task 3 ✓
- Spec의 sync 변경 불요 → Task 4 ✓
- Spec의 사이트별 global.css cleanup → Task 5-12 ✓
- Spec의 verification → Task 15 step 3 ✓
- Spec의 risks (셀렉터 충돌, 라이트 모드, 모바일) → Task 5 step 4 dev 검증 + Task 15 step 3 라이브 검증

**Placeholder scan:** "TBD" 없음.

**Type consistency:** Token 이름이 Task 1/2/3에서 일관 사용됨 (--header-btn-bg, --footer-fg 등).

**Scope:** 단일 PR + 8 사이트 commit으로 완결, decomposition 불요.

---

## Execution Handoff

Plan 작성 완료 — `/home/seo/txid-ui/docs/superpowers/plans/2026-05-27-header-footer-pill-unification.md`.

두 실행 방식:

1. **Subagent-Driven (추천)** — task당 fresh subagent, task 사이 review, 빠른 반복
2. **Inline Execution** — 이 세션에서 task batch 실행, checkpoint마다 사용자 review

어느 쪽으로 진행할까요?
