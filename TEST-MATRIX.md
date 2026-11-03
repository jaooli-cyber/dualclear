# DualClear — matriz de tests post-H0

- Fecha de corte: `2026-11-03T04:28:55Z`.
- Baseline documental revisada: `10ad9ef5f1391e31f743006c6d0379eeb7016c05`; última baseline con cambios de tests: `5d27a5ddd10f51e831bdce3fc5f545cf5be05130`.
- Toolchain objetivo: Fe 26.5.0, commit `3dab95f`.
- Estado global: **AUTHORED / STATIC-CHECKED / NOT EXECUTED**; gate **HOLD (RG-STOP)**.
- Regla de evidencia: ningún caso cambia a `EXECUTED-PASS` o `EXECUTED-FAIL` sin comando literal, UTC, commit, target, RC y log conservado.

## Semántica de estados

- `AUTHORED`: el test fuente existe cuando se cita un símbolo; en matrices de cobertura, la especificación del caso está escrita aunque una celda pueda indicar `GAP` de implementación.
- `STATIC-CHECKED`: nombre, input, assertions y resultado esperado se revisaron contra el código actual. No significa que se haya invocado el compilador ni el test runner sobre esta baseline.
- `NOT EXECUTED`: no existe evidencia de ejecución para esta baseline. `GATE-LOG.md:29-32` mantiene build/test pendientes y el gate en `HOLD (RG-STOP)`.
- `CORE-SONATINA`: ejecución directa del ingot `dualclear_core` con backend Sonatina, según `GATE-RUNBOOK.md:184-199`.
- `CORE-NATIVE`: segunda ejecución completa del mismo ingot `dualclear_core` con backend native, según `GATE-RUNBOOK.md:254-270`.
- `GAP`: falta un test del adaptador EVM o del wrapper nativo. Nunca se usa para C01-C15: el runbook ejecuta toda esa suite bajo ambos backends.

Todos los casos y especificaciones de este documento permanecen **AUTHORED / STATIC-CHECKED / NOT EXECUTED** hasta que se adjunte la evidencia definida al final.

## Inventario actual — ingot `dualclear_core`

La misma suite C01-C15 se ejecutará completa dos veces:

- `CORE-SONATINA`: `dualclear_core` bajo backend Sonatina.
- `CORE-NATIVE`: `dualclear_core` bajo backend native.

Las dos ejecuciones son evidencia cross-backend del core compartido. No sustituyen E01-E03 ni N01, que ejercitan las fronteras de adaptador.

