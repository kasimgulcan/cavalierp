# Mobil uygulama talep listesi

**Tarih:** 30 Ağustos 2026  
**Kaynak:** Mağaza personeli geri bildirimi  
**Kapsam:** CavalierShop (personel satış akışı)

Bu belge sahadan gelen 11 isteği düzenler: orijinal metin, mevcut davranış ve hedef davranış. Belirsiz maddeler “Açık soru” olarak işaretlenmiştir.

---

## Özet

| # | Talep | Tema | Öncelik |
|---|--------|------|---------|
| 1 | Oturum açık kalsın (logout demedikçe) | Oturum | Kritik |
| 7 | Sürekli logout; basic kullanıcıya düşme | Oturum | Kritik |
| 8 | Sepette ürün kaybı + müşteri bilgisi silinmesi | Oturum / satış taslağı | Kritik |
| 10 | Checkout’a girmeden ürünlere dönüp bilgi kaybetmeden gezinme | Satış akışı | Kritik |
| 2 | Tamamlanmış satışta müşteri bilgisi düzenleme; indirim tutarını satış kapanmadan görme | Satış düzenleme | Yüksek |
| 3 | Virgüllü tutar girişi; tutarı “Satışı Tamamla”dan önce gösterme | Fiyat / indirim | Yüksek |
| 4 | Satışı tamamlamadan önce onay (review/confirm) | Satış akışı | Yüksek |
| 5 | Contains + canlı arama; ürün adına göre arama; kapanınca arama sıfırlansın | Ürün arama | Yüksek |
| 6 | Satış takvimi varsayılanı bugün–bugün | Satış listesi | Orta |
| 9 | Hediye ürün (stok düşsün, bedel 0) ve/veya Promosyon ödeme tipi | Hediye / ödeme | Yüksek |
| 11 | İndirim alanlarında 0 yerine boş | Fiyat / indirim | Düşük |

---

## A. Oturum (1, 7, 8)

### 1 — Logout demedikçe oturum açık kalsın

**Orijinal:** Uygulamada ilk girdikten sonra log out demedikçe logged-in kalabilir miyiz? İşlem sırasında, başka bir ekrana bakarken vs. dışarı attı. Başka bir müşteriye bilgi girerken telefon verildi; bilgiler silinmiş ve logout olmuş.

**Mevcut:** Access token 15 dakikada doluyor. Refresh token (30 gün) sunucuda var ama uygulama yenilemiyor. 401 gelince oturum hemen kapanıyor; sepet ve checkout alanları da kayboluyor.

**Hedef:** Kullanıcı “Çıkış” demediği sürece oturum açık kalsın. Token süresi dolunca arka planda yenilensin. 401 yüzünden satış ortasında login ekranına düşülmesin.

### 7 — Sürekli logout; basic kullanıcıya dönüş

**Orijinal:** Sürekli log out oluyorum, nedenini anlamadım. Hep basic kullanıcıya dönüyor.

**Mevcut:** 401 → oturum kapanır. Personel (Staff) sekmeleri kaybolur; misafir görünümü (Ürünler + Profil) gelir. Profil yüklenene kadar da Staff değil gibi davranılır.

**Hedef:** Token yenileme ile bu kopmalar bitsin. Profil yüklenene kadar son bilinen rol (Staff) korunsun; kısa süreliğine “basic” arayüze düşülmesin.

### 8 — Sepette ürün görünmedi; ürünlere dönünce müşteri bilgisi silindi

**Orijinal:** Sepete attığımız halde bir ürün gözükmedi. Tekrar ürünlere döndüğümüzde müşteri bilgileri siliniyor. İki kere oldu.

**Mevcut:** Sepet bellekte tutuluyor; uygulama kapanırsa veya oturum düşerse gider. Müşteri adı / telefon / e-posta yalnızca checkout ekranındaki alanlarda duruyor; geri gidince siliniyor.

**Hedef:**
- Sepet, oturum açıkken sekme değişiminde kaybolmasın.
- Checkout’taki müşteri bilgileri taslak olarak korunsun; ürünlere gidip gelince silinmesin.
- Oturum yenileme (madde 1/7) sepet/müşteri kaybını da azaltır.

---

