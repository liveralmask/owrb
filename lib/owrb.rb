require "owrb/version"

require "uri"
require "json"
require "nokogiri"
require "watir-webdriver"
require "omniauth"
require "omniauth-twitter"
require "omniauth-facebook"
require "omniauth-github"
require "openssl"
require "base64"

module Owrb
  module URL
    def self.parse( url )
      URI.parse( url )
    end
    
    def self.encode( url )
      URI.encode( url )
    end
    
    def self.decode( url )
      URI.decode( url )
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
      attr_reader :element, :name, :attributes, :inner_html
      
      def initialize( element )
        @element = element
        @name = element.name
        @attributes = {}
        element.attributes.each{|name, attribute|
          @attributes[ attribute.name ] = attribute.value
        }
        @inner_html = element.inner_html
      end
      
      def to_h
        {
          :name       => @name,
          :attributes => @attributes,
          :inner_html => @inner_html,
        }
      end
    end
    
    class Document
      attr_reader :document
      
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
    
    module Style
      def self.css( name, *args )
        <<EOS
#{name} {
  #{args.collect{|styles| styles.join( ";\n  " )}.join( ";\n  " )}
}
EOS
      end
      
      def self.border( styles )
        result = []
        result.push "border: #{styles[ :border ]}" if styles.key?( :border )
        if styles.key?( :radius )
          result.push "border-radius: #{styles[ :radius ]}"
          result.push "-webkit-border-radius: #{styles[ :radius ]}"
          result.push "-moz-border-radius: #{styles[ :radius ]}"
        end
        result
      end
      
      def self.font( styles )
        result = []
        result.push "font-size: #{styles[ :size ]}" if styles.key?( :size )
        result.push "font-weight: #{styles[ :style ]}" if styles.key?( :style )
        result.push "font-family: #{styles[ :family ]}" if styles.key?( :family )
        result
      end
      
      def self.text( styles )
        result = []
        result.push "text-decoration: #{styles[ :decoration ]}" if styles.key?( :decoration )
        result.push "text-shadow: #{styles[ :shadow ]}" if styles.key?( :shadow )
        result.push "color: #{styles[ :color ]}" if styles.key?( :color )
        result
      end
      
      def self.background( styles )
        result = []
        if styles.key?( :linear_gradient )
          color = styles[ :linear_gradient ][ :color ]
          result.push "background-color: #{color[ 0 ]}"
          result.push "background-image: -webkit-gradient(linear, left top, left bottom, from(#{color[ 0 ]}), to(#{color[ 1 ]}))"
          result.push "background-image: -webkit-linear-gradient(top, #{color[ 0 ]}, #{color[ 1 ]})"
          result.push "background-image: -moz-linear-gradient(top, #{color[ 0 ]}, #{color[ 1 ]})"
          result.push "background-image: -ms-linear-gradient(top, #{color[ 0 ]}, #{color[ 1 ]})"
          result.push "background-image: -o-linear-gradient(top, #{color[ 0 ]}, #{color[ 1 ]})"
          result.push "background-image: linear-gradient(to bottom, #{color[ 0 ]}, #{color[ 1 ]})"
        end
        result
      end
    end
  end
  
  class Browser
    attr_reader :browser
    
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
    
    def document
      HTML.parse( @browser.html )
    end
  end
  
  module Rails
    module Auth
      def self.provider( type, key, secret )
        key = key.to_s
        key = ENV[ key ] if ENV.key?( key )
        
        secret = secret.to_s
        secret = ENV[ secret ] if ENV.key?( secret )
        
        [ type, key, secret ]
      end
      
      def self.set( providers )
        ::Rails.application.config.middleware.use ::OmniAuth::Builder do
          providers.each{|args|
            provider *Auth.provider( *args )
          }
        end
      end
    end
    
    class Cookie
      attr_reader :cookies
      
      def initialize( cookies )
        @cookies = cookies
      end
      
      def get( key, default_value )
        value = @cookies.signed[ key ]
        value.nil? ? default_value : value
      end
      
      def set( key, value, expires = 1.years.from_now )
        @cookies.signed[ key ] = { :value => value, :expires => expires }
      end
      
      def delete( key )
        @cookies.delete key
      end
    end
  end
  
  module Data
    def self.hash( data )
      Digest::SHA512::hexdigest( data )
    end
    
    class Cipher
      attr_reader   :cipher
      attr_accessor :key, :iv
      
      def initialize( cipher )
        @cipher = cipher
        @key = ""
        @iv = ""
      end
      
      def key_iv( pass, salt, count = 2000 )
        result = OpenSSL::PKCS5.pbkdf2_hmac_sha1( pass, salt, count, @cipher.key_len + @cipher.iv_len )
        @key = result[ 0, @cipher.key_len ]
        @iv = result[ @cipher.key_len, @cipher.iv_len ]
        [ @key, @iv ]
      end
      
      def encrypt( data )
        @cipher.encrypt
        @cipher.key = @key
        @cipher.iv = @iv
        "#{@cipher.update( data )}#{@cipher.final}"
      end
      
      def decrypt( data )
        @cipher.decrypt
        @cipher.key = @key
        @cipher.iv = @iv
        "#{@cipher.update( data )}#{@cipher.final}"
      end
    end
    
    def self.cipher( name = "AES-256-CBC" )
      Cipher.new( OpenSSL::Cipher.new( name ) )
    end
    
    module Base64
      def self.encode( data )
        ::Base64.urlsafe_encode64( data )
      end
      
      def self.decode( data )
        ::Base64.urlsafe_decode64( data )
      end
    end
  end
  
  class Time
    def initialize
      @value = ::Time.now
    end
    
    def to_s
      @value.strftime( "%Y/%m/%d %H:%M:%S.%6N" )
    end
  end
end
