# Plan: generisanje likova i epizoda Državnog posla na osnovu istraživanja

**Datum:** 2026-11-27
**Odnosi se na:** `series-transcription-pipeline` (glavni checkout, grana `feat/in-context-generation`): `chat_agent/` i `episode_generator/`

## Polazna tačka

| Deo | Kako radi sada | Problem |
|---|---|---|
| `chat_agent/character_prompt.py` | 15 **nasumičnih** replika (`ORDER BY RANDOM() LIMIT 15`), opis ličnosti na početku, pravilo „Maks 1–3 rečenice“ | Primeri nisu vezani za temu razgovora. Prave replike imaju u proseku 26–43 reči. Opis na početku slabije drži stil. |
| `episode_generator/` (Planner → Writer → Critic → Refiner) | Planner vraća jedan JSON za celu epizodu, a Writer piše celu epizodu odjednom | Nema podele na scene, nema pravih scena kao primera, nema memorije kroz epizode („ne ponavljaj teme“ je samo rečenica u promptu). |
| Podaci | ECAPA pogrešno pripiše procenjenih 5–10% segmenata; gold set se ispravlja ručno | Pogrešno pripisane replike se prenose i u memoriju i u trening. |

## Faza 1: `chat_agent`, pristup ChatHaruhi (bez treninga)

