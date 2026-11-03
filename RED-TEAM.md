# Red Team post-H0

- Fecha de revisión: `2026-11-03T03:49:53Z`.
- Baseline revisada: `6ebc479d8d0fed0505606b4e97f5f60cdcb24862`.
- Alcance: revisión estática del core compartido y de los adaptadores EVM y nativo.
- Método: lectura de fuentes, documentación, historial y evidencia registrada. Esta revisión no ejecutó compilación ni tests.
- Estado de gate: **HOLD**.
- S0 estáticos abiertos: **ninguno identificado**.

## Dictamen ejecutivo

La separación entre un core determinista y dos adaptadores finos es coherente y los hardenings existentes no introducen un S0 estático. Sin embargo, los `fe check` ya registrados no prueban que los artefactos se construyan ni que los tests se ejecuten correctamente en ambos targets. El gate no puede pasar a `GO` hasta disponer de esa evidencia para EVM y nativo y cerrar o aceptar expresamente los S1 residuales descritos abajo.

## Revisión técnica

- El workspace declara un único core y dos ingots dependientes (`gate/fe.toml:1-8`); ambos adaptadores delegan en `dualclear_core::clear` (`gate/evm/src/lib.fe:42`, `gate/native/src/lib.fe:4-6`). Esto reduce el riesgo de divergencia algorítmica.
- El adaptador EVM comprueba `1..=MAX_BIDS` antes de crear la segunda `MemVec` y copiar (`gate/evm/src/lib.fe:25-40`). La comprobación no limita la materialización previa del `DynArray` por el decoder tipado.
- El adaptador nativo es un wrapper directo y conserva la misma estructura de salida (`gate/native/src/lib.fe:4-6`). Su canario y su test usan el mismo golden (`gate/native/src/lib.fe:8-45`).
- El core valida cardinalidad, supply, cantidades positivas, IDs únicos y demanda suficiente mediante `core::assert` (`gate/core/src/lib.fe:168-190`). Esa política de error aún no está caracterizada por target.
- Los acumulados, productos de prorrata y comprobaciones de conservación se elevan a `u256` (`gate/core/src/lib.fe:174-189`, `240-267`), lo que evita depender de suma o multiplicación en `u64` para los casos extremos previstos.

## Revisión algorítmica y de seguridad

- El ranking es precio descendente e ID ascendente; la cantidad solo actúa como desempate tras un ID que contractualmente debe ser único (`gate/core/src/lib.fe:25-51`, `177-183`).
- El clearing localiza el grupo marginal y reparte su remanente por largest remainder (`gate/core/src/lib.fe:192-258`). Los remainders mayores preceden y, en igualdad, gana el ID menor (`gate/core/src/lib.fe:74-100`).
- Las invariantes de salida se comprueban internamente: ningún fill excede su bid y la suma de fills coincide con supply (`gate/core/src/lib.fe:260-267`).
- La serialización DCG1 usa dominio y anchos fijos (`gate/core/src/lib.fe:122-154`; `README.md:27-41`). La especificación permite reproducir el golden de 284 bytes.
- FNV-1a64 usa multiplicación modular intencionada (`gate/core/src/lib.fe:156-166`). Es útil para interoperabilidad, pero no aporta resistencia a colisiones y no puede sostener una afirmación de integridad adversarial.

## Revisión de concurso

- Upside: un algoritmo no trivial, determinista y compartido entre targets demuestra una capacidad de Fe más amplia que dos demos independientes.
- Riesgo principal: afirmar soporte dual antes de tener build y test reales en ambos backends. El ledger solo registra `fe check` con RC 0 y deja ambos build/test pendientes (`GATE-LOG.md:25-32`).
- La demo debe presentar FNV exclusivamente como fingerprint reproducible y la ABI EVM como interfaz acotada en el handler, no como protección de decode-time.
- Cualquier submission debe separar hechos ejecutados de garantías inferidas estáticamente y conservar los logs verificables del gate.

## Hallazgos corregidos

