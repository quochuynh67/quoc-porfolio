# Application architecture

The project is migrating incrementally to a feature-first structure:

```text
lib/
  app/                 application root, theme and bootstrap UI
  core/                configuration, navigation, logging and platform seams
  features/<feature>/
    domain/            immutable business models and rules
    data/              static catalogs, gateways and data sources
    application/       controllers and use cases
    presentation/      pages and widgets
```

Rules:

- Presentation code does not read environment variables or privileged keys.
- Domain models do not import Flutter, browser APIs or plugins.
- Platform APIs (`dart:html`, FFmpeg, file picker) stay behind core/data seams.
- Navigation uses typed destinations instead of feature-owned page indexes.
- Static catalogs are immutable; remote data access goes through a gateway.
- UI displays safe messages and never logs tokens, passwords or raw auth data.
- New features follow this layout; legacy `view/` code is migrated in small,
  buildable steps rather than through a risky full rewrite.
