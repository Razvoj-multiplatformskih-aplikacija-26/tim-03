# tim-03
# Centar za brigu o kućnim ljubimcima
Centar za brigu o kućnim ljubimcima - Aplikacija koja pruža usluge za kućne ljubimce: čuvanje (pansion), kupanje i šišanje i veterinarski pregled u centru, kao i šetnju – šetač dolazi na adresu vlasnika, preuzima ljubimca i vraća ga posle šetnje. Vlasnici preko mobilne aplikacije vode profile svojih ljubimaca, zakazuju usluge i prate boravak ljubimca u centru, a osoblje u backoffice aplikaciji upravlja kapacitetima, rasporedom i tokom svake usluge.

## Tim

| Ime i prezime | Broj indeksa | Grupa | GitHub nalog |
|---|---|---|---|
| Matej Lalić | SI 113/24 | 413 | [LalicMatej](https://github.com/LalicMatej) |
| Mladen Đošić | SI 91/24 | 413 | [mldndjsc](https://github.com/mldndjsc) |

## Zahtevi za temu

1.Uloge

Sistem ima četiri uloge: vlasnik (upravlja svojim ljubimcima i nalozima), negovatelj/veterinar (vidi svoj raspored, prima ljubimce, menja stanje naloga i piše dnevnik), šetač (u mobilnoj aplikaciji vidi samo svoje dodeljene šetnje, preuzima i vraća ljubimca na adresi) i menadžer (upravlja uslugama, cenama, smeštajem i osobljem i može da odbije ili otkaže bilo koji nalog). Vlasnik vidi samo svoje podatke, a osoblje vidi sve naloge centra.

2.Stanja

Nalog za uslugu prolazi kroz stanja: na čekanju → potvrđen → u toku (ljubimac primljen u centar ili preuzet od šetača) → spreman za preuzimanje (kod šetnje: vraćen vlasniku) → završen, uz bočna stanja odbijen (osoblje ne prihvata nalog) i otkazan (vlasnik ili centar otkazuje pre prijema).

3.Pravila

Smeštaj ne može biti popunjen preko kapaciteta u istom periodu, jedan negovatelj ili veterinar ne može imati dva termina koja se preklapaju, šetač ne može imati dve šetnje koje se preklapaju, računajući i vreme potrebno da stigne sa jedne adrese na drugu, isti ljubimac ne može imati dva naloga koja se vremenski preklapaju.

4.Rad bez mreže

Vlasnik bez signala može da otkaže nalog i da izmeni profil ljubimca (napomene o ishrani, alergijama, fotografija); izmene se čuvaju lokalno i šalju serveru kada se veza vrati, uz razrešavanje sukoba (npr. otkazivanje odbijeno jer je ljubimac u međuvremenu primljen). Pregled zakazanih naloga i kartona vakcinacije dostupan je i bez mreže. Šetač u parku bez signala označava preuzimanje i vraćanje ljubimca, a ruta se beleži lokalno i šalje kada se veza vrati.

5.Posao za osoblje

Osoblje radi sa dnevnim i nedeljnim rasporedom svih termina po članu osoblja (uključujući raspodelu šetnji šetačima po delovima grada) i sa mapom smeštaja (zauzetost svih boksova po danima, slično rezervaciji hotelskih soba), uz filtriranje, prevlačenje naloga i potvrdu zahteva na čekanju.

6.Javni sadržaj

Bez prijave su dostupni: ponuda usluga sa cenovnikom, radno vreme, slobodni kapaciteti pansiona po veličini ljubimca za izabrani period, profili osoblja i saveti za negu ljubimaca.

## Delovi sistema

| Deo | Korisnici | Tehnologija | Platforme |
|---|---|---|---|
| Mobilna aplikacija | vlasnici ljubimaca, šetači | Flutter | Android, iOS |
| Backoffice | negovatelji, veterinari, menadžeri | Flutter | Windows, veb |
| Javni veb | svi posetioci | Jaspr | pregledač |
| Server | ostali delovi sistema | Relic, PostgreSQL | Linux, Windows |
| Domenski paket | svi delovi sistema | Dart | sve |

## Pravila

Sva pravila su u `packages/domain/lib/src` i vraćaju uspeh ili grešku kao tip. Tekst poruke bira klijent, na jednom mestu: `packages/ui/lib/src/text/domain_errors.dart`. Brojevi u porukama dolaze iz konstanti domena, pa izmena konstante menja i poruku. Testovi su u `packages/domain/test`, grupisani po pravilu.

| Pravilo | Šta kaže | Vrednost | U domenu | Gde se proverava |
|---|---|---|---|---|
| R1 | Napomena uz nalog ima najviše 300 znakova. Emoji se broji kao jedan znak, a razmaci na početku i kraju se ne broje. | `OrderNote.maxLength = 300` | `order/order_note.dart` | mobilna, forma „Zakaži uslugu”, dok se kuca |
| R2 | Pansion traje od 1 do 30 noći. | `StayLength.min = 1`, `StayLength.max = 30` | `order/stay_length.dart` | mobilna, forma, broj noći |
| R3 | Termin je u budućnosti, počinje na pun sat ili pola sata i ceo je u radnom vremenu centra. Kod pansiona su predaja i preuzimanje ljubimca u radnom vremenu. | `ServicePeriod.step = 30 min` | `order/service_period.dart` | mobilna, forma, datum i vreme |
| R4 | Vlasnik otkazuje nalog najkasnije 24 sata pre početka. Menadžer može i kasnije, ali pre prijema ljubimca. | `cancellationNotice = 24 h` | `order/order_actions.dart` (`cancelOrder`) | mobilna, detalj naloga, „Otkaži nalog” |
| R5 | Dozvoljeni prelazi: na čekanju → potvrđen, odbijen ili otkazan; potvrđen → u toku ili otkazan; u toku → spreman za preuzimanje; spreman za preuzimanje → završen. Ostali prelazi nisu dozvoljeni. | 7 od 49 prelaza | `order/order_status.dart` (`canTransition`) | svaka akcija u obe aplikacije |
| R6 | Isti ljubimac nema dva aktivna naloga koja se vremenski preklapaju. | — | `availability.dart` (`petIsFree`) | mobilna, slanje forme |
| R7 | U boksu je jedan ljubimac, a boks mora da odgovara veličini ljubimca. Pansion dobija najmanji slobodan boks koji odgovara. | — | `availability.dart` (`assignKennel`) | backoffice, „Potvrdi” |
| R8 | Izvršilac (negovatelj za kupanje i šišanje, veterinar za pregled, šetač za šetnju) nema dva termina koja se preklapaju. Šetaču između dve šetnje treba 30 minuta da stigne na sledeću adresu. | `walkTravelTime = 30 min` | `availability.dart` (`assignStaff`) | backoffice, „Potvrdi” |

R6, R7 i R8 zavise od naloga drugih korisnika, pa su u domenu napisani kao izračunavanja nad listama. U KT1 se računaju nad lažnim podacima u memoriji, a od KT2 konačnu odluku donosi server.

