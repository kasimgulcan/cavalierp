# CavaliERP — E-ticaret stok senkronu (v2)

Karşı tarafa verilecek sözleşme. Stok hareketi. Ürün kataloğu ayrı kapı: `docs/ecommerce-product-catalog.md`.

İki kapı:

1. **Sizin URL’niz (site sizi besler):** site satış/iade POST’lar, listeyi GET snapshot ile çeker.
2. **Onların URL’si (siz onları beslersiniz):** `EcommerceSync:SubscriberUrl`. Mağaza/ERP stok girişi ve satış insert/update/delete olunca CavaliERP oraya POST atar.

## Kararlar

| Konu | Karar |
|---|---|
| Dış anahtar | **SKU CODE** (`skuCode`) = `ProductCode` + `_` + `Size` |
| İç anahtar | `SizeId` dış JSON’da yok; outbox’ta tutulur |
| Site → CavaliERP | Delta: `sale.created` / `return.created` (`quantity` = adet, kalan stok değil) |
| Yetersiz stok | Satış yine yazılır; bakiye eksi olabilir |
| Liste | Site `GET snapshot` çeker |
| CavaliERP → site | Tek abone URL, HMAC POST |
| Döngü | `Note = ecommerce` outbound’a düşmez |
| Abone kapalı | 3 tur dene, yerel kayıt durur; site snapshot ile toparlar |

`source`: `cavalierp` \| `ecommerce`.

v1 mutlak `stock.updated` **kabul edilmez**.

## Endpoint’ler

Production taban: `https://app.devcloud.com.tr/cavalierp/api`

| Yön | Method | Path / adres |
|---|---|---|
| Site satış/iade | `POST` | `/integrations/ecommerce/stock` |
| Tam liste (site çeker) | `GET` | `/integrations/ecommerce/stock/snapshot` |
| CavaliERP push | `POST` | reklam5 `SubscriberUrl` |

Örnekler:

- `https://app.devcloud.com.tr/cavalierp/api/integrations/ecommerce/stock`
- `https://app.devcloud.com.tr/cavalierp/api/integrations/ecommerce/stock/snapshot`

Mobil JWT bu kanalda yok. `Enabled: false` → inbound 404.

## Güvenlik (HMAC)

Paylaşılan secret: `EcommerceSync:SharedSecret` (git’e gerçek değer yazılmaz).

Header:

- `X-CavaliERP-Timestamp` — Unix saniye UTC
- `X-CavaliERP-Signature` — `sha256=<hex>`

Canonical:

- **POST** (inbound ve outbound): `{timestamp}.{rawBody}`
- **GET snapshot:** `{timestamp}.GET./integrations/ecommerce/stock/snapshot` (IIS öneki imzada yok)

±5 dk skew. İmza yok/yanlış → 401.

```json
"EcommerceSync": {
  "Enabled": true,
  "SharedSecret": "...en az 32 karakter...",
  "SubscriberUrl": "https://www.cavaliersanmarco.it/webhook/cavalierp-stock",
  "SubscriberBearerToken": "...sunucuda, git yok...",
  "PartnerSnapshotUrl": "https://www.cavaliersanmarco.it/en/data/plugin/get.ciqra?pluginName=cavalierp-stock-snapshot",
  "TimestampSkewMinutes": 5,
  "AllowedCidrs": []
}
```

## POST — site satış / iade

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

| eventType | CavaliERP |
|---|---|
| `sale.created` | `Sales` + `SaleLines`, `Note = ecommerce` |
| `return.created` | `StockEntries`, `Note = ecommerce` |

- `quantity` ≥ 1 (kaç adet satıldı/iade).
- Aynı `eventId` tekrarında ikinci yazım yok.
- SKU yok 404; birden fazla SizeId 409.
- Başarı: `{ "success": true, "eventType": "sale.created", "skuCode": "...", "quantity": 1, "onHand": -3 }`

## GET — snapshot

```json
{
  "generatedAt": "2026-08-28T00:00:00Z",
  "source": "cavalierp",
  "items": [
    { "skuCode": "H.RUGFL_FLC0001_FLC0001GRNNAV_XL", "quantity": 8 }
  ]
}
```

`quantity` = anlık bakiye (eksi olabilir).

## CavaliERP → site (push)

```json
{
  "eventId": "…",
  "eventType": "sale.created",
  "occurredAt": "2026-08-28T12:05:00Z",
  "source": "cavalierp",
  "item": { "skuCode": "H.RUGFL_…_XL", "quantity": 2, "onHand": 10 }
}
```

| eventType | Ne zaman | quantity |
|---|---|---|
| `sale.created` | SaleLines INSERT | satılan adet |
| `sale.updated` | Quantity değişti | yeni − eski |
| `sale.deleted` | SaleLines DELETE | silinen adet |
| `stock.received` | StockEntries INSERT | girilen adet |
| `stock.updated` | Quantity değişti | yeni − eski |
| `stock.deleted` | StockEntries DELETE | silinen adet |

Siteden gelen hareketler (`Note = ecommerce`) push edilmez.

reklam5 katmanı HMAC yanında `Authorization: Bearer` ister (`EcommerceSync:SubscriberBearerToken`).

## Partner snapshot (CavaliERP okur, yazmaz)

Mutabakat. Canonical: `{timestamp}.GET.{path}` — path query’siz (ör. `/en/data/plugin/get.ciqra`). İmza query string’de (`X-CavaliERP-Timestamp`, `X-CavaliERP-Signature`, URL-encode). Gövde JSON string içinde JSON olabilir; iki kez parse edilir.

Tester: `POST /tester/api/partner-snapshot`.

`skuCode` = `ProductCode` + `_` + `Size`. `Size` iç boşluk ve `/` korur (`6-7 Y`, `M / 46`).

## SQL

SSMS, `CavaliERP` veritabanı:

`sql/EcommerceStockWebhook.sql`

- Tablolar: `StockWebhookInbound`, `StockWebhookOutbound`
- Trigger: `TR_SaleLines_StockWebhook`, `TR_StockEntries_StockWebhook`
- SP: `API_WebHook_ApplyStock`, `API_WebHook_StockSnapshot`, outbox dequeue/mark

## Kod

- Controller: `api/CavaliERP.API/Controllers/EcommerceStockController.cs`
- Worker: `EcommerceOutboundDispatcher` / `EcommerceOutboundWorker`
- Partner snapshot: `EcommercePartnerSnapshotClient`
- HMAC: `EcommerceHmac.cs`

HTTP gövdeleri `StockWebhookInbound` / `StockWebhookOutbound` (`RequestJson`, `ResponseJson`). Migrate: `sql/Migrate_EcommerceWebhookHttpLog.sql`.

## Test istemcisi

Web simülatör (API ile birlikte yayınlanır): `https://app.devcloud.com.tr/cavalierp/api/tester/`

`EcommerceSync:TesterEnabled` açık olmalı. Push için `SubscriberUrl`:

`https://app.devcloud.com.tr/cavalierp/api/tester/stock-events/`
