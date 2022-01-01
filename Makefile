clean:
	mix deps.clean --unlock --unused

deep-clean:
	rm -rf _build
	rm -rf deps

format:
	mix format --check-formatted || mix format

force-format:
	find test -name '*.ex' -o -name '*.exs' | mix format --check-formatted || mix format
	find lib -name '*.ex' -o -name '*.exs' | mix format --check-formatted || mix format

gcdeps:
	mix deps.get && mix deps.compile

dev:
	MIX_ENV=dev iex -S mix phx.server

credo:
	mix credo --strict

dialyzer:
	MIX_DEBUG=1 mix dialyzer --ignore-exit-status --cache=false

dev-console:
	MIX_ENV=dev iex -S mix

test-console:
	MIX_ENV=test iex -S mix
