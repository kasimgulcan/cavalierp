# E-ticaret katalog tetikleme — CSM.OpsPilot (masaüstü)

Bu belge **yalnızca** `D:\KocaPanda\Projeler\Karbel\CSM.OpsPilot` (WinForms, .NET Framework 4.8, `CSM.CavaliERP`) içindir.

Karşı Cursor: bu dosyayı oku ve buradaki görevleri uygula. CavaliERP.Mobile / ASP.NET API / Flutter koduna dokunma.

**Tarih:** 2026-09-10  
**Kaynak:** reklam5 (site) e-postası — tetikleme uç noktası staging’de açık, canlıda aynı yapı.

Asıl kopya masaüstü repoda: `D:\KocaPanda\Projeler\Karbel\CSM.OpsPilot\docs\ecommerce-catalog-trigger-desktop.md`

---

## 1. Ne iş?

Site ürün kataloğunu artık 12 saatte bir çekmeye mahkûm değil. ERP’de ürün tanımı değişince **masaüstü, siteyi tetikleyecek**. Site hemen `{"status":"accepted"}` döner, kataloğu arka planda CavaliERP snapshot’ından çeker.

Stok ayrı kanaldır. Bu iş stok webhook’una, `StokDuzenleme` formuna, satışa dokunmaz.

### Zaten hazır (API / SQL — sen yazma)

- Site kataloğu çeker: `GET https://app.devcloud.com.tr/cavalierp/api/integrations/ecommerce/products/snapshot`
- `LastModifiedOn` katalog tablolarında var; **stok adedi** (`InStockQty`) bu alanı güncellemez
- HMAC kuralı stok snapshot ile aynı (aşağıda)
- Site 12 saatlik emniyet tarama turunu bırakmıyor; tetikleme düşerse en geç 12 saatte yine çeker

### Senin işin

1. Site tetikleme GET’ini HMAC ile çağıran küçük bir istemci
2. Katalog kaydetme ekranlarından **tek** tetikleme (debounce)
3. Liste fiyatını siteye basmak için **ayrı, onaylı** aksiyon (`price=force`)
4. SQL kayıt başarılı olduktan sonra tetikle; tetikleme hata verirse kaydı geri alma

---

## 2. Yasaklar

- HMAC secret private repo’da duruyor; `app.config`’e aşağıdaki değeri yaz. Public bir yere kopyalama.
- Tetiklemeyi **SQL kaydını rollback** ettirme. Site `busy` veya ağ kopsun — ürün ERP’de kayıtlı kalsın, kullanıcıya uyarı yeter.
- `StokDuzenleme` (`InsStokDuzenleme`) kaydında tetikleme **yok**. Stok zaten ayrı senkron.
- Her satır / her varyant için ayrı HTTP **atma**. Tur sürerken ikinci istek `busy` döner. Bir kaydetmede **en fazla bir** istek (gerekirse debounce).
- Kaydet butonuna gizlice `price=force` koyma. Kampanya liste fiyatı üzerinden yürüyorsa otomatik fiyat yazmak kampanyayı bozar. Partner bunu özellikle uyardı.
- Sitedeki indirim oranı / indirimli fiyat alanlarını göndermeye veya ezmeye çalışma. Dokunulmaz.
- CavaliERP.Mobile reposunu, IIS API’yi, Flutter’ı değiştirme.

---

## 3. Site sözleşmesi (kaynak gerçek)

### Adres

| Ortam | URL |
|---|---|
| Staging (şimdi test) | `https://staging.cavaliersanmarco.it/en/data/plugin/get.ciqra?pluginName=cavalierp-catalog-trigger` |
| Canlı | `https://www.cavaliersanmarco.it/en/data/plugin/get.ciqra?pluginName=cavalierp-catalog-trigger` |

E-postada örnek `www` ile yazılmış; stok snapshot’ta biz staging host’u ayrı tutuyoruz. Masaüstü varsayılanı **staging** olsun, canlı URL config’den değişsin.

### HMAC (stok snapshot ile birebir — yeni algoritma yok)

- Method: `GET`
- İmzalanan metin: `{timestamp}.GET./en/data/plugin/get.ciqra`
- Query string **imzaya girmez**
- `timestamp` = Unix saniye UTC
- Tolerans ±5 dakika
- İmza: HMAC-SHA256, header formatı `sha256=` + 64 karakter küçük harf hex
- **Query string zorunlu** (site altyapısı HTTP header’ı eklentiye geçirmiyor):

```
...&X-CavaliERP-Timestamp=1788876158&X-CavaliERP-Signature=sha256%3D<hex>
```

Header göndermek opsiyonel; query yeter. `sha256=` değeri URL-encode edilince `sha256%3D` olur.

