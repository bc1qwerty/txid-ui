# Header/Footer Pill Capsule Unification — Design Spec

**Date:** 2026-05-27
**Author:** seo + Claude
**Status:** Approved by user (Option C — Pill Capsule)

## Goal

8개 txid.uk 서브도메인(id, apps, dev, tools, tx, map, sim, portfolio) 의 chrome (Header + Footer)을 시각적으로 동일하게 보이도록 통일한다. 사용자 보고: "로그인 및 언어변경, 다크/라이트 모드 변경 버튼들이 사이트들마다 생긴게 달라."

비기능: 기존 wiring 동작(언어 라우팅, 테마 토글, hamburger drawer, login mount)을 1바이트도 깨뜨리지 않는다.

## Why Now

방금 [[project_txid_ui_header_unification_2026_05_27]] 로 Header **마크업과 동작**은 SSOT로 묶었지만, **시각 스타일은 여전히 각 사이트의 `src/styles/global.css` 안에 분산**되어 있다. 7/8 사이트가 동일 셀렉터(`.lang-btn`, `.theme-btn`, `.nav-top`, `.lang-dropdown`, `.hamburger-*`)를 10~11회 정의하며 작은 차이(border-radius, padding, hover color, active state 표현)가 drift로 누적되었다. 사용자가 시각 차이로 직접 보고했기에 즉시 해소가 필요.

## Selected Direction — C. Pill Capsule

(브레인스토밍 단계에서 A/B/C 세 시안 visual 비교 후 C 선택)

### Token Decisions

| Token | Value | 비고 |
|-------|-------|------|
| `--header-btn-bg` | `rgba(139, 148, 158, 0.12)` | 비액티브 일반 버튼 배경 |
| `--header-btn-bg-hover` | `rgba(139, 148, 158, 0.18)` | hover |
| `--header-btn-fg` | `#c9d1d9` | 비액티브 텍스트 |
| `--header-btn-radius` | `999px` | 모든 헤더 버튼 알약형 |
| `--header-btn-pad-text` | `0.4rem 0.95rem` | 텍스트 버튼 |
| `--header-btn-pad-icon` | `0.4rem 0.55rem` | 아이콘 전용 |
| `--header-active-bg` | `#f7931a` | 현재 lang 버튼 (드롭다운 닫힌 상태) |
| `--header-active-fg` | `#0d1117` | 활성 텍스트 |
| `--header-login-bg` | `rgba(247, 147, 26, 0.18)` | 로그인 ghost 배경 |
| `--header-login-border` | `rgba(247, 147, 26, 0.4)` | 로그인 외곽선 |
| `--header-login-fg` | `#f7931a` | 로그인 텍스트 |
| `--header-gap` | `0.5rem` | 버튼 사이 간격 |
| `--header-font` | `'Inter', system-ui, sans-serif` | 영문 우선 |
| `--header-font-size` | `0.78rem` | 텍스트 버튼 |

라이트 모드 (`[data-theme='light']`) 페어:
- `--header-btn-bg`: `rgba(13, 17, 23, 0.05)`
- `--header-btn-bg-hover`: `rgba(13, 17, 23, 0.08)`
- `--header-btn-fg`: `#1f2328`
- `--header-active-bg`: `#f7931a` (동일)
- `--header-active-fg`: `#0d1117` (동일, BTC 오렌지는 양 모드 가독)
- `--header-login-bg`: `rgba(247, 147, 26, 0.12)`
- `--header-login-border`: `rgba(247, 147, 26, 0.5)`
- `--header-login-fg`: `#9a5a00` (라이트에선 다크닝)

### Footer

토큰: `--footer-fg: #6e7681`, `--footer-link: #8b949e`, `--footer-link-hover: #c9d1d9`, `--footer-border: #21262d`, `--footer-font-size: 0.78rem`, `--footer-pad: 0.85rem 1.25rem`, `--footer-gap: 1rem`.

**이 spec은 Footer의 시각 시스템만 통일한다.** 마크업 구조와 링크 항목은 각 사이트의 현재 `@txid/ui/components/Footer.astro` 호출 결과를 그대로 둔다 (현재 마크업이 이미 SSOT — Phase 2 sync.sh 후 8 사이트가 같은 마크업). 항목 자체 변경(링크 추가/제거 등)은 별도 작업.

라이트 모드 페어:
- `--footer-fg`: `#6e7681` (회색 양 모드 공통 가독)
- `--footer-link`: `#57606a`
- `--footer-link-hover`: `#1f2328`
- `--footer-border`: `#d1d9e0`

## Architecture

### SSOT 위치

- **신규 생성**: `@txid/ui/components/Header.astro` 내부에 `<style is:global>` 블록 추가. 모든 셀렉터 정의를 여기에 모은다.
- **신규 생성**: `@txid/ui/components/Footer.astro` 내부에도 동일 `<style is:global>` 블록.
- **갱신**: `@txid/ui/styles/tokens.css` — 위 토큰 추가 (다른 토큰과 한 파일에).
- **deprecated**: `@txid/ui/styles/header.css` (현재 빈 stub 또는 부분 정의). 정리 후 삭제.

### Sync.sh 변경 불요

이미 components 전체 + tokens.css가 cp -r 되므로 Header.astro 안에 style 묶이면 자동 propagate.

### 각 사이트 마이그레이션

