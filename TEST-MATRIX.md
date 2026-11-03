# DualClear — matriz de tests post-H0

- Fecha de corte: `2026-11-03T04:12:39Z`.
- Baseline inventariada: `5d27a5ddd10f51e831bdce3fc5f545cf5be05130`.
- Toolchain objetivo: Fe 26.5.0, commit `3dab95f`.
- Estado global: **AUTHORED / STATIC-CHECKED / NOT EXECUTED**.
- Regla de evidencia: ningún caso cambia a `EXECUTED-PASS` o `EXECUTED-FAIL` sin comando literal, UTC, commit, target, RC y log conservado.

## Semántica de estados

- `AUTHORED`: el test fuente existe cuando se cita un símbolo; en matrices de cobertura, la especificación del caso está escrita aunque una celda pueda indicar `GAP` de implementación.
- `STATIC-CHECKED`: nombre, input, assertions y resultado esperado se revisaron contra el código actual. No significa que se haya invocado el compilador ni el test runner sobre esta baseline.
- `NOT EXECUTED`: no existe evidencia de ejecución para esta baseline. `GATE-LOG.md:29-31` mantiene build/test EVM y nativo pendientes.
- `GAP`: no hay test fuente actual para ese caso/backend. Un `GAP` no puede presentarse como cobertura ejecutada.

Todos los casos y especificaciones de este documento permanecen **AUTHORED / STATIC-CHECKED / NOT EXECUTED** hasta que se adjunte la evidencia definida al final.

## Inventario actual — ingot `dualclear_core`

Backend de ejecución previsto: test runner del ingot core compartido. Sus resultados son prerrequisito para EVM y nativo, pero no sustituyen los tests de adaptador.

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

Backend de ejecución previsto: harness EVM del ingot y llamada ABI a `DualClearGate`.

| ID | Test fuente | Requisito/caso | Resultado esperado | Estado |
| --- | --- | --- | --- | --- |
| E01 | `evm_adapter_matches_the_shared_golden` (`gate/evm/src/lib.fe:57-84`) | Deploy, encode ABI, ejecutar golden y decodificar output. | Price `2000000`, filled `7`, FNV `0xf85927c169cff4f1`, fills `[(9,2),(1,3),(2,2),(3,0)]`. | AUTHORED / STATIC-CHECKED / NOT EXECUTED |
| E02 | `evm_handler_precheck_rejects_empty_bids` (`:86-99`) | ABI con 0 bids. `#[test(should_revert)]`. | Revert del handler por límite inferior. | AUTHORED / STATIC-CHECKED / NOT EXECUTED |
| E03 | `evm_handler_precheck_rejects_seventeen_bids` (`:101-120`) | ABI con 17 bids. `#[test(should_revert)]`. | Revert del handler por límite superior antes de la segunda `MemVec`. | AUTHORED / STATIC-CHECKED / NOT EXECUTED |

Nota: E02/E03 validan el precheck del handler, no una cota de materialización del `DynArray` durante decode-time.

## Inventario actual — ingot `dualclear_native`

Backend de ejecución previsto: test runner nativo; el mismo canario también alimenta `main()`.

| ID | Test fuente | Requisito/caso | Resultado esperado | Estado |
| --- | --- | --- | --- | --- |
| N01 | `native_adapter_matches_the_shared_golden` (`gate/native/src/lib.fe:42-45`) | Ejecutar el wrapper nativo sobre el golden compartido. | `native_golden_matches()` es true: price `2000000`, filled `7`, FNV `0xf85927c169cff4f1`, fills `[(9,2),(1,3),(2,2),(3,0)]`. | AUTHORED / STATIC-CHECKED / NOT EXECUTED |

## Matriz cross-backend

Cada fila especifica el corpus que debe compararse. Una referencia C/E/N indica test fuente actual; `GAP` exige autoría futura antes de poder afirmar cobertura de ese backend.

| Caso | Core | EVM | Nativo | Igualdad/expected cross-backend | Estado |
| --- | --- | --- | --- | --- | --- |
| Golden 4 bids | C02 | E01 | N01 | Price, filled, orden/fills y FNV exactamente iguales. DCG1 canónico: 284 bytes; FNV `0xf85927c169cff4f1`. | AUTHORED / STATIC-CHECKED / NOT EXECUTED |
| Permutación del golden | C03 | GAP | GAP | Misma salida y fingerprint sin depender del orden de entrada. | AUTHORED / STATIC-CHECKED / NOT EXECUTED |
| Un bid / demanda exacta | C04 | GAP | GAP | Aceptación y fill completo idénticos. | AUTHORED / STATIC-CHECKED / NOT EXECUTED |
| Todos al mismo precio | C05 | GAP | GAP | Misma prorrata, conservación y orden por ID. | AUTHORED / STATIC-CHECKED / NOT EXECUTED |
| Remainder igual | C06 | GAP | GAP | ID menor obtiene el asiento residual en todos los targets. | AUTHORED / STATIC-CHECKED / NOT EXECUTED |
| Remainder desigual | C07 | GAP | GAP | Remainder mayor domina al ID menor en todos los targets. | AUTHORED / STATIC-CHECKED / NOT EXECUTED |
| 16 bids válidos | C08 | GAP | GAP | Aceptación, 16 fills y conservación de supply. | AUTHORED / STATIC-CHECKED / NOT EXECUTED |
| 0 bids inválidos | C09 | E02 | GAP | Rechazo; registrar forma observable por target. | AUTHORED / STATIC-CHECKED / NOT EXECUTED |
| 17 bids inválidos | C10 | E03 | GAP | Rechazo; EVM demuestra precheck del handler, no decode-time. | AUTHORED / STATIC-CHECKED / NOT EXECUTED |
| Supply 0 | C11 | GAP | GAP | Rechazo sin resultado parcial. | AUTHORED / STATIC-CHECKED / NOT EXECUTED |
| Quantity 0 | C12 | GAP | GAP | Rechazo sin resultado parcial. | AUTHORED / STATIC-CHECKED / NOT EXECUTED |
| ID duplicado | C13 | GAP | GAP | Rechazo determinista. | AUTHORED / STATIC-CHECKED / NOT EXECUTED |
| Demanda menor que supply | C14 | GAP | GAP | Rechazo determinista. | AUTHORED / STATIC-CHECKED / NOT EXECUTED |
| `u64::MAX` / `u256::MAX` | C15 | GAP | GAP | Preservación exacta de price, supply, filled y quantity; fingerprints iguales para el mismo input. | AUTHORED / STATIC-CHECKED / NOT EXECUTED |

