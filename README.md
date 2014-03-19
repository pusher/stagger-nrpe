# stagger-nrpe

An NRPE daemon for testing stagger reported values

## Invocation

`bin/stagger_nrpe_server [definition dir]`

## Definition files

Ruby scripts, by default loaded from `/etc/stagger-nrpe.d/*.rb`

```ruby
$DEFS.define(check_name, metric_name) { |metric_value|
  return [:warning, "There was a warning"]
}
```
