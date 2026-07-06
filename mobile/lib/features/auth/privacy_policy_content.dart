class PrivacyPolicySection {
  const PrivacyPolicySection({
    required this.title,
    this.paragraphs = const [],
    this.bullets = const [],
  });

  final String title;
  final List<String> paragraphs;
  final List<String> bullets;
}

const privacyPolicyLastUpdated = '3 Temmuz 2026';
const privacyPolicyCompany = 'Cavalier San Marco';
const privacyPolicyAppName = 'CavaliERP';
const privacyPolicyContactEmail = 'info@kocapanda.com';
const privacyPolicyWebsite = 'www.cavaliersanmarco.it';

const privacyPolicySections = <PrivacyPolicySection>[
  PrivacyPolicySection(
    title: '1. Giriş',
    paragraphs: [
      'Bu Gizlilik Politikası, $privacyPolicyCompany (“biz”, “şirket”) tarafından sunulan '
      '$privacyPolicyAppName mobil uygulamasını (“Uygulama”) kullandığınızda kişisel '
      'verilerinizin nasıl toplandığını, kullanıldığını ve korunduğunu açıklar.',
      'Uygulama; at ve yarış malzemeleri kataloğuna erişim, üye kullanıcılar için sipariş '
      'talebi oluşturma ve yetkili personel için barkod ile satış işlemlerini destekler.',
    ],
  ),
  PrivacyPolicySection(
    title: '2. Veri sorumlusu',
    paragraphs: [
      'Veri sorumlusu: $privacyPolicyCompany\n'
      'Web: $privacyPolicyWebsite\n'
      'Gizlilik iletişim: $privacyPolicyContactEmail',
    ],
  ),
  PrivacyPolicySection(
    title: '3. Topladığımız veriler',
    paragraphs: [
      'Uygulamayı kullanırken aşağıdaki veriler işlenebilir:',
      'Uygulama reklam amaçlı izleme yapmaz ve verilerinizi üçüncü taraflara satmaz.',
    ],
    bullets: [
      'Hesap bilgileri: kullanıcı adı ve şifre (şifre sunucuda güvenli biçimde saklanır; düz metin olarak tutulmaz).',
      'Talep ve iletişim bilgileri: sipariş talebinde isteğe bağlı olarak verdiğiniz isim/firma, telefon, e-posta ve not.',
      'İşlem verileri: sepet içeriği, sipariş talepleri; personel kullanıcılar için satış ve stok kayıtları.',
      'Kimlik doğrulama verileri: oturum belirteçleri (access / refresh token), cihazınızda güvenli depolamada tutulur.',
      'Teknik veriler: API isteklerinin işlenmesi için gerekli sunucu günlükleri (hata ayıklama ve güvenlik amaçlı, sınırlı süre).',
      'Kamera (yalnızca personel): barkod okuma için kamera erişimi; görüntü kaydedilmez, yalnızca anlık tarama yapılır.',
    ],
  ),
  PrivacyPolicySection(
    title: '4. Verilerin kullanım amaçları',
    bullets: [
      'Hesap oluşturma, giriş ve kimlik doğrulama',
      'Ürün kataloğu ve fiyat bilgilerinin sunulması',
      'Sipariş taleplerinin alınması, değerlendirilmesi ve işlenmesi',
      'Talep sürecinde sizinle iletişim kurulması (verdiğiniz telefon veya e-posta üzerinden)',
      'Yetkili personelin satış ve stok işlemlerini gerçekleştirmesi',
      'Hizmet güvenliği, hata giderme ve yasal yükümlülüklerin yerine getirilmesi',
    ],
  ),
  PrivacyPolicySection(
    title: '5. Hukuki dayanak',
    paragraphs: [
      'Kişisel verileriniz; sözleşmenin kurulması ve ifası (hesap ve sipariş hizmetleri), '
      'meşru menfaat (hizmet güvenliği) ve — gerektiğinde — açık rızanız (ör. kamera izni) '
      'kapsamında, 6698 sayılı Kişisel Verilerin Korunması Kanunu (KVKK) ve ilgili mevzuata '
      'uygun olarak işlenir.',
    ],
  ),
  PrivacyPolicySection(
    title: '6. Verilerin paylaşımı',
    paragraphs: [
      'Verileriniz yalnızca hizmetin sunulması için gerekli ölçüde, CavaliERP altyapısını '
      'barındıran sunucu ve teknik hizmet sağlayıcılarımızla paylaşılabilir. Bu taraflar '
      'verilerinizi yalnızca talimatlarımız doğrultusunda işler. Verileriniz reklam ağları '
      'veya veri komisyoncuları ile paylaşılmaz.',
    ],
  ),
  PrivacyPolicySection(
    title: '7. Saklama süresi',
    paragraphs: [
      'Hesap verileriniz hesabınız aktif olduğu sürece saklanır. Uygulama içinden hesabınızı '
      'sildiğinizde kişisel verileriniz makul süre içinde silinir veya anonimleştirilir; '
      'yasal saklama yükümlülükleri saklıdır.',
    ],
  ),
  PrivacyPolicySection(
    title: '8. Güvenlik',
    paragraphs: [
      'Verilerinizi korumak için HTTPS şifrelemesi, güvenli kimlik doğrulama belirteçleri '
      've erişim kontrolleri uygulanır. Hiçbir iletim veya depolama yöntemi tamamen risksiz '
      'olmasa da, endüstri standardı önlemler alınmaktadır.',
    ],
  ),
  PrivacyPolicySection(
    title: '9. Haklarınız',
    paragraphs: [
      'KVKK kapsamında kişisel verilerinizin işlenip işlenmediğini öğrenme, bilgi talep etme, '
      'düzeltilmesini veya silinmesini isteme haklarına sahipsiniz.',
      'Hesap silme: Uygulama içindeki Profil → Hesabımı Sil seçeneği ile hesabınızı '
      'kalıcı olarak silebilirsiniz.',
      'Talepleriniz için: $privacyPolicyContactEmail',
    ],
  ),
  PrivacyPolicySection(
    title: '10. Çocukların gizliliği',
    paragraphs: [
      'Uygulama 13 yaşın altındaki çocuklara yönelik değildir. Bilerek 13 yaş altından '
      'kişisel veri toplamıyoruz.',
    ],
  ),
  PrivacyPolicySection(
    title: '11. Uluslararası aktarım',
    paragraphs: [
      'Verileriniz, hizmet altyapımızın bulunduğu sunucularda (Türkiye / Avrupa) işlenebilir. '
      'Aktarım durumunda uygun koruma önlemleri uygulanır.',
    ],
  ),
  PrivacyPolicySection(
    title: '12. Politika değişiklikleri',
    paragraphs: [
      'Bu metni zaman zaman güncelleyebiliriz. Önemli değişikliklerde güncelleme tarihi '
      'revize edilir. Güncel metin uygulama içinde ve web sitemizde yayımlanır.',
    ],
  ),
  PrivacyPolicySection(
    title: '13. İletişim',
    paragraphs: [
      'Gizlilik ile ilgili sorularınız için:\n'
      '$privacyPolicyContactEmail\n'
      '$privacyPolicyWebsite',
    ],
  ),
];
