# ADR-0001: Testy uruchamiamy pytestem, nie runnerem Django

- **Status:** Accepted
- **Data:** 2026-09-08

## Kontekst

Sesja 5 wprowadza warstwę testową. Django dostarcza własny runner
(`manage.py test`, oparty na `unittest`), który działa bez żadnej dodatkowej
zależności — projekt korzystał z niego przy pierwszym smoke teście.

Testy nie są w tym projekcie dodatkiem. Faza B zakłada pisanie serwisów w rytmie
TDD, a faza C w całości dotyczy testów trudnych: współbieżnego zapisu z
`select_for_update` (sesje 14–15), świadomego użycia mocków i stubów (sesja 16),
weryfikacji indeksów (sesja 17). Wybór runnera przesądza, jak wygodnie będzie się
te testy pisało przez kolejne dwa miesiące.

Istotne ograniczenie techniczne: `django.test.TestCase` opakowuje każdy test w
jedną transakcję z rollbackiem. Test wyścigu wymaga, żeby kilka wątków widziało
nawzajem swoje **zatwierdzone** transakcje, więc pod `TestCase` jest fizycznie
niewykonalny — trzeba zejść do `TransactionTestCase`.

## Rozważane opcje

- **A — `manage.py test`** — zero dodatkowych zależności, zgodność z całą
  dokumentacją Django, jeden sposób uruchamiania dla runserver i testów.
- **B — `pytest` + `pytest-django`** — osobny runner nad tą samą warstwą testową
  Django.

## Decyzja

Wybieramy **B**, głównie z trzech powodów:

1. **Fikstury zamiast dziedziczenia.** Od fazy B praktycznie każdy test potrzebuje
   podobnego zestawu obiektów (trener, zajęcia, zajęcia zapełnione do limitu) w
   różnych kombinacjach. W `unittest` oznacza to hierarchię klas bazowych albo
   duplikację; fikstury składają się przez nazwę argumentu.
2. **Parametryzacja.** `@pytest.mark.parametrize` odpowiada wprost kształtowi
   sesji 12 (idempotentność `cancel()`, przypadki brzegowe). W `unittest`
   pozostaje pętla z `subTest()` albo N prawie identycznych metod.
3. **Przełączanie izolacji bazy markerem.** Wymóg z sesji 14–15 sprowadza się do
   zmiany `@pytest.mark.django_db` na `django_db(transaction=True)`, bez ruszania
   struktury klas. Istnieje też trzeci wariant (`django_db_serialized_rollback`),
   co pozwoli świadomie wybrać kompromis szybkość/wierność.

Dodatkowo ważą: zwykły `assert` z introspekcją wartości przy porażce, selekcja
(`-k`, `-m`, `--lf`), ekosystem wtyczek (`pytest-timeout` przy testach
współbieżności, `pytest-mock` przy sesji 16) oraz to, że test e2e jest zwykłą
funkcją, a nie klasą Django.

## Konsekwencje

Zyskujemy narzędzia opisane wyżej. Zachowujemy przy tym całą warstwę testową
Django: `django.test.Client`, `assertRedirects`, `assertNumQueries` (potrzebne w
fazie C) i `override_settings` działają bez zmian, a istniejące klasy dziedziczące
po `TestCase` pytest uruchamia bez modyfikacji. Migracja jest przyrostowa — stare
testy zostają, nowe pisze się po pytestowemu.

Koszty:

- Kolejna zależność i kolejna warstwa konfiguracji, która może się zepsuć w sposób
  nieoczywisty (błąd o `SECRET_KEY` zamiast o braku ustawień, cicho zignorowana
  sekcja konfiguracyjna).
- Dokumentacja Django i większość odpowiedzi w sieci zakłada `manage.py test` —
  trzeba tłumaczyć w głowie.
- `pytest-django` bywa w tyle za nowym wydaniem Django, co może opóźnić upgrade.
- Konfiguracja w `pyproject.toml` używa sekcji `[tool.pytest]`, obsługiwanej
  dopiero od pytest 9. Starszy pytest **zignoruje ją po cichu**; forma
  `[tool.pytest.ini_options]` działa w obu. Do sprawdzenia przy budowaniu CI.
- Dwa runnery w projekcie: `manage.py test` nadal istnieje i będzie działał na
  podzbiorze testów, dając mylące wyniki. Traktujemy `pytest` jako jedyny
  obowiązujący.

## Co odrzucono i dlaczego

**A (`manage.py test`)** — wystarczyłby dla projektu bez ambicji testowych, ale nie
daje ani fikstur, ani parametryzacji, a przełączanie izolacji bazy wymaga zmiany
klasy bazowej testu. Wróciłby do gry, gdyby projekt porzucił cele z fazy C albo
gdyby `pytest-django` zablokował potrzebny upgrade Django.
