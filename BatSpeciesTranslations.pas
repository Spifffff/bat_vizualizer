unit BatSpeciesTranslations;



interface



uses
  System.SysUtils, System.Generics.Collections;

type
  TDisplayLanguage = (dlDutch, dlEnglish, dlGerman, dlFrench, dlSpanish);

  { Translates a bat species common name (as produced by bat_ident, in English)
    into the requested display language and appends the scientific name, e.g.
    "Gewone dwergvleermuis (Pipistrellus pipistrellus)". Falls back to the
    original English name (with no scientific name appended) when the species
    isn't in the dictionary, so an unrecognised name never disappears from the
    UI.

    The species list and English common names are sourced from the label files
    bundled with every area/model combination BattyBirdNET-Analyzer ships
    (github.com/rdz-oss/BattyBirdNET-Analyzer, checkpoints/bats/v1.0 and
    labels/bats), since bat_ident.py's default --locale is "en" and this app
    never passes --locale, so these are the exact strings that end up in the
    "Common name" column of a .bat.results.csv. Some classifiers can't always
    distinguish two similar-sounding species and emit a merged name for both
    (e.g. "Daubentons or Whiskered bat") -- those merged names are kept as
    separate dictionary entries alongside the single-species ones, because
    which one appears depends on which --area was used to analyze the file. }
function TranslateSpeciesName(const AEnglishName: string; ALanguage: TDisplayLanguage): string;



implementation



type
  TSpeciesInfo = record
    Sci, NL, DE, FR, ES: string;
  end;

var
  Dict: TDictionary<string, TSpeciesInfo>;



procedure Add(const AEnglish, ASci, ANL, ADE, AFR, AES: string);
var
  Info: TSpeciesInfo;
begin
  Info.Sci := ASci;
  Info.NL := ANL;
  Info.DE := ADE;
  Info.FR := AFR;
  Info.ES := AES;
  { Keys are stored lower-cased so lookups can be case-insensitive without
    depending on a specific IEqualityComparer<string> being available. }
  Dict.AddOrSetValue(LowerCase(AEnglish), Info);
end;



