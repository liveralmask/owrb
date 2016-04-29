require "owrb/version"

require "uri"
require "json"
require "nokogiri"
require "watir-webdriver"

module Owrb
  module URL
    def self.parse( url )
      URI.parse( url )
    end
  end
  
  module JSON
    def self.encode( value )
      ::JSON.generate( value )
    end
    
    def self.decode( value )
      ::JSON.parse( value )
    end
  end
  
  module HTML
    class Element
      attr_reader :name, :attributes
      
      def initialize( element )
        @name = element.name
        @attributes = {}
        element.attributes.each{|name, attribute|
          @attributes[ attribute.name ] = attribute.value
        }
      end
    end
    
    class Document
      def initialize( document )
        @document = document
      end
      
      def xpath( expression )
        elements = []
        @document.xpath( expression ).each{|element|
          elements.push Element.new( element )
        }
        elements
      end
    end
    
    def self.parse( code )
      Document.new( Nokogiri::HTML.parse( code ) )
    end
  end
  
  class Browser
    def initialize( type = :phantomjs )
      @browser = Watir::Browser.new( type )
    end
    
    def html
      @browser.html
    end
    
    def go( url )
      @browser.goto( url )
    end
    
    def click( expression )
      @browser.element( :xpath, expression ).click
    end
    
    def quit
      @browser.quit
    end
  end
  
=begin
  class Cipher
    def encode
      
    end
    
    def decode
      
    end
  end
=end
end
