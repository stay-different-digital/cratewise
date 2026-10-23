/// CSV formula-injection guard (US-127, OWASP "CSV Injection").
///
/// Spreadsheet apps run cells starting with `= + - @ \t \r` as formulas, so
/// export prefixes those with `'`. Cells already starting with `'` get one
/// too, so [unescapeCsvCell] can strip exactly one prefix and round-trip
/// every value unchanged.
const _triggers = {'=', '+', '-', '@', '\t', '\r', "'"};

String escapeCsvCell(String cell) =>
    cell.isNotEmpty && _triggers.contains(cell[0]) ? "'$cell" : cell;

String unescapeCsvCell(String cell) =>
    cell.length > 1 && cell[0] == "'" && _triggers.contains(cell[1])
    ? cell.substring(1)
    : cell;
