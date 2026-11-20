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

## Pokretanje

Potrebni su Docker Desktop (na Windows-u sa WSL 2) i Flutter 3.47.6. Za backoffice na Windows-u treba Visual Studio 2022 sa „Desktop development with C++“ i C++ ATL (zbog `flutter_secure_storage`), a za mobilnu Android emulator.

### Baza i server

Iz korena repozitorijuma, posle čistog kloniranja:

```sh
cp .env.example .env    # Windows: copy .env.example .env
docker compose up -d --build
```

`.env` se ne menja: `.env.example` već ima razvojne vrednosti. `compose.yaml` podiže tri servisa:

| Servis | Šta radi | Adresa |
| --- | --- | --- |
| `db` | PostgreSQL 17 | `localhost:5435` |
| `migrate` | dbmate primeni migracije iz `apps/server/migrations`, pa izlazi | — |
| `server` | server u Dartu na Relic-u, slika iz `apps/server/Dockerfile` | http://localhost:8080 |

Kada je baza prazna, server upisuje početne podatke: korisnike sa heširanim lozinkama (Argon2id), ljubimce, boksove, radno vreme i naloge u svih sedam stanja.

Provera: `docker compose ps -a` (servis `migrate` je `Exited (0)`) i `curl localhost:8080/health` (odgovor `ok`; u PowerShell-u `curl.exe`).

| Komanda | Šta radi |
| --- | --- |
| `docker compose logs server` | ispis servera; `logs migrate` za migracije |
| `docker compose up -d --build server` | nova slika servera posle izmene u `apps/server` ili u paketima |
| `docker compose stop server` / `start server` | zaustavlja i vraća server (provera „server ne radi“ u aplikacijama) |
| `docker compose down` | gasi sistem, podaci ostaju |
| `docker compose down -v` | gasi sistem i briše bazu; sledeći `up -d` kreće od nule |

Lozinka baze, `DEMO_PASSWORD`, `JWT_SECRET`, trajanje prijave (`SESSION_TTL_MINUTES`, 480) i portovi su u `.env`, koji nije u git-u. Za proveru isteka prijave postavite `SESSION_TTL_MINUTES=1`, pa `docker compose up -d server`; posle vratite 480. SQL iz terminala: `docker compose exec db psql -U sapa -d sapa`.

### Aplikacije

Aplikacije rade nad serverom i nalaze ga bez izmene koda: Android emulator na `10.0.2.2:8080`, desktop i pregledač na `localhost:8080`. Telefon na istoj mreži se pokreće uz `--dart-define=SERVER_URL=http://<IP računara>:8080`. Pregledač sme da zove server samo sa adrese iz `CORS_ORIGINS` u `.env`; `.env.example` dozvoljava backoffice na `http://localhost:8081`.

Svaka aplikacija u svom terminalu, iz korena repozitorijuma:

```sh
cd apps/mobile
flutter run
```

```sh
cd apps/backoffice
flutter run -d windows    # ili -d chrome --web-port 8081
```

Prijava ostaje posle ponovnog pokretanja: token je u bezbednom skladištu platforme (Keystore, Keychain, Credential Manager), a u pregledaču u HttpOnly kolačiću. Lozinka se na uređaju ne čuva.

### Demo nalozi

Lozinka za sve naloge je vrednost `DEMO_PASSWORD` iz `.env` (u `.env.example`: `sapa-demo`).

| Nalog | Ime | Uloga | Aplikacija |
| --- | --- | --- | --- |
| `vlasnik1` | Jelena Marković | vlasnik | mobilna |
| `vlasnik2` | Petar Nikolić | vlasnik | mobilna |
| `negovatelj1` | Marija Ilić | negovatelj | backoffice |
| `veterinar1` | dr Stefan Kovač | veterinar | backoffice |
| `setac1` | Nikola Jović | šetač | backoffice |
| `menadzer1` | Ivana Simić | menadžer | backoffice |

Vlasnik se ne može prijaviti u backoffice, a osoblje u mobilnu aplikaciju; aplikacija tada kaže zašto.

### Pozivi mimo aplikacije

Server isto pravilo proverava i kada poziv ne dolazi iz aplikacije. Primeri su za Git Bash (PowerShell drugačije prosleđuje navodnike u JSON-u), a token se uzima iz polja `token` odgovora na prijavu:

```sh
curl -X POST localhost:8080/api/v1/sessions -H "Content-Type: application/json" -d "{\"username\":\"vlasnik1\",\"password\":\"sapa-demo\"}"
curl localhost:8080/api/v1/board                                                      # 401 sign-in-required
curl -X POST localhost:8080/api/v1/orders/<id>/confirmation -H "Authorization: Bearer <token>"   # vlasnik: 403 not-allowed
```