| ID | Corrección observada | Evidencia |
| --- | --- | --- |
| RT-FIX-01 | Core único compartido; no hay duplicación del clearing en adaptadores. | `gate/evm/src/lib.fe:42`; `gate/native/src/lib.fe:4-6` |
| RT-FIX-02 | Precheck EVM antes de la segunda reserva/copia. | `gate/evm/src/lib.fe:25-40` |
| RT-FIX-03 | Wrapper nativo explícito y test del golden. | `gate/native/src/lib.fe:4-45` |
| RT-FIX-04 | Cobertura fuente para bid único, demanda exacta, mismo precio, empate de remainder/ID, remainder desigual y máximo de 16 bids. | `gate/core/src/lib.fe:350-439` |
| RT-FIX-05 | DCG1 queda especificado y FNV queda limitado a uso no criptográfico. | `README.md:27-43`; `gate/core/src/lib.fe:156-157` |
| RT-FIX-06 | Los tres ingots pasan comprobación estática según el ledger. | `GATE-LOG.md:25-28` |

## S1 residuales

### S1-RT-01 — La ABI tipada materializa antes del handler

`Clear` recibe un `DynArray<BidInput>` (`gate/evm/src/lib.fe:16-19`). Cuando el precheck de `gate/evm/src/lib.fe:26` se ejecuta, el decoder ABI ya ha materializado el array, como reconoce `README.md:13-15`. El límite protege la segunda reserva/copia, pero no el coste de decode-time ni un calldata sobredimensionado.

Cierre requerido: medir o demostrar el comportamiento con 0, 16 y más de 16 elementos, registrar gas/memoria o rechazo observado, y mantener esta limitación en la narrativa. Si el target permite una entrada raw acotada antes de decodificar, evaluarla como hardening posterior; no es condición automática de GO si el alcance se declara con precisión.

### S1-RT-02 — FNV no es un compromiso seguro

El fingerprint de 64 bits es colisionable por diseño. La documentación ya lo advierte (`README.md:40-43`), pero el valor sigue formando parte de la salida pública (`gate/evm/src/lib.fe:51`, `gate/core/src/lib.fe:57-62`). Un integrador podría darle una semántica de identidad o integridad que no tiene.

Cierre requerido: ninguna decisión de autorización, unicidad, deduplicación adversarial o prueba debe depender solo de FNV. La demo y cualquier API deben llamarlo fingerprint de interoperabilidad; una necesidad criptográfica exige otro digest.

### S1-RT-03 — Asserts y errores dependen del target

Las precondiciones usan `core::assert` sin un error tipado compartido (`gate/core/src/lib.fe:171-189`). Falta evidencia de la forma concreta de fallo en EVM y nativo: revert/panic, datos de error, código de salida y ausencia de resultado parcial. La equivalencia del happy path no demuestra equivalencia de errores.

Cierre requerido: ejecutar la matriz negativa en cada backend, registrar el efecto observable y decidir si el contrato público promete solo rechazo o también una forma de error estable.

### S1-RT-04 — Casos inválidos y extremos aún no están ejecutados

Existen tests fuente para bordes positivos (`gate/core/src/lib.fe:350-439`), pero el ledger declara que no se ejecutó ningún test (`GATE-LOG.md:29-31`). Tampoco hay evidencia ejecutada para array vacío o mayor que 16, supply cero, quantity cero, ID duplicado, demanda menor que supply, cantidades/supply cercanos a `u64::MAX`, precio raw cercano a `u256::MAX` y combinaciones que estresen producto, downcast y canonicalización.

Cierre requerido: ejecutar esos casos en core y, donde aplique, a través de ambos adaptadores; conservar expected/actual, RC y logs. Los casos inválidos deben terminar de forma acotada y sin salida parcial.

## Gate exacto

### Estado actual: HOLD

El estado permanece `HOLD` porque `GATE-LOG.md:25-28` prueba solo fmt/check y `GATE-LOG.md:29-32` mantiene build, tests y decisión pendientes. Ningún resultado estático convierte ese estado en `GO`.

### GO

`GO` requiere simultáneamente:

