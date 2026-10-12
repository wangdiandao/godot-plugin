# Evidence-Based Recovery

Preserve original logs, inputs, and versions first, then narrow the problem using actual errors. Each recovery attempt must explain the observed cause it addresses. Allow at most two automatic recovery attempts for the same failure; stop repeating without new evidence. After fixing your implementation errors, rerun affected checks; do not lower acceptance standards by deleting assertions or ignoring errors.

| Observation | Recovery | Stop condition |
|---|---|---|
| New resources/global types cannot load | Run native import, then load the target again. | Source files are missing or the importer fails. |
| Missing API/signature mismatch | Check class documentation, ClassDB, and bindings for the actual version. | Return unsupported if the current build has no public capability. |
| Nodes/signals missing after saving | Check owner, persistent connections, and instance boundaries. | Existing structure cannot be preserved. |
| Save failure | Check Error, path, and writability; preserve the original. | Insufficient permissions, concurrent changes, or unknown integrity. |
| Process timeout | Preserve logs; terminate this operation's PID; inspect wait conditions. | The same failure persists after two recovery attempts. |
| Insufficient GPU capabilities | Check drivers/renderers and equivalent native alternatives. | Return blocked if alternatives cannot meet the requirements. |
| Missing templates | Verify and prepare official templates for the matching version. | Verification fails or target SDK/signing requirements are missing. |
| Engine startup/shutdown errors | Reproduce in a minimal project, locate the official source, and preserve evidence. | Mark as limited, not passed, when no reliable fix exists. |

Process cleanup may target only still-running PIDs created by this operation; do not kill all Godot processes by name. File recovery may target only paths recorded for this operation. Preserve failed downloads as explicitly marked partial files, not usable templates.

For limited features, continue work that does not depend on them and explain the specific gap and real alternatives. Do not make manual editor clicks the default recovery step.
