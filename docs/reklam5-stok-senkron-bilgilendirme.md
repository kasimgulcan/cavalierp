Merhaba,

CavaliERP tarafında e-ticaret stok senkronizasyon için satış, iade, snapshot ve webhook yapısını tamamladım ve kendi ortamımızda uçtan uca test ettim. 
Bu geliştirme ürün kataloğu değil; sitede ve mağazada stoğun nasıl hareket ettiğini ve anlık bakiyenin nasıl okunacağını kapsıyor.

Teknik ayrıntı, örnek JSON ve imza kuralı aşağıda. Lütfen sorunuz olursa bu metin üzerinden dönüş yapın.


## Yapı

İki yönlü, HMAC imzalı bir stok kanalı kurdum.
Sitede satış veya iade olunca bize kaç adet satıldığını veya iade edildiğini bildirirsiniz. 
Biz bunu CavaliERP’de satış veya stok girişi olarak yazarız.

Tüm SKU bakiyesini görmek istediğinizde bizim snapshot’ı çekersiniz. 
Bu, anlık listedir; webhook değildir.

Sizin snapshot adresiniz gelince, belli aralıklarla o listeyi çekip CavaliERP bakiyesini ona göre hizalayacağız. 
Bu hizalama size tekrar webhook olarak gitmez; döngü oluşmaz.

CavaliERP’de stok girişi ya da satış değişince (ekleme, adet güncelleme, silme) sizin vereceğiniz adrese webhook atarız. Gövdede hem hareket adedi hem o anki bakiye vardır.

SKU dışarıda `skuCode` alanıdır; format `ProductCode_Size`, örneğin `H.RUGFL_FLC0001_FLC0001GRNNAV_XL`. 
JSON’da SizeId yoktur.

Siteden gelen `quantity` kalan stok değildir; o andaki hareket adedidir (kaç sattınız, kaç iade aldınız). 
Stok yetmezse satış yine yazılır; bakiye eksi olabilir.

Aynı `eventId` ikinci kez gelirse tekrar yazılmaz. 
Siteden gelen hareketler size geri webhook olarak gitmez; döngü oluşmaz.


## Signing
Algoritma HMAC-SHA256, UTF-8’dir.

Secret Key:
CavalierSanMarco.reklam5.stock-sync.v1.H8cL2nP9qW4xR7mK

Her istekte iki header gönderin. 

1.	`X-CavaliERP-Timestamp` Unix saniye cinsinden UTC zamandır. 
2.	`X-CavaliERP-Signature` değeri `sha256=` ile başlar, ardından 64 karakter küçük harf hex gelir.

Saat kayması ±5 dakikayı aşarsa, imza yoksa veya yanlışsa yanıt 401’dir.

İmzalanan metin POST’ta `{timestamp}.{hamBody}` şeklindedir. 
`hamBody`, imzalamadan önceki ham JSON’dır. 
İmzadan sonra gövdeyi düzenlemeyin ve boşluk eklemeyin.

GET snapshot’ta metin `{timestamp}.GET.{path}` şeklindedir. 
`path` host’suz, sonda slash'sız yoldur. 
Siz bizim snapshot’ı çekerken path `/integrations/ecommerce/stock/snapshot` olur (`/cavalierp/api` yoktur). 


POST için örnek canonical (tek satır): 
1756473600.{"eventId":"3fa85f64-5717-4562-b3fc-2c963f66afa6","eventType":"sale.created","occurredAt":"2026-08-28T12:00:00Z","source":"ecommerce","item":{"skuCode":"H.RUGFL_FLC0001_FLC0001GRNNAV_XL","quantity":1}}

GET için örnek canonical (sizin bizim snapshot’ı çekmeniz):
1756473600.GET./integrations/ecommerce/stock/snapshot

PHP Örnek:
$timestamp = (string) time();
$canonical = $timestamp . '.' . $rawJsonBody; // GET: $timestamp . '.GET./integrations/ecommerce/stock/snapshot'
$signature = 'sha256=' . hash_hmac('sha256', $canonical, $secret);

Bizim webhook’u alırken aynı secret ve aynı POST kuralı ile doğrulayın. 
2xx dışı yanıtlarda üç kez deneriz, sonra dururuz. 
O durumda siz bizim snapshot’ı çekerek toparlarsınız.

## Endpoint’ler

Satış veya iade bildirmek için POST:
https://app.devcloud.com.tr/cavalierp/api/integrations/ecommerce/stock

Tüm stok listesini çekmek için GET:
https://app.devcloud.com.tr/cavalierp/api/integrations/ecommerce/stock/snapshot

İsteklerde `Content-Type: application/json; charset=utf-8` kullanın.


## Sizden bize: satış ve iade

