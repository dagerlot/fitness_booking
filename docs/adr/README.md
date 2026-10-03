# Architecture Decision Records

Rejestr decyzji architektonicznych projektu.

## Czym to jest, a czym nie

ADR opisuje **jedną decyzję**, która miała realną alternatywę i którą da się
odwrócić kosztem pracy. Jeśli nie potrafisz nazwać odrzuconej opcji — to nie
decyzja, tylko fakt, i jego miejsce jest w README albo w `notes/`.

- `notes/` — notatki z sesji: co zrobiliśmy i jak to działa. Żywe, poprawiane.
- `docs/adr/` — decyzje: dlaczego tak, a nie inaczej. Zamrożone.

## Zasady

1. Numeracja rosnąca, bez luk: `NNNN-krotki-tytul.md`.
2. **ADR-a się nie edytuje po zaakceptowaniu.** Zmiana zdania = nowy ADR ze
   statusem `Accepted`, a stary dostaje `Superseded by ADR-NNNN`.
   Wyjątek: literówki i linki.
3. Status: `Proposed` → `Accepted` → (`Superseded` | `Deprecated`).
4. ADR wchodzi tym samym commitem co zmiana, którą opisuje.
5. Nie ma decyzji bez odrzuconej alternatywy.

## Rejestr

| Nr | Tytuł | Status | Data |
|----|-------|--------|------|
| 0001 | [Testy uruchamiamy pytestem, nie runnerem Django](0001-pytest-zamiast-runnera-django.md) | Accepted | 2026-09-08 |
| 0002 | [Testy e2e są oddzielone od szybkich i domyślnie wyłączone](0002-podzial-testow-szybkie-i-e2e.md) | Accepted | 2026-09-08 |