**Izvor:** ChatHaruhi ([arXiv 2308.09597](https://arxiv.org/abs/2308.09597))

1. **Jedinica memorije je kratka scena, ne replika:** bar jedna replika sagovornika, odgovor lika i okolni kontekst. Scene se seku iz transkripata.
2. **Embedding indeks scena za svakog lika.** Prvo izmeriti koliko višejezični embedding dobro nalazi scene na srpskom: napraviti 30–50 ručnih upita sa očekivanim scenama i meriti recall@k.
3. **Pretraga po trenutnoj poruci:** uzimati najsličnije scene dok ne popune oko 1.500 tokena. Za istoriju razgovora ostaje oko 1.200 tokena (6–10 krugova).
4. **Redosled u promptu:** sistemski prompt → scene → istorija → poruka. **Opis ličnosti i fraze idu na kraj sistemskog prompta.**
5. Pravilo „1–3 rečenice“ zameniti stvarnom dužinom replika za svakog lika.
6. U prompt dodati uputstvo da lik ponovi originalnu repliku kad pitanje dotakne nešto iz serije.
7. **Likovi ostaju „loši“** ([arXiv 2601.04716](https://arxiv.org/abs/2601.04716)): modeli ublaže lenje, sebične i podmukle osobine. Te osobine treba u promptu zahtevati eksplicitno, uz primere iz scena.

**Gotovo kad:** na fiksnom skupu od oko 30 poruka nova verzija u parovima pobeđuje staru po ljudskoj oceni.

## Faza 2: komični mehanizmi kao podaci

**Zašto:** humor Državnog posla ima obrazac. Model dobro hvata formulu (ko nameće temu, kad ide digresija, kako se scena gasi), a promašuje punjenje (koja digresija, koja apsurdna logika). Ako su mehanizmi obeleženi po scenama, planner bira proverene kalupe, a writer vidi kako su pravi pisci punili baš taj kalup.

1. **Šema oznaka po sceni** (početni predlog, ispraviti tokom ručnog obeležavanja):
   - povod (sitnica od koje scena kreće),
   - tip eskalacije (npr. zavera, karantin, pozivanje na pravilnik, fizički haos),
   - digresija: ko skreće, na šta, i da li se vraća na temu,
   - birokratska logika primenjena na besmislicu (da/ne, kako),
   - uloge: ko nameće, ko mudruje ili se izvlači, ko strada,
   - odsutni likovi koji se pominju,
   - kako se scena završava (ugasi se, prekid, obrt).
2. **Ručno obeležiti 10–15 epizoda** iz gold seta. Taksonomija treba da izađe iz podataka, ne iz gornje liste: dodavati i spajati kategorije dok se ne ustale. Gold editor proširiti poljima za ove oznake.
3. **Ostatak korpusa obeležava LLM**, sa ručno obeleženim scenama kao primerima. Pre toga izdvojiti 3–5 ručno obeleženih epizoda za proveru i izmeriti slaganje po poljima.
4. **Čuvanje:** nova tabela mehanizama po sceni u `series_bible.db`, vezana za epizodu i raspon replika.
5. **Upotreba u Fazi 3:** planner bira i kombinuje mehanizme, a writer dobija prave scene sa *istim mehanizmom*, ne samo sa sličnom temom.

**Gotovo kad:** LLM oznake se na izdvojenim epizodama slažu sa ručnim u dovoljnoj meri (predlog: bar 80% na poljima povod, eskalacija i uloge), i svaki mehanizam koji planner sme da bira ima bar desetak pravih scena kao primere.

## Faza 3: `episode_generator`, struktura Dramatron + DraMaze

**Izvori:** Dramatron ([arXiv 2209.14958](https://arxiv.org/abs/2209.14958)), DraMaze ([arXiv 2610.32002](https://arxiv.org/abs/2610.32002))

1. **Memorija serije** (DraMaze): tabela epizoda sa temama, ključnim događajima i stalnim šalama. Planner je čita pre planiranja, a posle svake generisane epizode se dopisuje.
2. **Planner vraća plan po scenama:** 6–10 scena, za svaku: mesto, uloga u radnji (uvod / eskalacija / vrhunac / rasplet), likovi, šta se u sceni desi i **komični mehanizam izabran iz Faze 2** (povod, tip eskalacije, digresija, kraj).
3. **Writer piše scenu po scenu.** Svaka scena dobija:
   - logline i opis epizode,
   - opis te scene,
   - **ceo dijalog prethodne scene** (glavna zamerka profesionalaca na Dramatron),
   - 2–3 **prave scene iz serije** kao primere: sa **istim mehanizmom** (Faza 2) i, gde ima, sličnom temom (pretraga iz Faze 1).
4. **Kontrola ponavljanja:** ako se blok teksta ponovi više od 3 puta, scena se generiše ponovo (kao u Dramatronu).
5. **Critic po scenama** proverava doslednost (ko je šta rekao i ko šta zna) i usklađenost sa memorijom serije.
6. **Čovek u petlji:** pauza posle plana i posle svake scene, sa mogućnošću da se scena generiše ponovo ili ručno ispravi.

**Gotovo kad:** generisana epizoda od oko 1.200 reči prođe Critic bez ponavljanja tema iz memorije serije, i u parovima pobeđuje trenutni generator.

## Faza 4: evaluacija

**Izvori:** PRISM ([arXiv 2608.26674](https://arxiv.org/abs/2608.26674)), HumorRank ([arXiv 2604.19786](https://arxiv.org/abs/2604.19786)), Oogiri ([arXiv 2511.09133](https://arxiv.org/abs/2511.09133))

1. **Vernost liku po odvojenim osama:** kako lik shvata situaciju, kakav je prema sagovorniku, kako govori.
2. **Humor kroz poređenje u parovima** (A ili B), nikad kao apsolutna ocena.
3. **Ne oslanjati se samo na model kao sudiju:** modeli više vrednuju originalnost od ljudi. Zadržati ljudske ocene bar na uzorku.
4. **Automatski signal:** curenje fraza (npr. `razumiješ` kod lika koji nije Torbica) kao mera mešanja likova.

## Faza 5: fine-tune (tek posle Faza 1–4)

**Izvori:** ChatHaruhi, HER ([arXiv 2601.21459](https://arxiv.org/abs/2601.21459)), Slava-Qwen3-14B ([HF](https://huggingface.co/IvanCvetanovic/Slava-Qwen3-14B-Serbian))

1. **Preduslov:** ispravljena oznaka ko je šta rekao u gold setu (gold editor).
2. **Format primera kao u ChatHaruhi:** u ulazu su sistemski prompt, izvučene scene, istorija i poruka. Gubitak se računa samo na replici lika.
3. **LoRA, ne ceo model.** Uporediti sa osnovnim modelom na opštem srpskom testu (npr. Serbian SuperGLUE), jer treniranje na malo podataka lako pokvari opšte sposobnosti (Slava: znanje o Srbiji 75,6% → 74,8%, sažimanje lošije po izvornim govornicima).
4. Sporedni likovi sa malo replika ostaju na pristupu iz Faze 1.

## Rizici

| Rizik | Ublažavanje |
|---|---|
| Embedding loše nalazi scene na srpskom | Mera recall@k pre Faze 1, uz poređenje 2–3 modela |
| Pogrešno pripisane replike u memoriji | Prvo indeksirati scene iz gold seta i epizoda sa visokom pokrivenošću govornika |
| Humor ostane ravan | Pravi primeri scena sa istim mehanizmom, poređenje u parovima, čovek u petlji |
| Model reciklira poznate fore umesto novih | Planner kombinuje mehanizme sa novim povodom; memorija serije beleži iskorišćene digresije |
| LLM oznake mehanizama nepouzdane | Mera slaganja sa ručnim oznakama pre obeležavanja celog korpusa |
| Trošak (ChatHaruhi navodi 10–20× skuplje od običnog chata) | Keširanje sistemskog prompta, ograničen budžet za scene |

## Otvorena pitanja

- Koji embedding model za srpski?
- Da li Writer koristi Gemini 2.5 Pro ili otvoreni model (Qwen / DeepSeek, kao u DraMaze)?
- Koliko ljudskih ocena po iteraciji je realno?
- Kako se transkript seče na scene za obeležavanje mehanizama (epizode su uglavnom jedan neprekinut razgovor)?