POST `/integrations/ecommerce/stock`

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

`sale.created` bizim tarafta satış kaydı oluşturur. 
`return.created` bizim tarafta iadeyi stok girişi olarak yazar. 
`source` her zaman `"ecommerce"` olsun. 
`quantity` en az 1 olsun; bu kalan stok değil, hareket adedidir.
Her hareket için yeni bir GUID `eventId` üretin. 
Aynı kimlik tekrar gelirse ikinci yazım olmaz; ilk sonuç döner.

SKU yoksa 404 alırsınız. Aynı `skuCode` birden fazla bedene denk gelirse 409 alırsınız.

Başarılı yanıt örneği:
{
  "success": true,
  "eventType": "sale.created",
  "skuCode": "H.RUGFL_FLC0001_FLC0001GRNNAV_XL",
  "quantity": 1,
  "onHand": -3
}
`onHand` işlemden sonraki bakiyedir ve eksi olabilir.

---

## Siz bizim snapshot’ı çekersiniz

GET `/integrations/ecommerce/stock/snapshot`  
HMAC zorunludur; GET canonical kuralını kullanın.
{
  "generatedAt": "2026-08-28T00:00:00Z",
  "source": "cavalierp",
  "items": [
    { "skuCode": "H.RUGFL_FLC0001_FLC0001GRNNAV_XL", "quantity": 8 }
  ]
}

Burada `quantity` anlık bakiyedir. Açılışta ve sapma gördüğünüzde bu listeyi çekin. Eksi bakiyeler gizlenmez.

## Biz sizin snapshot’ınızı çekeriz

Bize bir HTTPS snapshot URL’si verin. 
Aynı JSON sözleşmesini döndürün; `quantity` anlık bakiye olsun, `source` `"ecommerce"` olsun.

Örnek yanıt:
{
  "generatedAt": "2026-08-28T00:00:00Z",
  "source": "ecommerce",
  "items": [
    { "skuCode": "H.RUGFL_FLC0001_FLC0001GRNNAV_XL", "quantity": 8 }
  ]
}

Adres geldikten sonra bu GET’i HMAC ile belli aralıklarla çağıracağız. 
Canonical path, sizin URL’nizin yoludur. Adres örneğin `https://www.cavaliersanmarco.it/api/stock/snapshot` ise imzalanan metin `{timestamp}.GET./api/stock/snapshot` olur.

Gelen bakiyeye göre CavaliERP’yi hizalayacağız. 
Bu düzeltme size webhook olarak gitmez.

Sizden 2xx ve yukarıdaki JSON’u bekleriz.

## Bizden size: webhook

CavaliERP’de stok ya da satış değişince sizin URL’nize webhook atarız. HMAC, satış bildirimindeki POST kuralı ile aynıdır.

{
  "eventId": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
  "eventType": "sale.created",
  "occurredAt": "2026-08-28T12:05:00Z",
  "source": "cavalierp",
  "item": {
    "skuCode": "H.RUGFL_FLC0001_FLC0001GRNNAV_XL",
    "quantity": 2,
    "onHand": 10
  }
}

`source` her zaman `"cavalierp"` gelir. 
`item.quantity` hareketin adedidir.
 `item.onHand` o anki bakiyedir.

`sale.created` satır eklendiğinde gider; quantity satılan adettir.  
`sale.updated` adet değiştiğinde gider; quantity = [yeni] – [eski] ‘dir.  Negatif olabilir.  
`sale.deleted` satır silindiğinde gider; quantity silinen adettir.  
`stock.received` stok girişi eklendiğinde gider; quantity girilen adettir.  
`stock.updated` giriş adedi değiştiğinde gider; quantity yeni eksi eskidir.  
`stock.deleted` giriş silindiğinde gider; quantity silinen adettir.

Sizin satış ve iadeleriniz (`source: ecommerce`) tekrar webhook olarak gitmez.

Sizden 2xx bekleriz. 401 veya 5xx alırsak üç denemeden sonra dururuz. O durumda siz bizim snapshot’ı çekerek toparlarsınız.
 

Canlıya almak için sizden iki adres bekliyorum: 
1. Stok hareketleri için webhook atacağımız HTTPS URL 
2. Sizin snapshot adresiniz


Bizim taraf hazır. Endpoint’ler ayakta, satış/iade/sizin çekeceğiniz snapshot ve webhook kısımlarını test ettim.
Şu an production ortamı test edilmeye müsait. Siz istediğiniz gibi kayıt gönderebilir, snapshot çekebilirsiniz.

Sizin snapshot URL’si gelince hizalamayı bağlarız. Testleri tamamladığımızda production ortamındaki stokları sıfırdan düzenleyip akışı çalıştıracağım.