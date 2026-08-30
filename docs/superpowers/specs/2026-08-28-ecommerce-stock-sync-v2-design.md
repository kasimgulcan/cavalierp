# E-ticaret stok senkronu v2 — Tasarım Spesifikasyonu

**Tarih:** 2026-08-28  
**Durum:** Onaylandı  
**Kapsam:** CavaliERP ↔ reklam5 stok hareketleri. Katalog create/update yok. v1 mutlak `stock.updated` POST’u kalkar (kırıcı değişiklik).

Karşı taraf sözleşmesi: `docs/ecommerce-stock-webhook.md`.

---

## 1. Özet

Site stok listesini CavaliERP’den **çeker** (snapshot). Sitede satış/iade olunca **adet** (delta) ile CavaliERP’ye bildirir; CavaliERP `Sales` veya `StockEntries` yazar. CavaliERP’de (mağaza/ERP) stok girişi ve satış insert/update/delete olunca reklam5’in verdiği HTTPS adresine **push** gider: hareket + güncel stok. Siteden gelen hareketler geri basılmaz.

---

## 2. Kararlar

| Konu | Karar |
|---|---|
| Liste | Site `GET snapshot` çeker (push değil) |
| Site → CavaliERP | Delta: `sale.created` / `return.created` |
| Yetersiz stok | Satış yine yazılır; `onHand` eksi olabilir |
| Site iade | `return.created` → `StockEntries`, `Note = ecommerce` |
| CavaliERP → site | Tek abone URL (`EcommerceSync:SubscriberUrl`) |
| Push içeriği | Hareket adedi + `onHand`; `SizeId` JSON’da yok |
| Outbox | `StockWebhookOutbound` içinde `SizeId` var |
| Kim yazar | Trigger (`SaleLines`, `StockEntries`) |
| Trigger olayları | INSERT, UPDATE (`Quantity`), DELETE |
| Döngü | `Note = ecommerce` outbox’a düşmez |
| Abone kapalıysa | 3 deneme, yerel kayıt başarılı kalır, satır `Failed`; site snapshot ile toparlar |
| HMAC | Aynı secret; inbound ve outbound POST aynı canonical kural |
| Dış anahtar | `skuCode` = `LTRIM(RTRIM(ProductCode)) + '_' + LTRIM(RTRIM(Size))` |
| İç anahtar | `SizeId` yalnız CavaliERP / outbox |

---

## 3. Akış

```
Mağaza / ERP ──► Sales / StockEntries ──► trigger ──► Outbox ──► worker POST reklam5
Site satış/iade ─► POST /stock ─► Sales veya StockEntries (Note=ecommerce)
                                          └─ trigger outbox yazmaz
Site liste ──────► GET /stock/snapshot
```

---

## 4. Endpoint’ler (CavaliERP)

Production taban: `https://app.devcloud.com.tr/cavalierp/api`

| Yön | Method | Path |
|---|---|---|
| Site satış/iade | `POST` | `/integrations/ecommerce/stock` |
| Tam liste (site çeker) | `GET` | `/integrations/ecommerce/stock/snapshot` |
| CavaliERP → site | `POST` | `EcommerceSync:SubscriberUrl` (reklam5 adresi) |

Mobil JWT bu kanalda kullanılmaz. `Enabled: false` iken inbound path’ler 404.

---

## 5. HMAC

Değişmez:

- Header: `X-CavaliERP-Timestamp` (Unix saniye UTC), `X-CavaliERP-Signature` (`sha256=<hex>`)
- POST canonical: `{timestamp}.{rawBody}` (minify yok)
- GET snapshot canonical: `{timestamp}.GET./integrations/ecommerce/stock/snapshot` (IIS öneki imzada yok)
- ±5 dk skew, secret yok/yanlış → 401

Outbound push da aynı POST kuralı ve aynı `SharedSecret` ile imzalanır. reklam5 doğrular.

---

## 6. Site → CavaliERP (inbound)

`POST /integrations/ecommerce/stock`

```json
{
  "eventId": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
  "eventType": "sale.created",
  "occurredAt": "2026-08-28T12:00:00Z",
  "source": "ecommerce",
  "item": {
    "skuCode": "H.RUGFL_FLC0001_FLC0001GRNNAV_XL",
    "quantity": 1
  }
}
```

| `eventType` | Anlam | CavaliERP yazımı |
|---|---|---|
| `sale.created` | `quantity` adet satıldı | `Sales` + `SaleLines`, `Sales.Note = ecommerce` |
| `return.created` | `quantity` adet iade | `StockEntries`, `Note = ecommerce` |

Kurallar:

