# Turtle CPU Project Root Makefile
# Provides convenient targets for testing and development

.PHONY: test test-single test-suite help clean

# Default target
help:
	@echo "Turtle CPU Test Framework"
	@echo "========================"
	@echo ""
	@echo "Available targets:"
	@echo "  test          - Run the full test suite (default)"
	@echo "  test-single   - Test a single file (use TEST_FILE=path/to/file.asm)"
	@echo "  test-suite    - Run the full test suite"
	@echo "  clean         - Clean test framework debug output"
	@echo "  help          - Show this help"
	@echo ""
	@echo "Examples:"
	@echo "  make test"
	@echo "  make test-single TEST_FILE=../turtle-toolkit/examples/load_store_different_address.asm"
	@echo "  make test-single TEST_FILE=integration/test_programs/test_fixed.asm"
	@echo "  make clean"

# Default test target
test: test-suite

# Test a single file
test-single:
ifndef TEST_FILE
	@echo "Error: TEST_FILE not specified"
	@echo "Usage: make test-single TEST_FILE=path/to/file.asm"
	@exit 1
endif
	cd .. && poetry run python tests/integration/test_framework.py --test-file $(TEST_FILE) $(if $(TEST_NAME),--test-name $(TEST_NAME))

# Run the full test suite
test-suite:
	cd .. && poetry run python tests/integration/test_framework.py --test-suite

# Clean test framework debug output
clean:
	@echo "Cleaning test framework debug output..."
	rm -rf integration/debug_output/*
	@echo "✅ Cleaned test framework debug output"
