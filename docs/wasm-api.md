# WebAssembly and FFI API

This document describes the intended host contract of the WASI reactor produced by the project.

> **Status:** experimental. The repository contains the exported Haskell functions and a CI build workflow, but no canonical host wrapper is included. Treat the JavaScript below as pseudocode until it is tested against the exact published artifact.

## Build artifact

The GitHub Actions workflow `.github/workflows/engine-wasm.yml`:

1. runs the native property-based test suite;
2. installs the GHC WASM toolchain;
3. configures a WASI reactor build;
4. builds `exe:Engine`;
5. copies the resulting file to `Engine.wasm`; and
6. uploads it as an artifact.

The workflow is currently triggered with `workflow_dispatch`, so it should not be described as running automatically for every pull request.

## Intended exports

The build configuration requests these exports:

- `run_decomposition`
- `free_haskell_string`
- `hs_init`
- `malloc`
- `free`

The exact final export list should be checked on every published artifact because it is determined by the toolchain and linker configuration.

## Application functions

The two project-defined functions are conceptually equivalent to:

```c
// input_json points to a NUL-terminated JSON string.
// The returned pointer refers to a newly allocated NUL-terminated JSON string.
char *run_decomposition(const char *input_json);

// Releases a pointer returned by run_decomposition.
void free_haskell_string(char *output_json);
```

Their Haskell definitions are:

```haskell
run_decomposition :: CString -> IO CString
free_haskell_string :: CString -> IO ()
```

## Input contract

`run_decomposition` expects:

- a non-null pointer in the module's linear memory;
- a NUL-terminated string;
- a JSON payload matching `IncomingGraphDto`; and
- semantically valid graph data as described in [json-api.md](json-api.md).

The current implementation calls `peekCString`, packs the resulting Haskell `String` with the lazy `ByteString.Char8` interface, and passes it to Aeson. Input keys and numeric data are ASCII-safe. Behavior for arbitrary non-ASCII text has not been established and should not be advertised without an integration test.

## Output contract

On a successful call, `run_decomposition` returns a pointer to a NUL-terminated JSON string allocated with `newCString`.

The host must:

1. copy or decode the output while the pointer is valid;
2. call `free_haskell_string(outputPtr)` exactly once; and
3. never use the pointer again after it has been freed.

Malformed JSON is intended to return an error object as described in [json-api.md](json-api.md). The current error string is assembled without JSON escaping, so some decoder messages can produce an invalid JSON payload. Not every semantic or runtime failure is converted to JSON; a WASM trap also remains possible.

## Runtime initialization

The module is built as a GHC/WASI reactor. Haskell runtime initialization is toolchain-specific. The host must initialize the runtime using the protocol required by the exact GHC WASM release and loader used to build the artifact.

Do not publish a bare `hs_init()` call signature unless it has been verified against that artifact. A wrapper supplied by the GHC WASM toolchain may need to prepare arguments, reactor state, or WASI imports.

The release documentation should record:

- the GHC WASM toolchain revision;
- the required WASI imports;
- the runtime initialization sequence;
- whether initialization is performed once per instance; and
- whether an instance can process multiple calls safely.

## Host call sequence

A host integration generally follows this sequence:

1. Instantiate the WASM module with the required WASI imports.
2. Initialize the Haskell runtime.
3. Serialize the graph with `JSON.stringify` or an equivalent serializer.
4. UTF-8 encode the payload and append a zero byte.
5. Allocate input memory using the module's compatible allocator.
6. Copy the bytes into linear memory.
7. Call `run_decomposition(inputPtr)`.
8. Read the NUL-terminated output string.
9. Parse the JSON and check for an `error` field.
10. Free the returned pointer with `free_haskell_string`.
11. Free the input allocation using the allocator paired with the allocation step.

## Host pseudocode

The following code intentionally leaves loader-specific functions abstract:

```javascript
const instance = await loadEngineWasm();
const api = instance.exports;

await initializeHaskellRuntime(instance);

function decomposeGraph(graph) {
  const inputText = JSON.stringify(graph);
  const inputPtr = writeCString(api.memory, api.malloc, inputText);

  let outputPtr = 0;

  try {
    outputPtr = api.run_decomposition(inputPtr);

    if (outputPtr === 0) {
      throw new Error("The engine returned a null output pointer");
    }

    const outputText = readCString(api.memory, outputPtr);
    const output = JSON.parse(outputText);

    if (output.error) {
      throw new Error(output.error);
    }

    return output;
  } finally {
    if (outputPtr !== 0) {
      api.free_haskell_string(outputPtr);
    }
    api.free(inputPtr);
  }
}
```

`loadEngineWasm`, `initializeHaskellRuntime`, `writeCString`, and `readCString` are placeholders. Their correct implementation depends on the host and toolchain.

## Memory rules

- Allocate and free memory with compatible functions from the same module or runtime.
- Do not free the output with plain `free` unless the implementation contract explicitly changes to allow it.
- Do not call `free_haskell_string` on the input pointer.
- Do not call `free_haskell_string` twice.
- Copy output before freeing it.
- Recreate typed-array views after memory growth, because a previous view may no longer cover the current buffer.
- Check allocation and returned pointers for zero when the host wrapper supports that failure mode.

## Error handling

Host code should distinguish:

1. **Instantiation errors:** missing WASI imports or incompatible artifact.
2. **Runtime initialization errors:** Haskell RTS not initialized correctly.
3. **Allocation errors:** input memory could not be reserved.
4. **Decode errors:** returned JSON contains `error`.
5. **Semantic input errors:** currently not reliably represented by structured JSON.
6. **WASM traps:** uncaught runtime failures, including invalid empty input states.
7. **Host parse errors:** returned bytes are not valid JSON or text.

## Concurrency and reentrancy

The repository does not document whether one WASM instance is safe for overlapping calls. Until verified:

- serialize calls per instance;
- initialize the runtime once;
- do not share raw pointers between calls; and
- create separate instances if the host requires true parallel execution.

## Release verification checklist

Before publishing a WASM release:

- [ ] Run the native test suite.
- [ ] Build the reactor from a clean checkout.
- [ ] Inspect the final export list.
- [ ] Instantiate the artifact in the supported host.
- [ ] Execute the conservative path example.
- [ ] Execute the circulation example.
- [ ] Execute a malformed-JSON example.
- [ ] Confirm that repeated calls do not leak output strings.
- [ ] Record the toolchain revision and host requirements.
- [ ] Update this document if any symbol or initialization step changed.