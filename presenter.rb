require 'rubygems'
require 'activesupport'
require 'test/unit'

module Presenter
  class Base
    attr_accessor :object
    
    def initialize(object)
      self.object = object
      self.class.send(:define_method, object.class.name.underscore){ object }
    end
  end
  
  class Proxy
    instance_methods.each do |method|
      undef_method(method) if method !~ /^(__|instance_eval|class|object_id|returning)/
    end
    
    attr_accessor :__object, :__presenter, :__module
    
    def initialize(object)
      self.__object = object
      self.__module = "#{object.class.name.pluralize}Presenter".constantize
      self.__presenter = Presenter::Base.new(object).extend(self.__module)
    end
    
    def __present
      object = self.__object
      self.__module.class.send(:define_method, self.__object.class.name.underscore){ object }
      self.__module.present
    end

    def method_missing(method, *args)
      returning self.__object.send(method) do |result|
        presenter = self.__presenter
        result.class.send(:define_method, :__present) do
          presenter.send(method)
        end
      end
    end
  end
end

module UsersPresenter
  def self.present
    user.name
  end
  
  def homepage
    '<a href="' + user.homepage + '">' + user.homepage + '</a>'
  end
end

class User
  attr_accessor :homepage, :name
end

def p(method)
  method.__present
end

if $0 == __FILE__
  class PresenterTest < Test::Unit::TestCase
    def setup
      @john = User.new
      @john.homepage = "http://matid.net"
      @john.name = "John"
      @presented_john = Presenter::Proxy.new(@john)
    end
    
    def test_present_user_homepage
      assert_equal "http://matid.net", @john.homepage
      assert_equal 'http://matid.net', @presented_john.homepage
      assert_equal '<a href="http://matid.net">http://matid.net</a>', p(@presented_john.homepage)
    end
    
    def test_present_user
      assert_equal "John", @presented_john.name
      assert_equal "John", p(@presented_john)
    end
  end
end