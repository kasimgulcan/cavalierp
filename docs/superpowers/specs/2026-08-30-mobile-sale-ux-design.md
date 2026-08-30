# Mobil satış UX — tasarım

**Tarih:** 2026-08-30  
**Durum:** Onaylandı  
**Kaynak:** `docs/talep-listesi.md`

## Kararlar

| Konu | Karar |
|------|--------|
| Kayıt sonrası satış | Tam düzenleme (kalem, fiyat, indirim, ödeme, müşteri) |
| Tutar | Kuruş açık (`21,04`) |
| Hediye | Satır işareti (fiyat 0, stok düşer) + ödeme tipi Promosyon |

## Oturum

Access token dolunca Dio 401’de `Auth.RefreshToken` ile yeniler, orijinal isteği bir kez tekrarlar. Refresh JWT’dir (`token_use=refresh`, 30 gün). Refresh başarısızsa logout.

Login’de `Role` saklanır. `isStaff` profil yüklenene kadar bu rolü kullanır; kısa süreliğine misafir arayüzüne düşülmez.

## Satış taslağı

`CheckoutDraft`: müşteri, telefon, e-posta, not, ödeme tipi, indirim, varsa `editingSaleId`. Checkout’tan ürünlere dönüşte silinmez. Başarılı satış veya logout’ta temizlenir.

Sepet (Staff): **İleri**. Checkout: **Satışı Tamamla** → onay (müşteri, kalem, net tutar). Checkout’ta **Ürün ekle** ürün sekmesine döner.

## Tutar / indirim

`roundSaleMoney` 2 ondalık. Birim fiyat ve indirim yazıldıkça toplam güncellenir. İndirim kutuları boş açılır.

## Hediye / Promosyon

Satırda Hediye → `unitPrice = 0`, `listPrice` korunur. `PaymentTypes` içine Promosyon eklenir.

## Arama

Yazarken (300 ms) contains. Stil, ürün adı, grup, kategori, renk, kod. Beden sheet kapanınca arama sıfırlanır.

## Satış listesi

Varsayılan tarih: bugün → bugün.

## Satış güncelleme

Mevcut `Sale.Update`: `SaleId`, `Customer`, `Note`, `PaymentTypeId`, `Lines`, `DiscountPercent`, `DiscountFixedAmount`. Detay → Düzenle → checkout taslağı + sepet doldurulur; kaydet `Sale.Update` çağırır.