procedure BuildDictionary;
begin
  Dict := TDictionary<string, TSpeciesInfo>.Create();

  // ---- Europe (Bavaria / EU / UK / Sweden / Scotland / South-Wales areas) ----
  Add('Western barbastelle', 'Barbastella barbastellus', 'Mopsvleermuis', 'Mopsfledermaus', 'Barbastelle d''Europe', 'Barbastela');
  Add('Barbastelle', 'Barbastella barbastellus', 'Mopsvleermuis', 'Mopsfledermaus', 'Barbastelle d''Europe', 'Barbastela');
  Add('Northern bat', 'Eptesicus nilssonii', 'Noordse vleermuis', 'Nordfledermaus', 'Sérotine de Nilsson', 'Murciélago nórdico');
  Add('Serotine bat', 'Eptesicus serotinus', 'Laatvlieger', 'Breitflügelfledermaus', 'Sérotine commune', 'Murciélago hortelano');
  Add('Serotine', 'Eptesicus serotinus', 'Laatvlieger', 'Breitflügelfledermaus', 'Sérotine commune', 'Murciélago hortelano');
  Add('Savis pipistrelle', 'Hypsugo savii', 'Savi''s dwergvleermuis', 'Alpenfledermaus', 'Vespère de Savi', 'Murciélago montañero');
  Add('Common bent-wing bat', 'Miniopterus schreibersii', 'Schreibers'' vleermuis', 'Langflügelfledermaus', 'Minioptère de Schreibers', 'Murciélago de cueva');
  Add('Alcathoe bat', 'Myotis alcathoe', 'Alcathoe-vleermuis', 'Nymphenfledermaus', 'Murin d''Alcathoe', 'Murciélago de Alcathoe');
  Add('Bechsteins bat', 'Myotis bechsteinii', 'Bechsteins vleermuis', 'Bechsteinfledermaus', 'Murin de Bechstein', 'Murciélago de Bechstein');
  Add('Brandt bat', 'Myotis brandtii', 'Brandts vleermuis', 'Große Bartfledermaus', 'Murin de Brandt', 'Murciélago de Brandt');
  Add('Long-fingered bat', 'Myotis capaccinii', 'Vingervleermuis', 'Langfingerfledermaus', 'Murin de Capaccini', 'Murciélago ratonero patudo');
  Add('Pond bat', 'Myotis dasycneme', 'Meervleermuis', 'Teichfledermaus', 'Murin des marais', 'Murciélago lagunero');
  Add('Daubentons or Whiskered bat', 'Myotis daubentonii / Myotis mystacinus', 'Watervleermuis of baardvleermuis', 'Wasser- oder Bartfledermaus',
    'Murin de Daubenton ou à moustaches', 'Murciélago ribereño o bigotudo');
  Add('Daubentons bat', 'Myotis daubentonii', 'Watervleermuis', 'Wasserfledermaus', 'Murin de Daubenton', 'Murciélago ribereño');
  Add('Geoffroys bat', 'Myotis emarginatus', 'Ingekorven vleermuis', 'Wimperfledermaus', 'Murin à oreilles échancrées', 'Murciélago de Geoffroy');
  Add('Greater mouse-eared bat', 'Myotis myotis', 'Vale vleermuis', 'Großes Mausohr', 'Grand Murin', 'Murciélago ratonero grande');
  Add('Whiskered or Daubentons bat', 'Myotis mystacinus / Myotis daubentonii', 'Baardvleermuis of watervleermuis', 'Bart- oder Wasserfledermaus',
    'Murin à moustaches ou de Daubenton', 'Murciélago bigotudo o ribereño');
  Add('Whiskered bat', 'Myotis mystacinus', 'Baardvleermuis', 'Kleine Bartfledermaus', 'Murin à moustaches', 'Murciélago bigotudo');
  Add('Natterers bat', 'Myotis nattereri', 'Franjestaart', 'Fransenfledermaus', 'Murin de Natterer', 'Murciélago de Natterer');
  Add('Greater noctule bat', 'Nyctalus lasiopterus', 'Reuzenvleermuis', 'Riesenabendsegler', 'Grande Noctule', 'Nóctulo grande');
  Add('Lesser noctule', 'Nyctalus leisleri', 'Bosvleermuis', 'Kleiner Abendsegler', 'Noctule de Leisler', 'Nóctulo pequeño');
  Add('Common noctule', 'Nyctalus noctula', 'Rosse vleermuis', 'Großer Abendsegler', 'Noctule commune', 'Nóctulo mediano');
  Add('Noctule', 'Nyctalus noctula', 'Rosse vleermuis', 'Großer Abendsegler', 'Noctule commune', 'Nóctulo mediano');
  Add('Kuhls or Nathusius pipistrelle', 'Pipistrellus kuhlii / Pipistrellus nathusii', 'Kuhls of ruige dwergvleermuis', 'Weißrand- oder Rauhautfledermaus',
    'Pipistrelle de Kuhl ou de Nathusius', 'Murciélago de borde claro o de Nathusius');
  Add('Kuhls pipistrelle', 'Pipistrellus kuhlii', 'Kuhls dwergvleermuis', 'Weißrandfledermaus', 'Pipistrelle de Kuhl', 'Murciélago de borde claro');
  Add('Madeira pipistrelle', 'Pipistrellus maderensis', 'Madeira-dwergvleermuis', 'Madeira-Fledermaus', 'Pipistrelle de Madère', 'Murciélago de Madeira');
  Add('Nathusius or Kuhls pipistrelle', 'Pipistrellus nathusii / Pipistrellus kuhlii', 'Ruige of Kuhls dwergvleermuis', 'Rauhaut- oder Weißrandfledermaus',
    'Pipistrelle de Nathusius ou de Kuhl', 'Murciélago de Nathusius o de borde claro');
  Add('Nathusius pipistrelle', 'Pipistrellus nathusii', 'Ruige dwergvleermuis', 'Rauhautfledermaus', 'Pipistrelle de Nathusius', 'Murciélago de Nathusius');
  Add('Common pipistrelle', 'Pipistrellus pipistrellus', 'Gewone dwergvleermuis', 'Zwergfledermaus', 'Pipistrelle commune', 'Murciélago común');
  Add('Soprano pipistrelle', 'Pipistrellus pygmaeus', 'Kleine dwergvleermuis', 'Mückenfledermaus', 'Pipistrelle soprane', 'Murciélago de Cabrera');
  Add('Long eared bat', 'Plecotus spec.', 'Grootoorvleermuis', 'Langohr', 'Oreillard', 'Orejudo');
  Add('Brown or Grey long eared bat', 'Plecotus auritus / Plecotus austriacus', 'Gewone of grijze grootoorvleermuis', 'Braunes oder Graues Langohr',
    'Oreillard roux ou gris', 'Orejudo dorado o gris');
  Add('Brown long-eared bat', 'Plecotus auritus', 'Gewone grootoorvleermuis', 'Braunes Langohr', 'Oreillard roux', 'Orejudo dorado');
  Add('Grey long-eared bat', 'Plecotus austriacus', 'Grijze grootoorvleermuis', 'Graues Langohr', 'Oreillard gris', 'Orejudo gris');
  Add('Blasius horseshoe bat', 'Rhinolophus blasii', 'Blasius'' hoefijzerneus', 'Blasius-Hufeisennase', 'Rhinolophe de Blasius',
    'Murciélago mediterráneo de herradura');
  Add('Greater horseshoe bat', 'Rhinolophus ferrumequinum', 'Grote hoefijzerneus', 'Große Hufeisennase', 'Grand rhinolophe', 'Murciélago grande de herradura');
  Add('Lesser horseshoe bat', 'Rhinolophus hipposideros', 'Kleine hoefijzerneus', 'Kleine Hufeisennase', 'Petit rhinolophe', 'Murciélago pequeño de herradura');
  Add('Lesser horseshoe bat social', 'Rhinolophus hipposideros', 'Kleine hoefijzerneus (sociaal)', 'Kleine Hufeisennase (sozial)',
    'Petit rhinolophe (cri social)', 'Murciélago pequeño de herradura (social)');
  Add('European free-tailed bat', 'Tadarida teniotis', 'Bulvleermuis', 'Europäische Bulldoggfledermaus', 'Molosse de Cestoni', 'Murciélago rabudo');
  Add('Parti-coloured bat', 'Vespertilio murinus', 'Tweekleurige vleermuis', 'Zweifarbfledermaus', 'Sérotine bicolore', 'Murciélago bicolor');

  // ---- North America (USA / USA-EAST / USA-WEST areas) ----
  // These species have no established Dutch/German/French/Spanish vernacular
  // name (they don't occur in Europe), so the translations below are
  // descriptive calques of the English name, following standard field-guide
  // practice for non-native species -- not official/authoritative names.
  Add('Pallid bat', 'Antrozous pallidus', 'Bleke vleermuis', 'Wüstenfledermaus', 'Antrozous pâle', 'Murciélago pálido');
  Add('Townsends big-eared bat', 'Corynorhinus townsendii', 'Townsends grootoorvleermuis', 'Townsend-Langohr', 'Oreillard de Townsend',
    'Murciélago orejudo de Townsend');
  Add('Big brown bat', 'Eptesicus fuscus', 'Grote bruine vleermuis', 'Große Braunfledermaus', 'Sérotine brune', 'Murciélago pardo grande');
  Add('Spotted bat', 'Euderma maculatum', 'Gevlekte vleermuis', 'Fleckfledermaus', 'Chauve-souris tachetée', 'Murciélago manchado');
  Add('Greater mastiff bat', 'Eumops perotis', 'Grote mastiefvleermuis', 'Große Bulldoggfledermaus', 'Molosse mastiff géant', 'Murciélago mastín mayor');
  Add('Allens big-eared bat', 'Idionycteris phyllotis', 'Allens grootoorvleermuis', 'Allen-Langohr', 'Oreillard d''Allen', 'Murciélago orejudo de Allen');
  Add('Silver-haired bat', 'Lasionycteris noctivagans', 'Zilverharige vleermuis', 'Silberhaarfledermaus', 'Chauve-souris argentée', 'Murciélago plateado');
  Add('Western red bat', 'Lasiurus blossevillii', 'Westelijke rode vleermuis', 'Westliche Rotfledermaus', 'Chauve-souris rousse de l''Ouest',
    'Murciélago rojo occidental');
  Add('Eastern red bat', 'Lasiurus borealis', 'Oostelijke rode vleermuis', 'Östliche Rotfledermaus', 'Chauve-souris rousse de l''Est',
    'Murciélago rojo oriental');
  Add('Hoary bat', 'Lasiurus cinereus', 'Rijpvleermuis', 'Bereifte Fledermaus', 'Chauve-souris cendrée', 'Murciélago escarchado');
  Add('Northern yellow bat', 'Lasiurus intermedius', 'Noordelijke gele vleermuis', 'Nördliche Gelbfledermaus', 'Chauve-souris jaune du Nord',
    'Murciélago amarillo norteño');
  Add('Seminole bat', 'Lasiurus seminolus', 'Seminole-vleermuis', 'Seminolenfledermaus', 'Chauve-souris séminole', 'Murciélago semínola');
  Add('Western yellow bat', 'Lasiurus xanthinus', 'Westelijke gele vleermuis', 'Westliche Gelbfledermaus', 'Chauve-souris jaune de l''Ouest',
    'Murciélago amarillo occidental');
  Add('Southeastern myotis', 'Myotis austroriparius', 'Zuidoostelijke vale vleermuis', 'Südost-Mausohr', 'Murin du Sud-Est', 'Murciélago ratonero del sudeste');
  Add('California bat', 'Myotis californicus', 'Californische vleermuis', 'Kalifornische Fledermaus', 'Murin de Californie', 'Murciélago californiano');
  Add('Western small-footed myotis', 'Myotis ciliolabrum', 'Westelijke kleinvoetvleermuis', 'Westliche Kleinfuß-Fledermaus', 'Murin à petits pieds de l''Ouest',
    'Murciélago patiblanco occidental');
  Add('Western long-eared bat', 'Myotis evotis', 'Westelijke langoorvleermuis', 'Westliches Langohr-Mausohr', 'Murin à longues oreilles de l''Ouest',
    'Murciélago orejudo occidental');
  Add('Gray bat', 'Myotis grisescens', 'Grijze vale vleermuis', 'Graufledermaus', 'Murin gris', 'Murciélago gris');
  Add('Eastern small-footed bat', 'Myotis leibii', 'Oostelijke kleinvoetvleermuis', 'Östliche Kleinfuß-Fledermaus', 'Murin à petits pieds de l''Est',
    'Murciélago patiblanco oriental');
  Add('Little brown bat', 'Myotis lucifugus', 'Kleine bruine vleermuis', 'Kleine Braunfledermaus', 'Petite chauve-souris brune', 'Murciélago pardo pequeño');
  Add('Northern long-eared bat', 'Myotis septentrionalis', 'Noordelijke langoorvleermuis', 'Nördliches Langohr-Mausohr', 'Murin nordique',
    'Murciélago orejudo norteño');
  Add('Indiana bat', 'Myotis sodalis', 'Indiana-vleermuis', 'Indiana-Fledermaus', 'Murin d''Indiana', 'Murciélago de Indiana');
  Add('Fringed bat', 'Myotis thysanodes', 'Amerikaanse franjestaart', 'Amerikanische Fransenfledermaus', 'Murin à franges', 'Murciélago flecudo');
  Add('Cave bat', 'Myotis velifer', 'Grotvleermuis', 'Höhlenfledermaus', 'Murin des grottes', 'Murciélago cavernícola');
  Add('Long-legged bat', 'Myotis volans', 'Langpotige vleermuis', 'Langbein-Fledermaus', 'Murin à longues pattes', 'Murciélago patilargo');
  Add('Yuma bat', 'Myotis yumanensis', 'Yuma-vleermuis', 'Yuma-Fledermaus', 'Murin de Yuma', 'Murciélago de Yuma');
  Add('Evening bat', 'Nycticeius humeralis', 'Avondvleermuis', 'Abendfledermaus', 'Chauve-souris du soir', 'Murciélago crepuscular');
  Add('Pocketed free-tailed bat', 'Nyctinomops femorosaccus', 'Gezakte vrijstaartvleermuis', 'Taschen-Bulldoggfledermaus', 'Molosse à poche',
    'Murciélago cola de ratón bolsillero');
  Add('Big free-tailed bat', 'Nyctinomops macrotis', 'Grote vrijstaartvleermuis', 'Große Bulldoggfledermaus (Nyctinomops)', 'Grand molosse à queue libre',
    'Murciélago cola de ratón grande');
  Add('Canyon bat', 'Parastrellus hesperus', 'Ravijnvleermuis', 'Canyonfledermaus', 'Pipistrelle des canyons', 'Murciélago del cañón');
  Add('Tricolored bat', 'Perimyotis subflavus', 'Driekleurige vleermuis', 'Dreifarbenfledermaus', 'Pipistrelle tricolore', 'Murciélago tricolor');
  Add('Brazilian free-tailed bat', 'Tadarida brasiliensis', 'Braziliaanse vrijstaartvleermuis', 'Brasilianische Bulldoggfledermaus', 'Molosse du Brésil',
    'Murciélago guanero');
end;



function TranslateSpeciesName(const AEnglishName: string; ALanguage: TDisplayLanguage): string;
var
  Info: TSpeciesInfo;
  CommonName: string;
begin
  if not Dict.TryGetValue(LowerCase(Trim(AEnglishName)), Info) then begin
    Result := AEnglishName;
    Exit();
  end;
  case ALanguage of
    dlDutch:
      CommonName := Info.NL;
    dlGerman:
      CommonName := Info.DE;
    dlFrench:
      CommonName := Info.FR;
    dlSpanish:
      CommonName := Info.ES;
  else
    CommonName := AEnglishName;
  end;
  Result := CommonName + ' (' + Info.Sci + ')';
end;



initialization



BuildDictionary();



finalization



Dict.Free();



end.
