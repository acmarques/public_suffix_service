require 'test_helper'

class PublicSuffixService::RuleTest < Test::Unit::TestCase

  def test_factory_should_return_rule_normal
    rule = PublicSuffixService::Rule.factory("com")
    assert_instance_of PublicSuffixService::Rule::Normal, rule

    rule = PublicSuffixService::Rule.factory("verona.it")
    assert_instance_of PublicSuffixService::Rule::Normal, rule
  end

  def test_factory_should_return_rule_exception
    rule = PublicSuffixService::Rule.factory("!british-library.uk")
    assert_instance_of PublicSuffixService::Rule::Exception, rule
  end

  def test_factory_should_return_rule_wildcard
    rule = PublicSuffixService::Rule.factory("*.do")
    assert_instance_of PublicSuffixService::Rule::Wildcard, rule

    rule = PublicSuffixService::Rule.factory("*.sch.uk")
    assert_instance_of PublicSuffixService::Rule::Wildcard, rule
  end

end


class PublicSuffixService::RuleBaseTest < Test::Unit::TestCase

  class ::PublicSuffixService::Rule::Test < ::PublicSuffixService::Rule::Base
  end

  def setup
    @klass = PublicSuffixService::Rule::Base
  end


  def test_initialize
    rule = @klass.new("verona.it")
    assert_instance_of @klass,          rule

    assert_equal :base,                 rule.type
    assert_equal "verona.it",           rule.name
    assert_equal "verona.it",           rule.value
    assert_equal %w(verona it).reverse, rule.labels
  end

  def test_equality_with_self
    rule = PublicSuffixService::Rule::Base.new("foo")
    assert_equal rule, rule
  end

  def test_equality_with_internals
    assert_equal      @klass.new("foo"), @klass.new("foo")
    assert_not_equal  @klass.new("foo"), @klass.new("bar")
    assert_not_equal  @klass.new("foo"), PublicSuffixService::Rule::Test.new("bar")
    assert_not_equal  @klass.new("foo"), Class.new { def name; foo; end }.new
  end


  def test_match
    assert  @klass.new("uk").match?("example.uk")
    assert !@klass.new("gk").match?("example.uk")
    assert !@klass.new("example").match?("example.uk")

    assert  @klass.new("uk").match?("example.co.uk")
    assert !@klass.new("gk").match?("example.co.uk")
    assert !@klass.new("co").match?("example.co.uk")

    assert  @klass.new("co.uk").match?("example.co.uk")
    assert !@klass.new("uk.co").match?("example.co.uk")
    assert !@klass.new("go.uk").match?("example.co.uk")
  end

  def test_length
    assert_raise(NotImplementedError) { @klass.new("com").length }
  end

  def test_parts
    assert_raise(NotImplementedError) { @klass.new("com").parts }
  end

  def test_decompose
    assert_raise(NotImplementedError) { @klass.new("com").decompose("google.com") }
  end

end


class PublicSuffixService::RuleNormalTest < Test::Unit::TestCase

  def setup
    @klass = PublicSuffixService::Rule::Normal
  end


  def test_initialize
    rule = @klass.new("verona.it")
    assert_instance_of @klass,              rule
    assert_equal :normal,                   rule.type
    assert_equal "verona.it",               rule.name
    assert_equal "verona.it",               rule.value
    assert_equal %w(verona it).reverse,     rule.labels
  end


  def test_match
    assert  @klass.new("uk").match?("example.uk")
    assert !@klass.new("gk").match?("example.uk")
    assert !@klass.new("example").match?("example.uk")

    assert  @klass.new("uk").match?("example.co.uk")
    assert !@klass.new("gk").match?("example.co.uk")
    assert !@klass.new("co").match?("example.co.uk")

    assert  @klass.new("co.uk").match?("example.co.uk")
    assert !@klass.new("uk.co").match?("example.co.uk")
    assert !@klass.new("go.uk").match?("example.co.uk")
  end

  def test_match_with_fully_qualified_domain_name
    assert  @klass.new("com").match?("com.")
    assert  @klass.new("com").match?("example.com.")
    assert  @klass.new("com").match?("www.example.com.")
  end

  def test_allow
    assert !@klass.new("com").allow?("com")
    assert  @klass.new("com").allow?("example.com")
    assert  @klass.new("com").allow?("www.example.com")
  end

  def test_allow_with_fully_qualified_domain_name
    assert !@klass.new("com").allow?("com.")
    assert  @klass.new("com").allow?("example.com.")
    assert  @klass.new("com").allow?("www.example.com.")
  end


  def test_length
    assert_equal 1, @klass.new("com").length
    assert_equal 2, @klass.new("co.com").length
    assert_equal 3, @klass.new("mx.co.com").length
  end

  def test_parts
    assert_equal %w(com), @klass.new("com").parts
    assert_equal %w(co com), @klass.new("co.com").parts
    assert_equal %w(mx co com), @klass.new("mx.co.com").parts
  end

  def test_decompose
    assert_equal [nil, nil], @klass.new("com").decompose("com")
    assert_equal %w( example com ), @klass.new("com").decompose("example.com")
    assert_equal %w( foo.example com ), @klass.new("com").decompose("foo.example.com")
  end

  def test_decompose_with_fully_qualified_domain_name
    assert_equal [nil, nil], @klass.new("com").decompose("com.")
    assert_equal %w( example com ), @klass.new("com").decompose("example.com.")
    assert_equal %w( foo.example com ), @klass.new("com").decompose("foo.example.com.")
  end

end


