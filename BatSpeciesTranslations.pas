unit BatSpeciesTranslations;

interface

uses
  System.SysUtils, System.Generics.Collections, System.Generics.Defaults;

type
  TDisplayLanguage = (dlDutch, dlEnglish, dlGerman, dlFrench, dlSpanish);

{ Translates a bat species common name (as produced by bat_ident, in English)
  into the requested display language. Falls back to the original English
  name when the species isn't in the dictionary, so an unrecognised name
  never disappears from the UI. }
function TranslateSpeciesName(const AEnglishName: string; ALanguage: TDisplayLanguage): string;

implementation

type
  TSpeciesNames = record
    NL, DE, FR, ES: string;
  end;

var
  Dict: TDictionary<string, TSpeciesNames>;

procedure Add(const AEnglish, ANL, ADE, AFR, AES: string);
var
  Names: TSpeciesNames;
begin
  Names.NL := ANL;
  Names.DE := ADE;
  Names.FR := AFR;
  Names.ES := AES;
  Dict.AddOrSetValue(AEnglish, Names);
end;

procedure BuildDictionary;
begin
  Dict := TDictionary<string, TSpeciesNames>.Create(TIStringComparer.OrdinalIgnoreCase);
  // Central European species set (matches the Bavaria/EU classifier area).
  Add('Common Pipistrelle', 'Gewone dwergvleermuis', 'Zwergfledermaus', 'Pipistrelle commune', 'Murciélago común');
  Add('Soprano Pipistrelle', 'Kleine dwergvleermuis', 'Mückenfledermaus', 'Pipistrelle soprane', 'Murciélago de Cabrera');
  Add('Nathusius Pipistrelle', 'Ruige dwergvleermuis', 'Rauhautfledermaus', 'Pipistrelle de Nathusius', 'Murciélago de Nathusius');
  Add('Kuhls Pipistrelle', 'Kuhls dwergvleermuis', 'Weißrandfledermaus', 'Pipistrelle de Kuhl', 'Murciélago de borde claro');
  Add('Serotine', 'Laatvlieger', 'Breitflügelfledermaus', 'Sérotine commune', 'Murciélago hortelano');
  Add('Noctule', 'Rosse vleermuis', 'Großer Abendsegler', 'Noctule commune', 'Nóctulo mediano');
  Add('Leislers Bat', 'Bosvleermuis', 'Kleiner Abendsegler', 'Noctule de Leisler', 'Nóctulo pequeño');
  Add('Greater Noctule', 'Reuzenvleermuis', 'Riesenabendsegler', 'Grande Noctule', 'Nóctulo grande');
  Add('Daubentons Bat', 'Watervleermuis', 'Wasserfledermaus', 'Murin de Daubenton', 'Murciélago ribereño');
  Add('Natterers Bat', 'Franjestaart', 'Fransenfledermaus', 'Murin de Natterer', 'Murciélago de Natterer');
  Add('Greater Mouse-eared Bat', 'Vale vleermuis', 'Großes Mausohr', 'Grand Murin', 'Murciélago ratonero grande');
  Add('Whiskered Bat', 'Baardvleermuis', 'Kleine Bartfledermaus', 'Murin à moustaches', 'Murciélago bigotudo');
  Add('Brandts Bat', 'Brandts vleermuis', 'Große Bartfledermaus', 'Murin de Brandt', 'Murciélago de Brandt');
  Add('Bechsteins Bat', 'Bechsteins vleermuis', 'Bechsteinfledermaus', 'Murin de Bechstein', 'Murciélago de Bechstein');
  Add('Pond Bat', 'Meervleermuis', 'Teichfledermaus', 'Murin des marais', 'Murciélago lagunero');
  Add('Geoffroys Bat', 'Ingekorven vleermuis', 'Wimperfledermaus', 'Murin à oreilles échancrées', 'Murciélago de Geoffroy');
  Add('Alcathoe Bat', 'Alcathoe-vleermuis', 'Nymphenfledermaus', 'Murin d''Alcathoe', 'Murciélago de Alcathoe');
  Add('Brown Long-eared Bat', 'Gewone grootoorvleermuis', 'Braunes Langohr', 'Oreillard roux', 'Orejudo dorado');
  Add('Grey Long-eared Bat', 'Grijze grootoorvleermuis', 'Graues Langohr', 'Oreillard gris', 'Orejudo gris');
  Add('Barbastelle', 'Mopsvleermuis', 'Mopsfledermaus', 'Barbastelle d''Europe', 'Barbastela');
  Add('Lesser Horseshoe Bat', 'Kleine hoefijzerneus', 'Kleine Hufeisennase', 'Petit rhinolophe', 'Murciélago pequeño de herradura');
  Add('Greater Horseshoe Bat', 'Grote hoefijzerneus', 'Große Hufeisennase', 'Grand rhinolophe', 'Murciélago grande de herradura');
  Add('Parti-coloured Bat', 'Tweekleurige vleermuis', 'Zweifarbfledermaus', 'Sérotine bicolore', 'Murciélago bicolor');
  Add('European Free-tailed Bat', 'Bulvleermuis', 'Europäische Bulldoggfledermaus', 'Molosse de Cestoni', 'Murciélago rabudo');
end;

function TranslateSpeciesName(const AEnglishName: string; ALanguage: TDisplayLanguage): string;
var
  Names: TSpeciesNames;
begin
  Result := AEnglishName;
  if ALanguage = dlEnglish then
    Exit();
  if not Dict.TryGetValue(Trim(AEnglishName), Names) then
    Exit();
  case ALanguage of
    dlDutch: Result := Names.NL;
    dlGerman: Result := Names.DE;
    dlFrench: Result := Names.FR;
    dlSpanish: Result := Names.ES;
  end;
end;

initialization
  BuildDictionary();

finalization
  Dict.Free();

end.
