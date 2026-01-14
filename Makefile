
.DEFAULT_GOAL := run

.PHONY: run
run:
	@./.launch.sh

# Ignore other make goals so extra words are passed as args instead of treated as targets
m:
	@./.launch.sh m

b:
	@./.launch.sh b



