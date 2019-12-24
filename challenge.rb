require 'watir'
require 'json'

class LinkedinMessageSender

   def initialize
      #Read the json config file
      jsonString = File.read("./config.json")
      @parsedJson = JSON.parse jsonString
      case @parsedJson["browser"]
          when 'chrome'
              @browser = Watir::Browser.new :chrome
          when 'ie'
              @browser = Watir::Browser.new :ie
          else
              @browser = Watir::Browser.new :firefox
      end

      # Go to LinkedIn and maximise the browser if needed 
      @browser.goto('www.linkedin.com')
      @browser.window.maximize
   end

   def clickElement(identifier, selector)
      until @browser.element(identifier => selector).exists? do
         sleep(0.5)
      end
      @browser.element(identifier => selector).click
   end

   def fillInput(identifier, selector, string)
      until @browser.element(identifier => selector).exists? do
         sleep(0.5)
      end
      @browser.element(identifier => selector).send_keys(string)
   end

   def Login
      # Click the Sign In button
      clickElement(:class, "nav__button-secondary")

      #Type Username
      fillInput(:id, "username", @parsedJson["username"])

      #Type Password
      fillInput(:id, "password", @parsedJson["password"])

      #Click on Submit
      clickElement(:type, "submit")
   end

   def FindAccount
       # Search for the account we want to send message to
       until @browser.input(:class => ["search-global-typeahead__input", "always-show-placeholder"], :type => "text", :role => "combobox").exists? do
           sleep(1)
       end
       input = @browser.input(:class => ["search-global-typeahead__input", "always-show-placeholder"], :type => "text", :role => "combobox")
       input.send_keys(@parsedJson["account"])
       input.send_keys(:enter)

       # Click on the input
       until @browser.span(:class => ["name", "actor-name"], :text => @parsedJson["account"] ).exists? do
           sleep(1)
       end
       @browser.span(:class => ["name", "actor-name"], :text => @parsedJson["account"] ).click
   end

   def SendMessage
       if @parsedJson["reallySendMessage"]
           #Click the Message button
           until @browser.span( :text => /Message/).exists? do
               sleep(1)
           end
           @browser.span(:text => /Message/).click
 
           #Type the message to send
           fillInput(:class, ["msg-form__contenteditable", "t-14", "t-black--light", "t-normal", "flex-grow-1", "notranslate"], @parsedJson["message"])

           #Click the Send button
           clickElement(:class, ["msg-form__send-button", "artdeco-button", "artdeco-button--1"])
       end
   end

   def Logout
       #Click the Me button
       clickElement(:class, ["nav-item__title", "nav-item__dropdown-trigger--title"])

       #Click on Sign out
       until @browser.element( :tag_name => "a", :class => ["block", "ember-view"], :text => /Sign out/).exists? do
          sleep(1)
       end
       @browser.element( :tag_name => "a", :class => ["block", "ember-view"], :text => /Sign out/).click
       until !(@browser.element( :tag_name => "a", :class => ["block", "ember-view"], :text => /Sign out/).exists?) do
          sleep(1)
       end

       #Close the browser
       @browser.quit
   end

end

sender = LinkedinMessageSender.new
sender.Login
sender.FindAccount
sender.SendMessage
sender.Logout