1. Build EVM y build nativo con RC 0 usando Fe 26.5.0, commit de toolchain `3dab95f`.
2. Tests de core, EVM y nativo con RC 0, incluidos golden, permutación, largest remainder, desempates, 1 bid y 16 bids.
3. Matriz inválida/extrema ejecutada y semántica de rechazo documentada en ambos targets.
4. Igualdad cross-backend para el corpus compartido: clearing price, filled, orden y cantidades de fills, bytes DCG1 y fingerprint.
5. Golden reproducido como 284 bytes y FNV-1a64 `0xf85927c169cff4f1`.
6. Ningún S0 y ningún S1 que contradiga las claims de la submission; ABI y FNV quedan descritos con sus límites reales.
7. Evidencia completa, fechada y ligada al commit exacto evaluado.

### PLAN B

`PLAN B` procede solo si el core y exactamente un backend tienen build y tests completos con RC 0, y el fallo restante se demuestra aislado al adaptador/toolchain del otro target. La submission se reduce explícitamente al backend probado, se retira toda claim dual y se conserva la misma especificación determinista. Un fallo de invariantes del core, arithmetic safety o canonicalización nunca es `PLAN B`.

### KILL

`KILL` procede ante cualquiera de estos hechos:

- fallo de conservación, `fill <= bid`, ranking, clearing price, largest remainder, desempate o determinismo por permutación;
- divergencia entre backends o entre DCG1 y el golden que no pueda aislarse a un adaptador descartable;
- overflow, downcast, panic o assert inesperado en entradas válidas/extremas;
- imposibilidad de construir y ejecutar al menos un backend con evidencia reproducible dentro del gate;
- dependencia de FNV como garantía de seguridad o claim de protección decode-time que el diseño no ofrece;
- evidencia o procedencia insuficiente para defender que el trabajo y sus resultados cumplen las reglas del concurso.

## Evidencia requerida para levantar HOLD

1. Commit exacto, árbol limpio, versión/hash de Fe, target, comando literal, UTC de inicio/fin y RC de cada ejecución.
2. Logs completos de build y test para core, EVM y nativo; warnings y skips deben quedar visibles.
3. Hashes y rutas de los artefactos producidos por cada backend.
4. Tabla de casos con input, expected, actual y resultado para happy path, bordes positivos, inválidos y extremos.
5. Comparación cross-backend del mismo corpus y reproducción independiente de DCG1 284 bytes/FNV golden.
6. Evidencia observable de errores por target para cada precondición de `gate/core/src/lib.fe:171-189` y para el límite EVM.
7. Registro final de S0/S1: cerrado, aceptado con claim limitada o causa exacta de `PLAN B`/`KILL`.

## Pre-execution conclusion (superseded)

No se identifica un S0 estático nuevo. El hardening mejora la calidad del candidato y mantiene un camino plausible a `GO`, pero el dictamen sigue siendo `HOLD`: solo la ejecución satisfactoria y reproducible de ambos backends, junto con la matriz negativa/extrema, permite levantarlo.

The empirical closure below supersedes this historical HOLD.

## Red Team closure after empirical execution

- **S0:** none open on the evaluated commit `41707de`.
- The initial invalid-opcode rejection was reproduced, classified, and fixed
  by using proper assertions and then a portable validation predicate.
- Sonatina and native executed the same 15-case core corpus successfully,
  including golden, permutation, both remainder tie-break paths, cardinality
  0/16/17, invalid supply/quantity/IDs/demand, and maximum u64/u256 values.
- Both adapters and the standalone native canary passed. No cross-backend
  divergence was observed in clearing price, fills, order, conservation, or
  the golden fingerprint.
- **S2 API limitation:** native invalid direct calls trap; callers have an
  explicit `valid_input` preflight. Prefer a typed `Result` API before a
  production-quality native integration.
- **S2 trust-model limitation:** IDs break equal-remainder ties. The trusted
  venue/batch builder must assign unique IDs under a deterministic policy;
  bidder-chosen IDs would make the tie-break strategically selectable.
- **S2 claim limits:** FNV is not a security commitment; EVM cardinality checks
  do not protect the ABI decoder from pre-materialization cost; and the
  four-bid 284-byte golden is fixed indirectly by format plus fingerprint, not
  shipped as a standalone byte-vector fixture.
- Exact invocation templates are in `GATE-RUNBOOK.md`; final logs preserve
  timestamps, results and return codes, while manifests bind inputs/outputs.

Red Team technical verdict: **GO**, with those claims and native API
hardening kept visible.