| ID | Test fuente | Requisito/caso | Resultado esperado | Estado |
| --- | --- | --- | --- | --- |
| C01 | `fnv1a64_official_vectors` (`gate/core/src/lib.fe:293-310`) | Vectores FNV-1a64: vacío, `a`, `foobar`. | `0xcbf29ce484222325`, `0xaf63dc4c8601ec8c`, `0x85944171f73967e8`. | AUTHORED / STATIC-CHECKED / NOT EXECUTED |
| C02 | `golden_clearing_uses_largest_remainder_and_id_tie_break` (`:312-324`) | Golden de 4 bids, supply 7; clearing, prorrata y desempate. | Price `2000000`, filled `7`, fills ordenados `[(9,2),(1,3),(2,2),(3,0)]`, FNV `0xf85927c169cff4f1`. | AUTHORED / STATIC-CHECKED / NOT EXECUTED |
| C03 | `input_permutation_has_the_same_outcome` (`:326-348`) | Invarianza ante permutación del input golden. | Mismos fills y mismo FNV golden que C02. | AUTHORED / STATIC-CHECKED / NOT EXECUTED |
| C04 | `one_bid_with_exact_demand_clears_in_full` (`:350-362`) | Un bid, demanda exactamente igual a supply. | Price `1250000`, filled `4`, fill `[(7,4)]`. | AUTHORED / STATIC-CHECKED / NOT EXECUTED |
| C05 | `all_same_price_is_proportional_and_conserves_supply` (`:364-382`) | Tres bids de quantity 2 al mismo precio; supply 4. | Orden por ID y fills `[(1,2),(2,1),(3,1)]`; suma `4`. | AUTHORED / STATIC-CHECKED / NOT EXECUTED |
| C06 | `equal_remainders_award_the_lower_id_first` (`:384-397`) | Remainders iguales; desempate por ID. | ID 4 recibe 1 e ID 8 recibe 0. | AUTHORED / STATIC-CHECKED / NOT EXECUTED |
| C07 | `larger_remainder_beats_the_lower_id` (`:399-412`) | Remainder desigual tiene prioridad sobre ID menor. | IDs 1 y 9 reciben 1 cada uno; el asiento residual va al ID 9 por remainder mayor. | AUTHORED / STATIC-CHECKED / NOT EXECUTED |
| C08 | `maximum_bid_count_with_exact_demand_conserves_supply` (`:414-439`) | Límite válido de 16 bids, uno por unidad, supply 16. | Acepta 16; orden ID 1..16; cada fill vale 1; total 16. | AUTHORED / STATIC-CHECKED / NOT EXECUTED |
| C09 | `empty_input_reverts` (`:441-445`) | Límite inferior: 0 bids. `#[test(should_revert)]`. | Rechazo por cardinalidad antes de clearing. | AUTHORED / STATIC-CHECKED / NOT EXECUTED |
| C10 | `seventeen_bids_revert` (`:447-457`) | Límite superior inválido: 17 bids. `#[test(should_revert)]`. | Rechazo por `count > MAX_BIDS`. | AUTHORED / STATIC-CHECKED / NOT EXECUTED |
| C11 | `zero_supply_reverts` (`:459-466`) | Supply 0. `#[test(should_revert)]`. | Rechazo por precondición de supply positivo. | AUTHORED / STATIC-CHECKED / NOT EXECUTED |
| C12 | `zero_quantity_reverts` (`:468-475`) | Bid con quantity 0. `#[test(should_revert)]`. | Rechazo por quantity no positiva. | AUTHORED / STATIC-CHECKED / NOT EXECUTED |
| C13 | `duplicate_id_reverts` (`:477-487`) | Dos bids con ID 7. `#[test(should_revert)]`. | Rechazo por ID duplicado. | AUTHORED / STATIC-CHECKED / NOT EXECUTED |
| C14 | `demand_below_supply_reverts` (`:489-496`) | Demanda agregada 1, supply 2. `#[test(should_revert)]`. | Rechazo por demanda insuficiente. | AUTHORED / STATIC-CHECKED / NOT EXECUTED |
| C15 | `maximum_u64_quantity_and_u256_price_are_preserved` (`:498-513`) | Quantity/supply `u64::MAX` y price raw `u256::MAX`. | Price, filled y fill conservan exactamente ambos máximos; no hay truncado. | AUTHORED / STATIC-CHECKED / NOT EXECUTED |

## Inventario actual — ingot `dualclear_evm`

Backend de ejecución previsto: Sonatina sobre el ingot `dualclear_evm`. E01-E03 son tests de adaptador/ABI y se ejecutan aparte de C01-C15 bajo `CORE-SONATINA`.

| ID | Test fuente | Requisito/caso | Resultado esperado | Estado |
| --- | --- | --- | --- | --- |
| E01 | `evm_adapter_matches_the_shared_golden` (`gate/evm/src/lib.fe:57-84`) | Deploy, encode ABI, ejecutar golden y decodificar output. | Price `2000000`, filled `7`, FNV `0xf85927c169cff4f1`, fills `[(9,2),(1,3),(2,2),(3,0)]`. | AUTHORED / STATIC-CHECKED / NOT EXECUTED |
| E02 | `evm_handler_precheck_rejects_empty_bids` (`:86-99`) | ABI con 0 bids. `#[test(should_revert)]`. | Revert del handler por límite inferior. | AUTHORED / STATIC-CHECKED / NOT EXECUTED |
| E03 | `evm_handler_precheck_rejects_seventeen_bids` (`:101-120`) | ABI con 17 bids. `#[test(should_revert)]`. | Revert del handler por límite superior antes de la segunda `MemVec`. | AUTHORED / STATIC-CHECKED / NOT EXECUTED |