Secret (CavaliERP.API `EcommerceSync:SharedSecret` ile aynı):

```
CavalierSanMarco.reklam5.stock-sync.v1.H8cL2nP9qW4xR7mK
```

### Parametreler (hepsi isteğe bağlı, birleştirilebilir)

| Query | Etki | Masaüstü ne zaman |
|---|---|---|
| *(yok)* | Son çekimden beri değişenleri alır | **Varsayılan** — Products / Lookups / PUBLISH kaydı sonrası |
| `mode=full` | Tüm katalogu baştan tarar | Nadir “tam tarama” butonu |
| `productCode=XXX` | Yalnızca o ürün | Tek ürün gönder (opsiyonel). `XXX` = `FULL PRODUCT CODE` (bedenli SKU değil) |
| `media=force` | Dosya adı aynı olsa bile görselleri yeniden işler | Kullanıcı aynı ada yeni dosya bastıysa |
| `price=force` | Liste fiyatlarını o turda uygular | **Yalnızca bilinçli fiyat butonu** |

Örnekler:

```
...&productCode=R.TOPWN_TPL0133_PIQ0015PNKPNK&media=force
...&mode=full&price=force
```

`productCode` örneği `GetFullProductCodes.FullProductCode` / `V_SKU.[FULL PRODUCT CODE]` ile aynı formattır (`H.RUGFL_STR0005_RPS0003BLKBLK` gibi). `SKU CODE` (`..._S / COB`) **değildir**.

### Yanıt

- Hemen döner: `{"status":"accepted"}` — iş arka planda; dakikalar sürebilir; UI beklemesin.
- Tur varken ikinci tetikleme: **busy** (çakışma yok). 30–60 sn sonra **en fazla 2 retry**.
- Başarısız HTTP / timeout: log + kullanıcıya kısa uyarı; SQL’e dokunma.

---

## 4. Bu projedeki mevcut kod (bağlanacağın yerler)

Çözüm: `CSM.CavaliERP.csproj`  
Namespace: `CSM.CavaliERP`  
HTTP örneği: `Core/DeepLTranslation.cs` (statik `HttpClient` + `app.config` `appSettings`). Aynı kalıbı kullan.

| Form | Dosya | Kaydet | Tetikle? |
|---|---|---|---|
| Products | `Forms/Products.cs` `btnKaydet_ItemClick` | `gvStyle/Article/Var/Size.Update(...)` | **Evet** — kayıt sonrası 1× incremental |
| Lookups | `Forms/Lookups.cs` `btnKaydet_ItemClick` | `gv.Update()` | **Evet** — kategori/renk vb. çok ürüne yayılır; 1× incremental |
| SKU List | `Forms/SKU.cs` `btnSave_ItemClick` | `SaveSKU` (PUBLISH + IN-STOCK QTY) | **Yalnızca PUBLISH değiştiyse** incremental. Sadece stok adedi ise **hayır** |
| SKU sil | `Forms/SKU.cs` `Sil` | `DelSize` | **Evet** — 1× incremental |
| Price List | `Forms/PriceList.cs` `btnKaydet_ItemClick` | `SavePriceList` | Kayıttan sonra incremental **fiyatsız** (`price=force` yok). Site fiyatı yazmaz, tanım senkronu yeter. |
| Price List | `Forms/PriceList.cs` `btnFiyatGuncelle_ItemClick` | Şu an stub: `"Bu işlem henüz aktif değildir."` | **Burayı aç:** onay sonrası `mode=full&price=force` |
| Stock | `Forms/StokDuzenleme.cs` | `InsStokDuzenleme` | **Hayır** |
| Product List | `Forms/ProductList.cs` | Rapor | Hayır |
| DilDestekliUrunDetay | popup | Products grid’ine yazar | Tetikleme Products kaydında |

`productCode` lazımsa: `GetFullProductCodes` zaten `Products.cs` içinde çağrılıyor (`FullProductCode` + `VariantId`).

Medya kolonları `Variant`: `MainPhoto`, `Photo2`…`Photo6`, `Video`, `ExtraMedia` (`varchar(500)`). Partner’a “dosya adını değiştireceğiz” denmiş. Kullanıcı foto alanındaki **metni** değiştirirse incremental yeter. Aynı dosya adı ile içeriği değiştiriyorsa ayrı `media=force` aksiyonu gerekir.

---

## 5. Uygulama planı

### Görev A — Config

`app.config` `appSettings`:

