# {{ repo_name }}

{{ description }}

## Usage

Declare as a `library: true` catalog entry in your archetype:

```yaml
catalog:
  {{ archetype_name }}:
    source: "<source-url>"
    library: true
```

Then use `require("{{ archetype_name }}.<module>")` for Lua modules
or `{{ LS }} include "{{ archetype_name }}/<partial>.atl" {{ RS }}` for template partials.

## Author

{{ author_full }}
