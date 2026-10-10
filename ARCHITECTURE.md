# Architecture Overview

This document outlines the architecture and foundational technology stack for the application.

## Core Technologies

*   **Language**: Vanilla JavaScript (ES Modules).
*   **Editor**: [Quill](https://quilljs.com/) is used for the core WYSIWYG editor functionality, providing rich text capabilities (headers, formatting, images, code blocks).
*   **Build Tool**: [Vite](https://vitejs.dev/) is used for fast development and building the application.

## Testing Strategy

*   **Framework**: [Vitest](https://vitest.dev/) is used as the test runner.
*   **DOM Environment**: [JSDOM](https://github.com/jsdom/jsdom) is used to simulate the browser environment for testing DOM interactions.
*   **Test Setup**: Test files interacting with the DOM include the `/** @vitest-environment jsdom */` pragma at the top of the file.

## Continuous Integration

*   **CI Provider**: GitHub Actions is used for continuous integration.
*   **Workflows**: The `.github/workflows/ci.yml` workflow runs on every push and pull request to the `main` branch. It ensures that the application builds and all tests pass using the `npm test` command.

## Core Components

### `VaultNotes` (`src/VaultNotes.js`)

This is the main class responsible for managing the editor instance. It:
*   Initializes a Quill editor within a specified container.
*   Configures a default toolbar (headers, bold, italic, underline, image, code-block).
*   Provides methods to retrieve content (`getText`, `getHTML`).
*   Provides a method to extract `#tags` from the plain text (`extractTags`).
