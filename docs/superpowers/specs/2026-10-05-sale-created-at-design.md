# Satış tarihi — düzenlenebilir CreatedAt

**Tarih:** 2026-10-05  
**Durum:** Onaylandı  
**Kaynak:** Satışın kağıttan sonradan girilmesi; gece yarısından sonra ertesi güne düşmesi

## Amaç

Yeni satışın tarihi varsayılan olarak kayıt anıdır. Gün ve saat, satış girerken ve kayıtlı satış düzeltilirken değiştirilebilir. İleri bir an seçilemez.

## Ekran

Alan ödeme ekranında, müşteri bölümünün üstündedir. Başlık **Satış tarihi**. Yan yana iki seçim vardır: gün `05.10.2026`, saat `00:30`. Aynı ekran yeni satışı ve kayıttan gelen düzeltmeyi kapsar.

Yeni satış açılışta o anı gösterir ve saat alanı orada donar. Kullanıcı gün veya saate dokunmazsa gönderilen değer kaydet anıdır. Birine dokunursa ekranda görünen gün ve saat yazılır. Yalnızca gün değişirse saat, açılışta donan saattir. Seçilen saatte saniye `00` olur.

Düzeltme, satışın kayıtlı `CreatedAt` değeriyle açılır. Dokunulmazsa o değer durur. Değiştirilirse yeni gün ve saat yazılır.

Gün seçici 1 Ocak 2020’den bugüne kadardır. Seçilen gün bugünse şu andan ileri saat kabul edilmez. İleri seçim uygulanmaz; “İleri tarih seçilemez” uyarısı çıkar. Kayıt 2020’den eskiyse ve kullanıcı dokunmazsa o tarih gönderilir.

Dokunulmuş seçim, ürünlere gidip geri dönünce taslakta kalır. Dokunulmamış yeni satış taslakta saat tutmaz; kaydet anı kullanılır. Liste ve satış detayı mevcut `CreatedAt` gösterimini kullanır.

## Sunucu

`Sales.CreatedAt` aynı kolon kalır. `API_Sale_Create` ve `API_Sale_Update` isteğe bağlı `@CreatedAt DATETIME = NULL` alır.

- Oluşturmada parametre boşsa `GETDATE()`.
- Güncellemede parametre boşsa kayıtlı tarih durur.
- Doluysa o değer yazılır. Sunucu saatinin 2 dakikadan fazla ilerisi reddedilir.

Uygulama yerel saati saat dilimi olmadan gönderir: `yyyy-MM-dd HH:mm:ss`.

Liste, detay ve sıralama `CreatedAt` ile devam eder. Boş veya okunamayan değer, oluşturmada “şimdi”, güncellemede kayıtlı tarihtir. Eski uygulama parametreyi göndermez. Script onaydan önce çalıştırılabilir: `sql/Migrate_SaleCreatedAt.sql`.

## Hata

Satış kaydı başarısız olursa taslak ve seçilen tarih durur. Sunucu reddi ödeme ekranındaki mevcut hata bildirimiyle gösterilir.

## Test

`mobile/test/features/sale/sale_datetime_test.dart`. Ayrı ekran testi yok.

- 5 Ekim 2026 00:30 → `2026-10-05 00:30:00`. Saat dilimi kaydırmaz.
- Şimdi ve geçmiş kabul edilir. İleri an reddedilir.
- Dokunulmamış yeni satış, kaydet anını gönderir.
- Dokunulmamış düzeltme, kayıtlı saati gönderir. Değişmiş seçim, seçilen değeri gönderir.