각 사이트의 `src/styles/global.css`에서 헤더/푸터 관련 셀렉터 정의 **삭제** (Header/Footer Astro 컴포넌트가 자체적으로 스타일을 들고 옴). 셀렉터:

```
.nav-top, .logo, .logo-sep, .logo-sub, .nav-right, .auth-mount,
.lang-dropdown, .lang-btn, .lang-menu, .lang-menu button,
.theme-btn, .desktop-only, .mobile-only,
.hamburger-wrap, .hamburger-panel, .settings-section,
.settings-label, .settings-lang-row, .settings-lang-btn,
.settings-item, #hamburger-theme-icon, #hamburger-theme-label,
footer, .footer-*, etc.
```

dev는 자체 `components/layout/Header.astro` wrapper에서 SharedHeader를 호출하므로 SharedHeader의 새 `<style is:global>`이 자동 적용된다. wrapper 자체에는 헤더 관련 CSS가 없으므로 (방금 grep `dev: 0 matches`로 확인) 추가 정리 없음. dev의 wrapper 존재 자체는 Search 컴포넌트 통합 의도가 있으므로 유지.

## Component Inventory

| 파일 | 변경 | 비고 |
|------|------|------|
| `txid-ui/components/Header.astro` | `<style is:global>` 추가, 마크업 무변경 | wiring `<script>`는 그대로 |
| `txid-ui/components/Footer.astro` | `<style is:global>` 추가, 마크업 무변경 | 현재 마크업 사용 |
| `txid-ui/styles/tokens.css` | header/footer 토큰 추가 | 다른 토큰 보존 |
| `txid-ui/styles/header.css` | 삭제 | 더 이상 사용 안 함 |
| 각 사이트 `src/styles/global.css` (×8) | 헤더/푸터 셀렉터 정의 삭제 | 컨텐츠/페이지 스타일은 보존 |

## Implementation Order

1. `txid-ui/components/Header.astro` 에 `<style is:global>` + 토큰 사용
2. `txid-ui/components/Footer.astro` 동일
3. `txid-ui/styles/tokens.css` 토큰 추가
4. `sync.sh` 실행 → 11 consumer propagate
5. 사이트별 `src/styles/global.css` 헤더/푸터 셀렉터 정리 (8개 사이트 순차)
6. 각 사이트 `npm run build` 검증
7. 1개 사이트 (id) `npm run dev` 띄워서 visual 수동 검증 (로그인 mount 위치, 햄버거 토글, 라이트 모드 전환)
8. txid-ui PR + 8 사이트 main commit (이전 작업과 동일 워크플로우)
9. CF Pages 자동 배포 → 사용자 라이브 visual 검증

## Verification

### Build-time
- 8 사이트 build green
- CSP `_headers` hash count 변동 없음 (style만 변경, script 무변경)
- 각 사이트 `dist/*/index.html` 에 헤더 마크업/wiring import 정상

### Runtime
- Playwright headless가 가능해지면 `tests/lang-audit.cjs` 패턴으로 lang button 8 사이트 visual smoke
- 현재(MCP 미연결)는 사용자 수동 검증: 8 사이트 라이브 각 1번씩 데스크탑 + 모바일 폭에서 보고 통일성 확인

## Out of Scope (별도 작업으로 둠)

- dev의 자체 Header wrapper (`components/layout/Header.astro`) 제거 — 이건 dev의 Search 컴포넌트 통합 등 다른 의도가 있어 그대로 둠
- tools/tx의 자체 setLang i18n 시스템 리팩토링 (헤더 wiring과 별개 영역)
- Footer 콘텐츠 구조 변경 (링크 항목, layout 재조정 등) — 현재 항목 유지하고 시각만 통일
- 라이트 모드 전체 디자인 시스템 (현재 dark 우선 + light fallback 구조 유지, 라이트 모드 토큰 페어만 추가)

## Risks

| Risk | Mitigation |
|------|------------|
| 셀렉터 충돌 — 사이트 콘텐츠가 `.lang-btn`을 다른 의미로 쓰고 있을 가능성 | grep으로 사용처 사전 검사, 발견 시 사이트 콘텐츠 셀렉터 rename |
| 라이트 모드 색상 누락 | tokens.css `[data-theme='light']` 분기에 모든 헤더 토큰 페어 명시 |
| 모바일 햄버거 panel CSS 누락 | sync.sh 후 모바일 폭에서 직접 toggle 확인 (id로 1차 검증) |
| 이전 PR과 충돌 (Phase 2 git workflow) | 동일 워크플로우(@txid/ui PR + 8 사이트 main commit) — 일관성 유지 |

## Success Criteria

1. 8 사이트 라이브에서 동일 헤더 외관 (사용자 육안 확인)
2. lang/theme/hamburger/login mount 기능 무회귀
3. 각 사이트 build green + CSP 변동 없음
4. 사이트별 global.css에서 헤더/푸터 셀렉터 0건 (grep 검증)
5. @txid/ui Header.astro + Footer.astro가 chrome 시각 SSOT로 작동

## References

- [[project_txid_ui_header_unification_2026_05_27]] (Phase 2 — 동작 통합)
- [[project_csp_externalize_account_2026_05_27]] (Phase 1 — id CSP 복구)
- [[feedback_shared_header_wiring_silent_drop]] (원래 문제)
- [[feedback_multi_repo_git_consistency]] (workflow 일관성 필요)
