require_relative "../test_helpers"

class HelperTester
  include AppHelpers
end

class AppHelpersTest < Minitest::Test
  def setup
    @app_helper = HelperTester.new
  end
  def test_valid_weight_string
    valid = %w[00.0 00,0 85.0 85,0 999.0 999,0]

    valid.each { assert @app_helper.valid_weight_string?(_1) }
  end

  def test_invalid_weight_string
    invalid = %w[0 99 0.00 0,00 85.85 85,85 1000.0 1000,0]

    invalid.each { refute @app_helper.valid_weight_string?(_1) }
  end

  def test_valid_height
    valid = [1, 50, 299]
    valid.each { assert @app_helper.valid_height?(_1) }
  end

  def test_invalid_height
    invalid = [-1, 0, 300, 1000]
  end
end
