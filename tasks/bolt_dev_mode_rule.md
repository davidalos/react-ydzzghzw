# ⚙️ Bolt Development Mode Rule

When executing Bolt tasks in **test** or **development** mode, always preserve the real production code used for the final build.

1. **Save Production Code**: Before applying any temporary test modifications (such as CAPTCHA bypass), commit or copy the current production-ready code.
2. **Run Tests Safely**: Perform your development or test run. If the flow works, continue.
3. **Restore Production State**: After testing, immediately restore the saved code so the repository reflects the functional version that will be built.
4. **Follow KEYBRIDGE Codex**: Ensure these steps respect `tasks/keybridge_sync.md` and any other Codex rules throughout the project.

This rule keeps development experiments from polluting the final build while remaining compliant with the KEYBRIDGE platform sync protocol.
