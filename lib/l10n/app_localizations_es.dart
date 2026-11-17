// ignore_for_file: deprecated_member_use

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
  String get filterButtonTooltip => 'Filtrar';

  @override
  String get searchFilterSheetTitle => 'Filtros de búsqueda';

  @override
  String get searchScopeTitle => 'Buscar en';

  @override
  String get sortTitle => 'Ordenar';

  @override
  String get filtersClearAll => 'Borrar todo';

  @override
  String get filtersApply => 'Aplicar';

  @override
  String get searchSortRelevance => 'Relevancia';

  @override
  String get searchSortNewestFirst => 'Más recientes primero';

  @override
  String get searchSortOldestFirst => 'Más antiguos primero';

  @override
  String get searchVinylOnly => 'Solo vinilo';

  @override
  String get searchNoResultsVinylOnlyBody =>
      'Ningún vinilo coincide con esta búsqueda.';

  @override
  String get searchShowAllFormats => 'Mostrar todos los formatos';

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
  String get settingsAutoSync => 'Sincronizar automáticamente con Discogs';

  @override
  String get settingsAutoSyncSubtitle =>
      'Los discos que añadas a tu colección o lista de deseos se envían de inmediato a tu cuenta de Discogs.';

  @override
  String get settingsAutoSyncNeedsAccount =>
      'Conecta tu cuenta de Discogs arriba para usar esta opción.';

  @override
  String get settingsAutoSyncTurnedOff =>
      'Desactivado porque Discogs rechazó tu token. Vuelve a conectar y actívalo de nuevo.';

  @override
  String settingsAutoSyncConfirmTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '¿Enviar $count discos a Discogs?',
      one: '¿Enviar 1 disco a Discogs?',
    );
    return '$_temp0';
  }

  @override
  String get settingsAutoSyncConfirmBody =>
      'Los discos de tu colección o lista de deseos que aún no están en Discogs se añadirán a tu cuenta de Discogs. Los que ya están no se añaden dos veces.';

  @override
  String get settingsAutoSyncConfirmAction => 'Activar';

  @override
  String get settingsAutoSyncRunning => 'Sincronizando con Discogs…';

  @override
  String settingsAutoSyncLastRun(String time, int sent, int added) {
    return 'Última sincronización $time: $sent enviados, $added añadidos.';
  }

  @override
  String settingsAutoSyncLastRunProblem(String time, String problem) {
    return 'Última sincronización $time: $problem Se volverá a intentar.';
  }

  @override
  String get settingsAutoSyncProblemNoConnection => 'Sin conexión.';

  @override
  String get settingsAutoSyncProblemDiscogsBusy => 'Discogs estaba ocupado.';

  @override
  String get settingsAutoSyncProblemFailed => 'Algo salió mal.';

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