Nota: E02/E03 validan el precheck del handler, no una cota de materialización del `DynArray` durante decode-time.

## Inventario actual — ingot `dualclear_native`

Backend de ejecución previsto: native sobre el ingot `dualclear_native`. N01 prueba el wrapper y el mismo canario alimenta `main()`; se ejecuta aparte de C01-C15 bajo `CORE-NATIVE`.

| ID | Test fuente | Requisito/caso | Resultado esperado | Estado |
| --- | --- | --- | --- | --- |
| N01 | `native_adapter_matches_the_shared_golden` (`gate/native/src/lib.fe:42-45`) | Ejecutar el wrapper nativo sobre el golden compartido. | `native_golden_matches()` es true: price `2000000`, filled `7`, FNV `0xf85927c169cff4f1`, fills `[(9,2),(1,3),(2,2),(3,0)]`. | AUTHORED / STATIC-CHECKED / NOT EXECUTED |

## Matriz cross-backend

C01-C15 se ejecutan sin huecos una vez como `CORE-SONATINA` y otra como `CORE-NATIVE`. Las columnas de adaptador son independientes: un `GAP` allí significa que el caso no atraviesa actualmente esa frontera ABI/wrapper, no que falte la comparación del core entre backends.

| Caso | Core/Sonatina | Core/native | Adaptador EVM/Sonatina | Wrapper native | Igualdad/expected cross-backend | Estado |
| --- | --- | --- | --- | --- | --- | --- |
| Golden 4 bids | C02 | C02 | E01 | N01 | Price, filled, orden/fills y FNV exactamente iguales. DCG1 canónico: 284 bytes; FNV `0xf85927c169cff4f1`. | AUTHORED / STATIC-CHECKED / NOT EXECUTED |
| Permutación del golden | C03 | C03 | GAP | GAP | El core produce la misma salida y fingerprint en ambos backends y no depende del orden de entrada. | AUTHORED / STATIC-CHECKED / NOT EXECUTED |
| Un bid / demanda exacta | C04 | C04 | GAP | GAP | El core acepta y llena completamente de forma idéntica en ambos backends. | AUTHORED / STATIC-CHECKED / NOT EXECUTED |
| Todos al mismo precio | C05 | C05 | GAP | GAP | Misma prorrata, conservación y orden por ID en ambos backends del core. | AUTHORED / STATIC-CHECKED / NOT EXECUTED |
| Remainder igual | C06 | C06 | GAP | GAP | ID menor obtiene el asiento residual bajo ambos backends del core. | AUTHORED / STATIC-CHECKED / NOT EXECUTED |
| Remainder desigual | C07 | C07 | GAP | GAP | Remainder mayor domina al ID menor bajo ambos backends del core. | AUTHORED / STATIC-CHECKED / NOT EXECUTED |
| 16 bids válidos | C08 | C08 | GAP | GAP | Aceptación, 16 fills y conservación de supply bajo ambos backends del core. | AUTHORED / STATIC-CHECKED / NOT EXECUTED |
| 0 bids inválidos | C09 | C09 | E02 | GAP | El core revierte bajo ambos backends; E02 cubre además el precheck del adaptador EVM. | AUTHORED / STATIC-CHECKED / NOT EXECUTED |
| 17 bids inválidos | C10 | C10 | E03 | GAP | El core revierte bajo ambos backends; E03 cubre el precheck EVM, no decode-time. | AUTHORED / STATIC-CHECKED / NOT EXECUTED |
| Supply 0 | C11 | C11 | GAP | GAP | El core revierte bajo ambos backends; fronteras de adaptador no cubiertas. | AUTHORED / STATIC-CHECKED / NOT EXECUTED |
| Quantity 0 | C12 | C12 | GAP | GAP | El core revierte bajo ambos backends; fronteras de adaptador no cubiertas. | AUTHORED / STATIC-CHECKED / NOT EXECUTED |
| ID duplicado | C13 | C13 | GAP | GAP | El core revierte determinísticamente bajo ambos backends. | AUTHORED / STATIC-CHECKED / NOT EXECUTED |
| Demanda menor que supply | C14 | C14 | GAP | GAP | El core revierte determinísticamente bajo ambos backends. | AUTHORED / STATIC-CHECKED / NOT EXECUTED |
| `u64::MAX` / `u256::MAX` | C15 | C15 | GAP | GAP | El core preserva exactamente price, supply, filled y quantity bajo ambos backends; fingerprints iguales. | AUTHORED / STATIC-CHECKED / NOT EXECUTED |

