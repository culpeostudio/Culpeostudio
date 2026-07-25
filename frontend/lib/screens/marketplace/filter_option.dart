// Eine Auswahlmoeglichkeit in den Marktplatz-Filterleisten.

class FilterOption {
  final String label;
  final String value;

  const FilterOption(this.label, this.value);
}

// M12: Vollstaendiger Detail-Dialog, der die Such-Treffer-Vorschau und –
// optional – die reichhaltigen /marktplatz/model/:id-Werte zeigt. Layout ist
// Identisch mit dem Kartenpanel, damit der Uebergang fließend wirkt.
