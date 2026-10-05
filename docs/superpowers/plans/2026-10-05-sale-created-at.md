# Satış tarihi Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ödeme ekranında gün ve saat düzenlensin; dokunulmazsa kayıt anı gitsin; `CreatedAt` isteğe bağlı parametreyle yazılsın.

**Architecture:** Saf fonksiyonlar biçim, ileri zaman ve “seçilmediyse şimdi” kuralını tutar. Taslak `saleAt` null ise yeni satış dokunulmamıştır. Sunucu `@CreatedAt` boşsa eski davranışı korur.

**Tech Stack:** Flutter, Dart, flutter_test, SQL Server. Çalışma dizini `mobile/`.

## Global Constraints

- Varsayılan kayıt anıdır. Gün ve saat değiştirilebilir. İleri an yok.
- Yeni satışta dokunulmazsa kaydet anı gider. Saat alanı açılışta donar. Yalnızca gün değişirse o donmuş saat yazılır. Seçilen saatte saniye `00`.
- Düzeltme kayıtlı `CreatedAt` ile açılır. Dokunulmazsa o değer gider.
- Gün seçici 1 Ocak 2020 – bugün. İleri seçimde “İleri tarih seçilemez”.
- Parametre `yyyy-MM-dd HH:mm:ss`, saat dilimi yok.
- `@CreatedAt DATETIME = NULL`. Oluşturmada boşsa `GETDATE()`. Güncellemede boşsa kolon durur. Sunucudan 2 dakikadan ileri reddedilir.
- Eski uygulama parametre göndermez. Script `sql/Migrate_SaleCreatedAt.sql` onaydan önce çalıştırılır; bu planda sunucuda çalıştırılmaz.
- Ayrı ekran testi yok. Test: `mobile/test/features/sale/sale_datetime_test.dart`.
- Git commit yok.

## File map

| File | Responsibility |
|---|---|
| `mobile/lib/features/sale/sale_datetime.dart` | Biçim, ileri zaman, gönderilecek an |
| `mobile/test/features/sale/sale_datetime_test.dart` | Bu kurallar |
| `mobile/lib/features/sale/checkout_draft.dart` | `saleAt`; null dokunulmamış yeni satış |
| `mobile/lib/features/sale/cart_provider.dart` | `Sale.Create` / `Sale.Update` `CreatedAt` |
| `mobile/lib/features/sale/checkout_screen.dart` | Satış tarihi bölümü |
| `mobile/lib/features/sale/sale_detail_screen.dart` | Düzeltme taslağına kayıtlı tarih |
| `sql/Migrate_SaleCreatedAt.sql` | İsteğe bağlı parametre |

---

### Task 1: Datetime helpers

**Files:**
- Create: `mobile/lib/features/sale/sale_datetime.dart`
- Test: `mobile/test/features/sale/sale_datetime_test.dart`

**Interfaces:**
- Produces: `formatSaleDateTime(DateTime)`, `isFutureSaleDateTime(DateTime value, DateTime now)`, `saleDateTimeToSend({DateTime? chosen, required DateTime now})`, `saleDateTimeWithPickedDate`, `saleDateTimeWithPickedTime`

- [ ] **Step 1: Write the failing test**

`2026-10-05 00:30` yerel `DateTime(2026, 10, 5, 0, 30)` → `2026-10-05 00:30:00`. `isFutureSaleDateTime` eşit ve geçmişte false, sonrada true. `saleDateTimeToSend(chosen: null, now: t)` → `t`. `chosen` doluysa o döner. Gün seçimi saati korur ve saniyeyi sıfırlar. Saat seçimi günü korur ve saniyeyi sıfırlar.

- [ ] **Step 2: Run test to verify it fails**

`flutter test test/features/sale/sale_datetime_test.dart` FAIL.

- [ ] **Step 3: Implement helpers and rerun**

Expected: PASS.

### Task 2: SQL script

**Files:**
- Create: `sql/Migrate_SaleCreatedAt.sql`

`API_Sale_Create` ve `API_Sale_Update` gövdeleri `sql/Migrate_SaleFlagMask.sql` ile aynı kalır. Ek: `@CreatedAt DATETIME = NULL`. Dolu ve `DATEADD(MINUTE, 2, GETDATE())` sonrasıysa `RAISERROR(N'İleri tarih seçilemez.', 16, 1)`. Create `COALESCE(@CreatedAt, GETDATE())` yazar. Update `CreatedAt = COALESCE(@CreatedAt, CreatedAt)`.

### Task 3: Checkout wiring

**Files:**
- Modify: `checkout_draft.dart`, `cart_provider.dart`, `checkout_screen.dart`, `sale_detail_screen.dart`

`CheckoutDraft.saleAt`. `hasUserInput` içinde `saleAt != null`.

`completeSale` / `updateSale` isteğe bağlı `DateTime? createdAt`. Doluysa `'CreatedAt': formatSaleDateTime(createdAt)`.

Ödeme ekranı müşterinin üstünde **Satış tarihi**. Taslak `saleAt` null ise gösterilen saat `_openedAt`. Değişince `saleAt` dolar ve taslağa yazılır. Kaydet `saleDateTimeToSend` kullanır. İleri sonuç kayda gitmez. Düzeltme `detail.createdAt` ile taslağı doldurur. Form sıfırlanınca `saleAt` null olur.

- [ ] **Step: Run sale datetime and draft tests**

`flutter test test/features/sale/sale_datetime_test.dart test/features/sale/checkout_draft_test.dart`