- `eventId` zorunlu GUID. Aynı id tekrarında stok **yeniden yazılmaz**; ilk sonuç döner.
- `quantity` tam sayı, **≥ 1**.
- `source` beklenen: `ecommerce` (yoksa da `ecommerce` sayılır).
- SKU yoksa 404; birden fazla `SizeId` 409. Ürün oluşturulmaz.
- `sale.created` stok eksiye inebilir; reddedilmez.
- Bu yazımlar trigger’da `Note = ecommerce` olduğu için **outbound gitmez**.

Başarı gövdesi:

```json
{ "success": true, "eventType": "sale.created", "skuCode": "...", "quantity": 1, "onHand": -3 }
```

v1 `eventType: stock.updated` + mutlak `quantity` (kalan stok) **kabul edilmez** (400).

`UserId`: e-ticaret satış ve stok girişleri her zaman `7` (`EcommerceSync:ActorUserId`, varsayılan 7). Fiyat satırları 0 olabilir; amaç stok hareketidir.

---

## 7. CavaliERP → site (outbound)

reklam5 `SubscriberUrl` adresine POST.

```json
{
  "eventId": "…guid…",
  "eventType": "sale.created",
  "occurredAt": "2026-08-28T12:05:00Z",
  "source": "cavalierp",
  "item": {
    "skuCode": "H.RUGFL_FLC0001_FLC0001GRNNAV_XL",
    "quantity": 2,
    "onHand": 10
  }
}
```

| `eventType` | Ne zaman | `item.quantity` | Stok etkisi (onHand) |
|---|---|---|---|
| `sale.created` | `SaleLines` INSERT | satılan adet (> 0) | düşer |
| `sale.updated` | `SaleLines.Quantity` değişti | yeni − eski (işaretli) | işaretin tersi |
| `sale.deleted` | `SaleLines` DELETE | silinen satır adedi (> 0) | artar |
| `stock.received` | `StockEntries` INSERT | girilen adet (> 0) | artar |
| `stock.updated` | `StockEntries.Quantity` değişti | yeni − eski (işaretli) | işaretle aynı |
| `stock.deleted` | `StockEntries` DELETE | silinen giriş adedi (> 0) | düşer |

`onHand`: trigger AFTER anında `V_SizeStock.StockQty` (o `SizeId`). Eksi olabilir.

`SizeId` bu JSON’da yoktur.

`SubscriberUrl` boşsa worker göndermez; outbox satırları `Pending` kalır (URL sonra dolunca gider).

Mevcut satış-düzeltme SP’si satırları silip yeniden eklerse site `sale.deleted` + `sale.created` çifti görebilir; net bakiye `onHand` ile doğru kalır.

---

## 8. Snapshot

`GET /integrations/ecommerce/stock/snapshot` — v1 ile aynı fikir:

```json
{
  "generatedAt": "2026-08-28T00:00:00Z",
  "source": "cavalierp",
  "items": [
    { "skuCode": "H.RUGFL_FLC0001_FLC0001GRNNAV_XL", "quantity": 8 }
  ]
}
```

`quantity` burada **anlık bakiye** (`onHand`). Site sapmayı bununla kapatır. Eksi bakiyeler listelenir (gizlenmez).

---

## 9. SQL

### 9.1 `StockWebhookInbound`

Inbound idempotency: `EventId` PK. İlk uygulamanın `ResultCode` / gövde özeti saklanır.

### 9.2 `StockWebhookOutbound`

| Kolon | Anlam |
|---|---|
| `OutboundId` | identity PK |
| `EventId` | uniqueidentifier, trigger `NEWID()` |
| `EventType` | §7 değerleri |
| `SizeId` | int, zorunlu |
| `SkuCode` | nvarchar |
| `Quantity` | int (hareket; update’te işaretli) |
| `OnHand` | int |
| `CreatedAt` | datetimeoffset UTC |
| `Status` | `Pending` / `Sent` / `Failed` |
| `Attempts` | int, varsayılan 0 |
| `LastError` | nvarchar, nullable |
| `SentAt` | datetimeoffset, nullable |

Index: `(Status, OutboundId)` worker poll için.

`Quantity = 0` olan UPDATE outbox’a **yazılmaz** (değişiklik yok).

### 9.3 Trigger’lar

- `dbo.TR_SaleLines_StockWebhook` — `SaleLines` AFTER INSERT, UPDATE, DELETE
- `dbo.TR_StockEntries_StockWebhook` — `StockEntries` AFTER INSERT, UPDATE, DELETE

**Atlama:**

