Tests can be run offline simply via: `nvim -l test/run.lua`.
To run a particular test file, for debugging purposes, follow these steps:
- Generate the fixtures: `nvim -l test/genfixtures.lua`
- Run the test setup, e.g `nvim --headless -n -u test/init-pckr.lua -c quit`
- Run the main test file, e.g. `nvim -u -n test/test-pckr.lua`