```xml
<add key="Ecommerce:Enabled" value="true" />
<add key="Ecommerce:CatalogTriggerUrl" value="https://staging.cavaliersanmarco.it/en/data/plugin/get.ciqra?pluginName=cavalierp-catalog-trigger" />
<add key="Ecommerce:SharedSecret" value="CavalierSanMarco.reklam5.stock-sync.v1.H8cL2nP9qW4xR7mK" />
```

`Ecommerce:SharedSecret` boşsa tetikleme **sessizce atlanır**. Doluysa çalışır.

Canlıya geçince URL’yi `www.cavaliersanmarco.it` yapın. Secret staging ve canlıda aynıdır.

### Görev B — HMAC + istemci

Yeni dosya önerisi: `Core/EcommerceCatalogTrigger.cs`

Davranış:

1. `Ecommerce:Enabled=false` veya URL/secret boş → no-op, `Skipped`
2. Unix timestamp UTC, canonical = `{timestamp}.GET.` + URI path (`/en/data/plugin/get.ciqra`, trailing slash yok)
3. HMAC-SHA256 UTF-8, hex **lowercase**, prefix `sha256=`
4. Mevcut query’yi koru (`pluginName=cavalierp-catalog-trigger`), üzerine opsiyonel `mode` / `productCode` / `media` / `price`, sonra `X-CavaliERP-Timestamp` ve `X-CavaliERP-Signature` ekle (`Uri.EscapeDataString`)
5. GET, `Accept: application/json`, timeout ~30 sn (cevap hemen gelir)
6. 2xx ve gövdede `accepted` → `Accepted`
7. Gövde/status `busy` → `Busy` (çağıran retry eder)
8. Diğer → exception mesajını sonuç olarak dön; fırlatıp kaydı bozma

.Net 4.8 iskelet (aynen kullanılabilir, test et):

```csharp
public sealed class CatalogTriggerRequest
{
    public string ProductCode;   // FULL PRODUCT CODE veya null
    public bool FullScan;        // mode=full
    public bool MediaForce;      // media=force
    public bool PriceForce;      // price=force
}

public enum CatalogTriggerStatus { Skipped, Accepted, Busy, Failed }

public static class EcommerceCatalogTrigger
{
    public static CatalogTriggerStatus Fire(CatalogTriggerRequest req, out string detail)
    {
        // 1) config oku
        // 2) imzala + GET
        // 3) accepted / busy / failed
        detail = "";
        return CatalogTriggerStatus.Skipped;
    }

    public static void FireAfterSave(CatalogTriggerRequest req)
    {
        // UI thread'i kilitleme. Task.Run.
        // Busy ise 30sn bekleyip en fazla 2 kez tekrar.
        // Failed: XForm.ShowErrorMessage veya status bar; SQL'e dokunma.
    }
}
```

Canonical path’i URL’den al: `new Uri(url).AbsolutePath` → `/en/data/plugin/get.ciqra`. Query’yi imzaya **katma**.

İmza hesabı:

```csharp
string timestamp = DateTimeOffset.UtcNow.ToUnixTimeSeconds().ToString();
string canonical = timestamp + ".GET." + uri.AbsolutePath.TrimEnd('/');
byte[] hash;
using (var hmac = new HMACSHA256(Encoding.UTF8.GetBytes(secret)))
    hash = hmac.ComputeHash(Encoding.UTF8.GetBytes(canonical));
string signature = "sha256=" + BitConverter.ToString(hash).Replace("-", "").ToLowerInvariant();
```

`.NET 4.8` notu: `DateTimeOffset.ToUnixTimeSeconds()` 4.6+ ile gelir; 4.8’de var.

Debounce: 5 sn içinde ikinci `FireAfterSave` gelirse tek istekte birleştir (son istek kazansın; `PriceForce` bir tanesinde true ise birleşimde true kalsın — ama kaydet yolu `PriceForce` göndermesin, sadece fiyat butonu göndersin).

### Görev C — Products

`Forms/Products.cs` → `btnKaydet_ItemClick` sonunda, `Update` çağrıları **başarılıysa**:

```csharp
EcommerceCatalogTrigger.FireAfterSave(new CatalogTriggerRequest());
```

Boş request = incremental. 20 varyant kaydı olsa bile **tek** çağrı.

İsteğe bağlı ribbon (Products):

- **Siteye gönder** → incremental (boş) veya seçili satırın `FullProductCode` ile `productCode=`
- **Görselleri yeniden işle** → seçili `productCode` + `media=force` (onaylı)
- **Tam katalog taraması** → `mode=full` (onaylı; ağır)

Bu üçü yoksa bile kaydet-sonrası incremental şart.

### Görev D — Lookups

`Forms/Lookups.cs` `btnKaydet_ItemClick` sonunda `gv.Update()` sonrası incremental `FireAfterSave`. Lookups (WebCategory, Color, …) birçok SKU’nun `LastModifiedOn` değerini yükseltir; `productCode` kullanma.

