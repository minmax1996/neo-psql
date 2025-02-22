.PHONY: test
test:
	nvim --headless -c "PlenaryBustedFile lua/tests/neo_psql_spec.lua"