## Matriz de límites 0 / 16 / 17

| Cardinalidad | Validez | Core/Sonatina | Core/native | Adaptador EVM | Wrapper native | Expected | Estado |
| ---: | --- | --- | --- | --- | --- | --- | --- |
| 0 | Inválida | C09 `should_revert` | C09 `should_revert` | E02 `should_revert` | GAP | Core revierte bajo ambos backends; EVM rechaza en el handler; no output. | AUTHORED / STATIC-CHECKED / NOT EXECUTED |
| 16 | Válida | C08 | C08 | GAP | GAP | Core acepta bajo ambos backends; 16 fills y suma = supply. Adaptadores no cubiertos para 16. | AUTHORED / STATIC-CHECKED / NOT EXECUTED |
| 17 | Inválida | C10 `should_revert` | C10 `should_revert` | E03 `should_revert` | GAP | Core revierte bajo ambos backends; EVM rechaza antes de la segunda reserva/copia. | AUTHORED / STATIC-CHECKED / NOT EXECUTED |

## Matriz negativa `should_revert`

| Precondición violada | Core/Sonatina | Core/native | Adaptador EVM | Wrapper native | Expected observable | Estado |
| --- | --- | --- | --- | --- | --- | --- |
| 0 bids | C09 | C09 | E02 | GAP | Revert en ambos backends del core y en handler EVM; conservar forma por target. | AUTHORED / STATIC-CHECKED / NOT EXECUTED |
| 17 bids | C10 | C10 | E03 | GAP | Revert en ambos backends del core y en precheck EVM. | AUTHORED / STATIC-CHECKED / NOT EXECUTED |
| Supply 0 | C11 | C11 | GAP | GAP | Revert del core por `supply > 0` bajo ambos backends. | AUTHORED / STATIC-CHECKED / NOT EXECUTED |
| Quantity 0 | C12 | C12 | GAP | GAP | Revert del core por quantity positiva bajo ambos backends. | AUTHORED / STATIC-CHECKED / NOT EXECUTED |
| ID duplicado | C13 | C13 | GAP | GAP | Revert del core por unicidad bajo ambos backends. | AUTHORED / STATIC-CHECKED / NOT EXECUTED |
| Demanda insuficiente | C14 | C14 | GAP | GAP | Revert del core por `total_demand >= supply` bajo ambos backends. | AUTHORED / STATIC-CHECKED / NOT EXECUTED |

C09-C14 comparan la semántica de rechazo del core bajo Sonatina y native. La aceptación de `#[test(should_revert)]` solo prueba que ocurrió un revert; no demuestra la frontera ABI/wrapper donde la tabla marca `GAP`, ni una forma de error estable más allá del rechazo.

## Golden DCG1 / FNV

El golden de C02/E01/N01 debe producir:

- payload DCG1 de `4 + 8 + 32 + 8 + 8 + (4 × 56) = 284` bytes;
- clearing price raw `2000000`;
- filled `7`;
- bids/fills canónicos `[(9,3000000,2,2),(1,2000000,5,3),(2,2000000,5,2),(3,1000000,7,0)]`;
- FNV-1a64 `0xf85927c169cff4f1`.

C02, E01 y N01 comparan el fingerprint, pero ningún test actual expone o aserta directamente la longitud 284. La evidencia de 284 bytes sigue dependiendo del oracle registrado en `GATE-LOG.md:14-16` o de un test dedicado futuro. FNV es un fingerprint de interoperabilidad, no un compromiso criptográfico.

