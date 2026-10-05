# Satış bayrakları — çoklu seçim ve etiketler

**Tarih:** 2026-10-05  
**Durum:** Onaylandı  
**Kaynak:** Cemal Karabel, 03.10.2026

## Amaç

Satış bayrağının adı görünsün ve bir satışta birden fazla bayrak seçilebilsin. Liste filtresi de birden fazla bayrak seçebilsin; satış, seçilenlerden herhangi birini taşıyorsa gelsin.

Etiketler:

- Kırmızı — Ödeme takip
- Mavi — Üretim
- Turuncu — Genel takip

## Ekran

Etiketler ödeme ekranı, satış detayı, satış özeti, liste filtresi ve liste kartında görünür. Sıra her yerde ödeme, üretim, genel takip.

Seçim (ödeme ve satış detayı) her bayrak için ayrı bir anahtardır: renkli ikon ve ad. Dokunmak yalnız o bayrağı açar veya kapatır.

Liste filtresinde **Tümü** ve **İşaretli** durur. Üç etiketli çip birlikte seçilebilir. Bir renk seçilince İşaretli kapanır. İşaretli seçilince renkler kapanır. Tümü hepsini kapatır.

Liste kartında seçili her bayrak, ikonu ve adıyla müşteri adının altında durur. Sığmazsa alt satıra kayar. Satış özeti aynı işaretleri gösterir.

İleride eklenecek bayraklar sabit katalogdur: adı ve rengi uygulama sürümüyle gelir. Personel kendi bayrağını oluşturmaz.

## Saklama

`Sales.Flag` `TINYINT` kalır. Mevcut satırlar güncellenmez. Genel takip kodu `3` yerinde kalır.

Eski ve yeni sürümün ortak tek bayrak kodları:

| Değer | Anlam |
|------:|-------|
| 0 | Bayrak yok |
| 1 | Ödeme takip |
| 2 | Üretim |
| 3 | Genel takip |

Yeni sürüm, tanınmayan biti olmayan tek bayrağı bu kodlarla yazar. Eski sürüm onları göstermeye ve `Flag` ile birebir filtrelemeye devam eder.

İki veya daha fazla bayrak `128 + bit` olarak yazılır. `128` çoklu kayıt işaretidir. Anlam bitleri:

| Bit | Anlam |
|----:|-------|
| 1 | Ödeme takip |
| 2 | Üretim |
| 4 | Genel takip |
| 8, 16, 32, 64 | İleride eklenecek sabit bayraklar |

Örnek: ödeme + üretim = `131`. Üçü birden = `135`. `4` ile `127` arasındaki değerler geçersizdir.

Okuma:

- `0` bayrak yok
- `1`, `2`, `3` tek bayrak
- `128` ve üzeri, anlam bitlerine ayrılır
- `8`, `16`, `32`, `64` bu sürümde etiketlenmez; kayıt tekrar yazılırken silinmez

Yeni sürüm yazarken yalnız `FlagMask` gönderir, `Flag` göndermez:

- tanınmayan bit yok ve bayrak yok: `0`
- tanınmayan bit yok ve tek bayrak: `1`, `2` veya `3`
- birden fazla bayrak, ya da `8` / `16` / `32` / `64` duruyorsa: `128 + bitler`

Tanınmayan bit varken tek bayrak `1`, `2` veya `3` yazılmaz; o bitler silinirdi. Bilinen bayrakların hepsi kapatılsa da tanınmayan bitler `128 + bit` olarak kalır.

## Sunucu

Script: `sql/Migrate_SaleFlagMask.sql`. Yeni sürüm onaya gönderilmeden önce uygulanır. Eski uygulama bu sırada bozulmaz: `FlagMask` göndermez, liste eşitliği ve `0`–`3` kodları aynı kalır.

`API_Sale_List`:

- `Flag` doluysa `Sales.Flag = @Flag` (eski sürüm)
- `FlagMask` doluysa seçilen bitlerden herhangi biri yeter
- ödeme biti `1`, `Flag = 1` veya (`Flag >= 128` ve bit `1`)
- üretim biti `2`, `Flag = 2` veya (`Flag >= 128` ve bit `2`)
- genel takip biti `4`, `Flag = 3` veya (`Flag >= 128` ve bit `4`)
- `8`, `16`, `32`, `64` yalnız çoklu kayıtta aranır
- `FlagAny = 1` ise `Flag <> 0`
- ikisi de yoksa bayrak filtresi yok

`FlagMask = 3` ödeme veya üretim demektir. Eski “yalnızca genel takip” satırını getirmez.

`API_Sale_Create`, `API_Sale_Update`, `API_Sale_SetFlags`:

- `FlagMask` varsa o yazılır
- yoksa eski sürümün `Flag` değeri yazılır
- kayıt `128` ve üzerindeyse ve gelen değer `0`–`3` ise (eski sürüm) çoklu bayrak silinmez
- `4`–`127` oluşturulurken `0` olur; güncellemede mevcut değer kalır

`API_Sale_Get` kolonu olduğu gibi döner.

## Hata

Satış detayında kayıt sürerken seçici kilitlenir. Sunucu reddederse seçim geri alınır ve “İşaret kaydedilemedi” çıkar. Ödeme ekranındaki bayraklar satışla birlikte gider; satış kaydı başarısızsa taslak durur. Liste hatası bugünkü boş hata durumudur. Eksik veya sayı olmayan `Flag` bayraksız sayılır.

## Test

`mobile/test/features/sale/sale_flags_test.dart` güncellenir. Ayrı ekran testi eklenmez.

- Tek bayrak `FlagMask` olarak `1`, `2`, `3`; hiçbiri `0`
- Ödeme + üretim `131`; üçü birden `135`
- `1`, `2`, `3` ve `128+` okuma
- `8`, `16`, `32`, `64` tekrar yazılırken durur; yanında tek bilinen bayrak kalsa da değer `128 + bit` kalır
- Liste: filtre yoksa parametre yok; İşaretli `FlagAny = 1`; seçilen bitler `FlagMask` (genel takip biti `4`)
- Aynı bayrağa tekrar basmak yalnız onu kaldırır
- Satış özeti ve detay JSON’u aynı kuralla okunur