## Matriz de límites 0 / 16 / 17

| Cardinalidad | Validez | Core | EVM | Nativo | Expected | Estado |
| ---: | --- | --- | --- | --- | --- | --- |
| 0 | Inválida | C09 `should_revert` | E02 `should_revert` | GAP | Rechazo acotado; no output. | AUTHORED / STATIC-CHECKED / NOT EXECUTED |
| 16 | Válida | C08 | GAP | GAP | Aceptación; fills len 16; suma de fills = supply. | AUTHORED / STATIC-CHECKED / NOT EXECUTED |
| 17 | Inválida | C10 `should_revert` | E03 `should_revert` | GAP | Rechazo; en EVM ocurre antes de la segunda reserva/copia. | AUTHORED / STATIC-CHECKED / NOT EXECUTED |

## Matriz negativa `should_revert`

| Precondición violada | Test actual | Backends previstos con test actual | Backend pendiente | Expected observable | Estado |
| --- | --- | --- | --- | --- | --- |
| 0 bids | C09, E02 | core, EVM | nativo | Test runner acepta el revert; conservar causa/forma por target. | AUTHORED / STATIC-CHECKED / NOT EXECUTED |
| 17 bids | C10, E03 | core, EVM | nativo | Test runner acepta el revert; EVM rechaza en precheck del handler. | AUTHORED / STATIC-CHECKED / NOT EXECUTED |
| Supply 0 | C11 | core | EVM, nativo | Revert por `supply > 0`. | AUTHORED / STATIC-CHECKED / NOT EXECUTED |
| Quantity 0 | C12 | core | EVM, nativo | Revert por quantity positiva. | AUTHORED / STATIC-CHECKED / NOT EXECUTED |
| ID duplicado | C13 | core | EVM, nativo | Revert por unicidad. | AUTHORED / STATIC-CHECKED / NOT EXECUTED |
| Demanda insuficiente | C14 | core | EVM, nativo | Revert por `total_demand >= supply`. | AUTHORED / STATIC-CHECKED / NOT EXECUTED |

La aceptación de `#[test(should_revert)]` solo prueba que ocurrió un revert. La evidencia de gate debe capturar además si EVM y nativo exponen panic/revert/código de salida diferentes y confirmar ausencia de output parcial.

## Golden DCG1 / FNV

El golden de C02/E01/N01 debe producir:

- payload DCG1 de `4 + 8 + 32 + 8 + 8 + (4 × 56) = 284` bytes;
- clearing price raw `2000000`;
- filled `7`;
- bids/fills canónicos `[(9,3000000,2,2),(1,2000000,5,3),(2,2000000,5,2),(3,1000000,7,0)]`;
- FNV-1a64 `0xf85927c169cff4f1`.

C02, E01 y N01 comparan el fingerprint, pero ningún test actual expone o aserta directamente la longitud 284. La evidencia de 284 bytes sigue dependiendo del oracle registrado en `GATE-LOG.md:14-16` o de un test dedicado futuro. FNV es un fingerprint de interoperabilidad, no un compromiso criptográfico.

## Orden de ejecución previsto

1. Core completo C01-C15, incluidos todos los `should_revert`.
2. EVM E01-E03.
3. Nativo N01.
4. Tras cubrir los `GAP`, repetir el mismo corpus en EVM y nativo y comparar outputs campo por campo.
5. Ejecutar una reproducción independiente de los 284 bytes DCG1 y su FNV.

Un fallo de core detiene los adaptadores. Un fallo de adaptador no invalida automáticamente el core, pero impide una claim cross-backend hasta aislarse.

## Evidencia mínima por ejecución

Para cambiar cualquier fila desde `NOT EXECUTED`:

1. Registrar commit exacto y confirmar árbol limpio.
2. Registrar binario Fe, versión `26.5.0`, hash `3dab95f` y target.
3. Conservar comando literal, UTC de inicio/fin, RC y stdout/stderr completos.
4. Conservar el listado de tests descubiertos para detectar skips o filtros accidentales.
5. Para golden/cross-backend, adjuntar expected y actual de cada campo, los 284 bytes o su dump reproducible y FNV.
6. Para negativos, identificar la precondición, el punto de rechazo y la forma observable por backend.
7. Para máximos, registrar que no hubo truncado, overflow, downcast inesperado ni divergencia de fingerprint.

## Estado de salida

Esta matriz documenta 19 tests fuente actuales: 15 core, 3 EVM y 1 nativo. Todos están **AUTHORED / STATIC-CHECKED / NOT EXECUTED**. Los `GAP` cross-backend son explícitos y no cuentan como tests implementados ni ejecutados.