class PublicSuffixService::RuleExceptionTest < Test::Unit::TestCase

  def setup
    @klass = PublicSuffixService::Rule::Exception
  end


  def test_initialize
    rule = @klass.new("!british-library.uk")
    assert_instance_of @klass,                    rule
    assert_equal :exception,                      rule.type
    assert_equal "!british-library.uk",           rule.name
    assert_equal "british-library.uk",            rule.value
    assert_equal %w(british-library uk).reverse,  rule.labels
  end


  def test_match
    assert  @klass.new("!uk").match?("example.co.uk")
    assert !@klass.new("!gk").match?("example.co.uk")
    assert  @klass.new("!co.uk").match?("example.co.uk")
    assert !@klass.new("!go.uk").match?("example.co.uk")
    assert  @klass.new("!british-library.uk").match?("british-library.uk")
    assert !@klass.new("!british-library.uk").match?("example.co.uk")
  end

  def test_match_with_fully_qualified_domain_name
    assert  @klass.new("!uk").match?("uk.")
    assert  @klass.new("!uk").match?("co.uk.")
    assert  @klass.new("!uk").match?("example.co.uk.")
    assert  @klass.new("!uk").match?("www.example.co.uk.")
  end

  def test_allow
    assert !@klass.new("!british-library.uk").allow?("uk")
    assert  @klass.new("!british-library.uk").allow?("british-library.uk")
    assert  @klass.new("!british-library.uk").allow?("www.british-library.uk")
  end

  def test_allow_with_fully_qualified_domain_name
    assert !@klass.new("!british-library.uk").allow?("uk.")
    assert  @klass.new("!british-library.uk").allow?("british-library.uk.")
    assert  @klass.new("!british-library.uk").allow?("www.british-library.uk.")
  end


  def test_length
    assert_equal 1, @klass.new("!british-library.uk").length
    assert_equal 2, @klass.new("!foo.british-library.uk").length
  end

  def test_parts
    assert_equal %w( uk ), @klass.new("!british-library.uk").parts
    assert_equal %w( tokyo jp ), @klass.new("!metro.tokyo.jp").parts
  end

  def test_decompose
    assert_equal [nil, nil], @klass.new("!british-library.uk").decompose("uk")
    assert_equal %w( british-library uk ), @klass.new("!british-library.uk").decompose("british-library.uk")
    assert_equal %w( foo.british-library uk ), @klass.new("!british-library.uk").decompose("foo.british-library.uk")
  end

  def test_decompose_with_fully_qualified_domain_name
    assert_equal [nil, nil], @klass.new("!british-library.uk").decompose("uk.")
    assert_equal %w( british-library uk ), @klass.new("!british-library.uk").decompose("british-library.uk.")
    assert_equal %w( foo.british-library uk ), @klass.new("!british-library.uk").decompose("foo.british-library.uk.")
  end

end


class PublicSuffixService::RuleWildcardTest < Test::Unit::TestCase

  def setup
    @klass = PublicSuffixService::Rule::Wildcard
  end


  def test_initialize
    rule = @klass.new("*.aichi.jp")
    assert_instance_of @klass,              rule
    assert_equal :wildcard,                 rule.type
    assert_equal "*.aichi.jp",              rule.name
    assert_equal "aichi.jp",                rule.value
    assert_equal %w(aichi jp).reverse,      rule.labels
  end


  def test_match
    assert  @klass.new("*.uk").match?("example.uk")
    assert  @klass.new("*.uk").match?("example.co.uk")
    assert  @klass.new("*.co.uk").match?("example.co.uk")
    assert !@klass.new("*.go.uk").match?("example.co.uk")
  end

  def test_match_with_fully_qualified_domain_name
    assert  @klass.new("*.uk").match?("uk.")
    assert  @klass.new("*.uk").match?("co.uk.")
    assert  @klass.new("*.uk").match?("example.co.uk.")
    assert  @klass.new("*.uk").match?("www.example.co.uk.")
  end

  def test_allow
    assert !@klass.new("*.uk").allow?("uk")
    assert !@klass.new("*.uk").allow?("co.uk")
    assert  @klass.new("*.uk").allow?("example.co.uk")
    assert  @klass.new("*.uk").allow?("www.example.co.uk")
  end

  def test_allow_with_fully_qualified_domain_name
    assert !@klass.new("*.uk").allow?("uk.")
    assert !@klass.new("*.uk").allow?("co.uk.")
    assert  @klass.new("*.uk").allow?("example.co.uk.")
    assert  @klass.new("*.uk").allow?("www.example.co.uk.")
  end


  def test_length
    assert_equal 2, @klass.new("*.uk").length
    assert_equal 3, @klass.new("*.co.uk").length
  end

  def test_parts
    assert_equal %w( uk ), @klass.new("*.uk").parts
    assert_equal %w( co uk ), @klass.new("*.co.uk").parts
  end

  def test_decompose
    assert_equal [nil, nil], @klass.new("*.do").decompose("nic.do")
    assert_equal %w( google co.uk ), @klass.new("*.uk").decompose("google.co.uk")
    assert_equal %w( foo.google co.uk ), @klass.new("*.uk").decompose("foo.google.co.uk")
  end

  def test_decompose_with_fully_qualified_domain_name
    assert_equal [nil, nil], @klass.new("*.do").decompose("nic.do.")
    assert_equal %w( google co.uk ), @klass.new("*.uk").decompose("google.co.uk.")
    assert_equal %w( foo.google co.uk ), @klass.new("*.uk").decompose("foo.google.co.uk.")
  end

end
