# ADR-0002: Testy e2e są oddzielone od szybkich i domyślnie wyłączone

- **Status:** Accepted
- **Data:** 2026-09-08

## Kontekst

W projekcie istnieją dwa rodzaje testów o skrajnie różnej charakterystyce:

| | szybkie (jednostkowe / integracyjne) | e2e |
|---|---|---|
| co uruchamiają | kod Pythona, baza | całą aplikację + przeglądarkę |
| czas | milisekundy | sekundy każdy |
| wymagania | baza danych | podniesiony stack, Firefox, geckodriver |
| stabilność | deterministyczne | podatne na timing |

Przed podziałem gołe `pytest` zbierało oba testy, więc każde uruchomienie
otwierało Firefoksa. To niszczy pętlę zwrotną, którą pisze się kod w rytmie TDD
(fazy B i C), a w środowisku bez przeglądarki — kontener aplikacji, runner CI bez
przygotowania — daje przebieg czerwony z powodu niezwiązanego z kodem.

Planowane CI (sesje 5b–5c) uruchomi oba rodzaje jako **osobne joby**, żeby widzieć
rozdzielne checki i czasy. Wymaga to możliwości wskazania podzbioru z linii poleceń.

## Rozważane opcje

- **A — brak podziału.** Jeden przebieg, zawsze wszystko.
- **B — tylko katalog.** `tests/e2e/` poza `testpaths`; e2e uruchamiane przez
  podanie ścieżki.
- **C — tylko marker.** `@pytest.mark.e2e`, pliki gdziekolwiek.
- **D — katalog + marker + domyślne wykluczenie w `addopts`.**

## Decyzja

Wybieramy **D**. Katalog i marker odpowiadają za różne rzeczy i nie zastępują się
nawzajem: `testpaths` decyduje, co pytest **zbiera**, marker decyduje, co z
zebranego **uruchamia**. Przy samym katalogu poza `testpaths` polecenie
`pytest -m e2e` niczego by nie znalazło, bo pytest nie zajrzałby do tych plików.

Układ:

- `fitness_booking/tests/` — testy szybkie, `tests/e2e/` — testy e2e; oba w `testpaths`.
- `@pytest.mark.e2e` na testach e2e, marker zarejestrowany w konfiguracji.
- `addopts` zawiera `-m not e2e`, więc gołe `pytest` uruchamia tylko szybkie.

Podział zabezpieczamy dwiema flagami w `addopts`:

- **`--strict-markers`** — nierejestrowany marker (np. literówka `@pytest.mark.e2ee`)
  jest błędem, a nie ostrzeżeniem. Bez tego test e2e wpadłby po cichu do szybkiego
  przebiegu, bo nie pasowałby do wykluczenia.
- **`--strict-config`** — literówka w kluczu konfiguracji (`testpath` zamiast
  `testpaths`) jest błędem, a nie ostrzeżeniem.

## Konsekwencje

Codzienna pętla wraca do sekund i nie wymaga przeglądarki ani podniesionego
stacku. Podział jest gotowy pod dwa joby CI bez dalszej pracy.

Koszty:

- **Gołe `pytest` nie znaczy „wszystko".** Domyślne zachowanie jest ukryte w
  konfiguracji; ktoś (albo job CI) może uznać, że uruchomił komplet, uruchomiwszy
  połowę. Dlatego polecenia są udokumentowane w README.
- **„Uruchom wszystko" przestało być oczywiste.** Puste wyrażenie `-m ""` działa,
  ale Windows PowerShell 5.1 gubi puste argumenty przy wywołaniu natywnego pliku
  wykonywalnego, więc w tej powłoce polecenie się wywala. Formą przenośną między
  bashem, PowerShellem i YAML-em CI jest `pytest -m "e2e or not e2e"`.
- Dwa drzewa katalogów zamiast jednego, oba wymagające `__init__.py`, żeby nazwy
  modułów były unikalne przy domyślnym trybie importu pytest.
- Wyrażenie podane w `-m` **nie jest walidowane** — `--strict-markers` tego nie
  obejmuje. Literówka w linii poleceń daje ciche `no tests collected`. Zabezpiecza
  nas przed tym kod wyjścia pytest: pusta selekcja kończy się kodem 5, czyli
  czerwonym jobem w CI.

## Co odrzucono i dlaczego

**A (brak podziału)** — nie do utrzymania przy TDD w fazach B–C. Wróciłoby tylko
wtedy, gdyby testy e2e zniknęły z projektu.

**B (tylko katalog)** — uniemożliwia selekcję markerem, bo pliki poza `testpaths`
nie są zbierane. Wystarczyłoby, gdybyśmy nigdy nie chcieli uruchamiać e2e
w ramach jednego przebiegu z resztą.

**C (tylko marker)** — działa, ale zostawia testy e2e wymieszane z jednostkowymi
w tym samym drzewie. Wróciłoby do gry, gdyby testów e2e było kilka i utrzymywanie
osobnego drzewa katalogów przestało się opłacać.