- `SaleLines`: `Sales.Note` (INSERT/UPDATE’te `inserted.SaleId`; DELETE’te `deleted.SaleId`) `ecommerce` ise yazma. `Sales` satırı yoksa atlama **yok** (CavaliERP silmesi sayılır).
- `StockEntries`: `Note = ecommerce` ise yazma (`inserted` veya `deleted`).

**SKU:** `V_ProductSize` (veya eşdeğer) üzerinden `SizeId` → `skuCode`. SKU çözülemezse outbox yine yazılır, `SkuCode` boş bırakılmaz; çözülemezse satır yazılmaz ve SQL error log’a (trigger yutmaz: satışın kendisi rollback olmasın diye SKU yoksa outbox skip + `RAISERROR` kullanma; sessiz skip yerine `SkuCode = CONCAT('SizeId:', SizeId)` fallback). Tercih: **fallback `SizeId:{id}`**, satış commit olur, worker yine dener; reklam5 o SKU’yu tanımazsa kendi tarafında loglar.

**`onHand`:** `ISNULL((SELECT StockQty FROM dbo.V_SizeStock WHERE SizeId = @id), 0)` AFTER DML.

**UPDATE:** yalnızca `Quantity` değiştiyse (`inserted.Quantity <> deleted.Quantity`).

Trigger gövdesi `inserted`/`deleted` set-based olmalı (çok satırlı insert).

### 9.4 Inbound SP

`dbo.API_WebHook_ApplyStock` mutlak-hedef davranışından çıkar (veya yeni ad `API_WebHook_ApplyMovement`):

- `@EventId`, `@EventType`, `@SkuCode`, `@Quantity`
- Idempotent inbound tablo
- `sale.created` → satış + satır, `Note = ecommerce`
- `return.created` → stok girişi, `Note = ecommerce`
- Satışta sıra zorunlu: önce `Sales` (`Note = ecommerce`), sonra `SaleLines` — yoksa trigger outbox’a basar.
- Dönen: ResultCode, SkuCode, Quantity, OnHand, ErrorMessage

Negatif stok kontrolü **yok**.

`API_WebHook_StockSnapshot` kalır; eksi `StockQty` dahil.

---

## 10. API worker

`IHostedService` (veya `BackgroundService`):

1. `Enabled` false veya `SubscriberUrl` boş → gönderim yok.
2. `Pending` ve `Attempts < 3` satırları al (küçük batch, `OutboundId` sırası).
3. HMAC POST JSON §7.
4. HTTP 2xx → `Sent`, `SentAt`.
5. Aksi / timeout / ağ → `Attempts++`, `LastError`. `Attempts = 3` → `Failed`.
6. Yerel satış/stok zaten commit; worker hatası onları geri almaz.

Retry aralığı: aynı döngüde ardışık 3 deneme değil; denemeler arasında kısa bekleme (worker turu, örn. 5–15 sn). Üç başarısız tur = `Failed`. (Aynı HTTP çağrısını tight-loop 3’lemek yok.)

Timeout: 10 sn.

---

## 11. Config

```json
"EcommerceSync": {
  "Enabled": true,
  "SharedSecret": "",
  "SubscriberUrl": "",
  "ActorUserId": 7,
  "TimestampSkewMinutes": 5,
  "AllowedCidrs": []
}
```

Gerçek secret ve URL git’e yazılmaz. IIS `appsettings.json` / ortam.

---

## 12. Test istemcisi

Web simülatör (`/tester/`) e-ticaret gibi:

- Snapshot çek
- `sale.created` / `return.created` POST (delta)
- İsteğe bağlı yerel HTTP dinleyici = `SubscriberUrl`; gelen push’u günlükte göster (HMAC doğrula)

Mutlak “stok = 8” gönderimi kalkar.

---

## 13. Testler (davranış)

- Inbound `sale.created` → Sale + Note ecommerce; outbox’ta satır yok
- Inbound `return.created` → StockEntry ecommerce; outbox yok
- Inbound yetersiz stok → 2xx, `onHand` eksi
- Aynı `eventId` → ikinci yazım yok
- `SaleLines` INSERT (Note boş) → outbox `sale.created` + SizeId + onHand
- Quantity 2→5 → `sale.updated` quantity 3
- SaleLine DELETE → `sale.deleted`
- StockEntry INSERT/UPDATE/DELETE eşlenikleri
- Worker 2xx → Sent; 3 tur fail → Failed
- Snapshot eksi bakiyeyi içerir

---

## 14. Dışında (bu iş değil)

- Çoklu abone kaydı API’si
- Siteden mutlak stok set
- Katalog / ürün create
- Trigger’ın satış transaction’ını HTTP ile kilitlemesi
- `SizeId`’nin reklam5 JSON’una eklenmesi