## B. Satış akışı ve düzenleme (2, 3, 4, 10, 11)

### 10 — Ürünlere dönüp değişiklik; “İleri” vs “Satışı Tamamla”

**Orijinal:** Satış esnasında check-out yapmadan ürünlere dönüp ilave veya değişiklik yapıp rahatça ve bilgileri kaybetmeden gezinmek gerekiyor. Şu an olmuyor gibi. Bir sonraki aşamaya geçmek için butona “İleri” yazıp, satışı gerçekten bitireceğimiz zaman “Satışı Tamamla” diyebiliriz. Şimdi her aşamada “Satışı Tamamla” ile ilerleniyor.

**Mevcut:** Sepetteki buton da “Satışı Tamamla”. Checkout’a gidince müşteri alanları dolduruluyor; geri dönünce bu alanlar boşalıyor. Checkout’tan ürün listesine serbest gidip gelmek yok.

**Hedef:**
- Sepet alt butonu: **İleri** → checkout.
- Checkout alt butonu: **Satışı Tamamla** (madde 4 ile onaylı).
- Checkout’tan geri / ürünlere dönüşte sepet + müşteri + ödeme + not + indirim taslağı kalsın.
- Checkout açıkken ürün ekleyip çıkabilmek (ör. “Ürün ekle” ile ürün sekmesine dönmek).

### 4 — Satışı tamamlamadan onay

**Orijinal:** Belki satışı tamamla basınca review/confirm gibi bir konfirmasyon koyabiliriz. Yanlışlıkla basıp kapatmayı engelleriz.

**Hedef:** “Satışı Tamamla” → onay diyaloğu (müşteri, kalem sayısı, net tutar). Vazgeç satışa dokunmaz; Onayla kaydı oluşturur.

### 2 — Satış düzenleme + indirimi kapanmadan görme

**Orijinal:** Satışlara müşteri bilgileri dahil edit yapabilir miyiz? Yanlış bir şey girdiğimde düzeltemedim. Bir müşterinin de sonradan mailini eklemek istedim, ekleyemedim. Manuel indirimi yazınca rakamı göremedim; görmek için satışı tamamla’ya bastım, satış kapandı. Yanlış girmiştim, düzeltmek istedim, düzeltemedim.

**Mevcut:** Tamamlanmış satışta yalnızca iptal var; müşteri / e-posta / tutar düzenlenemiyor. İndirim yazılınca alt bardaki net tutar güncellenmeli; birim fiyat ise klavye kapanana veya satış tamamlanana kadar satır tutarına yansımayabiliyor.

**Hedef (akış içi):** İndirim ve birim fiyat yazıldıkça alt toplam / satır tutarı anında güncellensin. Satış kapanmadan görülsün ve düzeltilebilsin.

**Hedef (kayıt sonrası):** Tam satış düzenleme. Satış detayından kalem ekleme/çıkarma, miktar, birim fiyat, indirim, ödeme tipi ve müşteri bilgisi (ad, telefon, e-posta, not) değiştirilebilsin. Stok, düzenlenen kalem farkına göre güncellensin.

**Karar:** C — tam satış düzenleme (30 Ağustos 2026).

### 3 — Virgüllü tutar; tutarı tamamlamadan gösterme

**Orijinal:** 21,04’lük bir düzeltme yapmak istedim. Virgüllü rakamı yazamadım. Satışı tamamla’ya basmadan da rakamı gösterebilir miyiz?

**Mevcut:** Alan virgül kabul ediyor; ancak satış toplamları tam liraya yuvarlanıyor (`21,04` → `21`). Birim fiyat satır tutarına ancak alan bırakılınca işleniyor.

**Hedef:** Virgül ve nokta ile ondalık girilebilsin. `21,04` olduğu gibi görünsün ve kaydedilsin. Satış toplamları da kuruşlu olsun. Yazılan tutar satış kapanmadan görünsün.

**Karar:** A — kuruş açık (30 Ağustos 2026).

### 11 — İndirim alanlarında 0 yerine boş

**Orijinal:** İndirim ve yüzde indirim ekranlarında 0 yerine boş getirebilir miyiz? Telefonda hep önce sıfırı silmek gerekiyor.

