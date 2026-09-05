# CavaliERP — E-ticaret ürün kataloğu

Karşı tarafa verilecek sözleşme. Site kataloğu **çeker**; CavaliERP ürün create/update kabul etmez.

Stok kanalı ayrı ve kilitlidir: `docs/ecommerce-stock-webhook.md`.

## Endpoint

Production taban: `https://app.devcloud.com.tr/cavalierp/api`

| Method | Path |
|---|---|
| `GET` | `/integrations/ecommerce/products/snapshot` |

Örnek: `https://app.devcloud.com.tr/cavalierp/api/integrations/ecommerce/products/snapshot`

Mobil JWT yok. `EcommerceSync:Enabled: false` → 404 (tüm `/integrations/ecommerce`).

## HMAC

Stok GET ile aynı secret ve header'lar:

- `X-CavaliERP-Timestamp` — Unix saniye UTC
- `X-CavaliERP-Signature` — `sha256=<hex>`
- Canonical: `{timestamp}.GET./integrations/ecommerce/products/snapshot` (IIS öneki imzada yok)
- ±5 dk skew

## Cevap

```json
{
  "generatedAt": "2026-09-05T09:00:00Z",
  "source": "cavalierp",
  "skus": [ { "SKU CODE": "H.RUGFL_FLC0001_FLC0001BLKRGL_S / COB", "STYLE NAME": "TORONTO", "PUBLISH": "1" } ],
  "styleModels": [ { "STYLE NAME": "ALASKA", "FULL PRODUCT CODE": "H.RUGFL_STR0005_RPS0003BLKBLK" } ],
  "models": [ { "MODEL NAME": "ALISA KAPTAN", "MODEL REFERENCE": "AK" } ]
}
```

- `skus` = `GetSKU` satırları (87 kolon; anahtar = SQL kolon adı, `SKU CODE` eşleme anahtarı)
- Her `skus` satırında aynı değeri taşıyan `BARCODE GS1/EAN` ve sonunda boşluk bulunan `BARCODE GS1/EAN ` anahtarları birlikte yer alır; anahtarları trim etmek çakışmaya yol açar.
- `styleModels` / `models` = `GetSKU_ModelReference` kümeleri
- Filtre ve sayfalama yok
- Boş liste: 200, diziler `[]`
- SP/SQL hata: 500 `{ "success": false, "error": "Unable to load product catalog." }`

Kaynak SP: `dbo.GetSKUSnapshot`.

## Tester

`https://app.devcloud.com.tr/cavalierp/api/tester/` — "Ürün kataloğu çek".
