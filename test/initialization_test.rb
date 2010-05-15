require File.join(File.dirname(__FILE__), 'test_helper')

class InitializationTest < Test::Unit::TestCase
  def test_init
    assert_equal 0, Siren::C.InitDSPSystem, "Expected InitDSPSystem to return 0 for success."
  end
end
  
