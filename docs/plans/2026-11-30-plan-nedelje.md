# Plan za nedelju 30. 11 – 4. 12. 2026.

**Cilj nedelje:** završiti Fazu 1 iz istraživačkog plana (`chat_agent` na ChatHaruhi pristupu, bez treninga), dokazati da je bolja od stare verzije u parovima i započeti Fazu 2 (komični mehanizmi).

**Gde se radi:** glavni checkout, `series-transcription-pipeline`, grana `feat/in-context-generation` (audio i `series_bible.db` postoje samo tamo). Istraživački plan: `docs/plans/2026-11-27-plan-generisanja-iz-istrazivanja.md` (grana `claude/previous-work-results-b0e8f1`).

> ⚠️ Pre bilo kakvog brisanja: `git status --ignored`. Nikad `rm -rf` u `data/` (posebno `data/gold/` i `data/transcripts/`).

## Pregled

| Dan | Fokus | Gotovo kad |
|---|---|---|
| Pon 30. 11 | Sređivanje + odluke | Grana ažurna, otvorena pitanja zatvorena |
| Uto 1. 12 | Scene + izbor embedding modela | Recall@k za 2–3 modela na 30–50 upita, izabran model |
| Sre 2. 12 | Pretraga scena u `chat_agent` | Novi prompt radi end-to-end, testovi prolaze |
| Čet 3. 12 | Evaluacija u parovima | 30 poruka ocenjeno A/B, odluka o Fazi 1 |
| Pet 4. 12 | Start Faze 2 + nedeljni pregled | Šema oznaka u gold editoru, 2–3 epizode obeležene, plan za sledeću nedelju |

---

## Ponedeljak 30. 11 — sređivanje i odluke

**Kod i grane (≈1 h)**
- [x] `git pull` na `feat/in-context-generation` (lokalno je 9 komitova iza `origin`). — urađeno 28. 11.
- [x] Pregledati neprijavljene fajlove (`data/pipeline.db*`, `profiles_v1.zip`, `episode_generator/prompts/To roll out`, `.bak` baze) — odlučiti šta ide u git, šta u `.gitignore`, šta u arhivu. **Ništa ne brisati.** — urađeno 28. 11. (pipeline `c597a48`).
- [ ] Otvoriti PR za `docs/plans/2026-11-27-plan-generisanja-iz-istrazivanja.md` (grana `claude/previous-work-results-b0e8f1`) i ovaj nedeljni plan, pa ih spojiti u `master`.
- [ ] Nabaviti `HF_TOKEN` i ubaciti ga u `.env` — odblokira transkripciju 38 epizoda na čekanju (može da radi u pozadini preko nedelje).

**Odluke (≈1 h) — zatvoriti otvorena pitanja iz istraživačkog plana**
- [ ] Kandidati za embedding model za srpski (predlog za test u utorak): `BAAI/bge-m3`, `intfloat/multilingual-e5-large`, `jinaai/jina-embeddings-v3`.
- [ ] Writer model za Fazu 3: Gemini 2.5 Pro vs. otvoreni (Qwen / DeepSeek). Dovoljno je zapisati odluku i razlog.
- [ ] Koliko ljudskih ocena po iteraciji je realno (predlog: 30 parova, 1–2 ocenjivača).
- [ ] Pravilo sečenja transkripta na scene (predlog: prozor od N replika oko replike lika + prekid na pauzi > X s ili promeni teme).

---

## Utorak 1. 12 — scene i izbor embedding modela

1. [ ] **Sečenje na scene** (`chat_agent/scenes.py` ili skripta u `scripts/`): iz transkripata napraviti scene = bar jedna replika sagovornika + odgovor lika + okolni kontekst. Prvo samo gold set i epizode sa visokom pokrivenošću govornika (`scripts/speaker_coverage_report.py --metric text`, prag ≥ 0.85 po tekstu).
2. [ ] **Test skup za pretragu:** 30–50 ručnih upita (poruka korisnika) sa očekivanim scenama. Sačuvati kao `tests/data/scene_retrieval_queries.json` da se može ponavljati.
3. [ ] **Izmeriti recall@5 i recall@10** za 2–3 modela. Rezultate upisati u tabelu u plan.
4. [ ] Izabrati model; izgraditi indeks scena po liku (Čvarkov, Torbica, Boškić).

**Gotovo kad:** postoji tabela recall@k po modelima i indeks za izabrani model.

---

## Sreda 2. 12 — pretraga scena u `chat_agent`

