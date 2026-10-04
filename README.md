A system for registering for group classes at a fitness club


## Testy

Runner: `pytest` + `pytest-django`. Konfiguracja w `pyproject.toml`, sekcja
`[tool.pytest]`. Uzasadnienie: [ADR-0001](docs/adr/0001-pytest-zamiast-runnera-django.md),
[ADR-0002](docs/adr/0002-podzial-testow-szybkie-i-e2e.md).

Testy dzielą się na dwa rodzaje, oznaczone markerem:

| Co uruchamiasz | Polecenie |
|---|---|
| tylko szybkie (**domyślnie**) | `pytest` |
| tylko e2e | `pytest -m e2e` |
| wszystko | `pytest -m "e2e or not e2e"` |

**Gołe `pytest` nie uruchamia testów e2e** — `addopts` zawiera `-m not e2e`.
Polecenia „uruchom wszystko" nie skracaj do `pytest -m ""`: Windows PowerShell
gubi puste argumenty przy wywoływaniu natywnych programów i pytest zgłosi
`argument -m: expected one argument`.

### Układ

```
fitness_booking/tests/    # szybkie: baza, warstwa serwisowa, widoki
tests/e2e/                # e2e: Selenium przeciwko podniesionemu stackowi
```

Oba katalogi są w `testpaths` i oba zawierają `__init__.py` — bez nich pytest
wyprowadza nazwę modułu z samej nazwy pliku, co przy dwóch plikach o tej samej
nazwie w różnych aplikacjach kończy się błędem `import file mismatch`.

### Czego wymagają

**Szybkie:** osiągalna baza PostgreSQL oraz plik `fitness_booking/.env` z kluczami
`SECRET_KEY`, `DATABASE_URL` i `DEBUG`. Plik jest ignorowany przez gita; wczytuje
go `environ.Env.read_env()` w `settings.py`, szukając `.env` w swoim katalogu.
Zmienne już obecne w środowisku mają pierwszeństwo, więc w kontenerze nadpisuje
je `env_file` z `docker-compose.yaml`.

**E2E:** dodatkowo podniesiony stack (`docker compose up`, aplikacja dostępna przez
nginx na porcie 80) oraz Firefox z geckodriverem na hoście.