### Görev E — SKU List

`SaveSKU` hem `PUBLISH` hem `IN-STOCK QTY` yazar.

- XML’de yalnızca stok adedi değişmişse tetikleme **yok**
- `PUBLISH` kolonu değişmişse incremental tetikle
- `DelSize` sonrası incremental tetikle

`SerializeChanges("SizeId", "IN-STOCK QTY", "PUBLISH")` çıktısına bak: PUBLISH değeri orijinalden farklı mı? Değilse stok-only say.

### Görev F — Price List (kritik UX)

1. `btnKaydet_ItemClick` — `SavePriceList` sonrası incremental, **`price=force` yok**. (Site liste fiyatını bu turda yazmaz; Excel döneminde de böyleydi.)
2. `btnFiyatGuncelle` — stub’ı kaldır. Caption önerisi: **Liste fiyatını siteye uygula**. Onay diyaloğu:

> ERP’deki liste fiyatları (EUR/TL/USD) siteye yazılacak. Sitedeki indirim alanlarına dokunulmaz. Kampanya liste fiyatı üzerinden hesaplanıyorsa etkilenebilir. Devam edilsin mi?

Onay → `FireAfterSave(new CatalogTriggerRequest { FullScan = true, PriceForce = true })` yani `mode=full&price=force`.

Tek ürün fiyatı için ileride `productCode` + `price=force` eklenebilir; ilk sürümde Price List butonu tüm tarama + fiyat yeter.

### Görev G — Stock

`Forms/StokDuzenleme.cs` — **değiştirme** (tetikleme ekleme).

---

## 6. Davranış matrisi

| Kullanıcı | Tetikleme query |
|---|---|
| Products kaydet (isim, kategori, PUBLISH, foto metni, yeni ürün) | *(boş)* incremental |
| Lookups kaydet | *(boş)* |
| SKU’da yalnızca adet | yok |
| SKU’da PUBLISH | *(boş)* |
| Size sil | *(boş)* |
| Price List kaydet | *(boş)* — fiyat siteye yazılmaz |
| “Liste fiyatını siteye uygula” | `mode=full&price=force` |
| Aynı dosya adı, görseli yenile | `productCode=...&media=force` |
| Stok ekranı | yok |

---

## 7. Doğrulama

1. `Ecommerce:SharedSecret` doldur, URL staging.
2. Products’ta bir ürün adını değiştir, kaydet. Fiddler/log: GET `pluginName=cavalierp-catalog-trigger`, query’de timestamp + signature, path imzada `/en/data/plugin/get.ciqra`.
3. Yanıt `accepted` (veya `busy` + retry sonrası `accepted`).
4. Site/partner log: tur başlamış olmalı. CavaliERP tester’dan katalog snapshot hâlâ çalışıyor olmalı.
5. Stok ekranından adet kaydet — **tetikleme isteği gitmesin**.
6. Price List kaydet — tetikleme gitsin, URL’de `price=force` **olmasın**.
7. “Liste fiyatını siteye uygula” — onay iptali istek atmasın; onay `mode=full` ve `price=force` göndersin.
8. Secret boşken kaydetme kırılmasın.

Partner kendi imzasını staging’de test etmiş. İlk 401’de: path (`/en/data/plugin/get.ciqra`), secret, `sha256=` lowercase hex, query encode, saat UTC.

---

## 8. Kapsam dışı (bilinçli)

- Mobil uygulama
- CavaliERP.API içinde tetikleme proxy’si (ileride secret masaüstünden çıkarılabilir; bu iş için gerekmez — partner uç noktası masaüstünün çağırması için açıldı)
- Stok snapshot / stok webhook
- `LastModifiedOn` SQL trigger’ları
- Site indirim alanları

---

## 9. Partner e-postası (özet, kaybolmasın)

Tetikleme uç noktası açıldı. Staging’de; canlıda aynı yapı. İmza stok snapshot ile aynı; yeni imza kodu yok. Query string zorunlu. Boş çağrı = son çekimden değişenler. `mode=full`, `productCode`, `media=force`, `price=force` birleştirilebilir. Yanıt hemen `accepted`; iş arka planda. İkinci çağrı `busy`. 12 saatlik periyodik tur emniyet ağı olarak kalır. Liste fiyatı her turda uygulanmaz — sitede kampanyalar liste fiyatı üzerinden yürüyebilir; otomatik yazmak kampanyayı bozar. Fiyatın işlenmesi için `price=force`. İndirim alanlarına hiç dokunulmaz. `LastModifiedOn` stok hareketinde artmaz; katalog senkronu stok değerine dokunmaz.