Izmene u `chat_agent/character_prompt.py` (TDD: prvo testovi):
1. [ ] Zameniti `ORDER BY RANDOM() LIMIT 15` pretragom scena po trenutnoj poruci; popunjavati do ≈1.500 tokena.
2. [ ] Istorija razgovora ≈1.200 tokena (6–10 krugova).
3. [ ] Redosled: sistemski prompt → scene → istorija → poruka; **opis ličnosti i fraze na kraj sistemskog prompta**.
4. [ ] Pravilo „1–3 rečenice“ zameniti stvarnom dužinom replika po liku (prosek 26–43 reči po replici — izračunati iz baze, ne hardkodovati).
5. [ ] Uputstvo da lik ponovi originalnu repliku kad pitanje dotakne nešto iz serije.
6. [ ] Eksplicitno tražiti „loše“ osobine (lenjost, sebičnost, podmuklost) uz primere iz scena.
7. [ ] Keširanje sistemskog prompta (trošak).
8. [ ] Testovi: `PYTHONPATH=. .venv-sb/bin/python -m pytest tests -q` (6 padova u `test_speaker_identifier.py` su od ranije — bez `pandas`).

**Gotovo kad:** chat radi end-to-end sa novim promptom za sva tri lika i testovi prolaze.

---

## Četvrtak 3. 12 — evaluacija u parovima

1. [ ] Fiksni skup od ≈30 poruka (mešavina: tema iz serije, svakodnevica, provokacija lika).
2. [ ] Generisati odgovore stare i nove verzije; pomešati redosled A/B (slepo).
3. [ ] Ljudska ocena po osama: razumevanje situacije, odnos prema sagovorniku, način govora + ukupni utisak (A ili B).
4. [ ] Automatski signal: curenje fraza (`razumiješ` van Torbice, `Dragane` kod Boškića) za staru i novu verziju.
5. [ ] **Odluka:** ako nova pobeđuje → Faza 1 zatvorena; ako ne → zapisati gde gubi i šta probati sledeće nedelje.
6. [ ] Gold editor: ispraviti još 2–3 epizode (treba za Fazu 2 i kasniji trening).

**Gotovo kad:** postoji tabela rezultata A/B i zapisana odluka.

---

## Petak 4. 12 — start Faze 2 + pregled nedelje

1. [ ] **Šema oznaka po sceni** u gold editoru (`tools/gold_editor`): povod, tip eskalacije, digresija (ko, na šta, vraća li se), birokratska logika (da/ne, kako), uloge (nameće / izvlači se / strada), pomenuti odsutni likovi, kraj scene. Testovi u `tests/test_gold_editor.py`.
2. [ ] Ručno obeležiti 2–3 epizode iz gold seta (cilj za Fazu 2 je 10–15). Dodavati/spajati kategorije dok se ne ustale.
3. [ ] **Nedeljni pregled (30 min):** šta je završeno, šta prelazi, plan za 7–11. 12 (nastavak Faze 2: 10–15 epizoda, LLM obeležavanje, mera slaganja ≥ 80%).

---

## Kasnije (ne ove nedelje)

LinkedIn mini-serija i javljanje glumcima (demo + poziv na večeru) čekaju da projekat dođe na ozbiljan nivo. Predlog uslova: Faza 1 pobeđuje staru verziju u A/B oceni i generator epizoda (Faza 3) daje scenu koju je vredno pokazati.

## Rizici ove nedelje

| Rizik | Šta radim |
|---|---|
| Embedding loše nalazi scene na srpskom | Test na 30–50 upita pre ugradnje; ako svi modeli < ~60% recall@10, dodati BM25 hibrid |
| Pogrešno pripisane replike u indeksu | Indeksirati prvo gold set + epizode sa visokom pokrivenošću po tekstu |
| Nema vremena za ljudske ocene | 30 parova je minimum; ako zafali vremena, smanjiti na 20, ali ne preskakati |
| `HF_TOKEN` kasni | Ne blokira Fazu 1; transkripcija 38 epizoda prelazi u sledeću nedelju |

## Podsetnici

- **Ponedeljak 30. 11 u 9:00** — zakazani zadatak `podsetnik-plan-nedelje-start`: pregled nedelje i lista za ponedeljak.
- **Petak 4. 12 u 16:00** — zakazani zadatak `podsetnik-nedeljni-pregled`: šta je urađeno, šta prelazi, plan za 7–11. 12.

Zadaci rade dok je Claude aplikacija otvorena; ako je zatvorena u zakazano vreme, pokrenu se pri sledećem otvaranju.
