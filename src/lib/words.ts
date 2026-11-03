export interface WordEntry {
  word: string;
  hint: string;
}

const WORDS: WordEntry[] = [
  { word: 'KALEIDOSKOP', hint: 'Optisches Spielzeug mit bunten Glasstücken' },
  { word: 'PARALLELOGRAMM', hint: 'Viereck mit zwei Paaren paralleler Seiten' },
  { word: 'ARCHITEKTUR', hint: 'Lehre vom Entwerfen und Bauen von Gebäuden' },
  { word: 'SPRACHWISSENSCHAFT', hint: 'Untersucht Sprache und ihre Entwicklung' },
  { word: 'PHOTOSYNTHESE', hint: 'Pflanzen wandeln Licht in Energie um' },
  { word: 'KRISTALLKUGEL', hint: 'Wahrsagerinnen blicken hinein' },
  { word: 'SCHWERELOSIGKEIT', hint: 'Zustand im Weltall, in dem man schwebt' },
  { word: 'MIKROSKOP', hint: 'Macht winzige Dinge sichtbar' },
  { word: 'JAHRHUNDERT', hint: 'Hundert Jahre am Stück' },
  { word: 'EINBAHNSTRASSE', hint: 'Verkehr fließt nur in eine Richtung' },
  { word: 'ORCHESTER', hint: 'Viele Musiker spielen gemeinsam' },
  { word: 'MEERESSCHILDKRÖTE', hint: 'Legt ihre Eier im Sand am Strand' },
  { word: 'MEDAILLON', hint: 'Kleiner Schmuckanhänger zum Öffnen' },
  { word: 'TRAUMFÄNGER', hint: 'Hängt über dem Bett und soll schlechte Träume abhalten' },
  { word: 'LABYRINTH', hint: 'Verwinkelter Irrgarten' },
  { word: 'BRÜCKENPFEILER', hint: 'Trägt die Last einer Brücke' },
  { word: 'DOMPTEUR', hint: 'Bändigt wilde Tiere in der Manege' },
  { word: 'ENTSCHEIDUNG', hint: 'Wahl zwischen mehreren Möglichkeiten' },
  { word: 'VERHANDLUNG', hint: 'Gespräch, um sich zu einigen' },
  { word: 'FEUERWERK', hint: 'Leuchtet am Silvesterhimmel' },
  { word: 'GEWITTERWOLKE', hint: 'Dunkle Wolke, die Blitze bringt' },
  { word: 'MITTELALTER', hint: 'Epoche mit Rittern und Burgen' },
  { word: 'NACHRICHTENSPRECHER', hint: 'Liest die Tagesschau vor' },
  { word: 'GLÜHWÜRMCHEN', hint: 'Leuchtet nachts im Sommer im Gras' },
  { word: 'SCHATZKARTE', hint: 'Zeigt den Weg zur vergrabenen Beute' },
  { word: 'ZWIEBELSUPPE', hint: 'Suppe mit Röstzwiebeln und Käse überbacken' },
  { word: 'ÜBERRASCHUNG', hint: 'Etwas, mit dem niemand gerechnet hat' },
  { word: 'ELEKTRIZITÄT', hint: 'Unsichtbare Kraft, die Lampen zum Leuchten bringt' },
  { word: 'BIOLOGIE', hint: 'Lehre von den Lebewesen' },
  { word: 'KATHEDRALE', hint: 'Große Kirche mit hohen Türmen' },
  { word: 'ARCHÄOLOGE', hint: 'Gräbt alte Funde aus der Erde aus' },
  { word: 'TINTENFISCH', hint: 'Meerestier mit acht Armen und zwei Fangarmen' },
  { word: 'PERSPEKTIVE', hint: 'Der Blickwinkel, aus dem man etwas betrachtet' },
  { word: 'PFEFFERMINZE', hint: 'Kräuter, die im Tee für Frische sorgen' },
  { word: 'MAGNETISMUS', hint: 'Kraft, die Eisen anzieht' },
  { word: 'LABORATORIUM', hint: 'Raum für Experimente in der Forschung' },
  { word: 'KORALLENRIFF', hint: 'Bunte Unterwasserlandschaft aus Kalk' },
  { word: 'TELESKOP', hint: 'Holt die Sterne ganz nah heran' },
  { word: 'PANORAMA', hint: 'Weiter Rundblick über eine Landschaft' },
  { word: 'KALENDERBLATT', hint: 'Zeigt einen Tag des Monats' },
  { word: 'FLUGZEUGTRÄGER', hint: 'Riesiges Kriegsschiff mit Landebahn' },
  { word: 'KONTINENTALPLATTE', hint: 'Riesige Gesteinsschicht, die sich langsam bewegt' },
  { word: 'WIDERSPRUCH', hint: 'Zwei Aussagen, die sich gegenseitig ausschließen' },
  { word: 'GEHEIMNISVOLL', hint: 'Voller Rätsel und unbekannter Hintergründe' },
  { word: 'SCHNEEKETTE', hint: 'Sorgt auf vereister Straße für Halt' },
];

export function getRandomWord(): WordEntry {
  return WORDS[Math.floor(Math.random() * WORDS.length)];
}