## Orden de ejecución previsto

El orden sigue `GATE-RUNBOOK.md` y es serial:

1. Build del adaptador EVM con Sonatina; no cuenta como test.
2. `CORE-SONATINA`: C01-C15 completos (`20-sonatina-core-tests.log`).
3. Adaptador EVM/Sonatina: E01-E03 (`30-sonatina-adapter-tests.log`).
4. Repetir resource guard antes de la fase native.
5. Build del ejecutable nativo; no cuenta como test.
6. Ejecutar el canario nativo de `main()` sobre el golden (`50-native-run.log`).
7. `CORE-NATIVE`: los mismos C01-C15 completos (`60-native-core-tests.log`).
8. Wrapper nativo: N01 (`70-native-wrapper-tests.log`).
9. Comparar resultados de C01-C15 entre backends, outputs de los adapters donde exista cobertura y reproducir independientemente DCG1 284/FNV.

Un fallo reproducible del core en cualquiera de los dos backends detiene el gate. Un fallo de adaptador no invalida automáticamente el core, pero impide la claim de ese adaptador hasta aislarse. Los `GAP` de adaptador no borran la cobertura cross-backend directa de C01-C15.

## Evidencia mínima por ejecución

Para cambiar cualquier fila desde `NOT EXECUTED`:

1. Registrar commit exacto y confirmar árbol limpio.
2. Registrar binario Fe, versión `26.5.0`, hash `3dab95f`, ingot y backend exactos.
3. Conservar comando literal, UTC de inicio/fin, RC y stdout/stderr completos.
4. Conservar el listado de tests descubiertos para detectar skips o filtros accidentales.
5. Para golden/cross-backend, adjuntar expected y actual de cada campo, los 284 bytes o su dump reproducible y FNV.
6. Para negativos, identificar la precondición, el punto de rechazo y la forma observable por backend.
7. Para máximos, registrar que no hubo truncado, overflow, downcast inesperado ni divergencia de fingerprint.

## Estado de salida

Esta matriz documenta 19 tests fuente actuales: 15 core, 3 EVM y 1 nativo. El plan produce 30 ejecuciones directas del core (C01-C15 bajo Sonatina y de nuevo bajo native), 3 del adaptador EVM y 1 del wrapper nativo, además del canario ejecutable nativo.

Todos permanecen **AUTHORED / STATIC-CHECKED / NOT EXECUTED**. C01-C15 no tienen `GAP` entre backends; los `GAP` restantes describen exclusivamente casos que aún no atraviesan un adaptador concreto.

+
+## Cierre empírico post-window (autoritativo)
+
+The tables above are the pre-execution planning snapshot and retain their
+historical `NOT EXECUTED` labels. They are superseded for the final evaluated
+baseline by this section.
+
+- Baseline: commit `41707de0d43d3e5bdbb412cba839af8724042d12`,
+  tree `7826e05fb6733c546854008e800380f3ea36f206`.
+- C01-C08 and C15 passed under both Sonatina and native.
+- C09-C14 were refactored into portable validation tests named
+  `empty_input_is_invalid`, `seventeen_bids_are_invalid`,
+  `zero_supply_is_invalid`, `zero_quantity_is_invalid`,
+  `duplicate_id_is_invalid`, and `demand_below_supply_is_invalid`.
+  All six passed under both backends.
+- E01-E03 passed under Sonatina.
+- N01 and the standalone native executable passed.
+- Totals: Sonatina core 15/15; EVM adapter 3/3; native core 15/15;
+  native wrapper 1/1; both builds and the native executable RC 0.
+- Evidence: `.gate-artifacts/late-final-20261103T091500Z`; manifest
+  SHA-256 `433baeef5d6083fab32ef301d44a62fa6ea0b0aa79ad994654b17e87c5134a6a`.
+
+Final post-window matrix status: **EXECUTED-PASS / technical GO**.