**Hedef:** `% indirim` ve `Tutar indirimi` boş açılsın. Boş = indirim yok.

---

## C. Ürün arama (5)

**Orijinal:** Search’de “contains” ile aratıp aktif filtreleme yapabilir miyiz? Şu an model adını tam bilip search’e yazıp ara’ya basmak gerekiyor. Aramaya ürün adını da dahil etme imkânı olur mu? Sadece style değil ürün açıklaması da. Örn. Alea pantolon adını bilmeyen “pantolon” diye aratıp menüden seçse süper olur. Her arama sonrası sepete ekleyip kapat deyince sıfırlanırsa daha pratik olur. Arka arkaya farklı model aratarak satış yapıyoruz; her defasında sil yazmak telefondan zor.

**Mevcut:** Arama Enter / “ara” ile çalışıyor; yazdıkça liste güncellenmiyor. Kapatınca arama metni kalıyor.

**Hedef:**
- Yazarken (kısa gecikmeyle) filtrele.
- Eşleşme: contains (içinde geçen).
- Alanlar: stil adı **ve** ürün adı / açıklama (ör. “pantolon”).
- Beden seçimi kapanınca arama kutusu ve filtre sıfırlansın.

---

## D. Satış listesi (6)

**Orijinal:** Default satış takvimi (tarih aralığı) başlangıç ve bitiş içinde olan gün olarak ayarlansın. Günlük kullanacağız; hemen bastığımızda ilk onu görelim.

**Mevcut:** Varsayılan aralık son 30 gün → bugün.

**Hedef:** Varsayılan **bugün → bugün**. İstenirse tarih yine değiştirilebilsin.

---

## E. Hediye / promosyon (9)

**Orijinal:** Hediye ürün veriyoruz. Stoktan düşüp ama bedele sıfır yazmalıyız. Hediye diye checkbox koyup işaretleyince bedelsiz getirsek olur mu? Bir kişiye sadece bir tek ürün verdik, ona da para almadık; ödemeye promosyon diye bir seçenek daha mı koysak? Ne yazacağımı bilemedim.

**Mevcut:** Kalemde fiyat 0 yapılabilir ama “Hediye” işareti yok. Ödeme tipi listesinde “Promosyon” yok (liste sunucudan geliyor).

**Hedef:**
- Satırda **Hediye** işareti: fiyat 0, stok yine düşer.
- Tüm satış bedelsizse / kampanyaysa ödeme tipi **Promosyon**.

**Karar:** A — ikisi birden (30 Ağustos 2026).

---

## Uygulama notları

Teknik kök nedenler (geliştirme sırasında):

1. Access token yenilenmiyor → 15 dk sonra 401 → logout + Staff sekmelerinin kaybı.
2. Checkout formu yerel; geri gidince müşteri bilgisi siliniyor.
3. Sepet ve checkout “Satışı Tamamla” diyor; yanlışlıkla satış kapanabiliyor.
4. Birim fiyat anında satır tutarına yansımıyor; indirim alanları `0` ile açılıyor.
5. Satış listesi varsayılanı 30 gün; arama Enter bekliyor.

---

## Karar bekleyen maddeler

Hepsi karara bağlandı (30 Ağustos 2026):

1. ~~Kayıt sonrası satış düzenleme kapsamı~~ → **C: tam satış düzenleme**
2. ~~Kuruş~~ → **A: kuruş açık** (`21,04` kayda öyle gider)
3. ~~Hediye vs Promosyon~~ → **A: satırda Hediye + ödeme tipinde Promosyon**

## Veritabanı

Güncel şema: `sql/db.sql`.  
Bu iş için üzerine eklenen değişiklikler: `sql/Migrate_MobileSaleUx.sql`

- `fn_Sale_NetTotal` kuruşa (2 ondalık) yuvarlar
- `API_Auth_RefreshToken` Role döndürür
- `API_Product_List` contains aramaya ürün grubu / kategori / renk ekler
- `API_Sale_Update` müşteri, not ve ödeme tipini tam yazar
- `PaymentTypes` içine **Promosyon** eklenir (yoksa)

Refresh token satırları uygulama API’si tarafından `RefreshTokens` tablosuna yazılır (önceden üretiliyor ama kaydedilmiyordu).
