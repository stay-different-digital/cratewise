// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get navSearch => 'Buscar';

  @override
  String get navCollection => 'Colección';

  @override
  String get navWishlist => 'Lista de deseos';

  @override
  String get navStatistics => 'Estadísticas';

  @override
  String get navSettings => 'Ajustes';

  @override
  String get searchHint => 'Artista, álbum o sello…';

  @override
  String get searchClearTooltip => 'Borrar búsqueda';

  @override
  String get searchEmptyTitle => 'Buscar en Discogs';

  @override
  String get searchEmptyBody =>
      'Escribe el nombre de un artista, álbum o sello para buscar.';

  @override
  String get searchNoResultsTitle => 'Sin resultados';

  @override
  String get searchNoResultsBody => 'Prueba con otro término de búsqueda.';

  @override
  String get searchSelectResultTitle => 'Selecciona un resultado';

  @override
  String get searchSelectResultBody =>
      'Toca un resultado para ver sus detalles.';

  @override
  String get searchFilterRelease => 'Release';

  @override
  String get searchFilterArtist => 'Artista';

  @override
  String get searchFilterLabel => 'Sello';

  @override
  String get searchSortTooltip => 'Ordenar';

  @override
  String get searchSortRelevance => 'Relevancia';

  @override
  String get searchSortNewestFirst => 'Más recientes primero';

  @override
  String get searchSortOldestFirst => 'Más antiguos primero';

  @override
  String get cachedResultsBanner => 'Mostrando resultados guardados';

  @override
  String get collectionSearchHint => 'Buscar en la colección…';

  @override
  String get collectionEmptyTitle => 'Tu colección está vacía';

  @override
  String get collectionOfflineNote =>
      'Tu colección se guarda en este dispositivo y funciona sin Internet.';

  @override
  String collectionNoResultsTitle(String query) {
    return 'Sin resultados para «$query»';
  }

  @override
  String get collectionNoResultsBody => 'Prueba con otro artista o título.';

  @override
  String get wishlistSearchHint => 'Buscar en la lista de deseos…';

  @override
  String get wishlistEmptyTitle => 'Tu lista de deseos está vacía';

  @override
  String get wishlistOfflineNote =>
      'Tu lista de deseos se guarda en este dispositivo y funciona sin Internet.';

  @override
  String wishlistNoResultsTitle(String query) {
    return 'Sin resultados para «$query»';
  }

  @override
  String get wishlistNoResultsBody => 'Prueba con otro artista o título.';

  @override
  String get addViaSearchHint =>
      'Usa la pestaña Buscar para encontrar y agregar lanzamientos.';

  @override
  String get calculating => 'Calculando…';

  @override
  String get settingsImportExport => 'Importar y exportar';

  @override
  String get settingsImportExportSubtitle =>
      'Mover registros hacia y desde Discogs o archivos CSV';

  @override
  String get settingsFailedActions => 'Acciones fallidas';

  @override
  String get settingsFailedActionsSubtitle =>
      'Ver acciones pendientes de reintento';

  @override
  String get settingsThumbnailCache => 'Caché de miniaturas';

  @override
  String get settingsLocalData => 'Datos locales';

  @override
  String get settingsClearCollection => 'Borrar colección';

  @override
  String get settingsClearWishlist => 'Borrar lista de deseos';

  @override
  String get settingsTourRestart => 'Reiniciar recorrido';

  @override
  String get settingsLanguage => 'Idioma';

  @override
  String get settingsLanguageSystem => 'Configuración del sistema';

  @override
  String get actionCancel => 'Cancelar';

  @override
  String get actionClear => 'Borrar';

  @override
  String get barcodeEnterManually => 'Introducir código de barras manualmente…';

  @override
  String get barcodeScanButton => 'Escanear código de barras';

  @override
  String get barcodeSearchButton => 'Buscar';

  @override
  String get barcodeScanPrompt =>
      'Toca «Escanear código de barras» para abrir la cámara';

  @override
  String get barcodePermissionDenied => 'Permiso de cámara denegado';

  @override
  String get barcodePermissionDeniedHint =>
      'Permite el acceso a la cámara en Ajustes para escanear códigos de barras.';

  @override
  String get barcodeScanOrEnter => 'Escanear o introducir un código de barras';

  @override
  String get barcodeScanOrEnterHint =>
      'Apunta la cámara a un código de barras o escríbelo arriba.';

  @override
  String get barcodeNoReleases => 'No se encontraron lanzamientos';

  @override
  String get barcodeNoReleasesHint =>
      'Ningún lanzamiento de Discogs coincide con este código de barras. Prueba otro código o verifica el número.';

  @override
  String get barcodeNoToken => 'Cuenta de Discogs no conectada';

  @override
  String get barcodeNoTokenHint =>
      'Ve a Ajustes para conectar tu cuenta de Discogs.';

  @override
  String get barcodeRateLimited => 'Demasiadas solicitudes';

  @override
  String get barcodeRateLimitedHint =>
      'Discogs está limitando las solicitudes ahora. Espera un momento e inténtalo de nuevo.';

  @override
  String get barcodeSomethingWrong => 'Algo salió mal';

  @override
  String get barcodeSomethingWrongHint =>
      'No se pudo contactar con Discogs. Se necesita conexión a Internet para buscar por código de barras.';

  @override
  String get barcodeValidationNotBarcode =>
      'Esto no parece un código de barras';

  @override
  String get barcodeValidationWrongLength =>
      'El código de barras debe tener 8, 12 o 13 dígitos';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageGerman => 'Deutsch';

  @override
  String get languageFrench => 'Français';

  @override
  String get languageSpanish => 'Español';

  @override
  String get languageDutch => 'Nederlands';
}
